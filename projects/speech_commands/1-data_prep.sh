#!/bin/bash -u

dataset="/data/datasets/speech_commands"
datadir="/data/processed/speech_commands"

mkdir -p "$datadir/clips"
rm -f "$datadir/clips.lst"

folders=$(find "$dataset" -type d | tail -n+2)
for dir in $folders; do
    echo "$dir"
    echo "$dir" | grep "^_" &>/dev/null && continue
    word=$(basename "$dir")
    find "$dir" -type f | while read path; do
        name=$(basename "$path" .wav)
        ln -f "$path" "$datadir/clips/${name}.wav"
        stat="$(sox "$path" -n stat 2>&1)"
        if [[ -n "$(echo "$stat" | grep FAIL)" ]]; then
            continue
        fi
        duration=$(echo "$stat" | grep Length | awk '{print $3 " * 1000"}' | bc)
        echo "$name $path $duration $word" >> "$datadir/clips.lst"
    done
done

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
