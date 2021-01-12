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


class StudySearchResult(BaseModel):
    study_id: int
    nct_id: str
    title: str
    detailed_description: str


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
    nct_id: str
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
    phase: str
    study_type: str
    has_expanded_access: str
    target_duration: str
    biospec_retention: str
    biospec_description: str
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
@app.get('/search', response_model=List[StudySearchResult])
def search(text: Optional[str] = '',
           conditions: Optional[str] = '',
           sponsors: Optional[str] = '',
           detailed_desc: Optional[str] = '',
           download: int = 0):
    """ Search """

    flds = ['study_id', 'nct_id', 'brief_title', 'detailed_description']
    # proj = {fld: 1 for fld in flds}
    # qry = {}

    where = []

    if text:
        # qry['$text'] = {'$search': text}
        where.append({
            'table':
            '',
            'where': ['s.text @@ to_tsquery({})'.format(make_bool(text))]
        })

    if detailed_desc:
        where.append({
            'table':
            '',
            'where': [
                's.detailed_description @@ to_tsquery({})'.format(
                    make_bool(detailed_desc))
            ]
        })

    if conditions:
        # qry['conditions'] = {'$in': conditions.split('::')}
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

    # res = mongo_db['ct'].find(qry, proj) if qry else []

    if not where:
        return []

    table_names = ', '.join(
        filter(None, ['study s'] + list(map(lambda x: x['table'], where))))
    where = '\nand '.join(chain.from_iterable(map(lambda x: x['where'],
                                                  where)))
    sql = """
        select s.study_id, s.nct_id, s.brief_title, s.detailed_description
        from   {}
        where  s.study_id is not null
        and {}
    """.format(table_names, where)
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

    if download:
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
    else:
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
@app.get('/quick_search/{term}', response_model=List[StudySearchResult])
def quick_search(term: str):
    """ Search text for keyword """
    def f(rec):
        return StudySearchResult(nct_id=rec['nct_id'],
                                 title=rec['brief_title'])

    cur = get_cur()
    sql = f"""
        select nct_id, brief_title as title
        from   study
        where  text @@ to_tsquery('{term}');
    """
    cur.execute(sql)
    res = cur.fetchall()
    studies = list(map(lambda r: StudySearchResult(**dict(r)), res))
    cur.close()

    return studies


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

        return StudyDetail(
            nct_id=study.nct_id,
            official_title=study.official_title,
            brief_title=study.brief_title,
            detailed_description=study.detailed_description,
            org_study_id=study.org_study_id,
            acronym=study.acronym,
            source=study.source,
            rank=study.rank,
            brief_summary=study.brief_summary,
            overall_status=study.overall_status,
            last_known_status=study.last_known_status,
            why_stopped=study.why_stopped,
            phase=study.phase,
            study_type=study.study_type,
            has_expanded_access=study.has_expanded_access,
            target_duration=study.target_duration,
            biospec_retention=study.biospec_retention,
            biospec_description=study.biospec_description,
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
            interventions=interventions)


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
