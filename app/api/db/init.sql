-- To be imported on database initialisation...

DROP TABLE IF EXISTS "basic_extra";
DROP SEQUENCE IF EXISTS basic_extra_id_seq;
CREATE SEQUENCE basic_extra_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."basic_extra" (
    "id" integer DEFAULT nextval('basic_extra_id_seq') NOT NULL,
    "bs_id" integer,
    "uic_code" character varying(5),
    "atoc_code" character varying(2) NOT NULL,
    "applicable_timetable" character varying(1) NOT NULL,
    CONSTRAINT "basic_extra_pkey" PRIMARY KEY ("id")
) WITH (oids = false);

CREATE INDEX "ix_basic_extra_bs_id" ON "public"."basic_extra" USING btree ("bs_id");

CREATE INDEX "ix_basic_extra_id" ON "public"."basic_extra" USING btree ("id");


DROP TABLE IF EXISTS "basic_schedule";
DROP SEQUENCE IF EXISTS basic_schedule_id_seq;
CREATE SEQUENCE basic_schedule_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."basic_schedule" (
    "id" integer DEFAULT nextval('basic_schedule_id_seq') NOT NULL,
    "cif_header" integer NOT NULL,
    "transaction_type" character varying(1) NOT NULL,
    "uid" character varying(6) NOT NULL,
    "date_runs_from" character varying(6) NOT NULL,
    "date_runs_to" character varying(6),
    "days_run" character varying(7),
    "bank_holiday_running" character varying(1),
    "train_status" character varying(1),
    "train_category" character varying(2),
    "train_identity" character varying(4),
    "headcode" character varying(4),
    "train_service_code" character varying(8),
    "portion_id" character varying(1),
    "power_type" character varying(3),
    "timing_load" character varying(4),
    "speed" character varying(3),
    "operating_characteristics" character varying(6),
    "seating_class" character varying(1),
    "sleepers" character varying(1),
    "reservations" character varying(1),
    "catering_code" character varying(4),
    "service_branding" character varying(4),
    "stp_indicator" character varying(1),
    CONSTRAINT "basic_schedule_pkey" PRIMARY KEY ("id")
) WITH (oids = false);

CREATE INDEX "ix_basic_schedule_date_runs_from" ON "public"."basic_schedule" USING btree ("date_runs_from");

CREATE INDEX "ix_basic_schedule_date_runs_to" ON "public"."basic_schedule" USING btree ("date_runs_to");

CREATE INDEX "ix_basic_schedule_days_run" ON "public"."basic_schedule" USING btree ("days_run");

CREATE INDEX "ix_basic_schedule_id" ON "public"."basic_schedule" USING btree ("id");

CREATE INDEX "ix_basic_schedule_uid" ON "public"."basic_schedule" USING btree ("uid");


DROP TABLE IF EXISTS "changes_en_route";
DROP SEQUENCE IF EXISTS changes_en_route_id_seq;
CREATE SEQUENCE changes_en_route_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."changes_en_route" (
    "id" integer DEFAULT nextval('changes_en_route_id_seq') NOT NULL,
    "bs_id" integer,
    "tiploc" character varying(7) NOT NULL,
    "suffix" integer,
    "train_category" character varying(2),
    "train_identity" character varying(4),
    "headcode" character varying(4),
    "train_service_code" character varying(8),
    "portion_id" character varying(1),
    "power_type" character varying(3),
    "timing_load" character varying(4),
    "speed" character varying(3),
    "operating_characteristics" character varying(6),
    "seating_class" character varying(1),
    "sleepers" character varying(1),
    "reservations" character varying(1),
    "catering_code" character varying(4),
    "service_branding" character varying(4),
    "uic_code" character varying(5),
    CONSTRAINT "changes_en_route_pkey" PRIMARY KEY ("id")
) WITH (oids = false);

CREATE INDEX "ix_changes_en_route_bs_id" ON "public"."changes_en_route" USING btree ("bs_id");

CREATE INDEX "ix_changes_en_route_id" ON "public"."changes_en_route" USING btree ("id");


