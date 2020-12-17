#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2020-12-04
Purpose: Rock the Casbah
"""

import argparse
import json
import os
import re
import xmltodict
from rich.progress import track
from itertools import chain
from functools import partial
from pprint import pprint
from xml.etree.ElementTree import ElementTree
from pathlib import Path
from typing import List, NamedTuple, Tuple, Any


class Args(NamedTuple):
    """ Command-line arguments """
    files: List[str]
    outdir: str

class Study(NamedTuple):
    """ Study """
    nct_id: str
    org_study_id: str
    title: str
    sponsors: List[Sponsor]
    source: str
    brief_summary: str
    detailed_description: str
    overall_status: str
    completion_date: str
    phase: str
    study_type: str
    study_design_allocation: str
    study_design_intervention_model: str
    study_design_primary_purpose: str
    study_design_masking: str
    primary_outcome: str
    secondary_outcome: str
    enrollment: str
    conditions: List[str]
    interventions: List[Intervention]
    eligibility_criteria: str
    eligibility_gender: str
    eligibility_minimum_age: str
    eligibility_maximum_age: str
    eligibility_healthy_volunteers: str


class Sponsor(NamedTuple):
    """ Sponsor """
    sponsor_type: str
    agency: str
    agency_class: str

class Intervention(NamedTuple):
    """ Intervention """
    intervention_type: str
    intervention_name: str


# --------------------------------------------------
def get_args() -> Args:
    """ Get command-line arguments """

    parser = argparse.ArgumentParser(
        description='Rock the Casbah',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-f',
                        '--file',
                        help='Input XML file(s)',
                        metavar='FILE',
                        type=str,
                        nargs='+')

    parser.add_argument('-d',
                        '--dir',
                        help='Directory of XML file',
                        metavar='DIR',
                        type=str)

    parser.add_argument('-o',
                        '--outdir',
                        help='Output directory',
                        metavar='DIR',
                        type=str,
                        default='json')

    args = parser.parse_args()

    if not os.path.isdir(args.outdir):
        os.makedirs(args.outdir)

    if args.dir and not args.file:
        if not os.path.isdir(args.dir):
            args.dir = os.path.abspath(args.dir)

        args.file = list(Path(args.dir).rglob('*.xml'))

    if not args.file:
        parser.error('Must indicate either input --file or --dir')

    return Args(args.file, args.outdir)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()

    num_files = len(list(args.files))
    print(f'Processing {num_files:,} file{"" if num_files == 1 else "s"}.')

    num_written = 0
    for file in track(args.files, description="Processing..."):
        # Determine outfile
        basename = os.path.basename(file)
        root = os.path.splitext(basename)[0]
        out_file = os.path.join(args.outdir, root + '.json')

        # Skip existing files
        if os.path.isfile(out_file):
            continue

        # Set the "text" to all the distinct words
        xml = xmltodict.parse(open(file).read())
        tree = ElementTree().parse(file)
        xml['text'] = ' '.join(
            set(chain.from_iterable((map(words, flatten(tree))))))

        # Convert to JSON
        out_fh = open(out_file, 'wt')
        out_fh.write(json.dumps(xml, indent=4) + '\n')
        out_fh.close()
        num_written += 1
        # break

    print(f'Done, wrote {num_written:,} to "{args.outdir}".')


# --------------------------------------------------
def words(t: Tuple[Any, str]) -> List[str]:
    """ Return the words from the tuple value """

    clean = partial(re.sub, '[^a-zA-Z0-9._-]', '')

    def stop(word):
        # digit
        if re.match('^[-]?[\d.]+$', word):
            return False

        if len(word) <= 1:
            return False

        if word in ('an', 'the', 'and'):
            return False

        return True

    return list(filter(stop, map(clean, t[1].lower().split())))


# --------------------------------------------------
def flatten(xml: str) -> List[Tuple[Any, Any]]:
    """ Flatten XML"""

    # https://stackoverflow.com/questions/2170610/
    # access-elementtree-node-parent-node
    parent_map = {c: p for p in xml.iter() for c in p}

    def find_parents(child, parents=[]):
        if parent := parent_map.get(child):
            parents.append(parent.tag)
            find_parents(parent, parents)

        return parents

    rec = []
    for child, parent in parent_map.items():
        path = '.'.join(list(reversed(find_parents(child, []))) + [child.tag])

        if text := child.text:
            if text := text.strip():
                rec.append((path, text))

        if attrib := child.attrib:
            for key, val in attrib.items():
                rec.append(('.'.join([path, key]), val))

    return rec


# --------------------------------------------------
def restructure(xml) -> Study:
    """ Restructure XML """


    pass

# --------------------------------------------------
if __name__ == '__main__':
    main()
