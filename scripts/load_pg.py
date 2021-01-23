#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2021-01-04
Purpose: Rock the Casbah
"""

import argparse
import dateparser
import datetime as dt
import json
import os
import sys
from pathlib import Path
from rich.progress import track
from pprint import pprint
from ct import Study, Condition, StudyToCondition, StudyToSponsor, Sponsor, \
    Keyword, StudyToKeyword, Intervention, StudyToIntervention
from typing import List, NamedTuple, TextIO


class Args(NamedTuple):
    """ Command-line arguments """
    files: List[str]


# --------------------------------------------------
def get_args() -> Args:
    """ Get command-line arguments """

    parser = argparse.ArgumentParser(
        description='Rock the Casbah',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-d',
                        '--dir',
                        help='Input JSON directory',
                        metavar='DIR',
                        type=str,
                        nargs='+')

    parser.add_argument('-f',
                        '--file',
                        help='Input JSON file(s)',
                        metavar='FILE',
                        type=str,
                        nargs='+')

    args = parser.parse_args()

    if args.dir and not args.file:
        filenames = []
        for dirname in args.dir:
            if not os.path.isdir(dirname):
                dirname = os.path.abspath(dirname)
            filenames.extend(list(Path(dirname).rglob('*.json')))

        args.file = filenames

    return Args(args.file)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()

    for file in track(args.files, description="Processing..."):
        data = json.loads(open(file).read())
        study, _ = Study.get_or_create(
            acronym=data['acronym'],
            biospec_description=data['biospec_description'],
            biospec_retention=data['biospec_retention'],
            brief_summary=data['brief_summary'],
            brief_title=data['brief_title'],
            detailed_description=data['detailed_description'],
            has_expanded_access=data['has_expanded_access'],
            last_known_status=data['last_known_status'],
            nct_id=data['nct_id'],
            official_title=data['official_title'],
            org_study_id=data['org_study_id'],
            overall_status=data['overall_status'],
            phase=data['phase'],
            rank=data['rank'],
            source=data['source'],
            study_type=data['study_type'],
            target_duration=data['target_duration'],
            why_stopped=data['why_stopped'],
            text=data['text'],
            # dates
            start_date=to_date(data['start_date']),
            completion_date=to_date(data['completion_date']),
            disposition_first_posted=to_date(data['disposition_first_posted']),
            disposition_first_submitted=to_date(
                data['disposition_first_submitted']),
            disposition_first_submitted_qc=to_date(
                data['disposition_first_submitted_qc']),
            last_update_posted=to_date(data['last_update_posted']),
            last_update_submitted=to_date(data['last_update_submitted']),
            last_update_submitted_qc=to_date(data['last_update_submitted_qc']),
            primary_completion_date=to_date(data['primary_completion_date']),
            results_first_posted=to_date(data['results_first_posted']),
            results_first_submitted=to_date(data['results_first_submitted']),
            results_first_submitted_qc=to_date(
                data['results_first_submitted_qc']),
            study_first_posted=to_date(data['study_first_posted']),
            study_first_submitted=to_date(data['study_first_submitted']),
            study_first_submitted_qc=to_date(data['study_first_submitted_qc']),
            verification_date=to_date(data['verification_date']),
        )

        for condition in data.get('conditions'):
            cond, _ = Condition.get_or_create(condition=condition)
            s2c, _ = StudyToCondition.get_or_create(
                study_id=study.study_id, condition_id=cond.condition_id)

        for sponsor in data.get('sponsors'):
            spon, _ = Sponsor.get_or_create(sponsor=sponsor)
            s2s, _ = StudyToSponsor.get_or_create(study_id=study.study_id,
                                                  sponsor_id=spon.sponsor_id)

        for keyword in data.get('keywords'):
            kw, _ = Keyword.get_or_create(keyword=keyword)
            s2k, _ = StudyToKeyword.get_or_create(study_id=study.study_id,
                                                  keyword_id=kw.keyword_id)

        for doc in data.get('study_docs'):
            kw, _ = StudyDoc.get_or_create(keyword=keyword)
            s2k, _ = StudyDocToKeyword.get_or_create(study_id=study.study_id,
                                                  keyword_id=kw.keyword_id)

        if interventions := data.get('interventions'):
            for intervention in interventions:
                int_, _ = Intervention.get_or_create(
                    intervention=intervention['intervention_name'])
                i2c, _ = StudyToIntervention.get_or_create(
                    study_id=study.study_id,
                    intervention_id=int_.intervention_id)

    print('Done.')


# --------------------------------------------------
def to_date(val: str):
    """ String to date() """

    if dp := dateparser.parse(val):
        return dt.datetime.utcfromtimestamp(dp.timestamp())


# --------------------------------------------------
if __name__ == '__main__':
    main()
