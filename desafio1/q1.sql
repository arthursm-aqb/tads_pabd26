CREATE MATERIALIZED VIEW mv_driver_season_summary AS
SELECT SD.year Ano, D.fullname Piloto, 
FROM driver D INNER JOIN season_driver SD ON D.id = SD.driver_id
LIMIT 1;

SELECT * FROM mv_driver_season_summary;

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_driver_season_summary;