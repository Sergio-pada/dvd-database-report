
DROP TABLE IF EXISTS detailed;
CREATE TABLE detailed(amount numeric(5,2), first_name VARCHAR(45), last_name VARCHAR(45), picture bytea);

DROP TABLE IF EXISTS summary;
CREATE TABLE summary(first_name VARCHAR(45), last_initial CHAR(1), total_sales numeric(7,2));

SELECT * FROM detailed;
SELECT * FROM summary;



INSERT INTO detailed
SELECT payment.amount, staff.first_name, staff.last_name, staff.picture
FROM payment
	INNER JOIN staff 
	ON payment.staff_id = staff.staff_id;

SELECT * FROM detailed;


CREATE OR REPLACE FUNCTION cut_last_name(current_last VARCHAR(45))
RETURNS char(1)
LANGUAGE plpgsql
AS $$
DECLARE
	last_name VARCHAR(45);
	last_initial CHAR(1);
BEGIN
	SELECT staff.last_name INTO last_name 
	FROM staff 
		WHERE current_last = staff.last_name;
	SELECT SUBSTRING(last_name,1,1) INTO last_initial;
	RETURN last_initial;
END;
$$;

INSERT INTO summary(first_name, last_initial, total_sales) 
	SELECT detailed.first_name, cut_last_name(detailed.last_name), SUM(amount) 
	FROM detailed
		GROUP BY detailed.first_name, detailed.last_name;
	
SELECT * FROM summary;
	

CREATE OR REPLACE FUNCTION update_summary()
RETURNS TRIGGER 
AS $update_summary$
DECLARE
	amount_input numeric(5,2);
	first_name_input VARCHAR(45);
BEGIN
	amount_input = NEW.amount;
	first_name_input = NEW.first_name;
	UPDATE summary
	SET total_sales = total_sales + amount_input
		WHERE first_name = first_name_input;
	RETURN NULL;
END;
$update_summary$ 
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER update_summary
AFTER INSERT ON detailed
	FOR EACH ROW 
	EXECUTE FUNCTION update_summary();

INSERT INTO detailed(amount, first_name, last_name, picture)
	VALUES(7.08, 'Jon', 'Stephens', NULL);

SELECT * FROM summary;


CREATE OR REPLACE PROCEDURE refresh_tables()
AS $$
BEGIN
	DELETE FROM detailed;
	
	INSERT INTO detailed
		SELECT payment.amount, staff.first_name, staff.last_name, staff.picture
		FROM payment
			INNER JOIN staff 
			ON payment.staff_id = staff.staff_id;
	
	DELETE FROM summary;
	
	INSERT INTO summary(first_name, last_initial, total_sales) 
		SELECT detailed.first_name, cut_last_name(detailed.last_name), SUM(amount) 
		FROM detailed
			GROUP BY detailed.first_name, detailed.last_name;
END;
$$ 
LANGUAGE PLPGSQL;


CALL refresh_tables();

SELECT * FROM summary;
