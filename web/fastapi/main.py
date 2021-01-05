import os
import psycopg2
import psycopg2.extras
from ct import Study, Condition, StudyToCondition
from configparser import ConfigParser
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
    nct_id: str
    title: str


class StudyDetail(BaseModel):
    nct_id: str
    title: str


class Summary(BaseModel):
    num_studies: int


dbh = psycopg2.connect('dbname=ct user=kyclark password="g0p3rl!"')

# --------------------------------------------------
def get_cur():
    """ Get db cursor """

    return dbh.cursor(cursor_factory=psycopg2.extras.DictCursor)


# --------------------------------------------------
@app.get('/search', response_model=List[StudySearchResult])
def search(text: Optional[str] = '', conditions: Optional[str] = ''):
    """ Search """
    def f(rec):
        return StudySearchResult(nct_id=rec['nct_id'],
                                 title=rec['official_title'])

    flds = ['nct_id', 'official_title']
    proj = {fld: 1 for fld in flds}
    qry = {}

    if text:
        qry['$text'] = { '$search': text }

    if conditions:
        qry['conditions'] = { '$in': conditions.split('::') }

    if qry:
        return list(map(f, mongo_db['ct'].find(qry, proj)))


# --------------------------------------------------
@app.get('/quick_search/{term}', response_model=List[StudySearchResult])
def quick_search(term: str):
    """ Search text for keyword """
    def f(rec):
        return StudySearchResult(nct_id=rec['nct_id'],
                                 title=rec['official_title'])

    cur = get_cur()
    sql = f"""
        select nct_id, official_title as title
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

    if study := Study.query().where(Study.nct_id == nct_id):
        return StudyDetail(nct_id=study.nct_id,
                           title=study.official_title)


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
