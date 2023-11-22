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