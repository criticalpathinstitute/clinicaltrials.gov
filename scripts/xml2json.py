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
import xmlschema
import dateparser
import datetime as dt
from rich.progress import track
from itertools import chain
from functools import partial
from pprint import pprint
from xml.etree.ElementTree import ElementTree
from pathlib import Path
from typing import Dict, List, NamedTuple, Tuple, Any, TextIO, Optional


class Args(NamedTuple):
    """ Command-line arguments """
    files: List[str]
    outdir: str
    schema: TextIO


class OversightInfo(NamedTuple):
    """ OversightInfo """
    has_dmc: str
    is_fda_regulated_drug: str
    is_fda_regulated_device: str
    is_unapproved_device: str
    is_ppsd: str
    is_us_export: str


class StudyDesign(NamedTuple):
    """ StudyDesign """
    allocation: str
    intervention_model: str
    intervention_model_description: str
    primary_purpose: str
    observational_model: str
    time_perspective: str
    masking: str
    masking_description: str


class Enrollment(NamedTuple):
    """ Enrollment """
    enrollment_type: str
    value: int


class ProtocolOutcome(NamedTuple):
    """ ProtocolOutcome """
    measure: str
    time_frame: str
    description: str


class ArmGroup(NamedTuple):
    """ ArmGroup """
    arm_group_label: str
    arm_group_type: str
    description: str


class Eligibility(NamedTuple):
    """ Eligibility """
    study_pop: str
    sampling_method: str
    criteria: str
    gender: str
    gender_based: str
    gender_description: str
    minimum_age: str
    maximum_age: str
    healthy_volunteers: str


class Intervention(NamedTuple):
    """ Intervention """
    intervention_type: str
    intervention_name: str
    description: str
    arm_group_label: Optional[List[str]]
    other_name: Optional[List[str]]


class Study(NamedTuple):
    """ Study """
    nct_id: str
    org_study_id: str
    brief_title: str
    official_title: str
    acronym: str
    source: str
    brief_summary: str
    detailed_description: str
    overall_status: str
    last_known_status: str
    why_stopped: str
    start_date: str
    completion_date: str
    primary_completion_date: str
    phase: str
    study_type: str
    has_expanded_access: str
    target_duration: str
    biospec_retention: str
    biospec_description: str
    conditions: List[str]
    eligibility: Optional[Eligibility]
    number_of_arms: Optional[int]
    number_of_groups: Optional[int]
    enrollment: Optional[Enrollment]
    oversight_info: Optional[OversightInfo]
    study_design: Optional[StudyDesign]
    primary_outcomes: List[ProtocolOutcome]
    secondary_outcomes: List[ProtocolOutcome]
    other_outcomes: List[ProtocolOutcome]
    arm_groups: List[ArmGroup]
    interventions: List[Intervention]


# class Sponsor(NamedTuple):
#     """ Sponsor """
#     sponsor_type: str
#     agency: str
#     agency_class: str


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

    parser.add_argument('-s',
                        '--schema',
                        help='XML Schema',
                        metavar='FILE',
                        type=argparse.FileType('rt'))

    args = parser.parse_args()

    if not os.path.isdir(args.outdir):
        os.makedirs(args.outdir)

    if args.dir and not args.file:
        if not os.path.isdir(args.dir):
            args.dir = os.path.abspath(args.dir)

        args.file = list(Path(args.dir).rglob('*.xml'))

    if not args.file:
        parser.error('Must indicate either input --file or --dir')

    return Args(args.file, args.outdir, args.schema)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()
    schema = xmlschema.XMLSchema(args.schema)

    num_files = len(list(args.files))
    print(f'Processing {num_files:,} file{"" if num_files == 1 else "s"}.')

    num_written = 0
    for file in track(args.files, description="Processing..."):
        # Determine outfile
        basename = os.path.basename(file)
        root = os.path.splitext(basename)[0]
        out_file = os.path.join(args.outdir, root + '.json')
        print(file)

        # Skip existing files
        # if os.path.isfile(out_file):
        #     continue

        # Set the "text" to all the distinct words
        # xml = xmltodict.parse(open(file).read())
        xml = schema.to_dict(open(file).read())
        tree = ElementTree().parse(file)
        xml['text'] = ' '.join(
            set(chain.from_iterable((map(words, flatten(tree))))))

        study = restructure(xml)
        pprint(str(study))

        # Convert to JSON
        out_fh = open(out_file, 'wt')
        out_fh.write(json.dumps(xml, indent=4) + '\n')
        out_fh.close()
        num_written += 1
        break

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
def get_textblock(xml, field):
    """ Get textblock """

    if block := xml.get(field):
        return re.sub('\s+', ' ', block.get('textblock')).strip()

    return ''


# --------------------------------------------------
def get_study_design(xml: str) -> Optional[StudyDesign]:
    """ Get StudyDesign """

    if val := xml.get('study_design_info'):
        return StudyDesign(allocation=val.get('allocation', ''),
                           intervention_model=val.get('intervention_model',
                                                      ''),
                           intervention_model_description=val.get(
                               'intervention_model_description', ''),
                           primary_purpose=val.get('primary_purpose', ''),
                           observational_model=val.get('observational_model',
                                                       ''),
                           time_perspective=val.get('time_perspective', ''),
                           masking=val.get('masking', ''),
                           masking_description=val.get('masking_description',
                                                       ''))


