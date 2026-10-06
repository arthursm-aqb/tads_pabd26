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

-- Questão 3

CREATE INDEX rental_return_date_index ON rental(return_date)
WHERE return_date IS NULL;

EXPLAIN ANALYZE
SELECT * FROM rental
WHERE return_date IS NULL;

-- Resultado da Query:  Index Scan using rental_return_date_index on rental  (cost=0.14..37.45 rows=183 width=36) (actual time=0.032..0.123 rows=183.00 loops=1)
-- Index Searches: 1
-- Buffers: shared hit=42 read=1
-- Planning:
-- Buffers: shared hit=75 read=8 dirtied=4
-- Planning Time: 8.892 ms
-- Execution Time: 0.152 ms

-- Questão 4

DROP INDEX film_description_index_gin;

CREATE INDEX film_description_index_gin ON film using gin (to_tsvector('english', description));

EXPLAIN ANALYZE
SELECT title, description
FROM film
WHERE to_tsvector('english', description) @@ to_tsquery('english', 'documentary | drama');

--  Bitmap Heap Scan on film  (cost=13.01..45.52 rows=10 width=109) (actual time=0.763..0.882 rows=207.00 loops=1)
--  Recheck Cond: (to_tsvector('english'::regconfig, description) @@ '''documentari'' | ''drama'''::tsquery)
--  Heap Blocks: exact=52
--  Buffers: shared hit=57
--  ->  Bitmap Index Scan on film_description_index_gin  (cost=0.00..13.01 rows=10 width=0) (actual time=0.318..0.319 rows=207.00 loops=1)
--         Index Cond: (to_tsvector('english'::regconfig, description) @@ '''documentari'' | ''drama'''::tsquery)
--         Index Searches: 1
--        Buffers: shared hit=5
-- Planning:
-- Buffers: shared hit=8 read=1
-- Planning Time: 0.554 ms
-- Execution Time: 1.192 ms


-- Questão 5

CREATE INDEX payment_costumer_index ON payment (customer_id, payment_date);
EXPLAIN ANALYZE SELECT * FROM payment WHERE customer_id = 1 ORDER BY payment_date DESC;

-- Resposta: A primeira coluna indexada deve ser a dos ids dos clientes, assim o indíce otimiza a busca dos pagamentos de um cliente específico.
-- Se fosse a coluna payment_date primeiro, ele organizaria em blocos de datas e seria ineficiente buscar o histórico dos clientes por cada bloco.

-- Questão 6

CREATE INDEX costumer_lowcaser_index ON customer (lower(email));

EXPLAIN ANALYZE
SELECT email FROM customer WHERE lower(email) = lower('MARY.SMITH@GMAIL.COM');

--  Bitmap Heap Scan on customer  (cost=4.30..11.15 rows=3 width=32) (actual time=0.060..0.061 rows=0.00 loops=1)
-- Recheck Cond: (lower((email)::text) = 'mary.smith@gmail.com'::text)
-- Buffers: shared hit=2
-- ->  Bitmap Index Scan on costumer_lowcaser_index  (cost=0.00..4.30 rows=3 width=0) (actual time=0.048..0.048 rows=0.00 loops=1)
--         Index Cond: (lower((email)::text) = 'mary.smith@gmail.com'::text)
--         Index Searches: 1
--        Buffers: shared hit=2
-- Planning Time: 0.189 ms
-- Execution Time: 0.089 ms

-- Questâo 7

CREATE OR REPLACE FUNCTION rental_devolucao()
    RETURNS trigger
    LANGUAGE plpgsql
AS 
$$
 BEGIN
    IF NEW.return_date IS NOT NULL AND NEW.return_date < OLD.rental_date THEN
        RAISE EXCEPTION 'Data de retorno anterior a data de aluguel';
    END IF;

    RETURN NEW;
 END;
$$;

CREATE TRIGGER return_date_change
    BEFORE INSERT OR UPDATE 
    ON rental
    FOR EACH ROW
    EXECUTE PROCEDURE rental_devolucao();


UPDATE rental
SET return_date = '2005-04-21'
WHERE rental_id = 2;

UPDATE rental
SET return_date = '2005-05-26'
WHERE rental_id = 2;