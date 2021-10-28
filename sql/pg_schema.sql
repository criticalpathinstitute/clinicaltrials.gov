--
-- PostgreSQL database dump
--

-- Dumped from database version 13.3
-- Dumped by pg_dump version 13.4 (Ubuntu 13.4-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: condition; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.condition (
    condition_id integer NOT NULL,
    condition_name character varying(255) NOT NULL
);


ALTER TABLE public.condition OWNER TO kyclark;

--
-- Name: condition_condition_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.condition_condition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.condition_condition_id_seq OWNER TO kyclark;

--
-- Name: condition_condition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.condition_condition_id_seq OWNED BY public.condition.condition_id;


--
-- Name: dataload; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.dataload (
    dataload_id integer NOT NULL,
    updated_on date
);


ALTER TABLE public.dataload OWNER TO kyclark;

--
-- Name: dataload_dataload_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.dataload_dataload_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dataload_dataload_id_seq OWNER TO kyclark;

--
-- Name: dataload_dataload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.dataload_dataload_id_seq OWNED BY public.dataload.dataload_id;


--
-- Name: intervention; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.intervention (
    intervention_id integer NOT NULL,
    intervention_name character varying(255) NOT NULL
);


ALTER TABLE public.intervention OWNER TO kyclark;

--
-- Name: intervention_intervention_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.intervention_intervention_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.intervention_intervention_id_seq OWNER TO kyclark;

--
-- Name: intervention_intervention_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.intervention_intervention_id_seq OWNED BY public.intervention.intervention_id;


--
-- Name: phase; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.phase (
    phase_id integer NOT NULL,
    phase_name character varying(255) NOT NULL
);


ALTER TABLE public.phase OWNER TO kyclark;

--
-- Name: phase_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.phase_phase_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.phase_phase_id_seq OWNER TO kyclark;

--
-- Name: phase_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.phase_phase_id_seq OWNED BY public.phase.phase_id;


--
-- Name: saved_search; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.saved_search (
    saved_search_id integer NOT NULL,
    web_user_id integer NOT NULL,
    search_name character varying(255) NOT NULL,
    full_text text DEFAULT ''::text NOT NULL,
    full_text_bool integer DEFAULT 0 NOT NULL,
    conditions text DEFAULT ''::text NOT NULL,
    conditions_bool integer DEFAULT 0 NOT NULL,
    sponsors text DEFAULT ''::text NOT NULL,
    sponsors_bool integer DEFAULT 0 NOT NULL,
    phase_ids text DEFAULT ''::text NOT NULL,
    study_type_ids text DEFAULT ''::text NOT NULL,
    enrollment integer DEFAULT 0 NOT NULL,
    email_to character varying(255) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.saved_search OWNER TO kyclark;

--
-- Name: saved_search_saved_search_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.saved_search_saved_search_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.saved_search_saved_search_id_seq OWNER TO kyclark;

--
-- Name: saved_search_saved_search_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.saved_search_saved_search_id_seq OWNED BY public.saved_search.saved_search_id;


--
-- Name: sponsor; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.sponsor (
    sponsor_id integer NOT NULL,
    sponsor_name character varying(255) NOT NULL
);


ALTER TABLE public.sponsor OWNER TO kyclark;

--
-- Name: sponsor_sponsor_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.sponsor_sponsor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sponsor_sponsor_id_seq OWNER TO kyclark;

--
-- Name: sponsor_sponsor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.sponsor_sponsor_id_seq OWNED BY public.sponsor.sponsor_id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.status (
    status_id integer NOT NULL,
    status_name character varying(255) NOT NULL
);


ALTER TABLE public.status OWNER TO kyclark;

--
-- Name: status_status_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.status_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_status_id_seq OWNER TO kyclark;

--
-- Name: status_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.status_status_id_seq OWNED BY public.status.status_id;


--
-- Name: study; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study (
    study_id integer NOT NULL,
    study_type_id integer NOT NULL,
    phase_id integer NOT NULL,
    overall_status_id integer NOT NULL,
    last_known_status_id integer NOT NULL,
    nct_id character varying(255) NOT NULL,
    brief_title text,
    official_title text,
    org_study_id text,
    acronym text,
    source text,
    rank text,
    brief_summary text,
    detailed_description text,
    why_stopped text,
    has_expanded_access text,
    target_duration text,
    biospec_retention text,
    biospec_description text,
    keywords text,
    enrollment integer,
    start_date date,
    completion_date date,
    record_last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fulltext tsvector,
    fulltext_load text,
    study_first_posted date,
    last_update_posted date
);


ALTER TABLE public.study OWNER TO kyclark;

--
-- Name: study_arm_group; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_arm_group (
    study_arm_group_id integer NOT NULL,
    study_id integer NOT NULL,
    arm_group_label character varying(255) NOT NULL,
    arm_group_type text,
    description text
);


ALTER TABLE public.study_arm_group OWNER TO kyclark;

--
-- Name: study_arm_group_study_arm_group_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_arm_group_study_arm_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_arm_group_study_arm_group_id_seq OWNER TO kyclark;

--
-- Name: study_arm_group_study_arm_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_arm_group_study_arm_group_id_seq OWNED BY public.study_arm_group.study_arm_group_id;


--
-- Name: study_design; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_design (
    study_design_id integer NOT NULL,
    study_id integer NOT NULL,
    allocation text,
    intervention_model text,
    intervention_model_description text,
    primary_purpose text,
    observational_model text,
    time_perspective text,
    masking text,
    masking_description text
);


ALTER TABLE public.study_design OWNER TO kyclark;

--
-- Name: study_design_study_design_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_design_study_design_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_design_study_design_id_seq OWNER TO kyclark;

--
-- Name: study_design_study_design_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_design_study_design_id_seq OWNED BY public.study_design.study_design_id;


--
-- Name: study_doc; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_doc (
    study_doc_id integer NOT NULL,
    study_id integer NOT NULL,
    doc_id character varying(255),
    doc_type character varying(255),
    doc_url text,
    doc_comment text
);


ALTER TABLE public.study_doc OWNER TO kyclark;

--
-- Name: study_doc_study_doc_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_doc_study_doc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_doc_study_doc_id_seq OWNER TO kyclark;

--
-- Name: study_doc_study_doc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_doc_study_doc_id_seq OWNED BY public.study_doc.study_doc_id;


--
-- Name: study_eligibility; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_eligibility (
    study_eligibility_id integer NOT NULL,
    study_id integer NOT NULL,
    study_pop text,
    sampling_method text,
    criteria text,
    gender text,
    gender_based text,
    gender_description text,
    minimum_age text,
    maximum_age text,
    healthy_volunteers text
);


ALTER TABLE public.study_eligibility OWNER TO kyclark;

--
-- Name: study_eligibility_study_eligibility_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_eligibility_study_eligibility_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_eligibility_study_eligibility_id_seq OWNER TO kyclark;

--
-- Name: study_eligibility_study_eligibility_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_eligibility_study_eligibility_id_seq OWNED BY public.study_eligibility.study_eligibility_id;


--
-- Name: study_location; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_location (
    study_location_id integer NOT NULL,
    study_id integer NOT NULL,
    facility_name character varying(255),
    status text,
    contact_name text,
    investigator_name text
);


ALTER TABLE public.study_location OWNER TO kyclark;

--
-- Name: study_location_study_location_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_location_study_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_location_study_location_id_seq OWNER TO kyclark;

--
-- Name: study_location_study_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_location_study_location_id_seq OWNED BY public.study_location.study_location_id;


--
-- Name: study_outcome; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_outcome (
    study_outcome_id integer NOT NULL,
    study_id integer NOT NULL,
    outcome_type character varying(255) NOT NULL,
    measure character varying(255) NOT NULL,
    time_frame character varying(255),
    description character varying(1200)
);


ALTER TABLE public.study_outcome OWNER TO kyclark;

--
-- Name: study_outcome_study_outcome_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_outcome_study_outcome_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_outcome_study_outcome_id_seq OWNER TO kyclark;

--
-- Name: study_outcome_study_outcome_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_outcome_study_outcome_id_seq OWNED BY public.study_outcome.study_outcome_id;


--
-- Name: study_study_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_study_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_study_id_seq OWNER TO kyclark;

--
-- Name: study_study_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_study_id_seq OWNED BY public.study.study_id;


--
-- Name: study_to_condition; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_to_condition (
    study_to_condition_id integer NOT NULL,
    study_id integer NOT NULL,
    condition_id integer NOT NULL
);


ALTER TABLE public.study_to_condition OWNER TO kyclark;

--
-- Name: study_to_condition_study_to_condition_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_to_condition_study_to_condition_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_to_condition_study_to_condition_id_seq OWNER TO kyclark;

--
-- Name: study_to_condition_study_to_condition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_to_condition_study_to_condition_id_seq OWNED BY public.study_to_condition.study_to_condition_id;


--
-- Name: study_to_intervention; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_to_intervention (
    study_to_intervention_id integer NOT NULL,
    study_id integer NOT NULL,
    intervention_id integer NOT NULL
);


ALTER TABLE public.study_to_intervention OWNER TO kyclark;

--
-- Name: study_to_intervention_study_to_intervention_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_to_intervention_study_to_intervention_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_to_intervention_study_to_intervention_id_seq OWNER TO kyclark;

--
-- Name: study_to_intervention_study_to_intervention_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_to_intervention_study_to_intervention_id_seq OWNED BY public.study_to_intervention.study_to_intervention_id;


--
-- Name: study_to_sponsor; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_to_sponsor (
    study_to_sponsor_id integer NOT NULL,
    study_id integer NOT NULL,
    sponsor_id integer NOT NULL
);


ALTER TABLE public.study_to_sponsor OWNER TO kyclark;

--
-- Name: study_to_sponsor_study_to_sponsor_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_to_sponsor_study_to_sponsor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_to_sponsor_study_to_sponsor_id_seq OWNER TO kyclark;

--
-- Name: study_to_sponsor_study_to_sponsor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_to_sponsor_study_to_sponsor_id_seq OWNED BY public.study_to_sponsor.study_to_sponsor_id;


--
-- Name: study_type; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_type (
    study_type_id integer NOT NULL,
    study_type_name character varying(255) NOT NULL
);


ALTER TABLE public.study_type OWNER TO kyclark;

--
-- Name: study_type_study_type_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_type_study_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_type_study_type_id_seq OWNER TO kyclark;

--
-- Name: study_type_study_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_type_study_type_id_seq OWNED BY public.study_type.study_type_id;


--
-- Name: study_url; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.study_url (
    study_url_id integer NOT NULL,
    study_id integer NOT NULL,
    url text
);


ALTER TABLE public.study_url OWNER TO kyclark;

--
-- Name: study_url_study_url_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.study_url_study_url_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_url_study_url_id_seq OWNER TO kyclark;

--
-- Name: study_url_study_url_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.study_url_study_url_id_seq OWNED BY public.study_url.study_url_id;


--
-- Name: web_user; Type: TABLE; Schema: public; Owner: kyclark
--

CREATE TABLE public.web_user (
    web_user_id integer NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    picture character varying(255) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.web_user OWNER TO kyclark;

--
-- Name: web_user_web_user_id_seq; Type: SEQUENCE; Schema: public; Owner: kyclark
--

CREATE SEQUENCE public.web_user_web_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.web_user_web_user_id_seq OWNER TO kyclark;

--
-- Name: web_user_web_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kyclark
--

ALTER SEQUENCE public.web_user_web_user_id_seq OWNED BY public.web_user.web_user_id;


--
-- Name: condition condition_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.condition ALTER COLUMN condition_id SET DEFAULT nextval('public.condition_condition_id_seq'::regclass);


--
-- Name: dataload dataload_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.dataload ALTER COLUMN dataload_id SET DEFAULT nextval('public.dataload_dataload_id_seq'::regclass);


--
-- Name: intervention intervention_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.intervention ALTER COLUMN intervention_id SET DEFAULT nextval('public.intervention_intervention_id_seq'::regclass);


--
-- Name: phase phase_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.phase ALTER COLUMN phase_id SET DEFAULT nextval('public.phase_phase_id_seq'::regclass);


--
-- Name: saved_search saved_search_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.saved_search ALTER COLUMN saved_search_id SET DEFAULT nextval('public.saved_search_saved_search_id_seq'::regclass);


--
-- Name: sponsor sponsor_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.sponsor ALTER COLUMN sponsor_id SET DEFAULT nextval('public.sponsor_sponsor_id_seq'::regclass);


--
-- Name: status status_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.status ALTER COLUMN status_id SET DEFAULT nextval('public.status_status_id_seq'::regclass);


--
-- Name: study study_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study ALTER COLUMN study_id SET DEFAULT nextval('public.study_study_id_seq'::regclass);


--
-- Name: study_arm_group study_arm_group_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_arm_group ALTER COLUMN study_arm_group_id SET DEFAULT nextval('public.study_arm_group_study_arm_group_id_seq'::regclass);


--
-- Name: study_design study_design_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_design ALTER COLUMN study_design_id SET DEFAULT nextval('public.study_design_study_design_id_seq'::regclass);


--
-- Name: study_doc study_doc_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_doc ALTER COLUMN study_doc_id SET DEFAULT nextval('public.study_doc_study_doc_id_seq'::regclass);


--
-- Name: study_eligibility study_eligibility_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_eligibility ALTER COLUMN study_eligibility_id SET DEFAULT nextval('public.study_eligibility_study_eligibility_id_seq'::regclass);


--
-- Name: study_location study_location_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_location ALTER COLUMN study_location_id SET DEFAULT nextval('public.study_location_study_location_id_seq'::regclass);


--
-- Name: study_outcome study_outcome_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_outcome ALTER COLUMN study_outcome_id SET DEFAULT nextval('public.study_outcome_study_outcome_id_seq'::regclass);


--
-- Name: study_to_condition study_to_condition_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_condition ALTER COLUMN study_to_condition_id SET DEFAULT nextval('public.study_to_condition_study_to_condition_id_seq'::regclass);


--
-- Name: study_to_intervention study_to_intervention_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_intervention ALTER COLUMN study_to_intervention_id SET DEFAULT nextval('public.study_to_intervention_study_to_intervention_id_seq'::regclass);


--
-- Name: study_to_sponsor study_to_sponsor_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_sponsor ALTER COLUMN study_to_sponsor_id SET DEFAULT nextval('public.study_to_sponsor_study_to_sponsor_id_seq'::regclass);


--
-- Name: study_type study_type_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_type ALTER COLUMN study_type_id SET DEFAULT nextval('public.study_type_study_type_id_seq'::regclass);


--
-- Name: study_url study_url_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_url ALTER COLUMN study_url_id SET DEFAULT nextval('public.study_url_study_url_id_seq'::regclass);


--
-- Name: web_user web_user_id; Type: DEFAULT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.web_user ALTER COLUMN web_user_id SET DEFAULT nextval('public.web_user_web_user_id_seq'::regclass);


--
-- Name: condition condition_condition_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.condition
    ADD CONSTRAINT condition_condition_name_key UNIQUE (condition_name);


--
-- Name: condition condition_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.condition
    ADD CONSTRAINT condition_pkey PRIMARY KEY (condition_id);


--
-- Name: dataload dataload_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.dataload
    ADD CONSTRAINT dataload_pkey PRIMARY KEY (dataload_id);


--
-- Name: dataload dataload_updated_on_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.dataload
    ADD CONSTRAINT dataload_updated_on_key UNIQUE (updated_on);


--
-- Name: intervention intervention_intervention_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.intervention
    ADD CONSTRAINT intervention_intervention_name_key UNIQUE (intervention_name);


--
-- Name: intervention intervention_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.intervention
    ADD CONSTRAINT intervention_pkey PRIMARY KEY (intervention_id);


--
-- Name: phase phase_phase_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.phase
    ADD CONSTRAINT phase_phase_name_key UNIQUE (phase_name);


--
-- Name: phase phase_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.phase
    ADD CONSTRAINT phase_pkey PRIMARY KEY (phase_id);


--
-- Name: saved_search saved_search_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.saved_search
    ADD CONSTRAINT saved_search_pkey PRIMARY KEY (saved_search_id);


--
-- Name: sponsor sponsor_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.sponsor
    ADD CONSTRAINT sponsor_pkey PRIMARY KEY (sponsor_id);


--
-- Name: sponsor sponsor_sponsor_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.sponsor
    ADD CONSTRAINT sponsor_sponsor_name_key UNIQUE (sponsor_name);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (status_id);


--
-- Name: status status_status_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_status_name_key UNIQUE (status_name);


--
-- Name: study_arm_group study_arm_group_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_arm_group
    ADD CONSTRAINT study_arm_group_pkey PRIMARY KEY (study_arm_group_id);


--
-- Name: study_design study_design_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_design
    ADD CONSTRAINT study_design_pkey PRIMARY KEY (study_design_id);


--
-- Name: study_doc study_doc_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_doc
    ADD CONSTRAINT study_doc_pkey PRIMARY KEY (study_doc_id);


--
-- Name: study_eligibility study_eligibility_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_eligibility
    ADD CONSTRAINT study_eligibility_pkey PRIMARY KEY (study_eligibility_id);


--
-- Name: study_location study_location_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_location
    ADD CONSTRAINT study_location_pkey PRIMARY KEY (study_location_id);


--
-- Name: study study_nct_id_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_nct_id_key UNIQUE (nct_id);


--
-- Name: study_outcome study_outcome_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_outcome
    ADD CONSTRAINT study_outcome_pkey PRIMARY KEY (study_outcome_id);


--
-- Name: study study_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_pkey PRIMARY KEY (study_id);


--
-- Name: study_to_condition study_to_condition_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_condition
    ADD CONSTRAINT study_to_condition_pkey PRIMARY KEY (study_to_condition_id);


--
-- Name: study_to_intervention study_to_intervention_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_intervention
    ADD CONSTRAINT study_to_intervention_pkey PRIMARY KEY (study_to_intervention_id);


--
-- Name: study_to_sponsor study_to_sponsor_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_sponsor
    ADD CONSTRAINT study_to_sponsor_pkey PRIMARY KEY (study_to_sponsor_id);


--
-- Name: study_type study_type_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_type
    ADD CONSTRAINT study_type_pkey PRIMARY KEY (study_type_id);


--
-- Name: study_type study_type_study_type_name_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_type
    ADD CONSTRAINT study_type_study_type_name_key UNIQUE (study_type_name);


--
-- Name: study_url study_url_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_url
    ADD CONSTRAINT study_url_pkey PRIMARY KEY (study_url_id);


--
-- Name: web_user web_user_email_key; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.web_user
    ADD CONSTRAINT web_user_email_key UNIQUE (email);


--
-- Name: web_user web_user_pkey; Type: CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.web_user
    ADD CONSTRAINT web_user_pkey PRIMARY KEY (web_user_id);


--
-- Name: condition_name; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX condition_name ON public.condition USING gin (to_tsvector('english'::regconfig, (condition_name)::text));


--
-- Name: fulltext; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX fulltext ON public.study USING gin (fulltext);


--
-- Name: idx_study_arm_group_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_arm_group_1 ON public.study_arm_group USING btree (study_id, arm_group_label, arm_group_type, description);


--
-- Name: idx_study_eligibility_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_eligibility_1 ON public.study_eligibility USING btree (study_id);


--
-- Name: idx_study_location_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_location_1 ON public.study_location USING btree (study_id);


--
-- Name: idx_study_outcome_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_outcome_1 ON public.study_outcome USING btree (study_id, outcome_type, measure, time_frame, description);


--
-- Name: idx_study_to_condition_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_to_condition_1 ON public.study_to_condition USING btree (study_id, condition_id);


--
-- Name: idx_study_to_intervention_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_to_intervention_1 ON public.study_to_intervention USING btree (study_id, intervention_id);


--
-- Name: idx_study_to_sponsor_1; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX idx_study_to_sponsor_1 ON public.study_to_sponsor USING btree (study_id, sponsor_id);


--
-- Name: last_known_status_id; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX last_known_status_id ON public.study USING btree (last_known_status_id);


--
-- Name: nct_id; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX nct_id ON public.study USING btree (nct_id);


--
-- Name: overall_status_id; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX overall_status_id ON public.study USING btree (overall_status_id);


--
-- Name: phase_id; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX phase_id ON public.study USING btree (phase_id);


--
-- Name: sponsor_name; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX sponsor_name ON public.sponsor USING gin (to_tsvector('english'::regconfig, (sponsor_name)::text));


--
-- Name: study_last_update_posted_idx; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX study_last_update_posted_idx ON public.study USING btree (last_update_posted);


--
-- Name: study_study_first_posted_idx; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX study_study_first_posted_idx ON public.study USING btree (study_first_posted);


--
-- Name: study_type_id; Type: INDEX; Schema: public; Owner: kyclark
--

CREATE INDEX study_type_id ON public.study USING btree (study_type_id);


--
-- Name: saved_search saved_search_web_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.saved_search
    ADD CONSTRAINT saved_search_web_user_id_fkey FOREIGN KEY (web_user_id) REFERENCES public.web_user(web_user_id) ON DELETE CASCADE;


--
-- Name: study_arm_group study_arm_group_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_arm_group
    ADD CONSTRAINT study_arm_group_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_design study_design_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_design
    ADD CONSTRAINT study_design_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_doc study_doc_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_doc
    ADD CONSTRAINT study_doc_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_eligibility study_eligibility_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_eligibility
    ADD CONSTRAINT study_eligibility_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study study_last_known_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_last_known_status_id_fkey FOREIGN KEY (last_known_status_id) REFERENCES public.status(status_id) ON DELETE CASCADE;


--
-- Name: study_location study_location_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_location
    ADD CONSTRAINT study_location_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_outcome study_outcome_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_outcome
    ADD CONSTRAINT study_outcome_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study study_overall_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_overall_status_id_fkey FOREIGN KEY (overall_status_id) REFERENCES public.status(status_id) ON DELETE CASCADE;


--
-- Name: study study_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES public.phase(phase_id) ON DELETE CASCADE;


--
-- Name: study study_study_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study
    ADD CONSTRAINT study_study_type_id_fkey FOREIGN KEY (study_type_id) REFERENCES public.study_type(study_type_id) ON DELETE CASCADE;


--
-- Name: study_to_condition study_to_condition_condition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_condition
    ADD CONSTRAINT study_to_condition_condition_id_fkey FOREIGN KEY (condition_id) REFERENCES public.condition(condition_id) ON DELETE CASCADE;


--
-- Name: study_to_condition study_to_condition_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_condition
    ADD CONSTRAINT study_to_condition_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_to_intervention study_to_intervention_intervention_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_intervention
    ADD CONSTRAINT study_to_intervention_intervention_id_fkey FOREIGN KEY (intervention_id) REFERENCES public.intervention(intervention_id) ON DELETE CASCADE;


--
-- Name: study_to_intervention study_to_intervention_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_intervention
    ADD CONSTRAINT study_to_intervention_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_to_sponsor study_to_sponsor_sponsor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_sponsor
    ADD CONSTRAINT study_to_sponsor_sponsor_id_fkey FOREIGN KEY (sponsor_id) REFERENCES public.sponsor(sponsor_id) ON DELETE CASCADE;


--
-- Name: study_to_sponsor study_to_sponsor_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_to_sponsor
    ADD CONSTRAINT study_to_sponsor_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: study_url study_url_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kyclark
--

ALTER TABLE ONLY public.study_url
    ADD CONSTRAINT study_url_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.study(study_id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: codrtestadmin
--

GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: TABLE condition; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.condition TO clinical_trial_user;


--
-- Name: SEQUENCE condition_condition_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.condition_condition_id_seq TO clinical_trial_user;


--
-- Name: TABLE dataload; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.dataload TO clinical_trial_user;


--
-- Name: SEQUENCE dataload_dataload_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.dataload_dataload_id_seq TO clinical_trial_user;


--
-- Name: TABLE intervention; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.intervention TO clinical_trial_user;


--
-- Name: SEQUENCE intervention_intervention_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.intervention_intervention_id_seq TO clinical_trial_user;


--
-- Name: TABLE phase; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.phase TO clinical_trial_user;


--
-- Name: SEQUENCE phase_phase_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.phase_phase_id_seq TO clinical_trial_user;


--
-- Name: TABLE saved_search; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.saved_search TO clinical_trial_user;


--
-- Name: SEQUENCE saved_search_saved_search_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.saved_search_saved_search_id_seq TO clinical_trial_user;


--
-- Name: TABLE sponsor; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.sponsor TO clinical_trial_user;


--
-- Name: SEQUENCE sponsor_sponsor_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.sponsor_sponsor_id_seq TO clinical_trial_user;


--
-- Name: TABLE status; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.status TO clinical_trial_user;


--
-- Name: SEQUENCE status_status_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.status_status_id_seq TO clinical_trial_user;


--
-- Name: TABLE study; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study TO clinical_trial_user;


--
-- Name: TABLE study_doc; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_doc TO clinical_trial_user;


--
-- Name: SEQUENCE study_doc_study_doc_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_doc_study_doc_id_seq TO clinical_trial_user;


--
-- Name: TABLE study_outcome; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_outcome TO clinical_trial_user;


--
-- Name: SEQUENCE study_outcome_study_outcome_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_outcome_study_outcome_id_seq TO clinical_trial_user;


--
-- Name: SEQUENCE study_study_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_study_id_seq TO clinical_trial_user;


--
-- Name: TABLE study_to_condition; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_to_condition TO clinical_trial_user;


--
-- Name: SEQUENCE study_to_condition_study_to_condition_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_to_condition_study_to_condition_id_seq TO clinical_trial_user;


--
-- Name: TABLE study_to_intervention; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_to_intervention TO clinical_trial_user;


--
-- Name: SEQUENCE study_to_intervention_study_to_intervention_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_to_intervention_study_to_intervention_id_seq TO clinical_trial_user;


--
-- Name: TABLE study_to_sponsor; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_to_sponsor TO clinical_trial_user;


--
-- Name: SEQUENCE study_to_sponsor_study_to_sponsor_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_to_sponsor_study_to_sponsor_id_seq TO clinical_trial_user;


--
-- Name: TABLE study_type; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.study_type TO clinical_trial_user;


--
-- Name: SEQUENCE study_type_study_type_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.study_type_study_type_id_seq TO clinical_trial_user;


--
-- Name: TABLE web_user; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON TABLE public.web_user TO clinical_trial_user;


--
-- Name: SEQUENCE web_user_web_user_id_seq; Type: ACL; Schema: public; Owner: kyclark
--

GRANT ALL ON SEQUENCE public.web_user_web_user_id_seq TO clinical_trial_user;


--
-- PostgreSQL database dump complete
--

