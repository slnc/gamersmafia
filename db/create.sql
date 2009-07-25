--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: archive; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA archive;


--
-- Name: stats; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stats;


--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = archive, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: pageviews; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);


SET search_path = public, pg_catalog;

SET default_with_oids = true;

--
-- Name: tracker_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracker_items (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    is_tracked boolean DEFAULT false NOT NULL,
    notification_sent_on timestamp without time zone
);


--
-- Name: tracker_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracker_items_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tracker_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracker_items_id_seq OWNED BY tracker_items.id;


SET search_path = archive, pg_catalog;

--
-- Name: tracker_items; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE tracker_items (
    id integer DEFAULT nextval('public.tracker_items_id_seq'::regclass) NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    is_tracked boolean DEFAULT false NOT NULL,
    notification_sent_on timestamp without time zone
);


SET default_with_oids = false;

--
-- Name: treated_visitors; Type: TABLE; Schema: archive; Owner: -; Tablespace: 
--

CREATE TABLE treated_visitors (
    id integer NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);


SET search_path = public, pg_catalog;

--
-- Name: ab_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ab_tests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ab_tests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ab_tests (
    id integer DEFAULT nextval('ab_tests_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    treatments integer NOT NULL,
    finished boolean DEFAULT false NOT NULL,
    minimum_difference numeric(10,2),
    metrics character varying,
    info_url character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    completed_on timestamp without time zone,
    min_difference numeric(10,2) DEFAULT 0.05 NOT NULL,
    cache_conversion_rates character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    dirty boolean DEFAULT true NOT NULL,
    cache_expected_completion_date timestamp without time zone,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: ads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    file character varying,
    link_file character varying,
    html character varying,
    advertiser_id integer
);


--
-- Name: ads_slots; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots (
    id integer NOT NULL,
    name character varying NOT NULL,
    location character varying NOT NULL,
    behaviour_class character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    advertiser_id integer,
    image_dimensions character varying
);


--
-- Name: ads_slots_instances; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots_instances (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ads_slot_id integer NOT NULL,
    ad_id integer NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: ads_slots_portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ads_slots_portals (
    id integer NOT NULL,
    ads_slot_id integer NOT NULL,
    portal_id integer NOT NULL
);


--
-- Name: advertisers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advertisers (
    id integer NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    due_on_day smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: allowed_competitions_participants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allowed_competitions_participants (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant_id integer NOT NULL
);


--
-- Name: anonymous_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE anonymous_users (
    id integer NOT NULL,
    session_id character(32) NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: autologin_keys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE autologin_keys (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    key character varying(40),
    user_id integer NOT NULL,
    lastused_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: avatars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE avatars (
    id integer NOT NULL,
    name character varying NOT NULL,
    level integer DEFAULT (-1) NOT NULL,
    path character varying,
    faction_id integer,
    user_id integer,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    submitter_user_id integer NOT NULL
);


--
-- Name: ban_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ban_requests (
    id integer NOT NULL,
    user_id integer NOT NULL,
    banned_user_id integer NOT NULL,
    confirming_user_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    confirmed_on timestamp without time zone,
    reason character varying NOT NULL,
    unban_user_id integer,
    unban_confirming_user_id integer,
    reason_unban character varying,
    unban_created_on timestamp without time zone,
    unban_confirmed_on timestamp without time zone
);


--
-- Name: bazar_districts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bazar_districts (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    icon character varying
);


--
-- Name: bets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    bets_category_id integer,
    closes_on timestamp without time zone NOT NULL,
    total_ammount numeric(14,2) DEFAULT 0 NOT NULL,
    winning_bets_option_id integer,
    cancelled boolean DEFAULT false NOT NULL,
    forfeit boolean DEFAULT false NOT NULL,
    tie boolean DEFAULT false NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: bets_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    bets_count integer DEFAULT 0 NOT NULL
);


--
-- Name: bets_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_options (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    name character varying NOT NULL,
    ammount numeric(14,2)
);


--
-- Name: bets_tickets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bets_tickets (
    id integer NOT NULL,
    bets_option_id integer NOT NULL,
    user_id integer NOT NULL,
    ammount numeric(14,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: blogentries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blogentries (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    title character varying NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    log character varying,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: cash_movements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cash_movements (
    id integer NOT NULL,
    description character varying NOT NULL,
    object_id_from integer,
    object_id_to integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ammount numeric(14,2),
    object_id_from_class character varying,
    object_id_to_class character varying
);


SET default_with_oids = true;

--
-- Name: chatlines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE chatlines (
    id integer NOT NULL,
    line character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    sent_to_irc boolean DEFAULT false NOT NULL
);


--
-- Name: clans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans (
    id integer NOT NULL,
    name character varying NOT NULL,
    tag character varying NOT NULL,
    simple_mode boolean DEFAULT true NOT NULL,
    website_external character varying,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    irc_channel character varying,
    irc_server character varying,
    o3_websites_dynamicwebsite_id integer,
    logo character varying,
    description text,
    competition_roster character varying,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    members_count integer DEFAULT 0 NOT NULL,
    website_activated boolean DEFAULT false NOT NULL,
    creator_user_id integer,
    cache_popularity integer,
    ranking_popularity_pos integer
);


--
-- Name: clans_friends; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_friends (
    from_clan_id integer NOT NULL,
    from_wants boolean DEFAULT false NOT NULL,
    to_clan_id integer NOT NULL,
    to_wants boolean DEFAULT false NOT NULL,
    id integer NOT NULL
);


--
-- Name: clans_games; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_games (
    clan_id integer NOT NULL,
    game_id integer NOT NULL
);


--
-- Name: clans_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    clans_groups_type_id integer NOT NULL,
    clan_id integer
);


--
-- Name: clans_groups_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: clans_groups_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_groups_users (
    clans_group_id integer NOT NULL,
    user_id integer NOT NULL
);


SET default_with_oids = false;

--
-- Name: clans_logs_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_logs_entries (
    id integer NOT NULL,
    message character varying,
    clan_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: clans_movements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_movements (
    id integer NOT NULL,
    clan_id integer NOT NULL,
    user_id integer,
    direction smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


SET default_with_oids = true;

--
-- Name: clans_sponsors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clans_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    clan_id integer NOT NULL,
    url character varying,
    image character varying
);


SET default_with_oids = false;

--
-- Name: columns; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE columns (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    columns_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: columns_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE columns_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    columns_count integer DEFAULT 0 NOT NULL
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    host inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    comment text NOT NULL,
    has_comments_valorations boolean DEFAULT false NOT NULL,
    portal_id integer,
    cache_rating character varying,
    netiquette_violation boolean,
    lastowner_version character varying,
    lastedited_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: comments_valorations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments_valorations (
    id integer NOT NULL,
    comment_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    comments_valorations_type_id integer NOT NULL,
    weight real NOT NULL
);


--
-- Name: comments_valorations_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments_valorations_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    direction smallint NOT NULL
);


--
-- Name: competitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    game_id integer NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    rules text,
    competitions_participants_type_id integer NOT NULL,
    default_maps_per_match smallint,
    forced_maps boolean DEFAULT true NOT NULL,
    random_map_selection_mode smallint,
    scoring_mode smallint DEFAULT 0 NOT NULL,
    pro boolean DEFAULT false NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    force_guids boolean DEFAULT false NOT NULL,
    estimated_end_on timestamp without time zone,
    timetable_for_matches smallint DEFAULT 0 NOT NULL,
    timetable_options character varying,
    fee numeric(14,2),
    invitational boolean DEFAULT false NOT NULL,
    competitions_types_options character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    closed_on timestamp without time zone,
    event_id integer,
    topics_category_id integer,
    header_image character varying,
    type character varying NOT NULL,
    send_notifications boolean DEFAULT true NOT NULL
);


--
-- Name: competitions_games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_games_maps (
    competition_id integer NOT NULL,
    games_map_id integer NOT NULL
);


--
-- Name: competitions_logs_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_logs_entries (
    id integer NOT NULL,
    message character varying,
    competition_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant1_id integer,
    participant2_id integer,
    result smallint,
    participant1_confirmed_result boolean DEFAULT false NOT NULL,
    participant2_confirmed_result boolean DEFAULT false NOT NULL,
    admin_confirmed_result boolean DEFAULT false NOT NULL,
    stage smallint DEFAULT 0 NOT NULL,
    maps smallint,
    score_participant1 integer,
    score_participant2 integer,
    accepted boolean DEFAULT true NOT NULL,
    completed_on timestamp without time zone,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    play_on timestamp without time zone,
    event_id integer,
    forfeit_participant1 boolean DEFAULT false NOT NULL,
    forfeit_participant2 boolean DEFAULT false NOT NULL,
    servers character varying,
    ladder_rules character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_clans_players; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_clans_players (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    competitions_participant_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_games_maps (
    competitions_match_id integer NOT NULL,
    games_map_id integer NOT NULL,
    partial_participant1_score integer,
    partial_participant2_score integer,
    id integer NOT NULL
);


--
-- Name: competitions_matches_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_reports (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    report text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_matches_uploads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_matches_uploads (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    file character varying,
    description character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: competitions_participants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_participants (
    competition_id integer NOT NULL,
    participant_id integer NOT NULL,
    competitions_participants_type_id smallint NOT NULL,
    id integer NOT NULL,
    name character varying NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    ties integer DEFAULT 0 NOT NULL,
    roster character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    points integer,
    "position" integer DEFAULT (random() * (100000)::double precision) NOT NULL
);


--
-- Name: competitions_participants_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_participants_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: competitions_sponsors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE competitions_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    competition_id integer NOT NULL,
    url character varying,
    image character varying
);


--
-- Name: content_ratings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_ratings (
    id integer NOT NULL,
    user_id integer,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    rating smallint NOT NULL
);


--
-- Name: content_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE content_types (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents (
    id integer NOT NULL,
    content_type_id integer NOT NULL,
    external_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    name character varying NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    game_id integer,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    platform_id integer,
    url character varying,
    user_id integer NOT NULL,
    portal_id integer,
    bazar_district_id integer,
    closed boolean DEFAULT false NOT NULL,
    source character varying
);


--
-- Name: contents_locks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_locks (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: contents_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_recommendations (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    sender_user_id integer NOT NULL,
    receiver_user_id integer NOT NULL,
    content_id integer NOT NULL,
    seen_on timestamp without time zone,
    marked_as_bad boolean DEFAULT false NOT NULL,
    confidence double precision,
    expected_rating smallint,
    comment character varying
);


--
-- Name: contents_terms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_terms (
    id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contents_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contents_versions (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    data text
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    code character varying,
    name character varying
);


--
-- Name: coverages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE coverages (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    description text NOT NULL,
    main text,
    event_id integer NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: demo_mirrors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demo_mirrors (
    id integer NOT NULL,
    demo_id integer NOT NULL,
    url character varying NOT NULL
);


--
-- Name: demos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demos (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    demos_category_id integer,
    entity1_local_id integer,
    entity2_local_id integer,
    entity1_external character varying,
    entity2_external character varying,
    games_map_id integer,
    event_id integer,
    pov_type smallint,
    pov_entity smallint,
    file character varying,
    file_hash_md5 character varying,
    downloaded_times integer DEFAULT 0 NOT NULL,
    file_size bigint,
    games_mode_id integer,
    games_version_id integer,
    demotype smallint,
    played_on date,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: demos_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE demos_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    demos_count integer DEFAULT 0 NOT NULL
);


--
-- Name: download_mirrors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE download_mirrors (
    id integer NOT NULL,
    download_id integer NOT NULL,
    url character varying NOT NULL
);


--
-- Name: downloaded_downloads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloaded_downloads (
    id integer NOT NULL,
    download_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    session_id character varying,
    referer character varying,
    user_id integer,
    download_cookie character varying(32)
);


--
-- Name: downloads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloads (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    downloads_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    file character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    essential boolean DEFAULT false NOT NULL,
    downloaded_times integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: downloads_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE downloads_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    downloads_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    description text,
    events_category_id integer,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    website character varying,
    parent_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: events_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    events_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);


--
-- Name: events_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events_users (
    event_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: f; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW f AS
    SELECT count(comments.id) AS count FROM comments GROUP BY date_trunc('day'::text, comments.created_on) ORDER BY date_trunc('day'::text, comments.created_on) DESC OFFSET 1 LIMIT 360;


--
-- Name: factions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions (
    id integer NOT NULL,
    name character varying NOT NULL,
    boss_user_id integer,
    underboss_user_id integer,
    building_bottom character varying,
    building_top character varying,
    building_middle character varying,
    description character varying,
    why_join character varying,
    code character varying,
    members_count integer DEFAULT 0 NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    is_platform boolean DEFAULT false NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    cache_member_cohesion numeric
);


--
-- Name: factions_banned_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_banned_users (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying,
    banner_user_id integer NOT NULL
);


--
-- Name: factions_headers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_headers (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    lasttime_used_on timestamp without time zone
);


--
-- Name: factions_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_links (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    image character varying
);


--
-- Name: factions_portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE factions_portals (
    faction_id integer NOT NULL,
    portal_id integer NOT NULL
);


SET default_with_oids = true;

--
-- Name: faq_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    "position" integer,
    parent_id integer,
    root_id integer
);


--
-- Name: faq_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_entries (
    id integer NOT NULL,
    question character varying NOT NULL,
    answer character varying NOT NULL,
    faq_category_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    "position" integer
);


SET default_with_oids = false;

--
-- Name: friends_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE friends_recommendations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    recommended_user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone,
    added_as_friend boolean,
    reason character varying
);


SET default_with_oids = true;

--
-- Name: friendships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE friendships (
    sender_user_id integer NOT NULL,
    receiver_user_id integer,
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    accepted_on timestamp without time zone,
    receiver_email character varying,
    invitation_text character varying,
    external_invitation_key character(32)
);


SET default_with_oids = false;

--
-- Name: funthings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE funthings (
    id integer NOT NULL,
    title character varying NOT NULL,
    description character varying,
    main character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


SET default_with_oids = true;

--
-- Name: games; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    has_guids boolean DEFAULT false NOT NULL,
    guid_format character varying
);


SET default_with_oids = false;

--
-- Name: games_maps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_maps (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    download_id integer,
    screenshot character varying
);


--
-- Name: games_modes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    entity_type smallint
);


--
-- Name: games_platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_platforms (
    game_id integer NOT NULL,
    platform_id integer NOT NULL
);


--
-- Name: games_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_users (
    game_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: games_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE games_versions (
    id integer NOT NULL,
    version character varying NOT NULL,
    game_id integer NOT NULL
);


--
-- Name: global_notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE global_notifications (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    completed_on timestamp without time zone,
    recipient_type character varying,
    title character varying,
    main character varying,
    confirmed boolean DEFAULT false NOT NULL
);


--
-- Name: global_vars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE global_vars (
    id integer NOT NULL,
    online_anonymous integer DEFAULT 0 NOT NULL,
    online_registered integer DEFAULT 0 NOT NULL,
    svn_revision character varying,
    ads_slots_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    gmtv_channels_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    pending_contents integer DEFAULT 0 NOT NULL,
    git_prev_revision character varying
);


--
-- Name: gmtv_broadcast_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gmtv_broadcast_messages (
    id integer NOT NULL,
    message character varying NOT NULL,
    starts_on timestamp without time zone DEFAULT now() NOT NULL,
    ends_on timestamp without time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL
);


--
-- Name: gmtv_channels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gmtv_channels (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    faction_id integer,
    file character varying,
    screenshot character varying
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    owner_user_id integer
);


--
-- Name: images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE images (
    id integer NOT NULL,
    description character varying,
    file character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    images_category_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: images_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE images_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    images_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);


--
-- Name: interviews; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    interviews_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: interviews_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE interviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    interviews_count integer DEFAULT 0 NOT NULL
);


--
-- Name: ip_bans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ip_bans (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone NOT NULL,
    expires_on timestamp without time zone,
    comment character varying,
    user_id integer
);


--
-- Name: ip_passwords_resets_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ip_passwords_resets_requests (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: macropolls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE macropolls (
    poll_id integer NOT NULL,
    user_id integer,
    answers text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet DEFAULT '0.0.0.0'::inet NOT NULL,
    host character varying
);


--
-- Name: macropolls_2007_1; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE macropolls_2007_1 (
    id integer NOT NULL,
    lacantidaddecontenidosquesepublicanenlawebteparece character varying,
    __sabesquepuedesenviarcontenidos_ character varying,
    __sabesquepuedesdecidirsiuncontenidosepublicaono_ character varying,
    __echasenfaltafuncionesimportantesenlaweb_ character varying,
    __estassuscritoafeedsrss_ character varying,
    participasencompeticiones_clanbase character varying,
    __tegustaelmanga_anime_ character varying,
    larapidezdecargadelaspaginasteparece character varying,
    lasecciondeforosteparece character varying,
    tesientesidentificadoconlaweb character varying,
    prefeririasnovermasqueloscontenidosdetujuego character varying,
    __quecreesquedeberiamosmejorardeformamasurgenteenlaweb_ character varying,
    ellogodelawebtegusta character varying,
    __estasenalgunclan_ character varying,
    eldisenodelawebteparece character varying,
    elnumerodefuncionesdelawebteparece_bis_ character varying,
    laactituddelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __tienesalgunavideoconsola_ character varying,
    siofreciesemosdenuevoelsistemadewebsparaclanes___creesquetuclan character varying,
    sipudiesesleregalariasalwebmasterunbilletea character varying,
    elambienteenloscomentarioses character varying,
    elnumerodefuncionesdelawebteparece character varying,
    seguneltiempoquelededicasalosjuegosteconsiderasunjugador character varying,
    lacantidaddepublicidadqueapareceenlawebteparece character varying,
    lalabordelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __sabesquepuedescreartuspropiascompeticionesoparticiparencompet character varying,
    lascabecerasteparecen character varying,
    tuopiniongeneralsobrelawebes character varying,
    razonprincipalporlaquevisitaslaweb character varying,
    lacalidaddeloscontenidosteparece character varying,
    lasecciondebabes_dudestegusta character varying,
    __quetendriaquetenerlawebparaquefueseperfectaparati_ character varying,
    __deentrelaswebsdejuegosquevisitasfrecuentementedondenossituari character varying,
    user_id integer,
    created_on character varying NOT NULL,
    ipaddr inet NOT NULL,
    host character varying
);


SET default_with_oids = true;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    id integer NOT NULL,
    user_id_from integer NOT NULL,
    user_id_to integer NOT NULL,
    title character varying NOT NULL,
    message text NOT NULL,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    in_reply_to integer,
    has_replies boolean DEFAULT false NOT NULL,
    message_type smallint DEFAULT 0 NOT NULL,
    sender_deleted boolean DEFAULT false NOT NULL,
    receiver_deleted boolean DEFAULT false NOT NULL,
    thread_id integer
);


SET default_with_oids = false;

--
-- Name: news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text,
    approved_by_user_id integer,
    news_category_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: news_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    news_count integer DEFAULT 0 NOT NULL,
    clan_id integer,
    file character varying
);


--
-- Name: outstanding_entities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE outstanding_entities (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    portal_id integer,
    active_on date NOT NULL,
    type character varying NOT NULL,
    reason character varying
);


--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE platforms (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL
);


--
-- Name: platforms_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE platforms_users (
    created_on timestamp without time zone,
    user_id integer,
    platform_id integer
);


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    polls_category_id integer,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    polls_votes_count integer DEFAULT 0 NOT NULL
);


--
-- Name: polls_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    polls_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);


--
-- Name: polls_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_options (
    id integer NOT NULL,
    poll_id integer NOT NULL,
    name character varying NOT NULL,
    polls_votes_count integer DEFAULT 0 NOT NULL,
    "position" integer
);


--
-- Name: polls_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls_votes (
    polls_option_id integer NOT NULL,
    user_id integer,
    id integer NOT NULL,
    remote_ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: portal_headers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portal_headers (
    id integer NOT NULL,
    date timestamp without time zone NOT NULL,
    factions_header_id integer NOT NULL,
    portal_id integer NOT NULL
);


--
-- Name: portal_hits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portal_hits (
    portal_id integer,
    date date DEFAULT (now())::date NOT NULL,
    hits integer DEFAULT 0 NOT NULL,
    id integer NOT NULL
);


--
-- Name: portals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portals (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    type character varying DEFAULT 'FactionsPortal'::character varying NOT NULL,
    fqdn character varying,
    options character varying,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    skin_id integer,
    default_gmtv_channel_id integer,
    cache_recent_hits_count integer,
    factions_portal_home character varying
);


--
-- Name: portals_skins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portals_skins (
    portal_id integer NOT NULL,
    skin_id integer NOT NULL
);


--
-- Name: potds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE potds (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL,
    portal_id integer,
    images_category_id integer,
    term_id integer
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    id integer NOT NULL,
    name character varying NOT NULL,
    price numeric(14,2) NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    cls character varying NOT NULL
);


--
-- Name: profile_signatures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profile_signatures (
    id integer NOT NULL,
    user_id integer NOT NULL,
    signer_user_id integer NOT NULL,
    signature character varying NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: publishing_decisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE publishing_decisions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    publish boolean NOT NULL,
    user_weight numeric NOT NULL,
    deny_reason character varying,
    is_right boolean,
    accept_comment character varying
);


--
-- Name: publishing_personalities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE publishing_personalities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    content_type_id integer NOT NULL,
    experience numeric DEFAULT 0.0
);


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions (
    id integer NOT NULL,
    title character varying NOT NULL,
    questions_category_id integer,
    description text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    accepted_answer_comment_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    approved_by_user_id integer,
    ammount numeric(10,2),
    answered_on timestamp without time zone,
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    answer_selected_by_user_id integer
);


--
-- Name: questions_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    questions_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_question_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);


--
-- Name: recruitment_ads; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE recruitment_ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    clan_id integer,
    game_id integer NOT NULL,
    levels character varying,
    country_id integer,
    main text,
    deleted boolean DEFAULT false NOT NULL,
    title character varying NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);


--
-- Name: refered_hits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE refered_hits (
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet NOT NULL,
    referer character varying NOT NULL,
    id integer NOT NULL
);


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    reviews_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    home_image character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: reviews_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    reviews_count integer DEFAULT 0 NOT NULL
);


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_info (
    version integer NOT NULL,
    "_Slony-I_gamersmafia_rowID" bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying
);


--
-- Name: sent_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sent_emails (
    id integer NOT NULL,
    message_key character varying NOT NULL,
    title character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    first_read_on timestamp without time zone,
    sender character varying,
    recipient character varying,
    recipient_user_id integer,
    global_notification_id integer
);


--
-- Name: silenced_emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE silenced_emails (
    id integer NOT NULL,
    email character varying NOT NULL
);


--
-- Name: skin_textures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE skin_textures (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    skin_id integer NOT NULL,
    texture_id integer NOT NULL,
    textured_element_position integer NOT NULL,
    texture_skin_position integer NOT NULL,
    user_config character varying,
    element character varying NOT NULL
);


--
-- Name: skins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE skins (
    id integer NOT NULL,
    name character varying NOT NULL,
    hid character varying NOT NULL,
    user_id integer NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    type character varying NOT NULL,
    file character varying,
    version integer DEFAULT 0 NOT NULL,
    intelliskin_header character varying,
    intelliskin_favicon character varying
);


--
-- Name: slog_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slog_entries (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    type_id integer NOT NULL,
    info character varying NOT NULL,
    headline character varying NOT NULL,
    request text,
    reporter_user_id integer,
    reviewer_user_id integer,
    short_version character varying,
    long_version character varying,
    completed_on timestamp without time zone,
    scope integer
);


--
-- Name: sold_products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sold_products (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    price_paid numeric(14,2) NOT NULL,
    used boolean DEFAULT false NOT NULL,
    type character varying
);


--
-- Name: terms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE terms (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description character varying,
    parent_id integer,
    game_id integer,
    platform_id integer,
    bazar_district_id integer,
    clan_id integer,
    contents_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    comments_count integer DEFAULT 0 NOT NULL,
    root_id integer,
    taxonomy character varying
);


--
-- Name: textures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE textures (
    id integer NOT NULL,
    name character varying,
    generator character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    valid_element_selectors character varying
);


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics (
    id integer NOT NULL,
    title character varying NOT NULL,
    topics_category_id integer,
    main text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    moved_on timestamp without time zone,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    unique_content_id integer
);


--
-- Name: topics_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    topics_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_topic_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);


--
-- Name: treated_visitors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE treated_visitors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: treated_visitors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE treated_visitors (
    id integer DEFAULT nextval('treated_visitors_id_seq'::regclass) NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);


--
-- Name: tutorials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tutorials (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    tutorials_category_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);


--
-- Name: tutorials_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tutorials_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    tutorials_count integer DEFAULT 0
);


--
-- Name: user_login_changes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_login_changes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    old_login character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(80),
    password character varying(40),
    validkey character varying(40),
    email character varying(100) DEFAULT ''::character varying NOT NULL,
    newemail character varying(100),
    ipaddr character varying(15) DEFAULT ''::character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    firstname character varying DEFAULT ''::character varying,
    lastname character varying DEFAULT ''::character varying,
    image bytea,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    faction_id integer,
    faction_last_changed_on timestamp without time zone,
    avatar_id integer,
    city character varying,
    homepage character varying,
    sex smallint,
    msn character varying,
    icq character varying,
    send_global_announces boolean DEFAULT true NOT NULL,
    birthday date,
    cache_karma_points integer,
    irc character varying,
    country_id integer,
    photo character varying,
    hw_mouse character varying,
    hw_processor character varying,
    hw_motherboard character varying,
    hw_ram character varying,
    hw_hdd character varying,
    hw_graphiccard character varying,
    hw_soundcard character varying,
    hw_headphones character varying,
    hw_monitor character varying,
    hw_connection character varying,
    description text,
    is_superadmin boolean DEFAULT false NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    referer_user_id integer,
    cache_faith_points integer,
    notifications_global boolean DEFAULT true NOT NULL,
    notifications_newmessages boolean DEFAULT true NOT NULL,
    notifications_newregistrations boolean DEFAULT true NOT NULL,
    notifications_trackerupdates boolean DEFAULT true NOT NULL,
    xfire character varying,
    cache_unread_messages integer DEFAULT 0,
    resurrected_by_user_id integer,
    resurrection_started_on timestamp without time zone,
    using_tracker boolean DEFAULT false NOT NULL,
    secret character(32),
    cash numeric(14,2) DEFAULT 0.00 NOT NULL,
    lastcommented_on timestamp without time zone,
    global_bans integer DEFAULT 0 NOT NULL,
    last_clan_id integer,
    antiflood_level smallint DEFAULT (-1) NOT NULL,
    last_competition_id integer,
    competition_roster character varying,
    enable_competition_indicator boolean DEFAULT false NOT NULL,
    is_hq boolean DEFAULT false NOT NULL,
    enable_profile_signatures boolean DEFAULT false NOT NULL,
    profile_signatures_count integer DEFAULT 0 NOT NULL,
    wii_code character(16),
    email_public boolean DEFAULT false NOT NULL,
    gamertag character varying,
    googletalk character varying,
    yahoo_im character varying,
    notifications_newprofilesignature boolean DEFAULT true NOT NULL,
    tracker_autodelete_old_contents boolean DEFAULT true NOT NULL,
    comment_adds_to_tracker_enabled boolean DEFAULT true NOT NULL,
    cache_remaining_rating_slots integer,
    has_seen_tour boolean DEFAULT false NOT NULL,
    is_bot boolean DEFAULT false NOT NULL,
    admin_permissions character varying DEFAULT '00000'::bpchar NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_is_faction_leader boolean DEFAULT false NOT NULL,
    profile_last_updated_on timestamp without time zone,
    visitor_id character varying,
    comments_valorations_type_id integer,
    comments_valorations_strength numeric(10,2),
    enable_comments_sig boolean DEFAULT false NOT NULL,
    comments_sig character varying,
    comment_show_sigs boolean,
    has_new_friend_requests boolean DEFAULT false NOT NULL,
    default_portal character varying,
    emblems_mask character varying,
    random_id double precision DEFAULT random(),
    is_staff boolean DEFAULT false NOT NULL,
    pending_slog integer DEFAULT 0 NOT NULL,
    ranking_karma_pos integer,
    ranking_faith_pos integer,
    ranking_popularity_pos integer,
    cache_popularity integer
);


--
-- Name: users_actions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_actions (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    type_id integer NOT NULL,
    data character varying,
    object_id integer
);


--
-- Name: users_contents_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_contents_tags (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    original_name character varying NOT NULL
);


--
-- Name: users_emblems; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_emblems (
    id integer NOT NULL,
    created_on date DEFAULT (now())::date NOT NULL,
    user_id integer,
    emblem character varying NOT NULL,
    details character varying
);


--
-- Name: users_guids; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_guids (
    id integer NOT NULL,
    guid character varying NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying
);


--
-- Name: users_lastseen_ips; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_lastseen_ips (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    lastseen_on timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    ip inet NOT NULL
);


--
-- Name: users_newsfeeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_newsfeeds (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    summary character varying NOT NULL,
    users_action_id integer
);


--
-- Name: users_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    value character varying
);


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_roles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role character varying NOT NULL,
    role_data character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);


