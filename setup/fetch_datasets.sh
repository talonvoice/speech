#!/bin/bash -u
mkdir -p /data/datasets
cd /data/datasets

fetch() {
    local dataset="$1"
    shift 1
    mkdir "$dataset"
    cd "$dataset"
    local IFS=$'\n'
    for url in "$@"; do
        aria2c -c -x 4 "$url"
    done
    cd ..
}

fetch speech_commands http://download.tensorflow.org/data/speech_commands_v0.01.tar.gz

fetch common_voice https://voice-prod-bundler-ee1969a6ce8178826482b88e843c335139bd3fb4.s3.amazonaws.com/cv-corpus-1/en.tar.gz

fetch tedlium http://www.openslr.org/resources/51/TEDLIUM_release-3.tgz

fetch tatoeba https://downloads.tatoeba.org/audio/tatoeba_audio_eng.zip

fetch librispeech \
    http://www.openslr.org/resources/12/dev-clean.tar.gz \
    http://www.openslr.org/resources/12/dev-other.tar.gz \
    http://www.openslr.org/resources/12/test-clean.tar.gz \
    http://www.openslr.org/resources/12/test-other.tar.gz \
    http://www.openslr.org/resources/12/train-clean-100.tar.gz \
    http://www.openslr.org/resources/12/train-clean-360.tar.gz \
    http://www.openslr.org/resources/12/train-other-500.tar.gz \
    http://www.openslr.org/resources/11/librispeech-lm-corpus.tgz \
    http://www.openslr.org/resources/11/librispeech-lm-norm.txt.gz \
    http://www.openslr.org/resources/11/librispeech-vocab.txt \
    http://www.openslr.org/resources/11/librispeech-lexicon.txt \
    http://www.openslr.org/resources/11/3-gram.arpa.gz \
    http://www.openslr.org/resources/11/3-gram.pruned.1e-7.arpa.gz \
    http://www.openslr.org/resources/11/3-gram.pruned.3e-7.arpa.gz \
    http://www.openslr.org/resources/11/4-gram.arpa.gz

fetch misc \
    http://www.openslr.org/resources/28/rirs_noises.zip \
    http://www.openslr.org/resources/45/ST-AEDS-20180100_1-OS.tgz \
    http://goofy.zamia.org/zamia-speech/corpora/noise.tar.xz

fetch swc \
    https://www2.informatik.uni-hamburg.de/nats/pub/SWC/SWC_English.tar
