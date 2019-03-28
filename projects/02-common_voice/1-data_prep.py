#!/usr/bin/python3

import csv
import itertools
import os
import re
import shutil

dataset = '/data/datasets/common_voice'
basedir = '/data/projects/02-common_voice'
datadir = os.path.join(basedir, 'data')

if not os.path.exists(basedir):
    os.makedirs(basedir)
os.chdir(basedir)

if os.path.exists(datadir):
    shutil.rmtree(datadir)
os.makedirs(datadir)

class UniqueCounter:
    def __init__(self):
        self.mapping = {}

    def get(self, key):
        if not key in self.mapping:
            count = len(self.mapping)
            self.mapping[key] = count
        return self.mapping[key]

words_re = re.compile(r'[a-zA-Z]+')

unique_users = UniqueCounter()
unique_ages = UniqueCounter()
unique_accents = UniqueCounter()

all_tokens = set()
def tokenize(phrase):
    out = []
    for c in phrase:
        if c.isalpha():
            out.append(c.lower())
        elif c == ' ':
            out.append('|')
    all_tokens.update(out)
    return ' '.join(out)
# for parity with librispeech dataset
all_tokens.add("'")

all_sentences = set()
all_words = set()

# client_id	path	sentence	up_votes	down_votes	age	gender	accent

def generate_dataset(name, tsv, feed_sentence=False):
    os.makedirs(os.path.join(datadir, name))
    number = itertools.count()
    genders = {'female': 'F', 'male': 'M'}

    with open(os.path.join(dataset, tsv)) as f:
        reader = csv.DictReader(f, dialect='excel-tab')
        for row in reader:
            path = os.path.join(dataset, 'flac', row['path'] + '.flac')
            if not os.path.exists(path):
                continue

            file_id = next(number)
            prefix = os.path.join(datadir, name, '{:09d}'.format(file_id))
            user_id = unique_users.get(row['client_id'])

            if feed_sentence:
                all_sentences.add(row['sentence'])

            words = words_re.findall(row['sentence'])
            for word in words:
                all_words.add(word.lower())

            tokens = tokenize(row['sentence'])
            with open(prefix + '.tkn', 'w') as f:
                f.write(tokens + '\n')

            with open(prefix + '.wrd', 'w') as f:
                f.write(' '.join(words).lower() + '\n')

            with open(prefix + '.id', 'w') as f:
                f.write('file_id {}\n'.format(file_id))
                f.write('speaker_id {}\n'.format(user_id))
                f.write('gender {}\n'.format(genders.get(row['gender'], 'O')))
                f.write('accent {}\n'.format(unique_accents.get(row['accent'])))
                f.write('age {}\n'.format(unique_ages.get(row['age'])))
                f.write('up_votes {}\n'.format(row['up_votes']))
                f.write('down_votes {}\n'.format(row['down_votes']))

            os.link(path, prefix + '.flac')

generate_dataset('train', 'train.tsv', True)
generate_dataset('test', 'test.tsv', False)
generate_dataset('valid', 'validated.tsv', False)
generate_dataset('dev', 'dev.tsv', False)

with open(os.path.join(datadir, 'sentences.txt'), 'w') as f:
    for sentence in all_sentences:
        f.write(sentence + '\n')

with open(os.path.join(datadir, 'lexicon.txt'), 'w') as f:
    for word in all_words:
        tokens = tokenize(word)
        f.write('{} {}\n'.format(word, tokens))

with open(os.path.join(datadir, 'tokens.txt'), 'w') as f:
    for token in all_tokens:
        f.write(token + '\n')