DROP TABLE IF EXISTS "header_record";
DROP SEQUENCE IF EXISTS header_record_id_seq;
CREATE SEQUENCE header_record_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."header_record" (
    "id" integer DEFAULT nextval('header_record_id_seq') NOT NULL,
    "mainframe_identity" character varying(20) NOT NULL,
    "extract_date" character varying(10) NOT NULL,
    "extract_time" character varying(8) NOT NULL,
    "current_file_ref" character varying(7) NOT NULL,
    "last_file_ref" character varying(7),
    "update_indicator" character varying(1) NOT NULL,
    "version" character varying(1) NOT NULL,
    "user_start_date" character varying(10) NOT NULL,
    "user_end_date" character varying(10) NOT NULL,
    "compressed_size" bigint NOT NULL,
    "uncompressed_size" bigint NOT NULL,
    "archive_file_name" character varying NOT NULL,
    "uncompressed_file_name" character varying NOT NULL,
    "downloaded_datetime" character varying(19) NOT NULL,
    "processed_datetime" character varying(19),
    "status" status,
    CONSTRAINT "header_record_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "ix_header_record_mainframe_identity" UNIQUE ("mainframe_identity")
) WITH (oids = false);

CREATE INDEX "ix_header_record_id" ON "public"."header_record" USING btree ("id");


DROP TABLE IF EXISTS "location";
DROP SEQUENCE IF EXISTS location_id_seq;
CREATE SEQUENCE location_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1;

CREATE TABLE "public"."location" (
    "id" integer DEFAULT nextval('location_id_seq') NOT NULL,
    "bs_id" integer,
    "record_type" character varying(2) NOT NULL,
    "tiploc" character varying(7) NOT NULL,
    "suffix" integer,
    "wta" character varying(5),
    "wtp" character varying(5),
    "wtd" character varying(5),
    "pta" character varying(4),
    "ptd" character varying(4),
    "platform" character varying(3),
    "line" character varying(3),
    "path" character varying(3),
    "activity" character varying(12),
    "engineering_allowance" character varying(2),
    "pathing_allowance" character varying(2),
    "performance_allowance" character varying(2),
    CONSTRAINT "location_pkey" PRIMARY KEY ("id")
) WITH (oids = false);

CREATE INDEX "ix_location_bs_id" ON "public"."location" USING btree ("bs_id");

CREATE INDEX "ix_location_id" ON "public"."location" USING btree ("id");


