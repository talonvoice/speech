#!/bin/bash -u
base=$(basename "$1" .mp3)
[[ ! -e "flac/$base.flac" ]] && sox "clips/$base.mp3" "flac/$base.flac"
