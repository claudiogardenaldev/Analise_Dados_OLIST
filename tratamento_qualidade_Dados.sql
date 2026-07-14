
-- 1. Contagem de Registros na Tabela

SELECT 'olist_orders' AS tabela, COUNT(*) AS total_linhas FROM olist_orders
UNION ALL
SELECT 'olist_order_items', COUNT(*) FROM olist_order_items
UNION ALL
SELECT 'olist_customers', COUNT(*) FROM olist_customers
UNION ALL
SELECT 'olist_products', COUNT(*) FROM olist_products
UNION ALL
SELECT 'olist_sellers', COUNT(*) FROM olist_sellers
UNION ALL
SELECT 'olist_order_payments', COUNT(*) FROM olist_order_payments
UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM olist_order_reviews;


-- 2. verificacao de nulos em pedidos

SELECT
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulo,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulo,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS status_nulo,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS compra_nula,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS aprovado_nulo,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS entrega_transportadora_nula,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS entrega_cliente_nula,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS entrega_estimada_nula
FROM olist_orders;


-- 3. Distribuição dos status dos pedidos

SELECT
    order_status,
    COUNT(*) AS total_pedidos,
    ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM olist_orders) * 100, 2) AS percentual
FROM olist_orders
GROUP BY order_status
ORDER BY total_pedidos DESC;


-- 4. Pedidos entregues sem data de entrega

SELECT
    COUNT(*) AS pedidos_entregues_sem_data_entrega
FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- 5. Verificação de datas innconsistente

SELECT
    COUNT(*) AS entregas_antes_da_compra
FROM olist_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;

SELECT
    COUNT(*) AS aprovacao_antes_da_compra
FROM olist_orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

SELECT
    COUNT(*) AS transportadora_antes_da_compra
FROM olist_orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;


-- 6. Verificação de preços e fretes inválidos

SELECT
    COUNT(*) AS total_itens,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price_nulo,
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS price_invalido,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS frete_nulo,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS frete_invalido
FROM olist_order_items;


-- 7. Produtos sem categoria

SELECT
    COUNT(*) AS total_produtos,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS produtos_sem_categoria
FROM olist_products;


-- 8. Reviews com campos nulos

SELECT
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS review_id_nulo,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulo,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS review_score_nulo,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS titulo_nulo,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS comentario_nulo,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS data_criacao_nula,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS data_resposta_nula
FROM olist_order_reviews;


-- 9. duplicidade nas chaves principais

SELECT
    order_id,
    COUNT(*) AS quantidade
FROM olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    customer_id,
    COUNT(*) AS quantidade
FROM olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT
    product_id,
    COUNT(*) AS quantidade
FROM olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT
    seller_id,
    COUNT(*) AS quantidade
FROM olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- 10. View de pedidos entregues com métricas logísticas

CREATE OR REPLACE VIEW vw_orders_delivered AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    ROUND(
        (EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400)::numeric,
        2
    ) AS dias_entrega,

    CASE
        WHEN order_delivered_customer_date::date > order_estimated_delivery_date::date
            THEN 'Atrasado'
        ELSE 'No prazo'
    END AS status_entrega,

    CASE
        WHEN order_delivered_customer_date::date > order_estimated_delivery_date::date
            THEN order_delivered_customer_date::date - order_estimated_delivery_date::date
        ELSE 0
    END AS dias_atraso

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- 11. View Base de Vendas

CREATE OR REPLACE VIEW vw_sales_base AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_city,
    c.customer_state,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    oi.shipping_limit_date,

    p.product_category_name,
    COALESCE(p.product_category_name, 'sem_categoria') AS categoria_tratada,

    s.seller_city,
    s.seller_state,

    o.order_purchase_timestamp,
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS ano_mes,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS ano,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS mes_numero

FROM olist_orders o
JOIN olist_order_items oi
    ON o.order_id = oi.order_id
JOIN olist_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN olist_products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL;


-- 12. VIEW de pagamentos agregados por pedidos

CREATE OR REPLACE VIEW vw_payments_by_order AS
SELECT
    order_id,
    COUNT(*) AS qtd_pagamentos,
    ROUND(SUM(payment_value)::numeric, 2) AS valor_pago_total,
    MAX(payment_installments) AS max_parcelas,
    MIN(payment_type) AS tipo_pagamento_exemplo
FROM olist_order_payments
GROUP BY order_id;


-- 13. View de reviews com status logístico

CREATE OR REPLACE VIEW vw_reviews_base AS
SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    o.status_entrega,
    o.dias_entrega,
    o.dias_atraso
FROM olist_order_reviews r
JOIN vw_orders_delivered o
    ON r.order_id = o.order_id;