SET search_path = stats, pg_catalog;

--
-- Name: ads; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    referer character varying,
    user_id integer,
    user_agent character varying,
    portal_id integer,
    url character varying NOT NULL,
    element_id character varying,
    ip inet NOT NULL,
    visitor_id character varying,
    session_id character varying
);


--
-- Name: ads_daily; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE ads_daily (
    id integer NOT NULL,
    ads_slots_instance_id integer,
    created_on date NOT NULL,
    hits integer NOT NULL,
    ctr double precision NOT NULL,
    pageviews integer NOT NULL
);


--
-- Name: bandit_treatments; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE bandit_treatments (
    id integer NOT NULL,
    behaviour_class character varying NOT NULL,
    abtest_treatment character varying NOT NULL,
    round integer DEFAULT (-1) NOT NULL,
    lever0_reward character varying,
    lever1_reward character varying,
    lever2_reward character varying,
    lever3_reward character varying,
    lever4_reward character varying,
    lever5_reward character varying,
    lever6_reward character varying,
    lever7_reward character varying,
    lever8_reward character varying,
    lever9_reward character varying,
    lever10_reward character varying,
    lever11_reward character varying,
    lever12_reward character varying,
    lever13_reward character varying,
    lever14_reward character varying,
    lever15_reward character varying,
    lever16_reward character varying,
    lever17_reward character varying,
    lever18_reward character varying,
    lever19_reward character varying,
    lever20_reward character varying
);


