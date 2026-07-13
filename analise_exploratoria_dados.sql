-- ============================================================
-- 03_analise_exploratoria.sql
-- Projeto: Olist E-commerce Analytics com SQL
-- Objetivo: análise exploratória para gerar KPIs e insights
-- Banco: PostgreSQL
-- Observação: execute primeiro o arquivo 02_tratamento_qualidade_dados.sql
-- ============================================================


-- 1. PERÍODO DISPONÍVEL NO DATASET

SELECT
    MIN(order_purchase_timestamp) AS primeira_compra,
    MAX(order_purchase_timestamp) AS ultima_compra
FROM olist_orders;


-- 2. DISTRIBUIÇÃO DOS PEDIDOS POR STATUS

SELECT
    order_status,
    COUNT(*) AS total_pedidos,
    ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM olist_orders) * 100, 2) AS percentual
FROM olist_orders
GROUP BY order_status
ORDER BY total_pedidos DESC;


-- 3. KPIs GERAIS DO E-COMMERCE

SELECT
    COUNT(DISTINCT order_id) AS total_pedidos,
    COUNT(DISTINCT customer_id) AS total_clientes,
    COUNT(DISTINCT product_id) AS total_produtos_vendidos,
    COUNT(DISTINCT seller_id) AS total_vendedores,
    ROUND(SUM(price)::numeric, 2) AS faturamento_produtos,
    ROUND(SUM(freight_value)::numeric, 2) AS frete_total,
    ROUND(SUM(price + freight_value)::numeric, 2) AS valor_total_pago,
    ROUND(SUM(price)::numeric / COUNT(DISTINCT order_id), 2) AS ticket_medio
FROM vw_sales_base;


-- 4. FATURAMENTO MENSAL

SELECT
    ano,
    mes_numero,
    ano_mes,
    ROUND(SUM(price)::numeric, 2) AS faturamento_produtos,
    ROUND(SUM(freight_value)::numeric, 2) AS frete_total,
    ROUND(SUM(price + freight_value)::numeric, 2) AS valor_total_pago,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(SUM(price)::numeric / COUNT(DISTINCT order_id), 2) AS ticket_medio
FROM vw_sales_base
GROUP BY
    ano,
    mes_numero,
    ano_mes
ORDER BY
    ano,
    mes_numero;


-- 5. FRETE TOTAL POR MÊS

SELECT
    ano,
    mes_numero,
    ano_mes,
    ROUND(SUM(freight_value)::numeric, 2) AS frete_total
FROM vw_sales_base
GROUP BY
    ano,
    mes_numero,
    ano_mes
ORDER BY
    ano,
    mes_numero;


-- 6. TOP 10 CATEGORIAS POR RECEITA

SELECT
    categoria_tratada AS categoria,
    ROUND(SUM(price)::numeric, 2) AS receita,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(SUM(price)::numeric / COUNT(DISTINCT order_id), 2) AS ticket_medio
FROM vw_sales_base
GROUP BY categoria_tratada
ORDER BY receita DESC
LIMIT 10;


-- 7. TOP 10 ESTADOS POR QUANTIDADE DE PEDIDOS

SELECT
    customer_state AS estado,
    COUNT(DISTINCT order_id) AS total_pedidos
FROM vw_sales_base
GROUP BY customer_state
ORDER BY total_pedidos DESC
LIMIT 10;


-- 8. TOP 10 ESTADOS POR FATURAMENTO

SELECT
    customer_state AS estado,
    ROUND(SUM(price)::numeric, 2) AS faturamento,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(SUM(price)::numeric / COUNT(DISTINCT order_id), 2) AS ticket_medio
FROM vw_sales_base
GROUP BY customer_state
ORDER BY faturamento DESC
LIMIT 10;


-- 9. FRETE COMO PERCENTUAL DO FATURAMENTO POR ESTADO

SELECT
    customer_state AS estado,
    ROUND(SUM(price)::numeric, 2) AS faturamento,
    ROUND(SUM(freight_value)::numeric, 2) AS frete_total,
    ROUND((SUM(freight_value)::numeric / NULLIF(SUM(price)::numeric, 0)) * 100, 2) AS percentual_frete_sobre_faturamento
