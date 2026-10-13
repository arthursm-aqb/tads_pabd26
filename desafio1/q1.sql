CREATE MATERIALIZED VIEW mv_driver_season_summary AS
SELECT SD.year Ano, D.full_name Piloto, COUNT(RD.race_id) Corridas, SD.total_race_wins vitorias, SD.total_podiums podios, SD.total_points pontos_totais
FROM driver D INNER JOIN season_driver SD ON D.id = SD.driver_id
INNER JOIN race_data RD ON SD.driver_id = RD.driver_id
GROUP BY Ano, Piloto, vitorias, podios, pontos_totais
ORDER BY Ano DESC, vitorias DESC, pontos_totais DESC;

SELECT * FROM mv_driver_season_summary;

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_driver_season_summary;