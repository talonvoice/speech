#!/bin/bash -u

dataset="/data/datasets/tatoeba/tatoeba_audio_eng"
basedir="/data/projects/06-tatoeba"
datadir="$basedir/data"

clean_sentence() {
    tr -d '?.,"!%+&/;' |\
        tr -- '’₂ïé‑\-­' "'"'2ie   ' |\
        tr '[A-Z]' '[a-z]' |\
        egrep -av '[0-9]' |\
        sed -Ee "s/'([A-Za-z]*)'/\\1/g"
}

process_line() {
    local line="$1"
    local id=$(echo "$line" | cut -f1)
    local user=$(echo "$line" | cut -f2)
    local sentence=$(echo "$line" | cut -f3 | clean_sentence)
    local filepath="$dataset/audio/$user/$id.mp3"
    local clip="$datadir/clips/$user-$id.flac"

    if [[ "$id" = "4012255" ]]; then
        sentence=$(echo "$sentence" | egrep -o 'Why.*$')
    fi
    [[ -z "$sentence" ]] && return
    if [[ ! -e "$clip" ]]; then
        sox "$filepath" -r 16000 -b 16 "$clip"
        [[ ! -e "$clip" ]] && return
    fi
    local stat="$(sox "$clip" -n stat 2>&1)"
    if [[ -n "$(echo "$stat" | grep FAIL)" ]]; then
        return
    fi
    local duration=$(echo "$stat" | grep Length | awk '{print $3 " * 1000"}' | bc)
    echo "tatoeba-$user-$id $clip $duration $sentence" >> "$datadir/clips.lst"
}

:> "$datadir/clips.lst"
mkdir -p "$datadir/clips"

count=$(wc -l "$dataset/sentences_with_audio.csv" | awk '{print $1}')
pos=1
njobs=0
maxjobs=256
tail -n+2 "$dataset/sentences_with_audio.csv" | sort -u | while read line; do
    echo "[$pos/$count]"
    process_line "$line" &
    if [[ "$njobs" -eq "$maxjobs" ]]; then
        wait
        njobs=0
    fi
    let njobs++
    let pos++
done
wait

cd "$datadir"
cut -d' ' -f4- clips.lst | tr ' ' '\n' | sort -u > words.txt

shuf clips.lst > clips.shuf
split -d -n l/10 clips.shuf clips.split
cat clips.split0[0] > test.lst
cat clips.split0[1] > dev.lst
cat clips.split0[2-9] > train.lst
rm clips.split* clips.shuf

# build lexicon
script=$(cat <<EOF
import sys

for line in open(sys.argv[1], 'r'):
    word = line.strip().lower()
    if not word: continue
    sys.stdout.write(word)
    last = None
    for c in word:
        if c != last:
            sys.stdout.write(' ' + c)
            last = c
    sys.stdout.write('\n')
EOF
)
echo "$script" | python3 - words.txt > lexicon.txt
echo '|' > tokens.txt
sed -e 's/./\0\n/g' words.txt | sort -u | grep -av '^$' >> tokens.txt