ALTER TABLE ONLY "public"."basic_extra" ADD CONSTRAINT "basic_extra_bs_id_fkey" FOREIGN KEY (bs_id) REFERENCES basic_schedule(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."changes_en_route" ADD CONSTRAINT "changes_en_route_bs_id_fkey" FOREIGN KEY (bs_id) REFERENCES basic_schedule(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."location" ADD CONSTRAINT "location_bs_id_fkey" FOREIGN KEY (bs_id) REFERENCES basic_schedule(id) ON DELETE CASCADE NOT DEFERRABLE;


-- Stored Procedure to process replace transactions
DROP PROCEDURE IF EXISTS process_rep();
CREATE OR REPLACE PROCEDURE process_rep() AS
$func$
    DECLARE 
        f RECORD;
    BEGIN
        FOR f in SELECT *
            FROM basic_schedule
            WHERE transaction_type = 'R'
        LOOP
            DELETE FROM basic_schedule WHERE id IN
                (SELECT id FROM basic_schedule
                    WHERE id < f.id 
                    AND 
                    uid = f.uid 
                    AND 
                    date_runs_from = f.date_runs_from 
                    AND 
                    stp_indicator = f.stp_indicator 
                    ORDER BY id ASC LIMIT 1);
        END LOOP;
        UPDATE basic_schedule
            SET transaction_type = 'N'
            WHERE transaction_type = 'R';
    END;
$func$ LANGUAGE plpgsql;

-- Stored Procedure to process delete transactions
DROP PROCEDURE IF EXISTS process_del();
CREATE OR REPLACE PROCEDURE process_del() AS
$func$
    DECLARE 
        f RECORD;
    BEGIN
        FOR f in SELECT * 
            FROM basic_schedule 
            WHERE transaction_type = 'D'
    LOOP
        DELETE FROM basic_schedule WHERE id IN
            (SELECT id FROM basic_schedule
                WHERE id < f.id 
                AND 
                uid = f.uid 
                AND 
                date_runs_from = f.date_runs_from 
                AND 
                stp_indicator = f.stp_indicator 
                ORDER BY id ASC LIMIT 1);
                
        DELETE FROM basic_schedule WHERE transaction_type = 'D';
    END LOOP;
    END;
$func$ LANGUAGE plpgsql;

-- Stored Procedure to delete expired schedules
DROP PROCEDURE IF EXISTS delete_expired();
CREATE OR REPLACE PROCEDURE delete_expired() AS
$func$
    DELETE FROM changes_en_route WHERE bs_id IN 
        (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
    DELETE FROM basic_extra WHERE bs_id IN 
        (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
    DELETE FROM location WHERE bs_id IN 
        (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
    DELETE FROM basic_schedule WHERE CAST 
        (date_runs_to AS DATE) < (current_date - INTEGER '1');
$func$ LANGUAGE SQL;

-- Stored Procedure to truncate all schedules
DROP PROCEDURE IF EXISTS truncate_all();
CREATE OR REPLACE PROCEDURE truncate_all() AS 
$func$
    TRUNCATE TABLE basic_schedule CASCADE;
$func$ LANGUAGE SQL;

-- Get applicable schedule uid's for date
DROP FUNCTION IF EXISTS get_applicable_uid_by_date(TEXT);
CREATE OR REPLACE FUNCTION get_applicable_uid_by_date(qry_date TEXT)
    RETURNS TABLE(valid_uid text) LANGUAGE 'plpgsql' STABLE STRICT AS 
$func$
BEGIN
    RETURN QUERY SELECT DISTINCT(basic_schedule.uid::text) AS valid_uid
    FROM basic_schedule WHERE date_runs_from::date <= qry_date::date AND 
    date_runs_to::date >= qry_date::date AND
    days_run LIKE format_days_run(qry_date);
END
$func$;

-- Return the days run string
DROP FUNCTION IF EXISTS format_days_run(TEXT);
CREATE OR REPLACE FUNCTION format_days_run(qry_date TEXT) 
RETURNS TEXT AS
$$
DECLARE
    day_of_week INTEGER := EXTRACT('DOW' FROM qry_date::date) + 1;
BEGIN
    IF day_of_week = 1 THEN
        RETURN '______1';
    END IF;
    IF day_of_week = 2 THEN
        RETURN '1______';
    END IF;
    IF day_of_week = 3 THEN
        RETURN '_1_____';
    END IF;
    IF day_of_week = 4 THEN
        RETURN '__1____';
    END IF;
    IF day_of_week = 5 THEN
        RETURN '___1___';
    END IF;
    IF day_of_week = 6 THEN
        RETURN '____1__';
    END IF;
    IF day_of_week = 7 THEN
        RETURN '_____1_';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Get schedules for DATE
DROP FUNCTION IF EXISTS get_schedules(TEXT);
CREATE OR REPLACE FUNCTION get_schedules(qry_date TEXT) 
RETURNS SETOF basic_schedule AS
$func$
DECLARE 
    q RECORD;
BEGIN
    FOR q IN SELECT valid_uid FROM get_applicable_uid_by_date(qry_date)
    LOOP
    RETURN QUERY SELECT * FROM basic_schedule WHERE uid = q.valid_uid AND days_run LIKE format_days_run(qry_date) ORDER BY stp_indicator ASC, id DESC LIMIT 1;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- Produce valid UID for a location on the given date
DROP FUNCTION IF EXISTS return_uid_for_location(TEXT,TEXT);
CREATE OR REPLACE FUNCTION return_uid_for_location(in_tiploc TEXT, qry_date TEXT)
    RETURNS TABLE(valid_uid text) LANGUAGE 'plpgsql' AS
$LINEUP$
DECLARE
    q RECORD;
BEGIN
    FOR q IN SELECT DISTINCT(bs_id) FROM location WHERE tiploc = in_tiploc
    LOOP
        RETURN QUERY SELECT DISTINCT(basic_schedule.uid::text) AS valid_uid 
        FROM basic_schedule
        WHERE
        id = q.bs_id AND
        days_run LIKE format_days_run(qry_date) AND
        date_runs_from::date <= qry_date::date AND 
        date_runs_to::date >= qry_date::date;
    END LOOP;
END;
$LINEUP$;

-- Return a location line-up
DROP FUNCTION IF EXISTS location_line_up(TEXT,TEXT);
CREATE OR REPLACE FUNCTION location_line_up(in_tiploc TEXT, qry_date TEXT)
    RETURNS SETOF basic_schedule AS
$func$
DECLARE 
    q RECORD;
BEGIN
    FOR q IN SELECT DISTINCT(valid_uid) FROM return_uid_for_location(in_tiploc, qry_date)
    LOOP
        RETURN QUERY SELECT * FROM basic_schedule 
        WHERE uid = q.valid_uid 
        AND 
        days_run LIKE format_days_run(qry_date)
        AND
        date_runs_from::date <= qry_date::date 
        AND 
        date_runs_to::date >= qry_date::date
        ORDER BY stp_indicator ASC, id DESC LIMIT 1;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- Return valid schedule ID and location ID for TRJA query
DROP FUNCTION IF EXISTS trja_schedules(TEXT,TEXT);
CREATE OR REPLACE FUNCTION trja_schedules(in_tiploc TEXT, qry_date TEXT)
    RETURNS TABLE(id INT, bs_id INT) 
    LANGUAGE 'plpgsql' STABLE STRICT AS
    $func$
        BEGIN
            RETURN QUERY SELECT location.id, location.bs_id FROM location WHERE
                location.tiploc = in_tiploc
                AND
                location.bs_id IN (
                    SELECT temp.id FROM location_line_up(in_tiploc, qry_date) temp
                    WHERE 
                        temp.date_runs_from::date <= qry_date::date
                    AND 
                        temp.date_runs_to::date >= qry_date::date
                );
        END;
    $func$;


-- TRJA like TRUST lineup
DROP FUNCTION IF EXISTS trja(TEXT,TEXT);
CREATE OR REPLACE FUNCTION trja(in_tiploc TEXT, qry_date TEXT)
    RETURNS TABLE(
        h_code VARCHAR,
        uid VARCHAR,
        origin VARCHAR,
        destination VARCHAR,
        arrive TIME,
        pass TIME,
        depart TIME,
        path VARCHAR,
        platform VARCHAR,
        line VARCHAR,
        stp VARCHAR
    )
    LANGUAGE 'plpgsql' 
    STABLE STRICT AS
    $$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN SELECT * FROM trja_schedules(in_tiploc, qry_date)
        LOOP
            SELECT basic_schedule.train_identity FROM basic_schedule INTO h_code
                WHERE basic_schedule.id = r.bs_id;
            SELECT basic_schedule.uid FROM basic_schedule INTO uid
                WHERE basic_schedule.id = r.bs_id;
            SELECT location.tiploc FROM location INTO origin
                WHERE location.bs_id = r.bs_id AND
                location.record_type = 'LO';
            SELECT location.tiploc FROM location INTO destination
                WHERE location.bs_id = r.bs_id AND
                location.record_type = 'LT';
            SELECT REPLACE(location.wta, 'H', '30') FROM location INTO arrive
                WHERE location.id = r.id;
            SELECT REPLACE(location.wtp, 'H', '30') FROM location INTO pass
                WHERE location.id = r.id;
            SELECT REPLACE(location.wtd, 'H', '30') FROM location INTO depart
                WHERE location.id = r.id;
            SELECT location.path FROM location INTO path
                WHERE location.id = r.id;
            SELECT location.platform FROM location INTO platform
                WHERE location.id = r.id;
            SELECT location.line FROM location INTO line
                WHERE location.id = r.id;
            SELECT 
                CASE 
                    WHEN basic_schedule.stp_indicator = 'P' THEN 'LTP'
                    WHEN basic_schedule.stp_indicator = 'N' THEN 'STP'
                    WHEN basic_schedule.stp_indicator = 'O' THEN 'VAR' 
                END
                AS stp_indicator
            
            FROM basic_schedule INTO stp
                WHERE basic_schedule.id = r.bs_id;
            RETURN NEXT;
        END LOOP;
    END;
    $$;

-- SELECT * FROM trja('CREWE', '2023-11-29') ORDER BY LEAST(arrive, pass, depart);
-- SELECT * FROM trja('BHAMNWS', '2023-12-01') WHERE LEAST(arrive, pass, depart) > (current_time - INTERVAL '10 minutes') AND LEAST (arrive, pass, depart) < (current_time + INTERVAL '4 hours') ORDER BY LEAST(arrive, pass, depart);
-- SELECT * FROM (
-- 	(SELECT '2023-12-03' AS dt, * FROM trja('BHAMNWS', '2023-12-03'))
-- 		UNION
-- 	(SELECT '2023-12-04' AS dt, * FROM trja('BHAMNWS', '2023-12-04'))
-- 	)
-- ORDER BY dt ASC, LEAST(arrive,pass,depart);