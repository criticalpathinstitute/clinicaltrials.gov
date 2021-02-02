"""
FastAPI server for Clinical Trials
"""

import csv
import ct
import io
import os
import psycopg2
import psycopg2.extras
import re
from fastapi.responses import StreamingResponse
from configparser import ConfigParser
from itertools import chain
from fastapi import FastAPI
from pymongo import MongoClient
from starlette.middleware.cors import CORSMiddleware
from typing import List, Optional
from pydantic import BaseModel

#
# Read configuration for global settings
#
config_file = './config.ini'
assert os.path.isfile(config_file)
config = ConfigParser()
config.read(config_file)

app = FastAPI(root_path=config['DEFAULT']['api_prefix'])
client = MongoClient(config['DEFAULT']['mongo_url'])
mongo_db = client['ct']

origins = [
    "http://localhost:*",
    "*",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Condition(BaseModel):
    condition: str


class ConditionDropDown(BaseModel):
    condition_id: int
    condition: str
    num_studies: int


class Phase(BaseModel):
    phase_id: int
    phase: str
    num_studies: int


class StudySearchResult(BaseModel):
    study_id: int
    nct_id: str
    title: str
    detailed_description: str


class StudyDoc(BaseModel):
    study_doc_id: int
    doc_id: str
    doc_type: str
    doc_url: str
    doc_comment: str


class StudyOutcome(BaseModel):
    study_outcome_id: int
    outcome_type: str
    measure: str
    time_frame: str
    description: str


class StudySponsor(BaseModel):
    sponsor_id: int
    sponsor_name: str


class StudyCondition(BaseModel):
    condition_id: int
    condition: str


class StudyIntervention(BaseModel):
    intervention_id: int
    intervention: str


class StudyDetail(BaseModel):
    study_id: int
    nct_id: str
    phase_id: int
    phase: str
    official_title: str
    brief_title: str
    detailed_description: str
    org_study_id: str
    acronym: str
    source: str
    rank: str
    brief_summary: str
    overall_status: str
    last_known_status: str
    why_stopped: str
    study_type: str
    has_expanded_access: str
    target_duration: str
    biospec_retention: str
    biospec_description: str
    keywords: str
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
    sponsors: List[StudySponsor]
    conditions: List[StudyCondition]
    interventions: List[StudyIntervention]
    study_outcomes: List[StudyOutcome]
    study_docs: List[StudyDoc]


class Sponsor(BaseModel):
    sponsor_id: int
    sponsor: str
    num_studies: int


class Summary(BaseModel):
    num_studies: int


dsn_tmpl = 'dbname=ct user={} password={} host={}'
dsn = dsn_tmpl.format(config['DEFAULT']['dbuser'], config['DEFAULT']['dbpass'],
                      config['DEFAULT']['dbhost'])
dbh = psycopg2.connect(dsn)


# --------------------------------------------------
def get_cur():
    """ Get db cursor """

    return dbh.cursor(cursor_factory=psycopg2.extras.DictCursor)


# --------------------------------------------------
@app.get('/download', response_model=List[StudySearchResult])
def download(study_ids: str) -> List[StudySearchResult]:
    """ Download """

    sql = """
        select s.study_id, s.nct_id, s.brief_title, s.detailed_description
        from   study s
        where  s.study_id in ({})
    """.format(study_ids)
    # print(sql)

    res = []
    try:
        cur = get_cur()
        cur.execute(sql)
        res = cur.fetchall()
        cur.close()
    except:
        dbh.rollback()

    if not res:
        return []

    def f(rec):
        return StudySearchResult(
            study_id=rec['study_id'],
            nct_id=rec['nct_id'],
            title=rec['brief_title'],
            detailed_description=rec['detailed_description'])

    flds = ['study_id', 'nct_id', 'brief_title', 'detailed_description']
    stream = io.StringIO()
    writer = csv.DictWriter(stream, fieldnames=flds, delimiter=',')
    writer.writeheader()
    for row in res:
        writer.writerow({f: row[f] for f in flds})

    response = StreamingResponse(iter([stream.getvalue()]),
                                 media_type="text/csv")
    response.headers[
        "Content-Disposition"] = "attachment; filename=download.csv"
    return response


# --------------------------------------------------
@app.get('/search', response_model=List[StudySearchResult])
def search(text: Optional[str] = '',
           conditions: Optional[str] = '',
           sponsors: Optional[str] = '',
           phases: Optional[str] = '') -> List[StudySearchResult]:
    """ Search """

    flds = ['study_id', 'nct_id', 'brief_title', 'detailed_description']
    where = []

    if text:
        where.append({
            'table':
            '',
            'where': ['s.text @@ to_tsquery({})'.format(make_bool(text))]
        })

    if phases:
        where.append({
            'table':
            '',
            'where': [
                's.phase_id in ({})'.format(phases)
            ]
        })

    if conditions:
        where.append({
            'table':
            'study_to_condition s2c',
            'where': [
                's.study_id=s2c.study_id',
                's2c.condition_id in ({})'.format(conditions)
            ]
        })

    if sponsors:
        where.append({
            'table':
            'study_to_sponsor s2p',
            'where': [
                's.study_id=s2p.study_id',
                's2p.sponsor_id in ({})'.format(sponsors)
            ]
        })


    if not where:
        return []

    table_names = ', '.join(
        filter(None, ['study s'] + list(map(lambda x: x['table'], where))))
    where = '\nand '.join(chain.from_iterable(map(lambda x: x['where'],
                                                  where)))
    sql = """
        select s.study_id, s.nct_id, s.brief_title, s.detailed_description
        from   {}
        where  s.nct_id != ''
        and {}
    """.format(table_names, where)

    print(sql)

    res = []
    try:
        cur = get_cur()
        cur.execute(sql)
        res = cur.fetchall()
        cur.close()
    except:
        dbh.rollback()

    if not res:
        return []

    def f(rec):
        return StudySearchResult(
            study_id=rec['study_id'],
            nct_id=rec['nct_id'],
            title=rec['brief_title'],
            detailed_description=rec['detailed_description'])

    return list(map(f, res))
    # return list(map(lambda r: StudySearchResult(**dict(r)), res))


# --------------------------------------------------
def make_bool(s: str):
    """ Turn and or to & | """

    s = re.sub('[*]', '', s)
    s = re.sub('\s+and\s+', ' & ', s, re.I)
    s = re.sub('\s+or\s+', ' | ', s, re.I)
    return f"'{s}'"


# --------------------------------------------------
@app.get('/summary', response_model=Summary)
def summary():
    """ DB summary stats """

    cur = get_cur()
    cur.execute('select count(study_id) as num_studies from study')
    res = cur.fetchone()
    cur.close()

    return Summary(num_studies=res['num_studies'])


# --------------------------------------------------
@app.get('/study/{nct_id}', response_model=Optional[StudyDetail])
def study(nct_id: str) -> StudyDetail:
    """ Study details """

    if studies := ct.Study.select().where(ct.Study.nct_id == nct_id):
        study = studies[0]

        sponsors = [
            StudySponsor(sponsor_id=s.sponsor_id,
                         sponsor_name=s.sponsor.sponsor)
            for s in ct.StudyToSponsor.select().where(
                ct.StudyToSponsor.study_id == study.study_id)
        ]

        conditions = [
            StudyCondition(condition_id=c.condition_id,
                           condition=c.condition.condition)
            for c in ct.StudyToCondition.select().where(
                ct.StudyToCondition.study_id == study.study_id)
        ]

        interventions = [
            StudyIntervention(intervention_id=c.intervention_id,
                              intervention=c.intervention.intervention)
            for c in ct.StudyToIntervention.select().where(
                ct.StudyToIntervention.study_id == study.study_id)
        ]

        study_docs = [
            StudyDoc(study_doc_id=doc.study_doc_id,
                     doc_id=doc.doc_id,
                     doc_type=doc.doc_type,
                     doc_url=doc.doc_url,
                     doc_comment=doc.doc_comment)
            for doc in ct.StudyDoc.select().where(
                ct.StudyDoc.study_id == study.study_id)
        ]

        study_outcomes = [
            StudyOutcome(study_outcome_id=o.study_outcome_id,
                         outcome_type=o.outcome_type,
                         measure=o.measure,
                         time_frame=o.time_frame,
                         description=o.description)
            for o in ct.StudyOutcome.select().where(
                ct.StudyOutcome.study_id == study.study_id)
        ]

        return StudyDetail(
            study_id=study.study_id,
            nct_id=study.nct_id,
            official_title=study.official_title or '',
            brief_title=study.brief_title or '',
            detailed_description=study.detailed_description or '',
            org_study_id=study.org_study_id or '',
            acronym=study.acronym or '',
            source=study.source or '',
            rank=study.rank or '',
            brief_summary=study.brief_summary or '',
            overall_status=study.overall_status or '',
            last_known_status=study.last_known_status or '',
            why_stopped=study.why_stopped or '',
            phase_id=study.phase_id,
            phase=study.phase.phase,
            study_type=study.study_type,
            has_expanded_access=study.has_expanded_access,
            target_duration=study.target_duration,
            biospec_retention=study.biospec_retention,
            biospec_description=study.biospec_description,
            keywords=study.keywords or '',
            start_date=str(study.start_date) or '',
            completion_date=str(study.completion_date) or '',
            verification_date=str(study.verification_date) or '',
            study_first_submitted=str(study.study_first_submitted) or '',
            study_first_submitted_qc=str(study.study_first_submitted_qc) or '',
            study_first_posted=str(study.study_first_posted) or '',
            results_first_submitted=str(study.results_first_submitted) or '',
            results_first_submitted_qc=str(study.results_first_submitted_qc)
            or '',
            results_first_posted=str(study.results_first_posted) or '',
            disposition_first_submitted=str(study.disposition_first_submitted)
            or '',
            disposition_first_submitted_qc=str(
                study.disposition_first_submitted_qc) or '',
            disposition_first_posted=str(study.disposition_first_posted) or '',
            last_update_submitted=str(study.last_update_submitted) or '',
            last_update_submitted_qc=str(study.last_update_submitted_qc) or '',
            last_update_posted=str(study.last_update_posted) or '',
            primary_completion_date=str(study.primary_completion_date) or '',
            sponsors=sponsors,
            conditions=conditions,
            interventions=interventions,
            study_outcomes=study_outcomes,
            study_docs=study_docs)


# --------------------------------------------------
@app.get('/conditions', response_model=List[ConditionDropDown])
def conditions(name: Optional[str] = '') -> List[ConditionDropDown]:
    """ Conditions/Num Studies """

    clause = f"and c.condition like '%{name}%'" if name else ''
    sql = f"""
        select   c.condition_id, c.condition, count(s.study_id) as num_studies
        from     condition c, study_to_condition s2c, study s
        where    c.condition_id=s2c.condition_id
        and      s2c.study_id=s.study_id
        {clause}
        group by 1, 2
        order by 2
    """

    cur = get_cur()
    cur.execute(sql)
    res = cur.fetchall()
    conditions = list(map(lambda r: ConditionDropDown(**dict(r)), res))
    cur.close()

    return conditions


# --------------------------------------------------
@app.get('/sponsors', response_model=List[Sponsor])
def sponsors() -> List[Sponsor]:
    """ Sponsors/Num Studies """

    sql = """
        select   p.sponsor_id, p.sponsor, count(s.study_id) as num_studies
        from     sponsor p, study_to_sponsor s2p, study s
        where    p.sponsor_id=s2p.sponsor_id
        and      s2p.study_id=s.study_id
        group by 1, 2
        order by 2
    """

    cur = get_cur()
    cur.execute(sql)
    res = cur.fetchall()
    conditions = list(map(lambda r: Sponsor(**dict(r)), res))
    cur.close()

    return conditions


# --------------------------------------------------
@app.get('/phases', response_model=List[Phase])
def phases() -> List[Phase]:
    """ Phases """

    sql = """
        select   p.phase_id, p.phase, count(s.study_id) as num_studies
        from     phase p, study s
        where    p.phase_id=s.phase_id
        group by 1, 2
        order by 2
    """

    cur = get_cur()
    cur.execute(sql)
    res = cur.fetchall()
    phases = list(map(lambda r: Phase(**dict(r)), res))
    cur.close()

    return phases
