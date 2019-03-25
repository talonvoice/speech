#!/bin/bash -u
mkdir -p flac
find clips -type f | xargs -n1 -P 64 ./mp3_to_flac.sh
