CREATE OR REPLACE FUNCTION verifica_driver()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
 BEGIN
     IF EXISTS(SELECT 1 FROM race_data RD where OLD.id = RD.driver_id) THEN
        RAISE EXCEPTION 'Não é possível excluir dados do piloto % ', OLD.name;
    END IF;

    RETURN OLD;
 END;
$$;


CREATE TRIGGER driver_num_pode
    BEFORE DELETE
    ON driver
    FOR EACH ROW
    EXECUTE PROCEDURE verifica_driver();

    DELETE FROM driver
    WHERE id = 'ayrton-senna';