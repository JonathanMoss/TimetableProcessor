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