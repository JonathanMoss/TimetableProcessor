-- To be imported on database initialisation...

-- Stored Procedure to process replace transactions
CREATE OR REPLACE PROCEDURE process_rep() AS
$func$
DECLARE f RECORD;
BEGIN
FOR f in SELECT *
FROM basic_schedule
WHERE transaction_type = 'D'
LOOP
DELETE FROM basic_schedule WHERE id IN
(SELECT id FROM basic_schedule
WHERE id < f.id AND uid = f.uid AND date_runs_from = f.date_runs_from AND stp_indicator = f.stp_indicator ORDER BY id ASC LIMIT 1);
END LOOP;
UPDATE basic_schedule
SET transaction_type = 'N'
WHERE transaction_type = 'R';
END;
$func$ LANGUAGE plpgsql;

-- Stored Procedure to process delete transactions
CREATE OR REPLACE PROCEDURE process_del() AS
$func$
DECLARE f RECORD;
BEGIN
FOR f in SELECT * 
FROM basic_schedule 
WHERE transaction_type = 'D'
LOOP
DELETE FROM basic_schedule WHERE id IN
(SELECT id FROM basic_schedule
WHERE id < f.id AND uid = f.uid AND date_runs_from = f.date_runs_from AND stp_indicator = f.stp_indicator ORDER BY id ASC LIMIT 1);
DELETE FROM basic_schedule WHERE transaction_type = 'D';
END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- Stored Procedure to delete expired schedules
CREATE OR REPLACE PROCEDURE delete_expired()
LANGUAGE SQL
AS $$
DELETE FROM changes_en_route WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM basic_extra WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM location WHERE bs_id IN (SELECT id FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1'));
DELETE FROM basic_schedule WHERE CAST (date_runs_to AS DATE) < (current_date - INTEGER '1');
$$;

-- Stored Procedure to truncate all schedules
CREATE OR REPLACE PROCEDURE truncate_all()
LANGUAGE SQL
AS $$
TRUNCATE TABLE basic_schedule CASCADE;
$$;

-- Get applicable schedule uid's for date
CREATE OR REPLACE FUNCTION get_applicable_uid_by_date(qry_date text)
    RETURNS TABLE(valid_uid text) LANGUAGE 'plpgsql' STABLE STRICT AS $$
BEGIN
    RETURN QUERY SELECT DISTINCT(basic_schedule.uid::text) AS valid_uid
    FROM basic_schedule WHERE date_runs_from::date <= qry_date::date AND 
    date_runs_to::date >= qry_date::date AND
    days_run LIKE format_days_run(qry_date);
END
$$;

-- Return the days run string
CREATE OR REPLACE FUNCTION format_days_run(qry_date text) 
RETURNS text AS
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
CREATE OR REPLACE FUNCTION get_schedules(qry_date text) 
RETURNS setof basic_schedule AS
$func$
DECLARE q RECORD;
BEGIN
FOR q IN SELECT valid_uid FROM get_applicable_uid_by_date(qry_date)
LOOP
RETURN QUERY SELECT * FROM basic_schedule WHERE uid = q.valid_uid AND days_run LIKE format_days_run(qry_date) ORDER BY stp_indicator ASC, id DESC LIMIT 1;
END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- Produce valid UID for a location on the given date
CREATE OR REPLACE FUNCTION return_uid_for_location(in_tiploc TEXT, qry_date TEXT)
    RETURNS TABLE(valid_uid text) LANGUAGE 'plpgsql' STABLE STRICT AS
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
        ORDER BY stp_indicator ASC, id DESC LIMIT 1;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- Return valid schedule ID and location ID for TRJA query
DROP function trja_schedules(text,text);
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
                        date_runs_from::DATE <= qry_date::DATE
                    AND 
                        date_runs_to::DATE >= qry_date::DATE
                );
        END;
    $func$;


-- TRJA like TRUST lineup
DROP FUNCTION trja(text,text);
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
            SELECT location.wta FROM location INTO arrive
                WHERE location.id = r.id;
            SELECT location.wtp FROM location INTO pass
                WHERE location.id = r.id;
            SELECT location.wtd FROM location INTO depart
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

SELECT * FROM trja('PADTON', '2023-11-27') ORDER BY LEAST(arrive, pass, depart);