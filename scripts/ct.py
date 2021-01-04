from peewee import *

database = PostgresqlDatabase('ct')

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

class Study(BaseModel):
    acronym = TextField(null=True)
    biospec_description = TextField(null=True)
    biospec_retention = TextField(null=True)
    brief_summary = TextField(null=True)
    brief_title = TextField(null=True)
    completion_date = TextField(null=True)
    detailed_description = TextField(null=True)
    disposition_first_posted = TextField(null=True)
    disposition_first_submitted = TextField(null=True)
    disposition_first_submitted_qc = TextField(null=True)
    has_expanded_access = TextField(null=True)
    last_known_status = TextField(null=True)
    last_update_posted = TextField(null=True)
    last_update_submitted = TextField(null=True)
    last_update_submitted_qc = TextField(null=True)
    nct_id = TextField(null=True)
    official_title = TextField(null=True)
    org_study_id = TextField(null=True)
    overall_status = TextField(null=True)
    phase = TextField(null=True)
    primary_completion_date = TextField(null=True)
    rank = TextField(null=True)
    results_first_posted = TextField(null=True)
    results_first_submitted = TextField(null=True)
    results_first_submitted_qc = TextField(null=True)
    source = TextField(null=True)
    start_date = TextField(null=True)
    study_first_posted = TextField(null=True)
    study_first_submitted = TextField(null=True)
    study_first_submitted_qc = TextField(null=True)
    study_id = AutoField()
    study_type = TextField(null=True)
    target_duration = TextField(null=True)
    text = TextField(null=True)
    verification_date = TextField(null=True)
    why_stopped = TextField(null=True)

    class Meta:
        table_name = 'study'

class StudyToCondition(BaseModel):
    condition = ForeignKeyField(column_name='condition_id', field='condition_id', model=Condition)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_condition_id = AutoField()

    class Meta:
        table_name = 'study_to_condition'

