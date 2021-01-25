from peewee import *

# database = PostgresqlDatabase('ct')
database = PostgresqlDatabase('ct', user='postgres', host='127.0.0.1')

class UnknownField(object):
    def __init__(self, *_, **__): pass

class BaseModel(Model):
    class Meta:
        database = database

class Condition(BaseModel):
    condition = CharField(null=True)
    condition_id = AutoField()

    class Meta:
        table_name = 'condition'

class Intervention(BaseModel):
    intervention = CharField(null=True)
    intervention_id = AutoField()

    class Meta:
        table_name = 'intervention'

class Keyword(BaseModel):
    keyword = CharField(null=True)
    keyword_id = AutoField()

    class Meta:
        table_name = 'keyword'

class Sponsor(BaseModel):
    sponsor = CharField(null=True)
    sponsor_id = AutoField()

    class Meta:
        table_name = 'sponsor'

class Study(BaseModel):
    acronym = TextField(null=True)
    biospec_description = TextField(null=True)
    biospec_retention = TextField(null=True)
    brief_summary = TextField(null=True)
    brief_title = TextField(null=True)
    completion_date = DateField(null=True)
    detailed_description = TextField(null=True)
    disposition_first_posted = DateField(null=True)
    disposition_first_submitted = DateField(null=True)
    disposition_first_submitted_qc = DateField(null=True)
    has_expanded_access = TextField(null=True)
    last_known_status = TextField(null=True)
    last_update_posted = DateField(null=True)
    last_update_submitted = DateField(null=True)
    last_update_submitted_qc = DateField(null=True)
    nct_id = TextField(null=True)
    official_title = TextField(null=True)
    org_study_id = TextField(null=True)
    overall_status = TextField(null=True)
    phase = TextField(null=True)
    primary_completion_date = DateField(null=True)
    rank = TextField(null=True)
    results_first_posted = DateField(null=True)
    results_first_submitted = DateField(null=True)
    results_first_submitted_qc = DateField(null=True)
    source = TextField(null=True)
    start_date = DateField(null=True)
    study_first_posted = DateField(null=True)
    study_first_submitted = DateField(null=True)
    study_first_submitted_qc = DateField(null=True)
    study_id = AutoField()
    study_type = TextField(null=True)
    target_duration = TextField(null=True)
    text = TextField(null=True)
    verification_date = DateField(null=True)
    why_stopped = TextField(null=True)

    class Meta:
        table_name = 'study'
        indexes = (
            ((), False),
            ((), False),
        )

class StudyToCondition(BaseModel):
    condition = ForeignKeyField(column_name='condition_id', field='condition_id', model=Condition)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_condition_id = AutoField()

    class Meta:
        table_name = 'study_to_condition'

class StudyToIntervention(BaseModel):
    intervention = ForeignKeyField(column_name='intervention_id', field='intervention_id', model=Intervention)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_intervention_id = AutoField()

    class Meta:
        table_name = 'study_to_intervention'

class StudyToKeyword(BaseModel):
    keyword = ForeignKeyField(column_name='keyword_id', field='keyword_id', model=Keyword)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_keyword_id = AutoField()

    class Meta:
        table_name = 'study_to_keyword'

class StudyToSponsor(BaseModel):
    sponsor = ForeignKeyField(column_name='sponsor_id', field='sponsor_id', model=Sponsor)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_sponsor_id = AutoField()

    class Meta:
        table_name = 'study_to_sponsor'

