#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2020-12-11
Purpose: Rock the Casbah
"""

import argparse
import xmlschema
from pprint import pprint
from xml.etree.ElementTree import ElementTree
from pathlib import Path
from typing import NamedTuple, TextIO


class Args(NamedTuple):
    """ Command-line arguments """
    dirname: str
    schema: TextIO

# class Study(NamedTuple):
#     """ A Study """


# --------------------------------------------------
def get_args() -> Args:
    """ Get command-line arguments """

    parser = argparse.ArgumentParser(
        description='Find all graphs',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('dir',
                        help='Input directory',
                        metavar='DIR',
                        type=str)


    parser.add_argument('-s',
                        '--schema',
                        help='XML schema',
                        metavar='FILE',
                        type=argparse.FileType('rt'),
                        default='public.xsd')

    args = parser.parse_args()

    return Args(args.dir, args.schema)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()
    #files = list(Path(args.dirname).rglob('*.xml'))
    files = ['../xml/NCT0326xxxx/NCT03260985.xml']
    schema = xmlschema.XMLSchema(args.schema)

    for i, file in enumerate(files, start=1):
        print(f'{i:6}: {file}')
        d = schema.to_dict(file)
        pprint(d)

        # tree = ElementTree().parse(file)
        # for title in tree.findall('brief_title'):
        #     print('Title:', title.text)

        break

    print('Done.')


# --------------------------------------------------
if __name__ == '__main__':
    main()
