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
import signal
import sys
from pathlib import Path
from rich.progress import track
from pprint import pprint
from ct import Study, Condition, StudyToCondition, StudyToSponsor, Sponsor, \
    Intervention, StudyToIntervention, StudyDoc, StudyOutcome, Phase
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

    def handler(signum, frame):
        print('Bye')
        sys.exit()

    signal.signal(signal.SIGINT, handler)

    for file in track(args.files, description="Processing..."):
        data = json.loads(open(file).read())

        phase, _ = Phase.get_or_create(phase=data['phase'] or 'N/A')

        study = None
        if studies := Study.select().where(Study.nct_id == data['nct_id']):
            study = studies[0]
        else:
            study, _ = Study.get_or_create(nct_id=data['nct_id'],
                                           phase_id=phase.phase_id)

        study.acronym = data['acronym']
        study.biospec_description = data['biospec_description']
        study.biospec_retention = data['biospec_retention']
        study.brief_summary = data['brief_summary']
        study.brief_title = data['brief_title']
        study.detailed_description = data['detailed_description']
        study.has_expanded_access = data['has_expanded_access']
        study.last_known_status = data['last_known_status']
        study.official_title = data['official_title']
        study.org_study_id = data['org_study_id']
        study.overall_status = data['overall_status']
        study.phase_id = phase.phase_id
        study.rank = data['rank']
        study.source = data['source']
        study.study_type = data['study_type']
        study.target_duration = data['target_duration']
        study.why_stopped = data['why_stopped']
        study.text = data['text']

        # dates
        study.start_date = to_date(data['start_date'])
        study.completion_date = to_date(data['completion_date'])
        study.disposition_first_posted = to_date(
            data['disposition_first_posted'])
        study.disposition_first_submitted = to_date(
            data['disposition_first_submitted'])
        study.disposition_first_submitted_qc = to_date(
            data['disposition_first_submitted_qc'])
        study.last_update_posted = to_date(data['last_update_posted'])
        study.last_update_submitted = to_date(data['last_update_submitted'])
        study.last_update_submitted_qc = to_date(
            data['last_update_submitted_qc'])
        study.primary_completion_date = to_date(
            data['primary_completion_date'])
        study.results_first_posted = to_date(data['results_first_posted'])
        study.results_first_submitted = to_date(
            data['results_first_submitted'])
        study.results_first_submitted_qc = to_date(
            data['results_first_submitted_qc'])
        study.study_first_posted = to_date(data['study_first_posted'])
        study.study_first_submitted = to_date(data['study_first_submitted'])
        study.study_first_submitted_qc = to_date(
            data['study_first_submitted_qc'])
        study.verification_date = to_date(data['verification_date'])
        study.keywords = ', '.join(data['keywords'])
        study.save()

        for condition in data.get('conditions'):
            cond, _ = Condition.get_or_create(condition=condition)
            s2c, _ = StudyToCondition.get_or_create(
                study_id=study.study_id, condition_id=cond.condition_id)

        for sponsor in data.get('sponsors'):
            spon, _ = Sponsor.get_or_create(sponsor=sponsor)
            s2s, _ = StudyToSponsor.get_or_create(study_id=study.study_id,
                                                  sponsor_id=spon.sponsor_id)

        for doc in data.get('study_docs'):
            study_doc, _ = StudyDoc.get_or_create(study_id=study.study_id,
                                                  doc_id=doc['doc_id'])

            study_doc.doc_type = doc['doc_type']
            study_doc.doc_url = doc['doc_url']
            study_doc.doc_comment = doc['doc_comment']
            study_doc.save()

        outcome_types = [
            'primary_outcomes', 'secondary_outcomes', 'other_outcomes'
        ]

        for outcome_type in outcome_types:
            for outcome in data.get(outcome_type, []):
                study_outcome, _ = StudyOutcome.get_or_create(
                    study_id=study.study_id,
                    outcome_type=outcome_type.replace('_outcomes', ''),
                    measure=outcome['measure'],
                    time_frame=outcome['time_frame'],
                    description=outcome['description'])

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
