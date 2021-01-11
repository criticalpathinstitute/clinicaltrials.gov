#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2021-01-04
Purpose: Rock the Casbah
"""

import argparse
import json
from ct import Study, Condition, StudyToCondition
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

    parser.add_argument('file',
                        help='Input JSON file(s)',
                        metavar='FILE',
                        type=str,
                        nargs='+')

    args = parser.parse_args()

    return Args(args.file)


# --------------------------------------------------
def main() -> None:
    """ Make a jazz noise here """

    args = get_args()

    for i, file in enumerate(args.files, start=1):
        print(f'{i:3}: {file}')
        data = json.loads(open(file).read())
        study, _ = Study.get_or_create(
            acronym=data['acronym'],
            biospec_description=data['biospec_description'],
            biospec_retention=data['biospec_retention'],
            brief_summary=data['brief_summary'],
            brief_title=data['brief_title'],
            completion_date=data['completion_date'],
            detailed_description=data['detailed_description'],
            disposition_first_posted=data['disposition_first_posted'],
            disposition_first_submitted=data['disposition_first_submitted'],
            disposition_first_submitted_qc=data[
                'disposition_first_submitted_qc'],
            has_expanded_access=data['has_expanded_access'],
            last_known_status=data['last_known_status'],
            last_update_posted=data['last_update_posted'],
            last_update_submitted=data['last_update_submitted'],
            last_update_submitted_qc=data['last_update_submitted_qc'],
            nct_id=data['nct_id'],
            official_title=data['official_title'],
            org_study_id=data['org_study_id'],
            overall_status=data['overall_status'],
            phase=data['phase'],
            primary_completion_date=data['primary_completion_date'],
            rank=data['rank'],
            results_first_posted=data['results_first_posted'],
            results_first_submitted=data['results_first_submitted'],
            results_first_submitted_qc=data['results_first_submitted_qc'],
            source=data['source'],
            start_date=data['start_date'],
            study_first_posted=data['study_first_posted'],
            study_first_submitted=data['study_first_submitted'],
            study_first_submitted_qc=data['study_first_submitted_qc'],
            study_type=data['study_type'],
            target_duration=data['target_duration'],
            text=data['text'],
            verification_date=data['verification_date'],
            why_stopped=data['why_stopped'],
        )

        for condition in data.get('conditions'):
            cond, _ = Condition.get_or_create(condition=condition)
            s2c, _ = StudyToCondition.get_or_create(
                study_id=study.study_id, condition_id=cond.condition_id)

    print('Done.')


# --------------------------------------------------
if __name__ == '__main__':
    main()
