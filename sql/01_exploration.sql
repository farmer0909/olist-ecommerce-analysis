-- Q1: 哪些州的 GMV 最高?
SELECT
    c.customer_state,
    Round(SUM(oi.price + oi.freight_value),2) AS gmv,
    COUNT(DISTINCT o.order_id) AS orders
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY gmv DESC;


SELECT
    c.customer_state,
    SUM(oi.price + oi.freight_value) AS gmv,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY gmv DESC,aov DESC ;


