from peewee import *
from playhouse.postgres_ext import *

database = PostgresqlDatabase('ct')

class UnknownField(object):
    def __init__(self, *_, **__): pass

class BaseModel(Model):
    class Meta:
        database = database

class Condition(BaseModel):
    condition_id = AutoField()
    condition_name = CharField(unique=True)

    class Meta:
        table_name = 'condition'
        indexes = (
            ((), False),
        )

class Dataload(BaseModel):
    dataload_id = AutoField()
    updated_on = DateField(null=True, unique=True)

    class Meta:
        table_name = 'dataload'

class Intervention(BaseModel):
    intervention_id = AutoField()
    intervention_name = CharField(unique=True)

    class Meta:
        table_name = 'intervention'

class Phase(BaseModel):
    phase_id = AutoField()
    phase_name = CharField(unique=True)

    class Meta:
        table_name = 'phase'

class WebUser(BaseModel):
    email = CharField(unique=True)
    name = CharField(constraints=[SQL("DEFAULT ''::character varying")])
    picture = CharField(constraints=[SQL("DEFAULT ''::character varying")])
    web_user_id = AutoField()

    class Meta:
        table_name = 'web_user'

class SavedSearch(BaseModel):
    conditions = TextField(constraints=[SQL("DEFAULT ''::text")])
    conditions_bool = IntegerField(constraints=[SQL("DEFAULT 0")])
    email_to = CharField(constraints=[SQL("DEFAULT ''::character varying")])
    enrollment = IntegerField(constraints=[SQL("DEFAULT 0")])
    full_text = TextField(constraints=[SQL("DEFAULT ''::text")])
    full_text_bool = IntegerField(constraints=[SQL("DEFAULT 0")])
    interventions = TextField(constraints=[SQL("DEFAULT ''::text")])
    interventions_bool = IntegerField(constraints=[SQL("DEFAULT 0")])
    phase_ids = TextField(constraints=[SQL("DEFAULT ''::text")])
    saved_search_id = AutoField()
    search_name = CharField()
    sponsors = TextField(constraints=[SQL("DEFAULT ''::text")])
    sponsors_bool = IntegerField(constraints=[SQL("DEFAULT 0")])
    study_type_ids = TextField(constraints=[SQL("DEFAULT ''::text")])
    web_user = ForeignKeyField(column_name='web_user_id', field='web_user_id', model=WebUser)

    class Meta:
        table_name = 'saved_search'

class Sponsor(BaseModel):
    sponsor_id = AutoField()
    sponsor_name = CharField(unique=True)

    class Meta:
        table_name = 'sponsor'
        indexes = (
            ((), False),
        )

class Status(BaseModel):
    status_id = AutoField()
    status_name = CharField(unique=True)

    class Meta:
        table_name = 'status'

class StudyType(BaseModel):
    study_type_id = AutoField()
    study_type_name = CharField(unique=True)

    class Meta:
        table_name = 'study_type'

class Study(BaseModel):
    acronym = TextField(null=True)
    biospec_description = TextField(null=True)
    biospec_retention = TextField(null=True)
    brief_summary = TextField(null=True)
    brief_title = TextField(null=True)
    completion_date = DateField(null=True)
    detailed_description = TextField(null=True)
    enrollment = IntegerField(null=True)
    fulltext = TSVectorField(index=True, null=True)
    fulltext_load = TextField(null=True)
    has_expanded_access = TextField(null=True)
    keywords = TextField(null=True)
    last_known_status = ForeignKeyField(column_name='last_known_status_id', field='status_id', model=Status)
    nct_id = CharField(index=True)
    official_title = TextField(null=True)
    org_study_id = TextField(null=True)
    overall_status = ForeignKeyField(backref='status_overall_status_set', column_name='overall_status_id', field='status_id', model=Status)
    phase = ForeignKeyField(column_name='phase_id', field='phase_id', model=Phase)
    rank = TextField(null=True)
    record_last_updated = DateTimeField(constraints=[SQL("DEFAULT CURRENT_TIMESTAMP")], null=True)
    source = TextField(null=True)
    start_date = DateField(null=True)
    study_id = AutoField()
    study_type = ForeignKeyField(column_name='study_type_id', field='study_type_id', model=StudyType)
    target_duration = TextField(null=True)
    why_stopped = TextField(null=True)

    class Meta:
        table_name = 'study'

class StudyArmGroup(BaseModel):
    arm_group_label = CharField()
    arm_group_type = TextField(null=True)
    description = TextField(null=True)
    study_arm_group_id = AutoField()
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)

    class Meta:
        table_name = 'study_arm_group'

class StudyDesign(BaseModel):
    allocation = TextField(null=True)
    intervention_model = TextField(null=True)
    intervention_model_description = TextField(null=True)
    masking = TextField(null=True)
    masking_description = TextField(null=True)
    observational_model = TextField(null=True)
    primary_purpose = TextField(null=True)
    study_design_id = AutoField()
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    time_perspective = TextField(null=True)

    class Meta:
        table_name = 'study_design'

class StudyDoc(BaseModel):
    doc_comment = TextField(null=True)
    doc_id = CharField(null=True)
    doc_type = CharField(null=True)
    doc_url = TextField(null=True)
    study_doc_id = AutoField()
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)

    class Meta:
        table_name = 'study_doc'

class StudyEligibility(BaseModel):
    criteria = TextField(null=True)
    gender = TextField(null=True)
    gender_based = TextField(null=True)
    gender_description = TextField(null=True)
    healthy_volunteers = TextField(null=True)
    maximum_age = TextField(null=True)
    minimum_age = TextField(null=True)
    sampling_method = TextField(null=True)
    study_eligibility_id = AutoField()
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_pop = TextField(null=True)

    class Meta:
        table_name = 'study_eligibility'

class StudyLocation(BaseModel):
    contact_name = CharField(null=True)
    facility_name = CharField(null=True)
    investigator_name = CharField(null=True)
    status = CharField(null=True)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_location_id = AutoField()

    class Meta:
        table_name = 'study_location'

class StudyOutcome(BaseModel):
    description = TextField(null=True)
    measure = TextField()
    outcome_type = CharField()
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_outcome_id = AutoField()
    time_frame = TextField(null=True)

    class Meta:
        table_name = 'study_outcome'

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

class StudyToSponsor(BaseModel):
    sponsor = ForeignKeyField(column_name='sponsor_id', field='sponsor_id', model=Sponsor)
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_to_sponsor_id = AutoField()

    class Meta:
        table_name = 'study_to_sponsor'

class StudyUrl(BaseModel):
    study = ForeignKeyField(column_name='study_id', field='study_id', model=Study)
    study_url_id = AutoField()
    url = TextField(null=True)

    class Meta:
        table_name = 'study_url'

