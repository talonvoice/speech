alias egrep='egrep --line-buffered'
wikifind() {
    find "$1" -type f | sort -n
}
wikicat() {
    wikifind "$1" | xargs bzcat
}
wikifilter() {
    egrep -v '[<>|0-9\-]' |\
        egrep '\.$' |\
        # tr '[A-Z]' '[a-z]' |\
        tr -dC "[ A-Za-z'.\n]" |\
        sed -Ee 's,\([^)]*\),,g' -e 's/ \.\.\. / /g' |\
        sed -Ee "s/'([A-Za-z]*)'/\\1/g"
}
extract_vocab() {
    egrep -o "\\b[a-z0-9'\\-]*\\b"
}

if [[ ! -e "vocab" ]]; then
    echo "[+] Extracting Vocab"
    IFS=$'\n'
    :>vocab
    for file in $(wikifind); do
        echo " [-] $file"
        bzcat "$file" | wikifilter | extract_vocab | sort -u >> vocab
    done
fi

wikicat "enwiki" | wikifilter | ~/build/kenlm/build/bin/lmplz -S 4G  -o 4 --prune 0 0 1 > enwiki.arpa