FROM vw_sales_base
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) >= 100
ORDER BY percentual_frete_sobre_faturamento DESC
LIMIT 10;


-- 10. PEDIDOS NO PRAZO VS ATRASADOS

SELECT
    status_entrega,
    COUNT(DISTINCT order_id) AS total_pedidos,
    ROUND(
        COUNT(DISTINCT order_id)::numeric /
        (SELECT COUNT(DISTINCT order_id) FROM vw_orders_delivered) * 100,
        2
    ) AS percentual
FROM vw_orders_delivered
GROUP BY status_entrega
ORDER BY total_pedidos DESC;


-- 11. PERCENTUAL GERAL DE PEDIDOS ATRASADOS

SELECT
    COUNT(DISTINCT order_id) AS total_pedidos_entregues,
    COUNT(DISTINCT CASE
        WHEN status_entrega = 'Atrasado'
        THEN order_id
    END) AS pedidos_atrasados,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN status_entrega = 'Atrasado'
            THEN order_id
        END)::numeric / COUNT(DISTINCT order_id) * 100,
        2
    ) AS percentual_pedidos_atrasados
FROM vw_orders_delivered;


-- 12. TOP 10 ESTADOS COM MAIOR PERCENTUAL DE ATRASO

SELECT
    c.customer_state AS estado,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(DISTINCT CASE
        WHEN o.status_entrega = 'Atrasado'
        THEN o.order_id
    END) AS pedidos_atrasados,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.status_entrega = 'Atrasado'
            THEN o.order_id
        END)::numeric / COUNT(DISTINCT o.order_id) * 100,
        2
    ) AS percentual_atraso
FROM vw_orders_delivered o
JOIN olist_customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY percentual_atraso DESC
LIMIT 10;


-- 13. TEMPO MÉDIO DE ENTREGA POR ESTADO

SELECT
    c.customer_state AS estado,
    ROUND(AVG(o.dias_entrega)::numeric, 2) AS tempo_medio_entrega_dias,
    COUNT(DISTINCT o.order_id) AS total_pedidos
FROM vw_orders_delivered o
JOIN olist_customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY tempo_medio_entrega_dias DESC
LIMIT 10;


-- 14. DISTRIBUIÇÃO DAS AVALIAÇÕES

SELECT
    review_score,
    COUNT(*) AS total_avaliacoes,
    ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM olist_order_reviews) * 100, 2) AS percentual
FROM olist_order_reviews
GROUP BY review_score
ORDER BY review_score;


-- 15. AVALIAÇÃO MÉDIA POR STATUS DE ENTREGA

SELECT
    status_entrega,
    ROUND(AVG(review_score)::numeric, 2) AS nota_media,
    COUNT(DISTINCT order_id) AS total_pedidos_avaliados
FROM vw_reviews_base
GROUP BY status_entrega
ORDER BY nota_media DESC;


-- 16. CATEGORIAS COM MAIOR NOTA MÉDIA

SELECT
    s.categoria_tratada AS categoria,
    ROUND(AVG(r.review_score)::numeric, 2) AS nota_media,
    COUNT(DISTINCT s.order_id) AS total_pedidos_avaliados
FROM vw_sales_base s
JOIN olist_order_reviews r
    ON s.order_id = r.order_id
GROUP BY s.categoria_tratada
HAVING COUNT(DISTINCT s.order_id) >= 100
ORDER BY nota_media DESC
LIMIT 10;


-- 17. TOP 10 VENDEDORES POR FATURAMENTO

SELECT
    seller_id,
    seller_state,
    ROUND(SUM(price)::numeric, 2) AS faturamento,
    COUNT(DISTINCT order_id) AS total_pedidos
FROM vw_sales_base
GROUP BY seller_id, seller_state
ORDER BY faturamento DESC
LIMIT 10;


-- 18. ESTADOS DOS VENDEDORES COM MAIOR FATURAMENTO

SELECT
    seller_state AS estado_vendedor,
    ROUND(SUM(price)::numeric, 2) AS faturamento,
    COUNT(DISTINCT order_id) AS total_pedidos
FROM vw_sales_base
GROUP BY seller_state
ORDER BY faturamento DESC
LIMIT 10;