-- Questão 1

CREATE VIEW v_staff_performance AS
WITH TotalLocacoes AS (
    SELECT staff_id, COUNT(rental_id) Vendas
    FROM rental
    GROUP BY staff_id
),
TotalPagamentos AS (
    SELECT staff_id, SUM(amount) Total
    FROM payment
    GROUP BY staff_id
)
SELECT S.staff_id ID, S.first_name || ' ' || S.last_name NOME, C.city || ' (' || CO.country || ')' Endereco,
       COALESCE(L.Vendas, 0) Vendas, 'R$' || COALESCE(P.Total, 0) Total
FROM staff S
INNER JOIN store ST ON S.store_id = ST.store_id
LEFT JOIN address A ON ST.address_id = A.address_id
LEFT JOIN city C ON A.city_id = C.city_id
LEFT JOIN country CO ON C.country_id = CO.country_id
INNER JOIN TotalLocacoes L ON S.staff_id = L.staff_id
INNER JOIN TotalPagamentos P ON S.staff_id = P.staff_id;

-- Questão 2


DROP MATERIALIZED VIEW IF EXISTS mv_category_total_sales;
CREATE OR REPLACE MATERIALIZED VIEW mv_category_total_sales AS
SELECT CG.name Categoria, COALESCE(SUM(P.amount), 0) Arrecadado
FROM category CG INNER JOIN film_category FCG ON CG.category_id = FCG.category_id
INNER JOIN inventory I ON I.film_id = FCG.film_id
INNER JOIN rental R ON R.inventory_id = I.inventory_id
INNER JOIN payment P ON P.rental_id =  R.rental_id
GROUP BY Categoria
ORDER BY Arrecadado DESC
WITH DATA;

CREATE UNIQUE INDEX CONCURRENTLY mv_category_name_index ON mv_category_total_sales(Categoria);

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_category_total_sales;