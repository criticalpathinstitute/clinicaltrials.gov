import os
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


class StudySearchResult(BaseModel):
    nct_id: str
    title: str


class StudyDetail(BaseModel):
    nct_id: str
    title: str


class Summary(BaseModel):
    num_studies: int


# --------------------------------------------------
def spelunk(path: str, rec: dict) -> str:
    """ Dive into dict struct """

    path = path.split('.')

    while path:
        node = path.pop(0)
        if not isinstance(rec, dict) or node not in rec:
            return ''
        rec = rec.get(node)

    return rec


# --------------------------------------------------
def test_spelunk() -> None:
    """ Test spelunk """

    assert spelunk('', {}) == ''
    assert spelunk('foo', {'foo': 3}) == 3
    assert spelunk('foo.bar', {'foo': 3}) == ''
    assert spelunk('foo.bar', {'foo': {'bar': 'hey'}}) == 'hey'


# --------------------------------------------------
@app.get('/search/{term}', response_model=List[StudySearchResult])
def search(term: str):
    """ Search text for keyword """
    def f(rec):
        return StudySearchResult(nct_id=rec['nct_id'],
                                 title=rec['official_title'])

    flds = ['nct_id', 'official_title']
    proj = {fld: 1 for fld in flds}
    return list(map(f, mongo_db['ct'].find({"$text": {
        "$search": term
    }}, proj)))


# --------------------------------------------------
@app.get('/summary', response_model=Summary)
def summary():
    """ DB summary stats """

    return Summary(num_studies=mongo_db['ct'].find({}).count())


# --------------------------------------------------
@app.get('/study/{nct_id}', response_model=Optional[StudyDetail])
def study(nct_id: str) -> StudyDetail:
    """ Study details """

    res = mongo_db['ct'].find({'nct_id': nct_id})

    if res.count() == 1:
        study = res.next()
        return StudyDetail(nct_id=study['nct_id'],
                           title=study['official_title'])


# --------------------------------------------------
@app.get('/conditions', response_model=List[Condition])
def study(nct_id: str) -> StudyDetail:
    """ Study details """

    res = mongo_db['ct'].find({'nct_id': nct_id})

    if res.count() == 1:
        study = res.next()
        return StudyDetail(nct_id=study['nct_id'],
                           title=study['official_title'])
