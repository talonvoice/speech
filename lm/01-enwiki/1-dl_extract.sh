#!/bin/bash -u
aria2c https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles-multistream.xml.bz2
git clone https://github.com/attardi/wikiextractor.git
python3 wikiextractor/WikiExtractor.py -o enwiki -b100M -c --no_templates --filter_disambig_pages enwiki-latest-pages-articles-multistream.xml.bz2