# --------------------------------------------------
def get_oversight(xml: str) -> Optional[OversightInfo]:
    """ Get oversight """

    if val := xml.get('oversight_info'):
        return OversightInfo(
            has_dmc=val.get('has_dmc', ''),
            is_fda_regulated_drug=val.get('is_fda_regulated_drug', ''),
            is_fda_regulated_device=val.get('is_fda_regulated_device', ''),
            is_unapproved_device=val.get('is_unapproved_device', ''),
            is_ppsd=val.get('is_ppsd', ''),
            is_us_export=val.get('is_us_export', ''))


# --------------------------------------------------
def get_date(val: Any) -> str:
    """ Get date """

    if isinstance(val, dict) and '$' in val:
        if dp := dateparser.parse(val['$']):
            date = dt.datetime.utcfromtimestamp(dp.timestamp())
            return date.strftime("%Y-%m-%d")

    return ''


# --------------------------------------------------
def get_arm_groups(xml: Dict[str, Any], fld: str) -> List[ArmGroup]:
    """ Get arm groups """

    groups = []
    if fld in xml:
        for group in xml[fld]:
            groups += ArmGroup(arm_group_label=group.get(
                'arm_group_label', ''),
                               arm_group_type=group.get('arm_group_type', ''),
                               description=group.get('description', ''))

    return groups


# --------------------------------------------------
def get_protocols(xml: Dict[str, Any], fld: str) -> List[ProtocolOutcome]:
    """ Get protocols """

    protocols = []
    if fld in xml:
        for protocol in xml[fld]:
            protocols += ProtocolOutcome(measure=protocol['measure'],
                                         time_frame=protocol['time_frame'],
                                         description=protocol['description'])

    return protocols


# --------------------------------------------------
def get_interventions(xml: Dict[str, Any], fld: str) -> List[Intervention]:
    """ Get Intervention """

    ints = []
    if fld in xml:
        for val in xml[fld]:
            ints += Intervention(
                intervention_type=val.get('intervention_type', ''),
                intervention_name=val.get('intervention_name', ''),
                description=val.get('description', ''),
                arm_group_label=val.get('arm_group_label'),
                other_name=val.get('other_name'))

    return ints

# --------------------------------------------------
def get_eligibility(xml, fld) -> Optional[Eligibility]:
    """ Get eligibility """

    if val := xml.get(fld):
        return Eligibility(
            study_pop=val.get('study_pop', ''),
            sampling_method=val.get('sampling_method', ''),
            criteria=val.get('', ''),
            gender=val.get('', ''),
            gender_based=val.get('', ''),
            gender_description=val.get('', ''),
            minimum_age=val.get('', ''),
            maximum_age=val.get('', ''),
            healthy_volunteers=val.get('', ''))

# --------------------------------------------------
def get_enrollment(xml) -> Optional[Enrollment]:
    """ Get enrollment """

    if enrollment := xml.get('enrollment'):
        if isinstance(enrollment, int):
            return Enrollment(enrollment_type='', value=enrollment)

        if isinstance(enrollment, dict):
            return Enrollment(enrollment_type=enrollment.get('@type', ''),
                              value=enrollment.get('$'))


# --------------------------------------------------
def get_str_list(xml, fld) -> List[str]:
    """ List of strings """

    if fld in xml:
        val = xml.get(fld)
        if isinstance(val, str):
            return [val]
        if isinstance(val, list):
            return val

    return []


# --------------------------------------------------
def restructure(xml) -> Study:
    """ Restructure XML """

    return Study(
        nct_id=xml['id_info']['nct_id'],
        org_study_id=xml['id_info']['org_study_id'],
        brief_title=xml.get('brief_title', ''),
        official_title=xml.get('official_title', ''),
        acronym=xml.get('acronym', ''),
        source=xml.get('source', ''),
        brief_summary=get_textblock(xml, 'brief_summary'),
        detailed_description=get_textblock(xml, 'detailed_description'),
        overall_status=xml.get('overall_status', ''),
        last_known_status=xml.get('last_known_status', ''),
        why_stopped=xml.get('why_stopped', ''),
        start_date=get_date(xml.get('start_date', '')),
        completion_date=get_date(xml.get('completion_date', '')),
        primary_completion_date=get_date(xml.get('primary_completion_date',
                                                 '')),
        phase=xml.get('phase', ''),
        study_type=xml.get('study_type', ''),
        has_expanded_access=xml.get('has_expanded_access', ''),
        target_duration=xml.get('target_duration', ''),
        number_of_arms=xml.get('number_of_arms'),  # allow null
        number_of_groups=xml.get('number_of_groups'),  # allow null
        biospec_retention=xml.get('biospec_retention', ''),
        biospec_description=get_textblock(xml, 'biospec_descr'),
        eligibility=get_eligibility(xml, 'eligibility'),
        conditions=get_str_list(xml, 'condition'),
        enrollment=get_enrollment(xml),
        oversight_info=get_oversight(xml),
        study_design=get_study_design(xml),
        primary_outcomes=get_protocols(xml, 'primary_outcome'),
        secondary_outcomes=get_protocols(xml, 'secondary_outcome'),
        other_outcomes=get_protocols(xml, 'other_outcome'),
        arm_groups=get_arm_groups(xml, 'arm_group'),
        interventions=get_interventions(xml, 'intervention'))


# --------------------------------------------------
if __name__ == '__main__':
    main()
