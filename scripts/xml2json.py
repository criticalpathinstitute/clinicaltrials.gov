#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2020-12-04
Purpose: Rock the Casbah
"""

import argparse
import dateparser
import datetime as dt
import json
# import namedtupled
import os
import re
import sys
import typedload
import xmlschema
import xmltodict
from rich.progress import track
from itertools import chain
from functools import partial
from pprint import pprint
from xml.etree.ElementTree import ElementTree
from pathlib import Path
from typing import Dict, List, NamedTuple, TypedDict, Tuple, Any, TextIO, Optional


class Args(NamedTuple):
    """ Command-line arguments """
    files: List[str]
    outdir: str
    schema: TextIO


class OversightInfo(TypedDict):
    """ OversightInfo """
    has_dmc: str
    is_fda_regulated_drug: str
    is_fda_regulated_device: str
    is_unapproved_device: str
    is_ppsd: str
    is_us_export: str


class StudyDesign(TypedDict):
    """ StudyDesign """
    allocation: str
    intervention_model: str
    intervention_model_description: str
    primary_purpose: str
    observational_model: str
    time_perspective: str
    masking: str
    masking_description: str


class Enrollment(TypedDict):
    """ Enrollment """
    enrollment_type: str
    value: int


class Reference(TypedDict):
    """ Reference """
    citation: str
    pmid: int


class ProtocolOutcome(TypedDict):
    """ ProtocolOutcome """
    measure: str
    time_frame: str
    description: str


class Contact(TypedDict):
    """ Contact """
    first_name: str
    middle_name: str
    last_name: str
    degrees: str
    phone: str
    phone_ext: str
    email: str


class Investigator(TypedDict):
    """ Investigator """
    first_name: str
    middle_name: str
    last_name: str
    degrees: str
    role: str
    affiliation: str


class ArmGroup(TypedDict):
    """ ArmGroup """
    arm_group_label: str
    arm_group_type: str
    description: str


class StudyDoc(TypedDict):
    """ StudyDoc """
    doc_id: str
    doc_type: str
    doc_url: str
    doc_comment: str


class ProvidedDocument(TypedDict):
    """ ProvidedDocument """
    document_type: str
    document_has_protocol: str
    document_has_icf: str
    document_has_sap: str
    document_date: str
    document_url: str


class PendingResult(TypedDict):
    """ PendingResult """
    submitted: str
    returned: str
    submission_canceled: str


class Eligibility(TypedDict):
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


class Intervention(TypedDict):
    """ Intervention """
    intervention_type: str
    intervention_name: str
    description: str
    arm_group_label: Optional[List[str]]
    other_name: Optional[List[str]]


class Study(TypedDict):
    """ Study """
    nct_id: str
    org_study_id: str
    brief_title: str
    official_title: str
    acronym: str
    source: str
    rank: str
    brief_summary: str
    detailed_description: str
    overall_status: str
    last_known_status: str
    why_stopped: str
    start_date: str
    completion_date: str
    verification_date: str
    study_first_submitted: str
    study_first_submitted_qc: str
    study_first_posted: str
    results_first_submitted: str
    results_first_submitted_qc: str
    results_first_posted: str
    disposition_first_submitted: str
    disposition_first_submitted_qc: str
    disposition_first_posted: str
    last_update_submitted: str
    last_update_submitted_qc: str
    last_update_posted: str
    primary_completion_date: str
    phase: str
    study_type: str
    has_expanded_access: str
    target_duration: str
    biospec_retention: str
    biospec_description: str
    text: str
    conditions: List[str]
    keywords: List[str]
    sponsors: List[str]
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
    interventions: List[Intervention]
    overall_official: List[Investigator]
    overall_contact: Optional[Contact]
    overall_contact_backup: Optional[Contact]
    references: List[Reference]
    condition_browse: List[str]
    intervention_browse: List[str]
    study_docs: List[str]
    provided_documents: List[ProvidedDocument]
    # pending_results: List[PendingResult]


# class Sponsor(TypedDict):
#     """ Sponsor """
#     sponsor: str


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
                        type=str,
                        nargs='+')

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
                        type=argparse.FileType('rt'),
                        required=True)

    args = parser.parse_args()

    if not os.path.isdir(args.outdir):
        os.makedirs(args.outdir)

    if args.dir and not args.file:
        filenames = []
        for dirname in args.dir:
            if not os.path.isdir(dirname):
                dirname = os.path.abspath(dirname)
            filenames.extend(list(Path(dirname).rglob('*.xml')))

        args.file = filenames

    if not args.file:
        parser.error('Must indicate either input --file or --dir')

    return Args(args.file, args.outdir, args.schema)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()
    schema = xmlschema.XMLSchema(args.schema.name)
    num_files = len(list(args.files))

    print(f'Processing {num_files:,} file{"" if num_files == 1 else "s"}.')

    num_written = 0
    errors = []
    for file in track(args.files, description="Processing..."):
        # Determine outfile
        basename = os.path.basename(file)
        root = os.path.splitext(basename)[0]
        out_file = os.path.join(args.outdir, root + '.json')
        # print(file)

        # Skip existing files
        # if os.path.isfile(out_file):
        #     continue

        # Set the "text" to all the distinct words
        # xml = xmltodict.parse(open(file).read())

        xml = open(file).read()
        if not schema.is_valid(xml):
            errors.append(f'Invalid document "{file}"')
            continue

        data = schema.to_dict(xml)
        tree = ElementTree().parse(file)
        all_text = ' '.join(
            set(chain.from_iterable((map(words, flatten(tree))))))

        study = restructure(data, all_text)
        # pprint(study)

        # Convert to JSON
        out_fh = open(out_file, 'wt')
        out_fh.write(json.dumps(typedload.dump(study), indent=4) + '\n')
        out_fh.close()
        num_written += 1

    if errors:
        print('\n'.join([f'{len(errors)} ERRORS:'] + errors), file=sys.stderr)

    print(f'Done, wrote {num_written:,} to "{args.outdir}".')


# --------------------------------------------------
def words(t: Tuple[Any, str]) -> List[str]:
    """ Return the words from the tuple value """
    def clean(s):
        s = re.sub('[\s_-]+', ' ', s)
        return re.sub('[^a-zA-Z0-9.\s]', '', s)

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
        for group in xml.get(fld):
            groups.append(
                ArmGroup(arm_group_label=group.get('arm_group_label', ''),
                         arm_group_type=group.get('arm_group_type', ''),
                         description=group.get('description', '')))

    return groups


# --------------------------------------------------
def get_protocols(xml: Dict[str, Any], fld: str) -> List[ProtocolOutcome]:
    """ Get protocols """

    protocols = []
    if fld in xml:
        for protocol in xml[fld]:
            protocols.append(
                ProtocolOutcome(measure=protocol.get('measure', ''),
                                time_frame=protocol.get('time_frame', ''),
                                description=protocol.get('description', '')))

    return protocols


# --------------------------------------------------
def get_references(xml: Dict[str, Any], fld: str) -> List[Reference]:
    """ Get references """

    refs = []
    if fld in xml:
        for val in xml[fld]:
            refs.append(
                Reference(citation=val.get('citation', ''),
                          pmid=val.get('pmid', 0)))

    return refs


# --------------------------------------------------
def get_interventions(xml: Dict[str, Any], fld: str) -> List[Intervention]:
    """ Get Intervention """

    ints = []
    if fld in xml:
        for val in xml[fld]:
            ints.append(
                Intervention(intervention_type=val.get('intervention_type',
                                                       ''),
                             intervention_name=val.get('intervention_name',
                                                       ''),
                             description=val.get('description', ''),
                             arm_group_label=val.get('arm_group_label'),
                             other_name=val.get('other_name')))

    return ints


# --------------------------------------------------
def get_investigators(xml: Dict[str, Any], fld: str) -> List[Investigator]:
    """ Get investigators """

    invs = []
    if fld in xml:
        for val in xml[fld]:
            invs.append(
                Investigator(first_name=val.get('first_name', ''),
                             middle_name=val.get('middle_name', ''),
                             last_name=val.get('last_name', ''),
                             degrees=val.get('degrees', ''),
                             role=val.get('role', ''),
                             affiliation=val.get('affiliation', '')))

    return invs


# --------------------------------------------------
def get_contact(xml: Dict[str, Any], fld: str) -> Optional[Contact]:
    """ Get contacts """

    if val := xml.get(fld):
        return Contact(first_name=val.get('first_name', ''),
                       middle_name=val.get('middle_name', ''),
                       last_name=val.get('last_name', ''),
                       degrees=val.get('degrees', ''),
                       phone=val.get('phone', ''),
                       phone_ext=val.get('phone_ext', ''),
                       email=val.get('email', ''))


# --------------------------------------------------
def get_eligibility(xml, fld) -> Optional[Eligibility]:
    """ Get eligibility """
    def textblock(x):
        text = x.get('textblock', '') if isinstance(x, dict) else x
        return re.sub('\s+', ' ', text).strip()

    if val := xml.get(fld):
        return Eligibility(study_pop=textblock(val.get('study_pop', '')),
                           sampling_method=val.get('sampling_method', ''),
                           criteria=textblock(val.get('criteria', '')),
                           gender=val.get('gender', ''),
                           gender_based=val.get('gender_based', ''),
                           gender_description=val.get('gender_description',
                                                      ''),
                           minimum_age=val.get('minimum_age', ''),
                           maximum_age=val.get('maximum_age', ''),
                           healthy_volunteers=val.get('healthy_volunteers',
                                                      ''))


# --------------------------------------------------
def get_browse_struct(xml, fld) -> List[str]:
    """ Get condition_browse """

    if val := xml.get(fld):
        return val.get('mesh_term')

    return []


# --------------------------------------------------
def get_study_docs(xml, fld) -> List[StudyDoc]:
    """ Get study_docs """

    docs = []
    if fld in xml:
        for val in xml.get(fld).get('study_doc'):
            docs.append(
                StudyDoc(doc_id=val.get('doc_id', ''),
                         doc_type=val.get('doc_type', ''),
                         doc_url=val.get('doc_url', ''),
                         doc_comment=val.get('doc_comment', '')))

    return docs


# --------------------------------------------------
# def get_pending_results(xml, fld) -> List[PendingResult]:
#     """
#     Get pending_results
#     {'submitted': ['December 2, 2020']}
#     """
#
#     results = []
#     print(xml.get(fld))
#     if fld in xml:
#         for val in xml.get(fld):
#             results += PendingResult(submitted=get_date(val.get('submitted')),
#                                      returned=get_date(val.get('returned')),
#                                      submission_canceled=get_date(
#                                          val.get('submission_canceled')))

