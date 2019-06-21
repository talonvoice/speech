#!/bin/bash -u
base=$(basename "$1" .mp3)
[[ ! -e "flac/$base.flac" ]] && sox -G "clips/$base.mp3" -r 16000 "flac/$base.flac"
