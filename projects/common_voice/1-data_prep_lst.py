#!/usr/bin/python3

import csv
import itertools
import os
import re
import shutil
import sox
import sys

dataset = '/data/datasets/common_voice'
basedir = '/data/processed/common_voice_2'

os.makedirs(basedir, exist_ok=True)
os.chdir(basedir)

words_re = re.compile(r"[a-zA-Z']+")

all_tokens = set()
all_tokens.update("|'")

def tokenize(phrase):
    out = []
    last_c = None
    for c in phrase:
        if c == last_c:
            continue
        last_c = c
        if c.isalpha() or c == "'":
            out.append(c.lower())
        elif c == ' ':
            out.append('|')
    all_tokens.update(out)
    return ' '.join(out)

all_words = set()

# client_id     path    sentence        up_votes        down_votes      age     gender  accent
def generate_dataset(name, tsv):
    print('[+]', name)
    list_path = os.path.join(basedir, name + '.lst')
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

            text = row['sentence'].lower()
            text = re.sub("[\u2018\u2019]", "'", text)
            text = text.replace("\u2014", " ")
            # filter out weird usage of quotes
            if text.startswith("'") and text.endswith("'"):
                text = text[1:-1].strip()
            text = re.sub(r"(^| )'( |$)", '', text)
            text = re.sub(r"\b'(\w)'\b'", r'\1', text)
            text = text.strip()
            if not text:
                continue

            good = True
            for c in text:
                if ord(c) > 128:
                    good = False
                    break
            if not good: continue

            words = words_re.findall(text)
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

with open(os.path.join(basedir, 'lexicon.txt'), 'w') as f:
    for word in all_words:
        tokens = tokenize(word)
        f.write('{} {}\n'.format(word, tokens))

with open(os.path.join(basedir, 'tokens.txt'), 'w') as f:
    for token in all_tokens:
        f.write(token + '\n')
