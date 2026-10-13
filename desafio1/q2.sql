DROP TABLE IF EXISTS points_adjustment_audit;

CREATE TABLE points_adjustment_audit (
    id         SERIAL PRIMARY KEY,
    year       INT NOT NULL,
    driver_id  VARCHAR(100) NOT NULL,
    old_points DECIMAL(8,2),
    new_points DECIMAL(8,2),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);


CREATE OR REPLACE FUNCTION audit_points_adjustment()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
 BEGIN
    IF  NEW.points != OLD.points THEN
        INSERT INTO points_adjustment_audit(year, driver_id, old_points, new_points)
        VALUES(NEW.year, NEW.driver_id, OLD.points, NEW.points);
    END IF;

    RETURN NEW;
 END;
$$;


CREATE TRIGGER season_driver_standing_trgger
    AFTER UPDATE
    ON season_driver_standing
    FOR EACH ROW
    EXECUTE PROCEDURE audit_points_adjustment();

UPDATE season_driver_standing
SET points = points + 100
WHERE driver_id = 'ayrton-senna';

SELECT driver.id, driver.full_name FROM driver WHERE driver.name ILIKE 'Ayrton%';

SELECT * FROM points_adjustment_audit;