--
-- Name: bets_results; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE bets_results (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    user_id integer NOT NULL,
    net_ammount numeric(10,2)
);


--
-- Name: clans_daily_stats; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE clans_daily_stats (
    id integer NOT NULL,
    clan_id integer,
    created_on date NOT NULL,
    popularity integer
);


--
-- Name: dates; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE dates (
    date date NOT NULL
);


--
-- Name: general; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE general (
    created_on date DEFAULT (now())::date NOT NULL,
    users_total integer DEFAULT 0 NOT NULL,
    users_confirmed integer DEFAULT 0 NOT NULL,
    users_active integer DEFAULT 0 NOT NULL,
    users_banned integer DEFAULT 0 NOT NULL,
    users_disabled integer DEFAULT 0 NOT NULL,
    karma_diff integer DEFAULT 0.0 NOT NULL,
    faith_diff integer DEFAULT 0 NOT NULL,
    cash_diff numeric(10,4) DEFAULT 0 NOT NULL,
    new_comments integer DEFAULT 0 NOT NULL,
    refered_hits integer DEFAULT 0 NOT NULL,
    avg_users_online double precision DEFAULT 0 NOT NULL,
    users_unconfirmed integer DEFAULT 0 NOT NULL,
    users_zombie integer DEFAULT 0 NOT NULL,
    users_resurrected integer DEFAULT 0 NOT NULL,
    users_shadow integer DEFAULT 0 NOT NULL,
    users_deleted integer DEFAULT 0 NOT NULL,
    users_unconfirmed_1w integer DEFAULT 0 NOT NULL,
    users_unconfirmed_2w integer DEFAULT 0 NOT NULL,
    new_clans integer,
    new_closed_topics integer,
    new_clans_portals integer,
    avg_page_render_time real,
    users_generating_karma integer,
    karma_per_user real,
    stddev_page_render_time real,
    active_factions_portals integer,
    completed_competitions_matches integer,
    active_clans_portals integer,
    proxy_errors integer,
    new_factions integer,
    http_401 integer,
    http_500 integer,
    http_404 integer,
    avg_db_queries_per_request double precision,
    stddev_db_queries_per_request double precision,
    requests integer,
    database_size bigint,
    sent_emails integer,
    downloaded_downloads_count integer,
    users_refered_today integer
);


--
-- Name: pageloadtime; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE pageloadtime (
    controller character varying,
    action character varying,
    "time" numeric(10,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    id integer NOT NULL,
    portal_id integer,
    http_status integer,
    db_queries integer,
    db_rows integer
);


--
-- Name: pageviews; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);


--
-- Name: portals; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE portals (
    id integer NOT NULL,
    created_on date NOT NULL,
    portal_id integer,
    karma integer NOT NULL,
    pageviews integer,
    visits integer,
    unique_visitors integer,
    unique_visitors_reg integer
);


--
-- Name: users_daily_stats; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE users_daily_stats (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on date NOT NULL,
    karma integer,
    faith integer,
    popularity integer
);


--
-- Name: users_karma_daily_by_portal; Type: TABLE; Schema: stats; Owner: -; Tablespace: 
--

CREATE TABLE users_karma_daily_by_portal (
    id integer NOT NULL,
    user_id integer NOT NULL,
    portal_id integer,
    karma integer,
    created_on date NOT NULL
);


SET search_path = public, pg_catalog;

--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_id_seq OWNED BY ads.id;


--
-- Name: ads_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_id_seq OWNED BY ads_slots.id;


--
-- Name: ads_slots_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_instances_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_instances_id_seq OWNED BY ads_slots_instances.id;


--
-- Name: ads_slots_portals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ads_slots_portals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_slots_portals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ads_slots_portals_id_seq OWNED BY ads_slots_portals.id;


--
-- Name: advertisers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE advertisers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: advertisers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE advertisers_id_seq OWNED BY advertisers.id;


--
-- Name: allowed_competitions_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allowed_competitions_participants_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: allowed_competitions_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allowed_competitions_participants_id_seq OWNED BY allowed_competitions_participants.id;


--
-- Name: anonymous_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE anonymous_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: anonymous_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE anonymous_users_id_seq OWNED BY anonymous_users.id;


--
-- Name: autologin_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE autologin_keys_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: autologin_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE autologin_keys_id_seq OWNED BY autologin_keys.id;


--
-- Name: avatars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE avatars_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: avatars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE avatars_id_seq OWNED BY avatars.id;


--
-- Name: ban_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ban_requests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ban_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ban_requests_id_seq OWNED BY ban_requests.id;


--
-- Name: bazar_districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bazar_districts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bazar_districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bazar_districts_id_seq OWNED BY bazar_districts.id;


--
-- Name: bets_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_categories_id_seq OWNED BY bets_categories.id;


--
-- Name: bets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_id_seq OWNED BY bets.id;


--
-- Name: bets_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_options_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_options_id_seq OWNED BY bets_options.id;


--
-- Name: bets_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bets_tickets_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bets_tickets_id_seq OWNED BY bets_tickets.id;


--
-- Name: blogentries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blogentries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: blogentries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blogentries_id_seq OWNED BY blogentries.id;


--
-- Name: cash_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cash_movements_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: cash_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cash_movements_id_seq OWNED BY cash_movements.id;


--
-- Name: chatlines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chatlines_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: chatlines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chatlines_id_seq OWNED BY chatlines.id;


--
-- Name: clans_friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_friends_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_friends_id_seq OWNED BY clans_friends.id;


--
-- Name: clans_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_groups_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_groups_id_seq OWNED BY clans_groups.id;


--
-- Name: clans_groups_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_groups_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_groups_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_groups_types_id_seq OWNED BY clans_groups_types.id;


--
-- Name: clans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_id_seq OWNED BY clans.id;


--
-- Name: clans_logs_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_logs_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_logs_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_logs_entries_id_seq OWNED BY clans_logs_entries.id;


--
-- Name: clans_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_movements_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_movements_id_seq OWNED BY clans_movements.id;


--
-- Name: clans_sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clans_sponsors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clans_sponsors_id_seq OWNED BY clans_sponsors.id;


--
-- Name: columns_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE columns_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: columns_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE columns_categories_id_seq OWNED BY columns_categories.id;


--
-- Name: columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE columns_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE columns_id_seq OWNED BY columns.id;


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: comments_valorations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_valorations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_valorations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_valorations_id_seq OWNED BY comments_valorations.id;


--
-- Name: comments_valorations_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_valorations_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: comments_valorations_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_valorations_types_id_seq OWNED BY comments_valorations_types.id;


--
-- Name: competitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_id_seq OWNED BY competitions.id;


--
-- Name: competitions_logs_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_logs_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_logs_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_logs_entries_id_seq OWNED BY competitions_logs_entries.id;


--
-- Name: competitions_matches_clans_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_clans_players_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_clans_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_clans_players_id_seq OWNED BY competitions_matches_clans_players.id;


--
-- Name: competitions_matches_games_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_games_maps_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_games_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_games_maps_id_seq OWNED BY competitions_matches_games_maps.id;


--
-- Name: competitions_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_id_seq OWNED BY competitions_matches.id;


--
-- Name: competitions_matches_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_reports_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_reports_id_seq OWNED BY competitions_matches_reports.id;


--
-- Name: competitions_matches_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_matches_uploads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_matches_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_matches_uploads_id_seq OWNED BY competitions_matches_uploads.id;


--
-- Name: competitions_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_participants_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_participants_id_seq OWNED BY competitions_participants.id;


--
-- Name: competitions_participants_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_participants_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_participants_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_participants_types_id_seq OWNED BY competitions_participants_types.id;


--
-- Name: competitions_sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE competitions_sponsors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: competitions_sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE competitions_sponsors_id_seq OWNED BY competitions_sponsors.id;


--
-- Name: content_ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_ratings_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_ratings_id_seq OWNED BY content_ratings.id;


--
-- Name: content_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_types_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: content_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_types_id_seq OWNED BY content_types.id;


--
-- Name: contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_id_seq OWNED BY contents.id;


--
-- Name: contents_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_locks_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_locks_id_seq OWNED BY contents_locks.id;


--
-- Name: contents_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_recommendations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_recommendations_id_seq OWNED BY contents_recommendations.id;


--
-- Name: contents_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_terms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_terms_id_seq OWNED BY contents_terms.id;


--
-- Name: contents_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contents_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contents_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contents_versions_id_seq OWNED BY contents_versions.id;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: demo_mirrors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demo_mirrors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demo_mirrors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demo_mirrors_id_seq OWNED BY demo_mirrors.id;


--
-- Name: demos_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demos_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demos_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demos_categories_id_seq OWNED BY demos_categories.id;


--
-- Name: demos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE demos_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: demos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE demos_id_seq OWNED BY demos.id;


--
-- Name: download_mirrors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE download_mirrors_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: download_mirrors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE download_mirrors_id_seq OWNED BY download_mirrors.id;


--
-- Name: downloaded_downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloaded_downloads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloaded_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloaded_downloads_id_seq OWNED BY downloaded_downloads.id;


--
-- Name: downloads_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloads_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloads_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloads_categories_id_seq OWNED BY downloads_categories.id;


--
-- Name: downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE downloads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE downloads_id_seq OWNED BY downloads.id;


--
-- Name: events_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_categories_id_seq OWNED BY events_categories.id;


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: events_news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_news_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_news_id_seq OWNED BY coverages.id;


--
-- Name: factions_banned_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_banned_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_banned_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_banned_users_id_seq OWNED BY factions_banned_users.id;


--
-- Name: factions_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_headers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_headers_id_seq OWNED BY factions_headers.id;


--
-- Name: factions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_id_seq OWNED BY factions.id;


--
-- Name: factions_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE factions_links_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: factions_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE factions_links_id_seq OWNED BY factions_links.id;


--
-- Name: faq_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE faq_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: faq_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE faq_categories_id_seq OWNED BY faq_categories.id;


--
-- Name: faq_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE faq_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: faq_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE faq_entries_id_seq OWNED BY faq_entries.id;


--
-- Name: forum_forums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_forums_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forum_forums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_forums_id_seq OWNED BY topics_categories.id;


--
-- Name: forum_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_topics_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forum_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_topics_id_seq OWNED BY topics.id;


--
-- Name: friends_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE friends_recommendations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: friends_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE friends_recommendations_id_seq OWNED BY friends_recommendations.id;


--
-- Name: friends_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE friends_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: friends_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE friends_users_id_seq OWNED BY friendships.id;


--
-- Name: funthings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE funthings_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: funthings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE funthings_id_seq OWNED BY funthings.id;


--
-- Name: games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_id_seq OWNED BY games.id;


--
-- Name: games_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_maps_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_maps_id_seq OWNED BY games_maps.id;


--
-- Name: games_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_modes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_modes_id_seq OWNED BY games_modes.id;


--
-- Name: games_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE games_versions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: games_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE games_versions_id_seq OWNED BY games_versions.id;


--
-- Name: global_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_notifications_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: global_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE global_notifications_id_seq OWNED BY global_notifications.id;


--
-- Name: global_vars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_vars_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: global_vars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE global_vars_id_seq OWNED BY global_vars.id;


--
-- Name: gmtv_broadcast_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gmtv_broadcast_messages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gmtv_broadcast_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gmtv_broadcast_messages_id_seq OWNED BY gmtv_broadcast_messages.id;


--
-- Name: gmtv_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gmtv_channels_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gmtv_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gmtv_channels_id_seq OWNED BY gmtv_channels.id;


--
-- Name: goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: images_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE images_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: images_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE images_categories_id_seq OWNED BY images_categories.id;


--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE images_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE images_id_seq OWNED BY images.id;


--
-- Name: interviews_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interviews_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: interviews_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interviews_categories_id_seq OWNED BY interviews_categories.id;


--
-- Name: interviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: interviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interviews_id_seq OWNED BY interviews.id;


--
-- Name: ip_bans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ip_bans_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ip_bans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ip_bans_id_seq OWNED BY ip_bans.id;


--
-- Name: ip_passwords_resets_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ip_passwords_resets_requests_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ip_passwords_resets_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ip_passwords_resets_requests_id_seq OWNED BY ip_passwords_resets_requests.id;


--
-- Name: macropolls_2007_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE macropolls_2007_1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: macropolls_2007_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE macropolls_2007_1_id_seq OWNED BY macropolls_2007_1.id;


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: news_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: news_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_categories_id_seq OWNED BY news_categories.id;


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_id_seq OWNED BY news.id;


--
-- Name: outstanding_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outstanding_users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: outstanding_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outstanding_users_id_seq OWNED BY outstanding_entities.id;


--
-- Name: platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE platforms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE platforms_id_seq OWNED BY platforms.id;


--
-- Name: polls_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_categories_id_seq OWNED BY polls_categories.id;


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_id_seq OWNED BY polls.id;


--
-- Name: polls_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_options_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_options_id_seq OWNED BY polls_options.id;


--
-- Name: polls_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_votes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: polls_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_votes_id_seq OWNED BY polls_votes.id;


--
-- Name: portal_headers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portal_headers_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portal_headers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portal_headers_id_seq OWNED BY portal_headers.id;


--
-- Name: portal_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portal_hits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portal_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portal_hits_id_seq OWNED BY portal_hits.id;


--
-- Name: portals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portals_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portals_id_seq OWNED BY portals.id;


--
-- Name: potds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE potds_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: potds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE potds_id_seq OWNED BY potds.id;


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: profile_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE profile_signatures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: profile_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE profile_signatures_id_seq OWNED BY profile_signatures.id;


--
-- Name: publishing_decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE publishing_decisions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: publishing_decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE publishing_decisions_id_seq OWNED BY publishing_decisions.id;


--
-- Name: publishing_personalities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE publishing_personalities_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: publishing_personalities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE publishing_personalities_id_seq OWNED BY publishing_personalities.id;


--
-- Name: questions_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE questions_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: questions_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE questions_categories_id_seq OWNED BY questions_categories.id;


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE questions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE questions_id_seq OWNED BY questions.id;


--
-- Name: recruitment_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recruitment_ads_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: recruitment_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recruitment_ads_id_seq OWNED BY recruitment_ads.id;


--
-- Name: refered_hits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE refered_hits_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: refered_hits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE refered_hits_id_seq OWNED BY refered_hits.id;


--
-- Name: reviews_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reviews_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reviews_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reviews_categories_id_seq OWNED BY reviews_categories.id;


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reviews_id_seq OWNED BY reviews.id;


--
-- Name: sent_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sent_emails_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sent_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sent_emails_id_seq OWNED BY sent_emails.id;


