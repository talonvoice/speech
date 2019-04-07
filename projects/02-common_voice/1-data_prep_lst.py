#!/usr/bin/python3

import csv
import itertools
import os
import re
import shutil
import sox
import sys

dataset = '/data/datasets/common_voice'
basedir = '/data/projects/02-common_voice'
datadir = os.path.join(basedir, 'data')

if not os.path.exists(basedir):
    os.makedirs(basedir)
os.chdir(basedir)

words_re = re.compile(r'[a-zA-Z]+')

all_tokens = set()
all_tokens.update("|'")

def tokenize(phrase):
    out = []
    last_c = None
    for c in phrase:
        if c == last_c:
            continue
        last_c = c
        if c.isalpha():
            out.append(c.lower())
        elif c == ' ':
            out.append('|')
    all_tokens.update(out)
    return ' '.join(out)

all_words = set()

# client_id     path    sentence        up_votes        down_votes      age     gender  accent
def generate_dataset(name, tsv):
    print('[+]', name)
    list_path = os.path.join(datadir, name + '.lst')
    number = itertools.count()

    with open(os.path.join(dataset, tsv)) as f, open(list_path, 'w') as lst:
        reader = csv.DictReader(f, dialect='excel-tab')
        for row in reader:
            path = os.path.join(dataset, 'flac', row['path'] + '.flac')
            try:
                duration = sox.file_info.duration(path) * 1000
            except OSError:
                continue

            file_id = next(number)
            sys.stdout.write('\r[-] {}-{:09d}'.format(name, file_id))
            sys.stdout.flush()

            words = words_re.findall(row['sentence'].lower())
            for word in words:
                all_words.add(word)

            lst.write(' '.join((
                '{}-{:09d}'.format(name, file_id),
                path, str(duration), ' '.join(words),
            )) + '\n')

    sys.stdout.write('\n\n')

generate_dataset('train', 'train.tsv')
generate_dataset('test', 'test.tsv')
#generate_dataset('other', 'other.tsv')
generate_dataset('valid', 'validated.tsv')
generate_dataset('dev', 'dev.tsv')

with open(os.path.join(datadir, 'lexicon.txt'), 'w') as f:
    for word in all_words:
        tokens = tokenize(word)
        f.write('{} {}\n'.format(word, tokens))

with open(os.path.join(datadir, 'tokens.txt'), 'w') as f:
    for token in all_tokens:
        f.write(token + '\n')