#     return results


# --------------------------------------------------
def get_sponsors(xml, fld) -> List[str]:
    """ Get sponsors """

    sponsors = []
    if data := xml.get(fld):
        if lead := data.get('lead_sponsor'):
            # sponsors.append(Sponsor(sponsor=lead.get('agency')))
            sponsors.append(lead.get('agency'))

        if collabs := data.get('collaborator'):
            for collab in collabs:
                # sponsors.append(Sponsor(sponsor=collab.get('agency')))
                sponsors.append(collab.get('agency'))

    return sponsors


# --------------------------------------------------
def get_provided_documents(xml, fld) -> List[ProvidedDocument]:
    """ Get provided_documents """

    docs = []
    if fld in xml:
        for val in xml.get(fld).get('provided_document'):
            docs.append(
                ProvidedDocument(
                    document_type=val.get('document_type'),
                    document_has_protocol=val.get('document_has_protocol', ''),
                    document_has_icf=val.get('document_has_icf', ''),
                    document_has_sap=val.get('document_has_sap', ''),
                    document_date=val.get('document_date', ''),
                    document_url=val.get('document_url', '')))

    return docs


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
def restructure(xml: str, all_text: str) -> Study:
    """ Restructure XML """

    id_info = xml.get('id_info', {})

    return Study(
        nct_id=id_info.get('nct_id', ''),
        org_study_id=id_info.get('org_study_id', ''),
        brief_title=xml.get('brief_title', ''),
        official_title=xml.get('official_title', ''),
        acronym=xml.get('acronym', ''),
        source=xml.get('source', ''),
        rank=xml.get('rank', ''),
        brief_summary=get_textblock(xml, 'brief_summary'),
        detailed_description=get_textblock(xml, 'detailed_description'),
        overall_status=xml.get('overall_status', ''),
        last_known_status=xml.get('last_known_status', ''),
        why_stopped=xml.get('why_stopped', ''),
        start_date=get_date(xml.get('start_date', '')),
        completion_date=get_date(xml.get('completion_date', '')),
        verification_date=get_date(xml.get('verification_date', '')),
        primary_completion_date=get_date(xml.get('primary_completion_date',
                                                 '')),
        study_first_submitted=get_date(xml.get('study_first_submitted', '')),
        study_first_submitted_qc=get_date(
            xml.get('study_first_submitted_qc', '')),
        study_first_posted=get_date(xml.get('study_first_posted', '')),
        results_first_submitted=get_date(xml.get('results_first_submitted',
                                                 '')),
        results_first_submitted_qc=get_date(
            xml.get('results_first_submitted_qc', '')),
        results_first_posted=get_date(xml.get('results_first_posted', '')),
        disposition_first_submitted=get_date(
            xml.get('disposition_first_submitted', '')),
        disposition_first_submitted_qc=get_date(
            xml.get('disposition_first_submitted_qc', '')),
        disposition_first_posted=get_date(
            xml.get('disposition_first_posted', '')),
        last_update_submitted=get_date(xml.get('last_update_submitted', '')),
        last_update_submitted_qc=get_date(
            xml.get('last_update_submitted_qc', '')),
        last_update_posted=get_date(xml.get('last_update_posted', '')),
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
        sponsors=get_sponsors(xml, 'sponsors'),
        primary_outcomes=get_protocols(xml, 'primary_outcome'),
        secondary_outcomes=get_protocols(xml, 'secondary_outcome'),
        other_outcomes=get_protocols(xml, 'other_outcome'),
        arm_groups=get_arm_groups(xml, 'arm_group'),
        interventions=get_interventions(xml, 'intervention'),
        overall_official=get_investigators(xml, 'investigator'),
        overall_contact=get_contact(xml, 'overall_contact'),
        overall_contact_backup=get_contact(xml, 'overall_contact_backup'),
        references=get_references(xml, 'reference'),
        keywords=get_str_list(xml, 'keyword'),
        condition_browse=get_browse_struct(xml, 'condition_browse'),
        intervention_browse=get_browse_struct(xml, 'intervention_browse'),
        study_docs=get_study_docs(xml, 'study_docs'),
        provided_documents=get_provided_documents(xml,
                                                  'provided_document_section'),
        text=all_text)

    # pending_results=get_pending_results(xml, 'pending_results'))


# --------------------------------------------------
if __name__ == '__main__':
    main()