--
-- Name: silenced_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE silenced_emails_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: silenced_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE silenced_emails_id_seq OWNED BY silenced_emails.id;


--
-- Name: skin_textures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE skin_textures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: skin_textures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE skin_textures_id_seq OWNED BY skin_textures.id;


--
-- Name: skins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE skins_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: skins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE skins_id_seq OWNED BY skins.id;


--
-- Name: slog_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE slog_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: slog_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE slog_entries_id_seq OWNED BY slog_entries.id;


--
-- Name: sold_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sold_products_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sold_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sold_products_id_seq OWNED BY sold_products.id;


--
-- Name: terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE terms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE terms_id_seq OWNED BY terms.id;


--
-- Name: textures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE textures_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: textures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE textures_id_seq OWNED BY textures.id;


--
-- Name: tutorials_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tutorials_categories_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tutorials_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tutorials_categories_id_seq OWNED BY tutorials_categories.id;


--
-- Name: tutorials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tutorials_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tutorials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tutorials_id_seq OWNED BY tutorials.id;


--
-- Name: user_login_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_login_changes_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: user_login_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_login_changes_id_seq OWNED BY user_login_changes.id;


--
-- Name: users_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_actions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_actions_id_seq OWNED BY users_actions.id;


--
-- Name: users_contents_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_contents_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_contents_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_contents_tags_id_seq OWNED BY users_contents_tags.id;


--
-- Name: users_emblems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_emblems_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_emblems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_emblems_id_seq OWNED BY users_emblems.id;


--
-- Name: users_guids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_guids_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_guids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_guids_id_seq OWNED BY users_guids.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_lastseen_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_lastseen_ips_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_lastseen_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_lastseen_ips_id_seq OWNED BY users_lastseen_ips.id;


--
-- Name: users_newsfeeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_newsfeeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_newsfeeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_newsfeeds_id_seq OWNED BY users_newsfeeds.id;


--
-- Name: users_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_preferences_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_preferences_id_seq OWNED BY users_preferences.id;


--
-- Name: users_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_roles_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_roles_id_seq OWNED BY users_roles.id;


SET search_path = stats, pg_catalog;

--
-- Name: ads_daily_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE ads_daily_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_daily_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE ads_daily_id_seq OWNED BY ads_daily.id;


--
-- Name: ads_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: ads_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE ads_id_seq OWNED BY ads.id;


--
-- Name: bandit_treatments_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE bandit_treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bandit_treatments_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE bandit_treatments_id_seq OWNED BY bandit_treatments.id;


--
-- Name: bets_results_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE bets_results_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bets_results_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE bets_results_id_seq OWNED BY bets_results.id;


--
-- Name: clans_daily_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE clans_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clans_daily_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE clans_daily_stats_id_seq OWNED BY clans_daily_stats.id;


--
-- Name: pageloadtime_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE pageloadtime_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pageloadtime_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE pageloadtime_id_seq OWNED BY pageloadtime.id;


--
-- Name: pageviews_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE pageviews_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pageviews_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE pageviews_id_seq OWNED BY pageviews.id;


--
-- Name: portals_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE portals_stats_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: portals_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE portals_stats_id_seq OWNED BY portals.id;


--
-- Name: users_daily_stats_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE users_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_daily_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE users_daily_stats_id_seq OWNED BY users_daily_stats.id;


--
-- Name: users_karma_daily_by_portal_id_seq; Type: SEQUENCE; Schema: stats; Owner: -
--

CREATE SEQUENCE users_karma_daily_by_portal_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_karma_daily_by_portal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: -
--

ALTER SEQUENCE users_karma_daily_by_portal_id_seq OWNED BY users_karma_daily_by_portal.id;


SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots ALTER COLUMN id SET DEFAULT nextval('ads_slots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots_instances ALTER COLUMN id SET DEFAULT nextval('ads_slots_instances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ads_slots_portals ALTER COLUMN id SET DEFAULT nextval('ads_slots_portals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE advertisers ALTER COLUMN id SET DEFAULT nextval('advertisers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allowed_competitions_participants ALTER COLUMN id SET DEFAULT nextval('allowed_competitions_participants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE anonymous_users ALTER COLUMN id SET DEFAULT nextval('anonymous_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE autologin_keys ALTER COLUMN id SET DEFAULT nextval('autologin_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE avatars ALTER COLUMN id SET DEFAULT nextval('avatars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ban_requests ALTER COLUMN id SET DEFAULT nextval('ban_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bazar_districts ALTER COLUMN id SET DEFAULT nextval('bazar_districts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets ALTER COLUMN id SET DEFAULT nextval('bets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_categories ALTER COLUMN id SET DEFAULT nextval('bets_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_options ALTER COLUMN id SET DEFAULT nextval('bets_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bets_tickets ALTER COLUMN id SET DEFAULT nextval('bets_tickets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE blogentries ALTER COLUMN id SET DEFAULT nextval('blogentries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cash_movements ALTER COLUMN id SET DEFAULT nextval('cash_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE chatlines ALTER COLUMN id SET DEFAULT nextval('chatlines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans ALTER COLUMN id SET DEFAULT nextval('clans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_friends ALTER COLUMN id SET DEFAULT nextval('clans_friends_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_groups ALTER COLUMN id SET DEFAULT nextval('clans_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_groups_types ALTER COLUMN id SET DEFAULT nextval('clans_groups_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_logs_entries ALTER COLUMN id SET DEFAULT nextval('clans_logs_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_movements ALTER COLUMN id SET DEFAULT nextval('clans_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE clans_sponsors ALTER COLUMN id SET DEFAULT nextval('clans_sponsors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE columns ALTER COLUMN id SET DEFAULT nextval('columns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE columns_categories ALTER COLUMN id SET DEFAULT nextval('columns_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments_valorations ALTER COLUMN id SET DEFAULT nextval('comments_valorations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments_valorations_types ALTER COLUMN id SET DEFAULT nextval('comments_valorations_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions ALTER COLUMN id SET DEFAULT nextval('competitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_logs_entries ALTER COLUMN id SET DEFAULT nextval('competitions_logs_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches ALTER COLUMN id SET DEFAULT nextval('competitions_matches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_clans_players ALTER COLUMN id SET DEFAULT nextval('competitions_matches_clans_players_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_games_maps ALTER COLUMN id SET DEFAULT nextval('competitions_matches_games_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_reports ALTER COLUMN id SET DEFAULT nextval('competitions_matches_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_matches_uploads ALTER COLUMN id SET DEFAULT nextval('competitions_matches_uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_participants ALTER COLUMN id SET DEFAULT nextval('competitions_participants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_participants_types ALTER COLUMN id SET DEFAULT nextval('competitions_participants_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE competitions_sponsors ALTER COLUMN id SET DEFAULT nextval('competitions_sponsors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_ratings ALTER COLUMN id SET DEFAULT nextval('content_ratings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE content_types ALTER COLUMN id SET DEFAULT nextval('content_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents ALTER COLUMN id SET DEFAULT nextval('contents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_locks ALTER COLUMN id SET DEFAULT nextval('contents_locks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_recommendations ALTER COLUMN id SET DEFAULT nextval('contents_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_terms ALTER COLUMN id SET DEFAULT nextval('contents_terms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contents_versions ALTER COLUMN id SET DEFAULT nextval('contents_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE coverages ALTER COLUMN id SET DEFAULT nextval('events_news_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demo_mirrors ALTER COLUMN id SET DEFAULT nextval('demo_mirrors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demos ALTER COLUMN id SET DEFAULT nextval('demos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE demos_categories ALTER COLUMN id SET DEFAULT nextval('demos_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE download_mirrors ALTER COLUMN id SET DEFAULT nextval('download_mirrors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloaded_downloads ALTER COLUMN id SET DEFAULT nextval('downloaded_downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloads ALTER COLUMN id SET DEFAULT nextval('downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE downloads_categories ALTER COLUMN id SET DEFAULT nextval('downloads_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE events_categories ALTER COLUMN id SET DEFAULT nextval('events_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions ALTER COLUMN id SET DEFAULT nextval('factions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_banned_users ALTER COLUMN id SET DEFAULT nextval('factions_banned_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_headers ALTER COLUMN id SET DEFAULT nextval('factions_headers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE factions_links ALTER COLUMN id SET DEFAULT nextval('factions_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE faq_categories ALTER COLUMN id SET DEFAULT nextval('faq_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE faq_entries ALTER COLUMN id SET DEFAULT nextval('faq_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE friends_recommendations ALTER COLUMN id SET DEFAULT nextval('friends_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE friendships ALTER COLUMN id SET DEFAULT nextval('friends_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE funthings ALTER COLUMN id SET DEFAULT nextval('funthings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_maps ALTER COLUMN id SET DEFAULT nextval('games_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_modes ALTER COLUMN id SET DEFAULT nextval('games_modes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE games_versions ALTER COLUMN id SET DEFAULT nextval('games_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE global_notifications ALTER COLUMN id SET DEFAULT nextval('global_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE global_vars ALTER COLUMN id SET DEFAULT nextval('global_vars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gmtv_broadcast_messages ALTER COLUMN id SET DEFAULT nextval('gmtv_broadcast_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gmtv_channels ALTER COLUMN id SET DEFAULT nextval('gmtv_channels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE images ALTER COLUMN id SET DEFAULT nextval('images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE images_categories ALTER COLUMN id SET DEFAULT nextval('images_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE interviews ALTER COLUMN id SET DEFAULT nextval('interviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE interviews_categories ALTER COLUMN id SET DEFAULT nextval('interviews_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ip_bans ALTER COLUMN id SET DEFAULT nextval('ip_bans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ip_passwords_resets_requests ALTER COLUMN id SET DEFAULT nextval('ip_passwords_resets_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE macropolls_2007_1 ALTER COLUMN id SET DEFAULT nextval('macropolls_2007_1_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE news ALTER COLUMN id SET DEFAULT nextval('news_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE news_categories ALTER COLUMN id SET DEFAULT nextval('news_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE outstanding_entities ALTER COLUMN id SET DEFAULT nextval('outstanding_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE platforms ALTER COLUMN id SET DEFAULT nextval('platforms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls ALTER COLUMN id SET DEFAULT nextval('polls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_categories ALTER COLUMN id SET DEFAULT nextval('polls_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_options ALTER COLUMN id SET DEFAULT nextval('polls_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls_votes ALTER COLUMN id SET DEFAULT nextval('polls_votes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portal_headers ALTER COLUMN id SET DEFAULT nextval('portal_headers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portal_hits ALTER COLUMN id SET DEFAULT nextval('portal_hits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE portals ALTER COLUMN id SET DEFAULT nextval('portals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE potds ALTER COLUMN id SET DEFAULT nextval('potds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE profile_signatures ALTER COLUMN id SET DEFAULT nextval('profile_signatures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE publishing_decisions ALTER COLUMN id SET DEFAULT nextval('publishing_decisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE publishing_personalities ALTER COLUMN id SET DEFAULT nextval('publishing_personalities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE questions ALTER COLUMN id SET DEFAULT nextval('questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE questions_categories ALTER COLUMN id SET DEFAULT nextval('questions_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE recruitment_ads ALTER COLUMN id SET DEFAULT nextval('recruitment_ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE refered_hits ALTER COLUMN id SET DEFAULT nextval('refered_hits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reviews ALTER COLUMN id SET DEFAULT nextval('reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reviews_categories ALTER COLUMN id SET DEFAULT nextval('reviews_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sent_emails ALTER COLUMN id SET DEFAULT nextval('sent_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE silenced_emails ALTER COLUMN id SET DEFAULT nextval('silenced_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE skin_textures ALTER COLUMN id SET DEFAULT nextval('skin_textures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE skins ALTER COLUMN id SET DEFAULT nextval('skins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE slog_entries ALTER COLUMN id SET DEFAULT nextval('slog_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sold_products ALTER COLUMN id SET DEFAULT nextval('sold_products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE terms ALTER COLUMN id SET DEFAULT nextval('terms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE textures ALTER COLUMN id SET DEFAULT nextval('textures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE topics ALTER COLUMN id SET DEFAULT nextval('forum_topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE topics_categories ALTER COLUMN id SET DEFAULT nextval('forum_forums_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tracker_items ALTER COLUMN id SET DEFAULT nextval('tracker_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tutorials ALTER COLUMN id SET DEFAULT nextval('tutorials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tutorials_categories ALTER COLUMN id SET DEFAULT nextval('tutorials_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_login_changes ALTER COLUMN id SET DEFAULT nextval('user_login_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_actions ALTER COLUMN id SET DEFAULT nextval('users_actions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_contents_tags ALTER COLUMN id SET DEFAULT nextval('users_contents_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_emblems ALTER COLUMN id SET DEFAULT nextval('users_emblems_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_guids ALTER COLUMN id SET DEFAULT nextval('users_guids_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_lastseen_ips ALTER COLUMN id SET DEFAULT nextval('users_lastseen_ips_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_newsfeeds ALTER COLUMN id SET DEFAULT nextval('users_newsfeeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_preferences ALTER COLUMN id SET DEFAULT nextval('users_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users_roles ALTER COLUMN id SET DEFAULT nextval('users_roles_id_seq'::regclass);


SET search_path = stats, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE ads_daily ALTER COLUMN id SET DEFAULT nextval('ads_daily_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE bandit_treatments ALTER COLUMN id SET DEFAULT nextval('bandit_treatments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE bets_results ALTER COLUMN id SET DEFAULT nextval('bets_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE clans_daily_stats ALTER COLUMN id SET DEFAULT nextval('clans_daily_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE pageloadtime ALTER COLUMN id SET DEFAULT nextval('pageloadtime_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE pageviews ALTER COLUMN id SET DEFAULT nextval('pageviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE portals ALTER COLUMN id SET DEFAULT nextval('portals_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE users_daily_stats ALTER COLUMN id SET DEFAULT nextval('users_daily_stats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: stats; Owner: -
--

ALTER TABLE users_karma_daily_by_portal ALTER COLUMN id SET DEFAULT nextval('users_karma_daily_by_portal_id_seq'::regclass);


SET search_path = archive, pg_catalog;

--
-- Name: pageviewspkey; Type: CONSTRAINT; Schema: archive; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviewspkey PRIMARY KEY (id);


--
-- Name: tracker_items_pkey; Type: CONSTRAINT; Schema: archive; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_pkey PRIMARY KEY (id);


--
-- Name: treated_visitors_pkey; Type: CONSTRAINT; Schema: archive; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);


SET search_path = public, pg_catalog;

--
-- Name: ab_tests_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_name_key UNIQUE (name);


--
-- Name: ab_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_pkey PRIMARY KEY (id);


--
-- Name: ads_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_name_key UNIQUE (name);


--
-- Name: ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots_instances
    ADD CONSTRAINT ads_slots_instances_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_name_key UNIQUE (name);


--
-- Name: ads_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_pkey PRIMARY KEY (id);


--
-- Name: ads_slots_portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_slots_portals
    ADD CONSTRAINT ads_slots_portals_pkey PRIMARY KEY (id);


--
-- Name: advertisers_email_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_email_key UNIQUE (email);


--
-- Name: advertisers_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_name_key UNIQUE (name);


--
-- Name: advertisers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_pkey PRIMARY KEY (id);


--
-- Name: allowed_competitions_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allowed_competitions_participants
    ADD CONSTRAINT allowed_competitions_participants_pkey PRIMARY KEY (id);


--
-- Name: anonymous_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY anonymous_users
    ADD CONSTRAINT anonymous_users_pkey PRIMARY KEY (id);


--
-- Name: anonymous_users_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY anonymous_users
    ADD CONSTRAINT anonymous_users_session_id_key UNIQUE (session_id);


--
-- Name: autologin_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY autologin_keys
    ADD CONSTRAINT autologin_keys_pkey PRIMARY KEY (id);


--
-- Name: avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_pkey PRIMARY KEY (id);


--
-- Name: ban_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_pkey PRIMARY KEY (id);


--
-- Name: bazar_districts_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_code_key UNIQUE (code);


--
-- Name: bazar_districts_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_name_key UNIQUE (name);


--
-- Name: bazar_districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_pkey PRIMARY KEY (id);


--
-- Name: bets_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_pkey PRIMARY KEY (id);


--
-- Name: bets_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_options
    ADD CONSTRAINT bets_options_pkey PRIMARY KEY (id);


--
-- Name: bets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_pkey PRIMARY KEY (id);


--
-- Name: bets_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_tickets
    ADD CONSTRAINT bets_tickets_pkey PRIMARY KEY (id);


--
-- Name: bets_title_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_title_key UNIQUE (title);


--
-- Name: blogentries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_pkey PRIMARY KEY (id);


--
-- Name: cash_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cash_movements
    ADD CONSTRAINT cash_movements_pkey PRIMARY KEY (id);


--
-- Name: chatlines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY chatlines
    ADD CONSTRAINT chatlines_pkey PRIMARY KEY (id);


--
-- Name: clans_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_pkey PRIMARY KEY (id);


--
-- Name: clans_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_games
    ADD CONSTRAINT clans_games_pkey PRIMARY KEY (clan_id, game_id);


--
-- Name: clans_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_pkey PRIMARY KEY (id);


--
-- Name: clans_groups_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_name_key UNIQUE (name);


--
-- Name: clans_groups_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_pkey PRIMARY KEY (id);


--
-- Name: clans_logs_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_logs_entries
    ADD CONSTRAINT clans_logs_entries_pkey PRIMARY KEY (id);


--
-- Name: clans_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_movements
    ADD CONSTRAINT clans_movements_pkey PRIMARY KEY (id);


--
-- Name: clans_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_name_key UNIQUE (name);


--
-- Name: clans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_pkey PRIMARY KEY (id);


--
-- Name: clans_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT clans_sponsors_pkey PRIMARY KEY (id);


--
-- Name: clans_tag_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_tag_key UNIQUE (tag);


--
-- Name: columns_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_pkey PRIMARY KEY (id);


--
-- Name: columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: comments_valorations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_pkey PRIMARY KEY (id);


--
-- Name: comments_valorations_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_name_key UNIQUE (name);


--
-- Name: comments_valorations_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_pkey PRIMARY KEY (id);


--
-- Name: competitions_games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_games_maps
    ADD CONSTRAINT competitions_games_maps_pkey PRIMARY KEY (competition_id, games_map_id);


--
-- Name: competitions_logs_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_logs_entries
    ADD CONSTRAINT competitions_logs_entries_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_clans_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_clans_players
    ADD CONSTRAINT competitions_matches_clans_players_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_games_maps
    ADD CONSTRAINT competitions_matches_games_maps_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_reports
    ADD CONSTRAINT competitions_matches_reports_pkey PRIMARY KEY (id);


--
-- Name: competitions_matches_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_matches_uploads
    ADD CONSTRAINT competitions_matches_uploads_pkey PRIMARY KEY (id);


--
-- Name: competitions_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_name_key UNIQUE (name);


--
-- Name: competitions_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants
    ADD CONSTRAINT competitions_participants_pkey PRIMARY KEY (id);


--
-- Name: competitions_participants_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_name_key UNIQUE (name);


--
-- Name: competitions_participants_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_pkey PRIMARY KEY (id);


--
-- Name: competitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (id);


--
-- Name: competitions_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY competitions_sponsors
    ADD CONSTRAINT competitions_sponsors_pkey PRIMARY KEY (id);


--
-- Name: content_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_ratings
    ADD CONSTRAINT content_ratings_pkey PRIMARY KEY (id);


--
-- Name: content_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_name_key UNIQUE (name);


--
-- Name: content_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_pkey PRIMARY KEY (id);


--
-- Name: contents_content_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_key UNIQUE (content_type_id, external_id);


--
-- Name: contents_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_locks
    ADD CONSTRAINT contents_locks_pkey PRIMARY KEY (id);


--
-- Name: contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: contents_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_pkey PRIMARY KEY (id);


--
-- Name: contents_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_pkey PRIMARY KEY (id);


--
-- Name: contents_url_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_url_key UNIQUE (url);


--
-- Name: contents_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contents_versions
    ADD CONSTRAINT contents_versions_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: demo_mirrors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demo_mirrors
    ADD CONSTRAINT demo_mirrors_pkey PRIMARY KEY (id);


--
-- Name: demos_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_pkey PRIMARY KEY (id);


--
-- Name: demos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_pkey PRIMARY KEY (id);


--
-- Name: downloaded_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloaded_downloads
    ADD CONSTRAINT downloaded_downloads_pkey PRIMARY KEY (id);


--
-- Name: downloadmirrors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY download_mirrors
    ADD CONSTRAINT downloadmirrors_pkey PRIMARY KEY (id);


--
-- Name: downloads_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_pkey PRIMARY KEY (id);


--
-- Name: downloads_path_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_path_key UNIQUE (file);


--
-- Name: downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_pkey PRIMARY KEY (id);


--
-- Name: events_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_pkey PRIMARY KEY (id);


--
-- Name: events_news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: events_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events_users
    ADD CONSTRAINT events_users_pkey PRIMARY KEY (event_id, user_id);


--
-- Name: factions_banned_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_pkey PRIMARY KEY (id);


--
-- Name: factions_building_bottom_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_bottom_key UNIQUE (building_bottom);


--
-- Name: factions_building_middle_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_middle_key UNIQUE (building_middle);


--
-- Name: factions_building_top_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_top_key UNIQUE (building_top);


--
-- Name: factions_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_code_key UNIQUE (code);


--
-- Name: factions_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_headers
    ADD CONSTRAINT factions_headers_pkey PRIMARY KEY (id);


--
-- Name: factions_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_links
    ADD CONSTRAINT factions_links_pkey PRIMARY KEY (id);


--
-- Name: factions_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_name_key UNIQUE (name);


--
-- Name: factions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_pkey PRIMARY KEY (id);


--
-- Name: factions_portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY factions_portals
    ADD CONSTRAINT factions_portals_pkey PRIMARY KEY (faction_id, portal_id);


--
-- Name: faq_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_name_key UNIQUE (name);


--
-- Name: faq_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_pkey PRIMARY KEY (id);


--
-- Name: faq_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_entries
    ADD CONSTRAINT faq_entries_pkey PRIMARY KEY (id);


--
-- Name: forum_forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_pkey PRIMARY KEY (id);


--
-- Name: forum_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_pkey PRIMARY KEY (id);


--
-- Name: friends_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friends_recommendations
    ADD CONSTRAINT friends_recommendations_pkey PRIMARY KEY (id);


--
-- Name: friends_users_external_invitation_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_external_invitation_key_key UNIQUE (external_invitation_key);


--
-- Name: friends_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_pkey PRIMARY KEY (id);


--
-- Name: funthings_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_name_key UNIQUE (title);


--
-- Name: funthings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_pkey PRIMARY KEY (id);


--
-- Name: funthings_url_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_url_key UNIQUE (main);


--
-- Name: games_code_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_code_unique UNIQUE (code);


--
-- Name: games_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_maps
    ADD CONSTRAINT games_maps_pkey PRIMARY KEY (id);


--
-- Name: games_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_modes
    ADD CONSTRAINT games_modes_pkey PRIMARY KEY (id);


--
-- Name: games_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_name_key UNIQUE (name);


--
-- Name: games_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: games_platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_platforms
    ADD CONSTRAINT games_platforms_pkey PRIMARY KEY (game_id, platform_id);


--
-- Name: games_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY games_versions
    ADD CONSTRAINT games_versions_pkey PRIMARY KEY (id);


--
-- Name: global_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY global_notifications
    ADD CONSTRAINT global_notifications_pkey PRIMARY KEY (id);


--
-- Name: global_vars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY global_vars
    ADD CONSTRAINT global_vars_pkey PRIMARY KEY (id);


--
-- Name: gmtv_broadcast_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gmtv_broadcast_messages
    ADD CONSTRAINT gmtv_broadcast_messages_pkey PRIMARY KEY (id);


--
-- Name: gmtv_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gmtv_channels
    ADD CONSTRAINT gmtv_channels_pkey PRIMARY KEY (id);


--
-- Name: groups_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: images_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_pkey PRIMARY KEY (id);


--
-- Name: images_path_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_path_key UNIQUE (file);


--
-- Name: images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: interviews_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_pkey PRIMARY KEY (id);


--
-- Name: interviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_pkey PRIMARY KEY (id);


--
-- Name: ip_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ip_bans
    ADD CONSTRAINT ip_bans_pkey PRIMARY KEY (id);


--
-- Name: ip_passwords_resets_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ip_passwords_resets_requests
    ADD CONSTRAINT ip_passwords_resets_requests_pkey PRIMARY KEY (id);


--
-- Name: macropolls_2007_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: news_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_pkey PRIMARY KEY (id);


--
-- Name: news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: outstanding_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY outstanding_entities
    ADD CONSTRAINT outstanding_users_pkey PRIMARY KEY (id);


--
-- Name: platforms_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_code_key UNIQUE (code);


--
-- Name: platforms_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);


--
-- Name: platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);


--
-- Name: polls_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_pkey PRIMARY KEY (id);


--
-- Name: polls_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_pkey PRIMARY KEY (id);


--
-- Name: polls_options_poll_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_poll_id_key UNIQUE (poll_id, name);


--
-- Name: polls_options_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls_votes
    ADD CONSTRAINT polls_options_users_pkey PRIMARY KEY (id);


--
-- Name: polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: polls_title_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_title_key UNIQUE (title);


--
-- Name: portal_headers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portal_headers
    ADD CONSTRAINT portal_headers_pkey PRIMARY KEY (id);


--
-- Name: portal_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portal_hits
    ADD CONSTRAINT portal_hits_pkey PRIMARY KEY (id);


--
-- Name: portals_code_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_code_key UNIQUE (code);


--
-- Name: portals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_pkey PRIMARY KEY (id);


--
-- Name: portals_skins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals_skins
    ADD CONSTRAINT portals_skins_pkey PRIMARY KEY (portal_id, skin_id);


--
-- Name: potds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_pkey PRIMARY KEY (id);


--
-- Name: products_cls_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_cls_key UNIQUE (cls);


--
-- Name: products_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_name_key UNIQUE (name);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: profile_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profile_signatures
    ADD CONSTRAINT profile_signatures_pkey PRIMARY KEY (id);


--
-- Name: publishing_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publishing_decisions
    ADD CONSTRAINT publishing_decisions_pkey PRIMARY KEY (id);


--
-- Name: publishing_personalities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publishing_personalities
    ADD CONSTRAINT publishing_personalities_pkey PRIMARY KEY (id);


--
-- Name: questions_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_pkey PRIMARY KEY (id);


--
-- Name: questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: recruitment_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_pkey PRIMARY KEY (id);


--
-- Name: refered_hits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_pkey PRIMARY KEY (id);


--
-- Name: reviews_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_pkey PRIMARY KEY (id);


--
-- Name: reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_info__Slony-I_gamersmafia_rowID_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_info
    ADD CONSTRAINT "schema_info__Slony-I_gamersmafia_rowID_key" UNIQUE ("_Slony-I_gamersmafia_rowID");


--
-- Name: schema_info_version_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_info
    ADD CONSTRAINT schema_info_version_key UNIQUE (version);


--
-- Name: schema_migrations_version_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);


--
-- Name: sent_emails_message_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_message_key_key UNIQUE (message_key);


--
-- Name: sent_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_pkey PRIMARY KEY (id);


--
-- Name: silenced_emails_email_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_email_key UNIQUE (email);


--
-- Name: silenced_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_pkey PRIMARY KEY (id);


--
-- Name: skin_textures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skin_textures
    ADD CONSTRAINT skin_textures_pkey PRIMARY KEY (id);


--
-- Name: skins_hid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_hid_key UNIQUE (hid);


--
-- Name: skins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_pkey PRIMARY KEY (id);


--
-- Name: slog_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slog_entries
    ADD CONSTRAINT slog_entries_pkey PRIMARY KEY (id);


--
-- Name: sold_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sold_products
    ADD CONSTRAINT sold_products_pkey PRIMARY KEY (id);


--
-- Name: terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);


--
-- Name: textures_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY textures
    ADD CONSTRAINT textures_name_key UNIQUE (name);


--
-- Name: textures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY textures
    ADD CONSTRAINT textures_pkey PRIMARY KEY (id);


--
-- Name: tracker_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_pkey PRIMARY KEY (id);


--
-- Name: treated_visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);


--
-- Name: tutorials_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_pkey PRIMARY KEY (id);


--
-- Name: tutorials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_pkey PRIMARY KEY (id);


--
-- Name: user_login_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_login_changes
    ADD CONSTRAINT user_login_changes_pkey PRIMARY KEY (id);


--
-- Name: users_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_actions
    ADD CONSTRAINT users_actions_pkey PRIMARY KEY (id);


--
-- Name: users_contents_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_pkey PRIMARY KEY (id);


--
-- Name: users_emblems_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_emblems
    ADD CONSTRAINT users_emblems_pkey PRIMARY KEY (id);


--
-- Name: users_guids_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_guids
    ADD CONSTRAINT users_guids_pkey PRIMARY KEY (id);


--
-- Name: users_lastseen_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_lastseen_ips
    ADD CONSTRAINT users_lastseen_ips_pkey PRIMARY KEY (id);


--
-- Name: users_newsfeeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_newsfeeds
    ADD CONSTRAINT users_newsfeeds_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_preferences
    ADD CONSTRAINT users_preferences_pkey PRIMARY KEY (id);


--
-- Name: users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_pkey PRIMARY KEY (id);


SET search_path = stats, pg_catalog;

--
-- Name: ads_daily_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads_daily
    ADD CONSTRAINT ads_daily_pkey PRIMARY KEY (id);


--
-- Name: ads_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: bandit_treatments_abtest_treatment_key; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_abtest_treatment_key UNIQUE (abtest_treatment);


--
-- Name: bandit_treatments_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_pkey PRIMARY KEY (id);


--
-- Name: bets_results_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bets_results
    ADD CONSTRAINT bets_results_pkey PRIMARY KEY (id);


--
-- Name: clans_daily_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_pkey PRIMARY KEY (id);


--
-- Name: general_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general
    ADD CONSTRAINT general_pkey PRIMARY KEY (created_on);


--
-- Name: pageloadtime_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageloadtime
    ADD CONSTRAINT pageloadtime_pkey PRIMARY KEY (id);


--
-- Name: pageviews_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviews_pkey PRIMARY KEY (id);


--
-- Name: portals_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_stats_pkey PRIMARY KEY (id);


--
-- Name: users_daily_stats_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_pkey PRIMARY KEY (id);


--
-- Name: users_karma_daily_by_portal_pkey; Type: CONSTRAINT; Schema: stats; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_karma_daily_by_portal
    ADD CONSTRAINT users_karma_daily_by_portal_pkey PRIMARY KEY (id);


SET search_path = public, pg_catalog;

--
-- Name: anonymous_users_lastseen; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX anonymous_users_lastseen ON anonymous_users USING btree (lastseen_on);


--
-- Name: autologin_keys_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX autologin_keys_key ON autologin_keys USING btree (key);


--
-- Name: autologin_keys_lastused_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX autologin_keys_lastused_on ON autologin_keys USING btree (lastused_on);


--
-- Name: avatars_clan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_clan_id ON avatars USING btree (clan_id);


--
-- Name: avatars_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_faction_id ON avatars USING btree (faction_id);


--
-- Name: avatars_name_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX avatars_name_faction_id ON avatars USING btree (name, faction_id);


--
-- Name: avatars_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX avatars_user_id ON avatars USING btree (user_id);


--
-- Name: bets_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_approved_by_user_id ON bets USING btree (approved_by_user_id);


--
-- Name: bets_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX bets_categories_unique ON bets_categories USING btree (name, parent_id);


--
-- Name: bets_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_state ON bets USING btree (state);


--
-- Name: bets_tickets_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_tickets_user_id ON bets_tickets USING btree (user_id);


--
-- Name: bets_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bets_user_id ON bets USING btree (user_id);


--
-- Name: blogentries_published; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX blogentries_published ON blogentries USING btree (user_id, deleted);


--
-- Name: blogentries_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX blogentries_state ON blogentries USING btree (state);


--
-- Name: cash_movements_from; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX cash_movements_from ON cash_movements USING btree (object_id_from, object_id_from_class);


--
-- Name: cash_movements_to; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX cash_movements_to ON cash_movements USING btree (object_id_to, object_id_to_class);


--
-- Name: chatlines_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chatlines_created_on ON chatlines USING btree (created_on);


--
-- Name: clans_groups_r_users_group_user; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_groups_r_users_group_user ON clans_groups_users USING btree (clans_group_id, user_id);


--
-- Name: clans_groups_types_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_groups_types_name ON clans_groups_types USING btree (name);


--
-- Name: clans_r_games_clan_game; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_r_games_clan_game ON clans_games USING btree (clan_id, game_id);


--
-- Name: clans_r_games_clan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_r_games_clan_id ON clans_games USING btree (clan_id);


--
-- Name: clans_r_games_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_r_games_game_id ON clans_games USING btree (game_id);


--
-- Name: clans_sponsors_clan_id_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX clans_sponsors_clan_id_name ON clans_sponsors USING btree (clan_id, name);


--
-- Name: clans_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX clans_tag ON clans USING btree (tag);


--
-- Name: columns_appr_and_not_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_appr_and_not_deleted ON columns USING btree (approved_by_user_id, deleted);


--
-- Name: columns_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_approved_by_user_id ON columns USING btree (approved_by_user_id);


--
-- Name: columns_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX columns_categories_unique ON columns_categories USING btree (name, parent_id);


--
-- Name: columns_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_state ON columns USING btree (state);


--
-- Name: columns_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX columns_user_id ON columns USING btree (user_id);


--
-- Name: comments_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_content_id ON comments USING btree (content_id);


--
-- Name: comments_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on ON comments USING btree (created_on);


--
-- Name: comments_created_on_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on_content_id ON comments USING btree (created_on, content_id);


--
-- Name: comments_created_on_date_trunc; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_created_on_date_trunc ON comments USING btree (date_trunc('day'::text, created_on));


--
-- Name: comments_has_comments_valorations_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_has_comments_valorations_user_id ON comments USING btree (has_comments_valorations, user_id);


--
-- Name: comments_user_id_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX comments_user_id_created_on ON comments USING btree (user_id, created_on);


--
-- Name: comments_valorations_comment_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX comments_valorations_comment_id_user_id ON comments_valorations USING btree (comment_id, user_id);


--
-- Name: competitions_games_maps_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX competitions_games_maps_uniq ON competitions_games_maps USING btree (competition_id, games_map_id);


--
-- Name: competitions_matches_competition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_competition_id ON competitions_matches USING btree (competition_id);


--
-- Name: competitions_matches_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_event_id ON competitions_matches USING btree (event_id);


--
-- Name: competitions_matches_participant1_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_participant1_id ON competitions_matches USING btree (participant1_id);


--
-- Name: competitions_matches_participant2_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_matches_participant2_id ON competitions_matches USING btree (participant2_id);


--
-- Name: competitions_participants_competition_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX competitions_participants_competition_id ON competitions_participants USING btree (competition_id);


--
-- Name: competitions_participants_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX competitions_participants_uniq ON competitions_participants USING btree (competition_id, participant_id, competitions_participants_type_id);


--
-- Name: content_ratings_comb; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX content_ratings_comb ON content_ratings USING btree (ip, user_id, created_on);


--
-- Name: content_ratings_user_id_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX content_ratings_user_id_content_id ON content_ratings USING btree (user_id, content_id);


--
-- Name: contents_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_created_on ON contents USING btree (created_on);


--
-- Name: contents_is_public; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_is_public ON contents USING btree (is_public);


--
-- Name: contents_is_public_and_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_is_public_and_game_id ON contents USING btree (is_public, game_id);


--
-- Name: contents_locks_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_locks_uniq ON contents_locks USING btree (content_id);


--
-- Name: contents_recommendations_seen_on_content_id_receiver_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_recommendations_seen_on_content_id_receiver_user_id ON contents_recommendations USING btree (content_id, receiver_user_id);


--
-- Name: contents_recommendations_sender_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_recommendations_sender_user_id ON contents_recommendations USING btree (sender_user_id);


--
-- Name: contents_recommendations_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_recommendations_uniq ON contents_recommendations USING btree (content_id, sender_user_id, receiver_user_id);


--
-- Name: contents_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_state ON contents USING btree (state);


--
-- Name: contents_terms_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_terms_content_id ON contents_terms USING btree (content_id);


--
-- Name: contents_terms_term_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_terms_term_id ON contents_terms USING btree (term_id);


--
-- Name: contents_terms_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contents_terms_uniq ON contents_terms USING btree (content_id, term_id);


--
-- Name: contents_user_id_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contents_user_id_state ON contents USING btree (user_id, state);


--
-- Name: demos_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_approved_by_user_id ON demos USING btree (approved_by_user_id);


--
-- Name: demos_approved_by_user_id_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_approved_by_user_id_deleted ON demos USING btree (approved_by_user_id, deleted);


--
-- Name: demos_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_categories_unique ON demos_categories USING btree (name, parent_id);


--
-- Name: demos_common; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_common ON demos USING btree (created_on, approved_by_user_id, deleted, user_id, demos_category_id);


--
-- Name: demos_file; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_file ON demos USING btree (file);


--
-- Name: demos_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX demos_hash_md5 ON demos USING btree (file_hash_md5);


--
-- Name: demos_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_state ON demos USING btree (state);


--
-- Name: demos_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX demos_user_id ON demos USING btree (user_id);


--
-- Name: downloads_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_approved_by_user_id ON downloads USING btree (approved_by_user_id);


--
-- Name: downloads_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX downloads_categories_unique ON downloads_categories USING btree (name, parent_id);


--
-- Name: downloads_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_hash_md5 ON downloads USING btree (file_hash_md5);


--
-- Name: downloads_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_state ON downloads USING btree (state);


--
-- Name: downloads_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX downloads_user_id ON downloads USING btree (user_id);


--
-- Name: events_appr_and_not_deleted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_appr_and_not_deleted ON events USING btree (approved_by_user_id, deleted);


--
-- Name: events_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_approved_by_user_id ON events USING btree (approved_by_user_id);


--
-- Name: events_news_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_approved_by_user_id ON coverages USING btree (approved_by_user_id);


--
-- Name: events_news_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_state ON coverages USING btree (state);


--
-- Name: events_news_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_news_user_id ON coverages USING btree (user_id);


--
-- Name: events_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_state ON events USING btree (state);


--
-- Name: events_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX events_user_id ON events USING btree (user_id);


--
-- Name: factions_banned_users_fu; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_banned_users_fu ON factions_banned_users USING btree (faction_id, user_id);


--
-- Name: factions_headers_lasttime_used_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX factions_headers_lasttime_used_on ON factions_headers USING btree (lasttime_used_on);


--
-- Name: factions_headers_names_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_headers_names_faction_id ON factions_headers USING btree (faction_id, name);


--
-- Name: factions_links_names_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX factions_links_names_faction_id ON factions_links USING btree (faction_id, name);


--
-- Name: forum_forums_code_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX forum_forums_code_name_parent_id ON topics_categories USING btree (code, name, parent_id);


--
-- Name: forum_topics_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX forum_topics_state ON topics USING btree (state);


--
-- Name: forum_topics_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX forum_topics_user_id ON topics USING btree (user_id);


--
-- Name: friends_recommendations_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX friends_recommendations_uniq ON friends_recommendations USING btree (user_id, recommended_user_id);


--
-- Name: friends_recommendations_user_id_undecided; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX friends_recommendations_user_id_undecided ON friends_recommendations USING btree (user_id, added_as_friend);


--
-- Name: friends_users_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX friends_users_uniq ON friendships USING btree (sender_user_id, receiver_user_id);


--
-- Name: funthings_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX funthings_state ON funthings USING btree (state);


--
-- Name: games_maps_name_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_maps_name_game_id ON games_maps USING btree (name, game_id);


--
-- Name: games_modes_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_modes_uniq ON games_modes USING btree (name, game_id);


--
-- Name: games_users_game_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX games_users_game_id ON games_users USING btree (game_id);


--
-- Name: games_users_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_users_uniq ON games_users USING btree (user_id, game_id);


--
-- Name: games_users_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX games_users_user_id ON games_users USING btree (user_id);


--
-- Name: games_versions_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX games_versions_uniq ON games_versions USING btree (version, game_id);


--
-- Name: images_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_approved_by_user_id ON images USING btree (approved_by_user_id);


--
-- Name: images_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX images_categories_unique ON images_categories USING btree (name, parent_id);


--
-- Name: images_hash_md5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_hash_md5 ON images USING btree (file_hash_md5);


--
-- Name: images_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_state ON images USING btree (state);


--
-- Name: images_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX images_user_id ON images USING btree (user_id);


--
-- Name: interviews_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_approved_by_user_id ON interviews USING btree (approved_by_user_id);


--
-- Name: interviews_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX interviews_categories_unique ON interviews_categories USING btree (name, parent_id);


--
-- Name: interviews_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_state ON interviews USING btree (state);


--
-- Name: interviews_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX interviews_user_id ON interviews USING btree (user_id);


--
-- Name: ip_passwords_resets_requests_ip_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ip_passwords_resets_requests_ip_created_on ON ip_passwords_resets_requests USING btree (ip, created_on);


--
-- Name: messages_user_id_is_read; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_user_id_is_read ON messages USING btree (user_id_to) WHERE (is_read IS FALSE);


--
-- Name: news_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_approved_by_user_id ON news USING btree (approved_by_user_id);


--
-- Name: news_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX news_categories_unique ON news_categories USING btree (name, parent_id);


--
-- Name: news_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_state ON news USING btree (state);


--
-- Name: news_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX news_user_id ON news USING btree (user_id);


--
-- Name: outstanding_entities_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX outstanding_entities_uniq ON outstanding_entities USING btree (type, portal_id, active_on);


--
-- Name: platforms_users_platform_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX platforms_users_platform_id ON platforms_users USING btree (platform_id);


--
-- Name: platforms_users_platform_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX platforms_users_platform_id_user_id ON platforms_users USING btree (user_id, platform_id);


--
-- Name: platforms_users_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX platforms_users_user_id ON platforms_users USING btree (user_id);


--
-- Name: polls_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_approved_by_user_id ON polls USING btree (approved_by_user_id);


--
-- Name: polls_categories_code_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX polls_categories_code_parent_id ON polls_categories USING btree (code, parent_id);


--
-- Name: polls_categories_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX polls_categories_name_parent_id ON polls_categories USING btree (name, parent_id);


--
-- Name: polls_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_state ON polls USING btree (state);


--
-- Name: polls_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX polls_user_id ON polls USING btree (user_id);


--
-- Name: portal_hits_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portal_hits_uniq ON portal_hits USING btree (portal_id, date);


--
-- Name: portals_name_code_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portals_name_code_type ON portals USING btree (name, code, type);


--
-- Name: potds_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX potds_uniq ON potds USING btree (date, portal_id, images_category_id);


--
-- Name: profile_signatures_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX profile_signatures_user_id ON profile_signatures USING btree (user_id);


--
-- Name: profile_signatures_user_id_signer_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX profile_signatures_user_id_signer_user_id ON profile_signatures USING btree (user_id, signer_user_id);


--
-- Name: publishing_decisions_user_id_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX publishing_decisions_user_id_content_id ON publishing_decisions USING btree (user_id, content_id);


--
-- Name: publishing_personalities_user_id_content_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX publishing_personalities_user_id_content_type_id ON publishing_personalities USING btree (user_id, content_type_id);


--
-- Name: questions_categories_code_name_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX questions_categories_code_name_parent_id ON questions_categories USING btree (code, name, parent_id);


--
-- Name: questions_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_state ON questions USING btree (state);


--
-- Name: questions_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_user_id ON questions USING btree (user_id);


--
-- Name: refered_hits_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX refered_hits_user_id ON refered_hits USING btree (user_id);


--
-- Name: reviews_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_approved_by_user_id ON reviews USING btree (approved_by_user_id);


--
-- Name: reviews_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX reviews_categories_unique ON reviews_categories USING btree (name, parent_id);


--
-- Name: reviews_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_state ON reviews USING btree (state);


--
-- Name: reviews_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reviews_user_id ON reviews USING btree (user_id);


--
-- Name: sent_emails_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sent_emails_created_on ON sent_emails USING btree (created_on);


--
-- Name: sent_emails_gnotif; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sent_emails_gnotif ON sent_emails USING btree (global_notification_id);


--
-- Name: silenced_emails_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX silenced_emails_lower ON silenced_emails USING btree (lower((email)::text));


--
-- Name: slog_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slog_type_id ON slog_entries USING btree (type_id);


--
-- Name: terms_name_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_name_uniq ON terms USING btree (game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, name);


--
-- Name: terms_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_parent_id ON terms USING btree (parent_id);


--
-- Name: terms_root_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_root_id ON terms USING btree (root_id);


--
-- Name: terms_slug_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX terms_slug_uniq ON terms USING btree (game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, slug);


--
-- Name: tracker_items_content_id_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tracker_items_content_id_user_id ON tracker_items USING btree (content_id, user_id);


--
-- Name: tracker_items_full; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tracker_items_full ON tracker_items USING btree (content_id, user_id, lastseen_on, is_tracked);


--
-- Name: tracker_items_user_id_is_tracked; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tracker_items_user_id_is_tracked ON tracker_items USING btree (user_id, is_tracked) WHERE (is_tracked = true);


--
-- Name: treated_visitors_multi; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX treated_visitors_multi ON treated_visitors USING btree (ab_test_id, visitor_id, treatment);


--
-- Name: treated_visitors_per_test; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX treated_visitors_per_test ON treated_visitors USING btree (ab_test_id, visitor_id);


--
-- Name: tutorials_approved_by_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_approved_by_user_id ON tutorials USING btree (approved_by_user_id);


--
-- Name: tutorials_categories_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX tutorials_categories_unique ON tutorials_categories USING btree (name, parent_id);


--
-- Name: tutorials_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_state ON tutorials USING btree (state);


--
-- Name: tutorials_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tutorials_user_id ON tutorials USING btree (user_id);


--
-- Name: users_actions_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_actions_created_on ON users_actions USING btree (created_on);


--
-- Name: users_cache_remaning; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_cache_remaning ON users USING btree (cache_remaining_rating_slots) WHERE (cache_remaining_rating_slots IS NOT NULL);


--
-- Name: users_comments_sig; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_comments_sig ON users USING btree (comments_sig);


--
-- Name: users_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_email_id ON users USING btree (email, id);


--
-- Name: users_emblems_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_emblems_created_on ON users_emblems USING btree (created_on);


--
-- Name: users_emblems_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_emblems_user_id ON users_emblems USING btree (user_id);


--
-- Name: users_faction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_faction_id ON users USING btree (faction_id);


--
-- Name: users_guids_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_guids_uniq ON users_guids USING btree (guid, game_id);


--
-- Name: users_lastseen; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lastseen ON users USING btree (lastseen_on);


--
-- Name: users_lower_all; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lower_all ON users USING btree (lower((login)::text), lower((email)::text), lower((firstname)::text), lower((lastname)::text), ipaddr);


--
-- Name: users_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_lower_login ON users USING btree (lower((login)::text));


--
-- Name: users_newsfeeds_created_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_newsfeeds_created_on ON users_newsfeeds USING btree (created_on);


--
-- Name: users_preferences_user_id_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_preferences_user_id_name ON users_preferences USING btree (user_id, name);


--
-- Name: users_random_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_random_id ON users USING btree (random_id);


--
-- Name: users_roles_role; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_role ON users_roles USING btree (role);


--
-- Name: users_roles_role_role_data; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_role_role_data ON users_roles USING btree (role, role_data);


--
-- Name: users_roles_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_roles_uniq ON users_roles USING btree (user_id, role, role_data);


--
-- Name: users_roles_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_roles_user_id ON users_roles USING btree (user_id);


--
-- Name: users_secret; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_secret ON users USING btree (secret);


--
-- Name: users_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_state ON users USING btree (state);


--
-- Name: users_uniq_lower_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_uniq_lower_email ON users USING btree (lower((email)::text));


--
-- Name: users_uniq_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_uniq_lower_login ON users USING btree (lower((login)::text));


--
-- Name: users_validkey; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_validkey ON users USING btree (validkey);


SET search_path = stats, pg_catalog;

--
-- Name: bandit_treatments_abtest_treatment; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX bandit_treatments_abtest_treatment ON bandit_treatments USING btree (abtest_treatment);


--
-- Name: clans_daily_stats_clan_id_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX clans_daily_stats_clan_id_created_on ON clans_daily_stats USING btree (clan_id, created_on);


--
-- Name: dates_date; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX dates_date ON dates USING btree (date);


--
-- Name: pageloadtime_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageloadtime_created_on ON pageloadtime USING btree (created_on);


--
-- Name: pageviews_abtest_treatmentnotnull; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_abtest_treatmentnotnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NOT NULL);


--
-- Name: pageviews_abtest_treatmentnull; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_abtest_treatmentnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NULL);


--
-- Name: pageviews_created_on_abtest_treatment; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_created_on_abtest_treatment ON pageviews USING btree (created_on, abtest_treatment);


--
-- Name: pageviews_id_visitor_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_id_visitor_id ON pageviews USING btree (visitor_id, id);


--
-- Name: pageviews_portal_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_portal_id ON pageviews USING btree (portal_id);


--
-- Name: pageviews_visitor_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_visitor_id ON pageviews USING btree (visitor_id);


--
-- Name: pageviews_visitor_id_and_tstamps; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX pageviews_visitor_id_and_tstamps ON pageviews USING btree (visitor_id, created_on);


--
-- Name: portals_stats_portal_id; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX portals_stats_portal_id ON portals USING btree (portal_id);


--
-- Name: portals_stats_uniq; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX portals_stats_uniq ON portals USING btree (created_on, portal_id);


--
-- Name: users_daily_stats_user_id_created_on; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE INDEX users_daily_stats_user_id_created_on ON users_daily_stats USING btree (user_id, created_on);


--
-- Name: users_karma_daily_by_portal_uniq; Type: INDEX; Schema: stats; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_karma_daily_by_portal_uniq ON users_karma_daily_by_portal USING btree (user_id, portal_id, created_on);


SET search_path = public, pg_catalog;

--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT "$1" FOREIGN KEY (user_id_from) REFERENCES users(id) MATCH FULL;


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT "$1" FOREIGN KEY (clans_groups_type_id) REFERENCES clans_groups_types(id) MATCH FULL;


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT "$1" FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT "$2" FOREIGN KEY (user_id_to) REFERENCES users(id) MATCH FULL;


--
-- Name: ads_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES advertisers(id);


--
-- Name: ads_slots_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES advertisers(id) MATCH FULL;


--
-- Name: ads_slots_instances_ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads_slots_instances
    ADD CONSTRAINT ads_slots_instances_ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ads(id) MATCH FULL;


--
-- Name: ads_slots_instances_ads_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads_slots_instances
    ADD CONSTRAINT ads_slots_instances_ads_slot_id_fkey FOREIGN KEY (ads_slot_id) REFERENCES ads_slots(id) MATCH FULL;


--
-- Name: ads_slots_portals_ads_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ads_slots_portals
    ADD CONSTRAINT ads_slots_portals_ads_slot_id_fkey FOREIGN KEY (ads_slot_id) REFERENCES ads_slots(id) MATCH FULL;


--
-- Name: allowed_competitions_participants_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY allowed_competitions_participants
    ADD CONSTRAINT allowed_competitions_participants_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: autologin_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY autologin_keys
    ADD CONSTRAINT autologin_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: avatars_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: avatars_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: avatars_submitter_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_submitter_user_id_fkey FOREIGN KEY (submitter_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: ban_requests_banned_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_banned_user_id_fkey FOREIGN KEY (banned_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: ban_requests_confirming_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_confirming_user_id_fkey FOREIGN KEY (confirming_user_id) REFERENCES users(id);


--
-- Name: ban_requests_unban_confirming_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_unban_confirming_user_id_fkey FOREIGN KEY (unban_confirming_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: ban_requests_unban_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_unban_user_id_fkey FOREIGN KEY (unban_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: ban_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: bets_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);


--
-- Name: bets_bets_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_bets_category_id_fkey FOREIGN KEY (bets_category_id) REFERENCES bets_categories(id);


--
-- Name: bets_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES bets(id);


--
-- Name: bets_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES bets_categories(id);


--
-- Name: bets_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES bets_categories(id);


--
-- Name: bets_options_bet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_options
    ADD CONSTRAINT bets_options_bet_id_fkey FOREIGN KEY (bet_id) REFERENCES bets(id) MATCH FULL;


--
-- Name: bets_tickets_bets_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_tickets
    ADD CONSTRAINT bets_tickets_bets_option_id_fkey FOREIGN KEY (bets_option_id) REFERENCES bets_options(id) MATCH FULL;


--
-- Name: bets_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets_tickets
    ADD CONSTRAINT bets_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: bets_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: bets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: bets_winning_bets_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_winning_bets_option_id_fkey FOREIGN KEY (winning_bets_option_id) REFERENCES bets_options(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: blogentries_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: blogentries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: chatlines_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY chatlines
    ADD CONSTRAINT chatlines_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: clans_creator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: clans_friends_from_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_from_clan_id_fkey FOREIGN KEY (from_clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_friends_to_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_to_clan_id_fkey FOREIGN KEY (to_clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_groups_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_groups_clans_groups_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_clans_groups_type_id_fkey FOREIGN KEY (clans_groups_type_id) REFERENCES clans_groups_types(id);


--
-- Name: clans_groups_r_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_groups_users
    ADD CONSTRAINT clans_groups_r_users_group_id_fkey FOREIGN KEY (clans_group_id) REFERENCES clans_groups(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_logs_entries_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_logs_entries
    ADD CONSTRAINT clans_logs_entries_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: clans_movements_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_movements
    ADD CONSTRAINT clans_movements_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: clans_movements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clans_movements
    ADD CONSTRAINT clans_movements_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: columns_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES columns(id) ON DELETE SET NULL;


--
-- Name: columns_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES columns_categories(id) MATCH FULL;


--
-- Name: columns_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES columns_categories(id) MATCH FULL;


--
-- Name: columns_columns_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_columns_category_id_fkey FOREIGN KEY (columns_category_id) REFERENCES columns_categories(id) MATCH FULL;


--
-- Name: columns_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: comments_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: comments_lastedited_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_lastedited_by_user_id_fkey FOREIGN KEY (lastedited_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: comments_valorations_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES comments(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: comments_valorations_comments_valorations_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_comments_valorations_type_id_fkey FOREIGN KEY (comments_valorations_type_id) REFERENCES comments_valorations_types(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: comments_valorations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: competitions_competitions_participants_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_competitions_participants_type_id_fkey FOREIGN KEY (competitions_participants_type_id) REFERENCES competitions_participants_types(id) MATCH FULL;


--
-- Name: competitions_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: competitions_forum_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_forum_forum_id_fkey FOREIGN KEY (topics_category_id) REFERENCES topics_categories(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: competitions_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: competitions_games_maps_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_games_maps
    ADD CONSTRAINT competitions_games_maps_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id) MATCH FULL;


--
-- Name: competitions_games_maps_games_map_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_games_maps
    ADD CONSTRAINT competitions_games_maps_games_map_id_fkey FOREIGN KEY (games_map_id) REFERENCES games_maps(id) MATCH FULL;


--
-- Name: competitions_logs_entries_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_logs_entries
    ADD CONSTRAINT competitions_logs_entries_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: competitions_matches_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id);


--
-- Name: competitions_matches_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: competitions_matches_games_maps_competitions_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_games_maps
    ADD CONSTRAINT competitions_matches_games_maps_competitions_match_id_fkey FOREIGN KEY (competitions_match_id) REFERENCES competitions_matches(id) MATCH FULL;


--
-- Name: competitions_matches_games_maps_games_map_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_games_maps
    ADD CONSTRAINT competitions_matches_games_maps_games_map_id_fkey FOREIGN KEY (games_map_id) REFERENCES games_maps(id) MATCH FULL;


--
-- Name: competitions_matches_participant1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant1_id_fkey FOREIGN KEY (participant1_id) REFERENCES competitions_participants(id) ON DELETE SET NULL;


--
-- Name: competitions_matches_participant2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant2_id_fkey FOREIGN KEY (participant2_id) REFERENCES competitions_participants(id) ON DELETE SET NULL;


--
-- Name: competitions_matches_reports_competitions_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_reports
    ADD CONSTRAINT competitions_matches_reports_competitions_match_id_fkey FOREIGN KEY (competitions_match_id) REFERENCES competitions_matches(id);


--
-- Name: competitions_matches_reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_reports
    ADD CONSTRAINT competitions_matches_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: competitions_matches_uploads_competitions_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_uploads
    ADD CONSTRAINT competitions_matches_uploads_competitions_match_id_fkey FOREIGN KEY (competitions_match_id) REFERENCES competitions_matches(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: competitions_matches_uploads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_matches_uploads
    ADD CONSTRAINT competitions_matches_uploads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: competitions_participants_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_participants
    ADD CONSTRAINT competitions_participants_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: competitions_participants_competitions_participants_type_i_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_participants
    ADD CONSTRAINT competitions_participants_competitions_participants_type_i_fkey FOREIGN KEY (competitions_participants_type_id) REFERENCES competitions_participants_types(id) MATCH FULL;


--
-- Name: competitions_sponsors_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY competitions_sponsors
    ADD CONSTRAINT competitions_sponsors_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES competitions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: content_ratings_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_ratings
    ADD CONSTRAINT content_ratings_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id);


--
-- Name: content_ratings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_ratings
    ADD CONSTRAINT content_ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: contents_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: contents_content_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_fkey FOREIGN KEY (content_type_id) REFERENCES content_types(id) MATCH FULL;


--
-- Name: contents_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: contents_locks_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_locks
    ADD CONSTRAINT contents_locks_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: contents_locks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_locks
    ADD CONSTRAINT contents_locks_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: contents_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL;


--
-- Name: contents_recommendations_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: contents_recommendations_receiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_receiver_user_id_fkey FOREIGN KEY (receiver_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: contents_recommendations_sender_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES users(id);


--
-- Name: contents_terms_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: contents_terms_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: contents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: contents_versions_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contents_versions
    ADD CONSTRAINT contents_versions_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: coverages_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT coverages_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: demo_mirrors_demo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demo_mirrors
    ADD CONSTRAINT demo_mirrors_demo_id_fkey FOREIGN KEY (demo_id) REFERENCES demos(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: demos_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);


--
-- Name: demos_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES demos(id);


--
-- Name: demos_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES demos_categories(id);


--
-- Name: demos_categories_root_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_root_id_fkey FOREIGN KEY (root_id) REFERENCES demos_categories(id);


--
-- Name: demos_demos_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_demos_category_id_fkey FOREIGN KEY (demos_category_id) REFERENCES demos_categories(id);


--
-- Name: demos_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: demos_games_map_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_map_id_fkey FOREIGN KEY (games_map_id) REFERENCES games_maps(id) MATCH FULL;


--
-- Name: demos_games_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_mode_id_fkey FOREIGN KEY (games_mode_id) REFERENCES games_modes(id) MATCH FULL;


--
-- Name: demos_games_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_version_id_fkey FOREIGN KEY (games_version_id) REFERENCES games_versions(id) MATCH FULL;


--
-- Name: demos_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: demos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: downloaded_downloads_download_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloaded_downloads
    ADD CONSTRAINT downloaded_downloads_download_id_fkey FOREIGN KEY (download_id) REFERENCES downloads(id) MATCH FULL;


--
-- Name: downloaded_downloads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloaded_downloads
    ADD CONSTRAINT downloaded_downloads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: downloadmirrors_download_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY download_mirrors
    ADD CONSTRAINT downloadmirrors_download_id_fkey FOREIGN KEY (download_id) REFERENCES downloads(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: downloads_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: downloads_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES downloads(id) ON DELETE SET NULL;


--
-- Name: downloads_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES downloads_categories(id) MATCH FULL;


--
-- Name: downloads_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES downloads_categories(id) MATCH FULL;


--
-- Name: downloads_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: downloads_downloads_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_downloads_category_id_fkey FOREIGN KEY (downloads_category_id) REFERENCES downloads_categories(id) MATCH FULL;


--
-- Name: downloads_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: events_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: events_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES events(id) ON DELETE SET NULL;


--
-- Name: events_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES events_categories(id) MATCH FULL;


--
-- Name: events_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES events_categories(id) MATCH FULL;


--
-- Name: events_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: events_events_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_events_category_id_fkey FOREIGN KEY (events_category_id) REFERENCES events_categories(id) MATCH FULL;


--
-- Name: events_news_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_news_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: events_news_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES events(id) MATCH FULL;


--
-- Name: events_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: events_users_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_users
    ADD CONSTRAINT events_users_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;


--
-- Name: events_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events_users
    ADD CONSTRAINT events_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: factions_banned_users_banner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_banner_user_id_fkey FOREIGN KEY (banner_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: factions_banned_users_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: factions_banned_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: factions_boss_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_boss_user_id_fkey FOREIGN KEY (boss_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: factions_headers_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_headers
    ADD CONSTRAINT factions_headers_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL;


--
-- Name: factions_links_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_links
    ADD CONSTRAINT factions_links_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL;


--
-- Name: factions_portals_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_portals
    ADD CONSTRAINT factions_portals_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL;


--
-- Name: factions_portals_portal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions_portals
    ADD CONSTRAINT factions_portals_portal_id_fkey FOREIGN KEY (portal_id) REFERENCES portals(id) MATCH FULL;


--
-- Name: factions_underboss_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_underboss_user_id_fkey FOREIGN KEY (underboss_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: faq_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES faq_categories(id);


--
-- Name: faq_categories_root_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_root_id_fkey FOREIGN KEY (root_id) REFERENCES faq_categories(id);


--
-- Name: faq_entries_faq_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY faq_entries
    ADD CONSTRAINT faq_entries_faq_category_id_fkey FOREIGN KEY (faq_category_id) REFERENCES faq_categories(id) MATCH FULL;


--
-- Name: forum_forums_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES topics(id) ON DELETE SET NULL;


--
-- Name: forum_forums_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES topics_categories(id) MATCH FULL;


--
-- Name: forum_forums_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES topics_categories(id) MATCH FULL;


--
-- Name: forum_topics_forum_forum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_forum_forum_id_fkey FOREIGN KEY (topics_category_id) REFERENCES topics_categories(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: forum_topics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: friends_recommendations_recommended_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends_recommendations
    ADD CONSTRAINT friends_recommendations_recommended_user_id_fkey FOREIGN KEY (recommended_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: friends_recommendations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends_recommendations
    ADD CONSTRAINT friends_recommendations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: friends_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: friendships_receiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friendships
    ADD CONSTRAINT friendships_receiver_user_id_fkey FOREIGN KEY (receiver_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: funthings_approved_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: funthings_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: funthings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: games_maps_download_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_maps
    ADD CONSTRAINT games_maps_download_id_fkey FOREIGN KEY (download_id) REFERENCES downloads(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: games_maps_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_maps
    ADD CONSTRAINT games_maps_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: games_modes_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_modes
    ADD CONSTRAINT games_modes_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: games_platforms_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_platforms
    ADD CONSTRAINT games_platforms_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: games_platforms_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_platforms
    ADD CONSTRAINT games_platforms_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: games_users_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_users
    ADD CONSTRAINT games_users_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: games_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_users
    ADD CONSTRAINT games_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: games_versions_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY games_versions
    ADD CONSTRAINT games_versions_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: gmtv_channels_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gmtv_channels
    ADD CONSTRAINT gmtv_channels_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL;


--
-- Name: gmtv_channels_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gmtv_channels
    ADD CONSTRAINT gmtv_channels_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: groups_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: images_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: images_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES images(id) ON DELETE SET NULL;


--
-- Name: images_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES images_categories(id) MATCH FULL;


--
-- Name: images_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES images_categories(id) MATCH FULL;


--
-- Name: images_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: images_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: interviews_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES interviews(id) ON DELETE SET NULL;


--
-- Name: interviews_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES interviews_categories(id) MATCH FULL;


--
-- Name: interviews_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES interviews_categories(id) MATCH FULL;


--
-- Name: interviews_interviews_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_interviews_category_id_fkey FOREIGN KEY (interviews_category_id) REFERENCES interviews_categories(id) MATCH FULL;


--
-- Name: interviews_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: ip_bans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ip_bans
    ADD CONSTRAINT ip_bans_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: macropolls_2007_1_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: macropolls_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macropolls
    ADD CONSTRAINT macropolls_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: messages_in_reply_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_in_reply_to_fkey FOREIGN KEY (in_reply_to) REFERENCES messages(id) ON DELETE SET NULL;


--
-- Name: messages_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_thread_id_fkey FOREIGN KEY (thread_id) REFERENCES messages(id) MATCH FULL;


--
-- Name: news_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: news_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES news(id) ON DELETE SET NULL;


--
-- Name: news_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES news_categories(id) MATCH FULL;


--
-- Name: news_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES news_categories(id) MATCH FULL;


--
-- Name: news_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: news_news_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_news_category_id_fkey FOREIGN KEY (news_category_id) REFERENCES news_categories(id) MATCH FULL;


--
-- Name: news_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: platforms_users_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY platforms_users
    ADD CONSTRAINT platforms_users_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: platforms_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY platforms_users
    ADD CONSTRAINT platforms_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: polls_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: polls_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES polls(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: polls_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES polls_categories(id) MATCH FULL;


--
-- Name: polls_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES polls_categories(id) MATCH FULL;


--
-- Name: polls_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: polls_options_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES polls(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: polls_options_users_polls_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_votes
    ADD CONSTRAINT polls_options_users_polls_option_id_fkey FOREIGN KEY (polls_option_id) REFERENCES polls_options(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: polls_options_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls_votes
    ADD CONSTRAINT polls_options_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: polls_polls_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_polls_category_id_fkey FOREIGN KEY (polls_category_id) REFERENCES polls_categories(id) MATCH FULL;


--
-- Name: polls_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: portal_headers_faction_header_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portal_headers
    ADD CONSTRAINT portal_headers_faction_header_id_fkey FOREIGN KEY (factions_header_id) REFERENCES factions_headers(id) MATCH FULL;


--
-- Name: portal_headers_portal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portal_headers
    ADD CONSTRAINT portal_headers_portal_id_fkey FOREIGN KEY (portal_id) REFERENCES portals(id) MATCH FULL;


--
-- Name: portals_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: portals_default_gmtv_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_default_gmtv_channel_id_fkey FOREIGN KEY (default_gmtv_channel_id) REFERENCES gmtv_channels(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: portals_skin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_skin_id_fkey FOREIGN KEY (skin_id) REFERENCES skins(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: portals_skins_portal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portals_skins
    ADD CONSTRAINT portals_skins_portal_id_fkey FOREIGN KEY (portal_id) REFERENCES portals(id) MATCH FULL;


--
-- Name: portals_skins_skin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portals_skins
    ADD CONSTRAINT portals_skins_skin_id_fkey FOREIGN KEY (skin_id) REFERENCES skins(id) MATCH FULL;


--
-- Name: potds_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_image_id_fkey FOREIGN KEY (image_id) REFERENCES images(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: potds_images_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_images_category_id_fkey FOREIGN KEY (images_category_id) REFERENCES images_categories(id) MATCH FULL;


--
-- Name: potds_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: profile_signatures_signer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profile_signatures
    ADD CONSTRAINT profile_signatures_signer_user_id_fkey FOREIGN KEY (signer_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: profile_signatures_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profile_signatures
    ADD CONSTRAINT profile_signatures_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: publishing_decisions_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishing_decisions
    ADD CONSTRAINT publishing_decisions_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: publishing_decisions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishing_decisions
    ADD CONSTRAINT publishing_decisions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: publishing_personalities_content_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishing_personalities
    ADD CONSTRAINT publishing_personalities_content_type_id_fkey FOREIGN KEY (content_type_id) REFERENCES content_types(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: publishing_personalities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishing_personalities
    ADD CONSTRAINT publishing_personalities_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: questions_accepted_answer_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_accepted_answer_comment_id_fkey FOREIGN KEY (accepted_answer_comment_id) REFERENCES comments(id);


--
-- Name: questions_answer_selected_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_answer_selected_by_user_id_fkey FOREIGN KEY (answer_selected_by_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: questions_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: questions_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES questions(id) ON DELETE SET NULL;


--
-- Name: questions_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES questions_categories(id) MATCH FULL;


--
-- Name: questions_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES questions_categories(id) MATCH FULL;


--
-- Name: questions_questions_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_questions_category_id_fkey FOREIGN KEY (questions_category_id) REFERENCES questions_categories(id) MATCH FULL;


--
-- Name: questions_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: questions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: recruitment_ads_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: recruitment_ads_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id) MATCH FULL;


--
-- Name: recruitment_ads_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id);


--
-- Name: recruitment_ads_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id) MATCH FULL;


--
-- Name: recruitment_ads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: refered_hits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: reviews_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES reviews(id) ON DELETE SET NULL;


--
-- Name: reviews_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES reviews_categories(id) MATCH FULL;


--
-- Name: reviews_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES reviews_categories(id) MATCH FULL;


--
-- Name: reviews_reviews_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_reviews_category_id_fkey FOREIGN KEY (reviews_category_id) REFERENCES reviews_categories(id) MATCH FULL;


--
-- Name: reviews_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: sent_emails_global_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_global_notification_id_fkey FOREIGN KEY (global_notification_id) REFERENCES global_notifications(id);


--
-- Name: sent_emails_recipient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES users(id);


--
-- Name: skin_textures_skin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skin_textures
    ADD CONSTRAINT skin_textures_skin_id_fkey FOREIGN KEY (skin_id) REFERENCES skins(id) MATCH FULL;


--
-- Name: skin_textures_texture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skin_textures
    ADD CONSTRAINT skin_textures_texture_id_fkey FOREIGN KEY (texture_id) REFERENCES textures(id) MATCH FULL;


--
-- Name: skins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: slog_entries_reporter_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY slog_entries
    ADD CONSTRAINT slog_entries_reporter_user_id_fkey FOREIGN KEY (reporter_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: slog_entries_reviewer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY slog_entries
    ADD CONSTRAINT slog_entries_reviewer_user_id_fkey FOREIGN KEY (reviewer_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: sold_products_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sold_products
    ADD CONSTRAINT sold_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) MATCH FULL;


--
-- Name: sold_products_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sold_products
    ADD CONSTRAINT sold_products_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: terms_bazar_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_bazar_district_id_fkey FOREIGN KEY (bazar_district_id) REFERENCES bazar_districts(id) MATCH FULL;


--
-- Name: terms_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: terms_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;


--
-- Name: terms_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES contents(id);


--
-- Name: terms_parent_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_parent_term_id_fkey FOREIGN KEY (parent_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: terms_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES platforms(id) MATCH FULL;


--
-- Name: terms_root_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_root_id_fkey FOREIGN KEY (root_id) REFERENCES terms(id) MATCH FULL;


--
-- Name: topics_categories_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT topics_categories_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: topics_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;


--
-- Name: topics_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: tracker_items_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: tracker_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: treated_visitors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: tutorials_categories_last_updated_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES tutorials(id) ON DELETE SET NULL;


--
-- Name: tutorials_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES tutorials_categories(id) MATCH FULL;


--
-- Name: tutorials_categories_toplevel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_toplevel_id_fkey FOREIGN KEY (root_id) REFERENCES tutorials_categories(id) MATCH FULL;


--
-- Name: tutorials_tutorials_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_tutorials_category_id_fkey FOREIGN KEY (tutorials_category_id) REFERENCES tutorials_categories(id) MATCH FULL;


--
-- Name: tutorials_unique_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);


--
-- Name: user_login_changes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_login_changes
    ADD CONSTRAINT user_login_changes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_actions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_actions
    ADD CONSTRAINT users_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_avatar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_avatar_id_fkey FOREIGN KEY (avatar_id) REFERENCES avatars(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: users_comments_valorations_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_comments_valorations_type_id_fkey FOREIGN KEY (comments_valorations_type_id) REFERENCES comments_valorations_types(id);


--
-- Name: users_contents_tags_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id);


--
-- Name: users_contents_tags_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id);


--
-- Name: users_contents_tags_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: users_emblems_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_emblems
    ADD CONSTRAINT users_emblems_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_faction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL ON DELETE SET NULL;


--
-- Name: users_guids_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_guids
    ADD CONSTRAINT users_guids_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: users_guids_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_guids
    ADD CONSTRAINT users_guids_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: users_last_clan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_clan_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey1 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_clan_id_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey2 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey1 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_last_competition_id_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey2 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;


--
-- Name: users_lastseen_ips_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_lastseen_ips
    ADD CONSTRAINT users_lastseen_ips_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: users_newsfeeds_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_newsfeeds
    ADD CONSTRAINT users_newsfeeds_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_newsfeeds_users_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_newsfeeds
    ADD CONSTRAINT users_newsfeeds_users_action_id_fkey FOREIGN KEY (users_action_id) REFERENCES users_actions(id) MATCH FULL;


--
-- Name: users_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_preferences
    ADD CONSTRAINT users_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_referer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_referer_user_id_fkey FOREIGN KEY (referer_user_id) REFERENCES users(id) MATCH FULL;


--
-- Name: users_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_roles
    ADD CONSTRAINT users_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;


SET search_path = stats, pg_catalog;

--
-- Name: ads_daily_ads_slots_instance_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY ads_daily
    ADD CONSTRAINT ads_daily_ads_slots_instance_id_fkey FOREIGN KEY (ads_slots_instance_id) REFERENCES public.ads_slots_instances(id) MATCH FULL;


--
-- Name: ads_user_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;


--
-- Name: bets_results_bet_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY bets_results
    ADD CONSTRAINT bets_results_bet_id_fkey FOREIGN KEY (bet_id) REFERENCES public.bets(id) MATCH FULL;


--
-- Name: bets_results_user_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY bets_results
    ADD CONSTRAINT bets_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;


--
-- Name: clans_daily_stats_clan_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES public.clans(id) MATCH FULL;


--
-- Name: portals_stats_portal_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_stats_portal_id_fkey FOREIGN KEY (portal_id) REFERENCES public.portals(id) MATCH FULL;


--
-- Name: users_daily_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;


--
-- Name: users_karma_daily_by_portal_user_id_fkey; Type: FK CONSTRAINT; Schema: stats; Owner: -
--

ALTER TABLE ONLY users_karma_daily_by_portal
    ADD CONSTRAINT users_karma_daily_by_portal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;


--
-- PostgreSQL database dump complete
--

