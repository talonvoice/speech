#!/bin/bash -u

dataset="/data/datasets/tedlium/TEDLIUM_release-3/data"
basedir="/data/projects/05-tedlium"
datadir="$basedir/data"

clean_sentence() {
    sed -E \
        -e '/\$/d' \
        -e '/4shbab/d' \
        -e "s/ '/'/g" \
        -e 's/<unk>//g' \
        -e 's/\[.*(\]|$)//g' \
        -e 's/.*\]//g' \
        -e "s/(^| )'( |$)//g" \
        -e 's/@ robotinthewild/robot in the wild/' \
        -e 's/=/equals/g' \
        -e 's/([0-9]) [^0-9]*?]/\1 /g' \
        -e 's/two \^ five/two to the power of five/g' \
        -e 's/\^//g' \
        -e 's/\\//g' \
        -e 's/@/at/g' \
        -e 's/ālep/aleph/g' \
        -e 's/# two/number two/g' \
        -e 's/f #/f sharp/g' \
        -e 's/#//g' \
        -e 's/%/percent/g' \
        -e 's/&/and/g' \
        -e 's/\*//g' \
        -e 's/romeo \+ juliet/romeo and juliet/' \
        -e 's/\+/plus/g' \
        -e 's/ +/ /g' \
        -e 's/(^ | $)//g'
}

process_talk() {
    local name="$1"
    local i=1
    local file=$(cat "$dataset/stm/${name}.stm")
    local length=$(wc -l <<<$file)
    for line in $file; do
        # echo -ne "\r  Clip [$i/$length]"
        local s_start=$(cut -d' ' -f 4 <<<$line)
        local s_end=$(cut -d' ' -f 5 <<<$line)
        local sentence=$(cut -d' ' -f 7- <<<$line | clean_sentence)
        local s_length=$(echo "$s_end - $s_start" | bc)
        local duration=$(echo "$s_length * 1000" | bc)
        local clip="$datadir/clips/${name}-${i}.flac"
        if [[ ! -e "$clip" ]]; then
            sox "$dataset/sph/$name.sph" "$clip" trim "$s_start" "$s_length"
        fi
        [[ -z "$sentence" ]] && continue
        echo "${name}-${i} $(realpath "$clip") $duration $sentence" >> "$datadir/clips.txt/${name}"
        let i++
    done
    # echo
}

rm -rf "$datadir/clips.txt"
mkdir -p "$datadir/clips"
mkdir -p "$datadir/clips.txt"

IFS=$'\n'
stms=$(ls -1 "$dataset/stm/")
count=$(echo "$stms" | wc -l)
pos=1
njobs=0
maxjobs=256
for stm in $stms; do
    name=$(basename "$stm" .stm)
    echo "[$pos/$count] $name"
    process_talk "$name" &
    let pos++
    let njobs++
    if [[ "$njobs" -eq "$maxjobs" ]]; then
        wait
        njobs=0
    fi
done
wait
find "$datadir/clips.txt" -type f -exec cat {} + > "$datadir/clips.lst"
rm -rf "$datadir/clips.txt"

cd "$datadir"
cut -d' ' -f4- clips.lst | tr ' ' '\n' | sort -u > words.txt

shuf clips.lst > clips.shuf
split -d -n l/10 clips.shuf clips.split
cat clips.split0[0] > test.lst
cat clips.split0[1] > dev.lst
cat clips.split0[2-9] > train.lst
rm clips.split* clips.shuf

script=$(cat <<EOF
import sys

for line in open(sys.argv[1], 'r'):
    word = line.strip().lower()
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
sed -e 's/./\0\n/g' words.txt | sort -u | grep -v '^$' > tokens.txt
echo '|' >> tokens.txt
