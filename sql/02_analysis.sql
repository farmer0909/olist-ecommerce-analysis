SELECT
    p.product_category_name,
    COUNT(DISTINCT o.order_id) AS orders,
    sum(oi.price+oi.freight_value) AS gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id = oi.order_id
JOIN `05_products` p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'SP'
GROUP BY p.product_category_name
ORDER BY gmv DESC
LIMIT 15

SELECT
    p.product_category_name,
    COUNT(DISTINCT o.order_id) AS orders,
    sum(oi.price+oi.freight_value) AS gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id = oi.order_id
JOIN `05_products` p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'RJ'
GROUP BY p.product_category_name
ORDER BY gmv DESC
LIMIT 15;

SELECT
    c.customer_state,
    ROUND(AVG(oi.price), 2)         AS avg_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND c.customer_state IN ('SP','RJ')
GROUP BY c.customer_state;

