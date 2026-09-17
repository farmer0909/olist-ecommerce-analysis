-- ============================================================
-- 02 — Analysis
-- Scenario: quarterly ops review — where does the money come
--           from, and where is it leaking?
--
-- Definitions:
--   GMV = price + freight_value (gross merchandise value, not profit)
--   All queries filtered to order_status = 'delivered'
--   order → order_items is one-to-many, so order counts use
--   COUNT(DISTINCT order_id)
-- ============================================================

USE olist_ecommerce;


-- ============================================================
-- Q1 — Which states generate the most GMV?
-- ============================================================

SELECT
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value), 2)                              AS gmv,
    COUNT(DISTINCT o.order_id)                                              AS orders,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `04_customers`   c  ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id    = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY gmv DESC;

-- Results (top 3):
--   SP  GMV 5,769,703 | orders 40,501 | AOV 142
--   RJ  GMV 2,055,402 | orders 12,350 | AOV 166
--   MG  GMV 1,818,892 | orders 11,354
--
-- Findings:
--   - SP accounts for ~37% of national GMV, 2.8x the runner-up RJ
--   - But SP's AOV (142) is LOWER than RJ's (166)
--   - SP leads on order volume (3.3x RJ), not on spending power
--   - Top 3 states together make up ~62% — highly concentrated
--
-- → Follow-up: why is SP's AOV lower? (see Q2)


-- ============================================================
-- Q2 — Why is SP's average order value lower than RJ's?
-- Hypothesis: the two states buy different product categories
-- ============================================================

-- 2a. Top 15 categories, per state
--     (swap 'SP' for 'RJ' and run again, then compare side by side)

SELECT
    p.product_category_name,
    COUNT(DISTINCT o.order_id)                                              AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)                              AS gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `04_customers`   c  ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id    = oi.order_id
JOIN `05_products`    p  ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'SP'
GROUP BY p.product_category_name
ORDER BY gmv DESC
LIMIT 15;

-- Result: both states share nearly identical top 15 categories,
--         differing only slightly in rank
--         (SP top 3: cama_mesa_banho / beleza_saude / relogios_presentes
--          RJ top 3: relogios_presentes / cama_mesa_banho / beleza_saude)
--
-- → Hypothesis REJECTED: category mix does not explain the AOV gap
-- → But note: within every shared category, SP's AOV is lower than RJ's
--    without exception. e.g. beleza_saude: RJ 169.33 vs SP 137.35


-- 2b. Split the gap: is it product price, or freight?

SELECT
    c.customer_state,
    ROUND(AVG(oi.price), 2)         AS avg_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight
FROM `01_order` o
JOIN `04_customers`   c  ON o.customer_id = c.customer_id
JOIN `02_order_items` oi ON o.order_id    = oi.order_id
WHERE o.order_status = 'delivered'
  AND c.customer_state IN ('SP', 'RJ')
GROUP BY c.customer_state;

-- Results:
--   SP  avg product price 109.10 | avg freight 15.12
--   RJ  avg product price 124.42 | avg freight 20.91
--
-- Findings:
--   - Total gap ~R$21: product price contributes 15.32 (73%),
--     freight contributes 5.79 (27%)
--   - SP freight is 28% cheaper than RJ — consistent with most
--     sellers being based in SP (local delivery costs less)
--   - The dominant driver is the product price itself, likely due
--     to dense seller competition in SP
--
-- Conclusion: SP's lower AOV does not indicate weaker purchasing
--             power — it reflects a mature market with abundant supply.
--
-- → Follow-up: how large is freight as a share of order value
--   nationally? Are remote states suppressed by shipping cost? (see Q5)


-- ============================================================
-- Q3 — Which categories contribute the most GMV?  [TODO]
-- ============================================================


-- ============================================================
-- Q4 — What is the monthly GMV trend?
-- ============================================================

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')                        AS month,
    ROUND(SUM(oi.price + oi.freight_value), 2)                              AS gmv,
    COUNT(DISTINCT o.order_id)                                              AS orders
FROM `01_order` o
JOIN `02_order_items` oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- Findings:
--   - Data spans 2016-09 to 2018-08. The first four months are
--     near-zero and 2016-11 is missing entirely -> excluded when
--     reading the trend
--   - 2017: steady climb, roughly 150k in January to ~1M in December (~7x)
--   - 2018 Jan-Aug: flat at 1.0-1.2M per month -- growth stalled
--   - The final month dips slightly, most likely data truncation
--     rather than a real decline
--
-- Key point: the story is not "the platform is growing" -- it is that
--            the growth engine stopped in early 2018.


-- ============================================================
-- Q5 — Late delivery rate and severity
-- Late is defined as:
--   order_delivered_customer_date > order_estimated_delivery_date
-- ============================================================

-- 5a. National baseline

SELECT
    COUNT(*)                                                                AS delivered_orders,
    SUM(order_delivered_customer_date > order_estimated_delivery_date)      AS late_orders,
    ROUND(AVG(order_delivered_customer_date > order_estimated_delivery_date) * 100, 2)
                                                                            AS late_rate_pct,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 1)
                                                                            AS avg_days_vs_promise
FROM `01_order`
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- Note: a boolean expression returns 1 or 0 in MySQL, so SUM() gives
--       the count of late orders and AVG() gives the rate directly.
--
-- Results:
--   delivered_orders     96,470
--   late_orders           7,826
--   late_rate_pct          8.11
--   avg_days_vs_promise   -11.9   (i.e. 11.9 days EARLY on average)


-- 5b. How late are the late ones?

SELECT
    CASE
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 7  THEN '1-7 days late'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 30 THEN '8-30 days late'
        ELSE '30+ days late'
    END                                                                     AS delay_bucket,
    COUNT(*)                                                                AS orders
FROM `01_order`
WHERE order_status = 'delivered'
  AND order_delivered_customer_date > order_estimated_delivery_date
GROUP BY delay_bucket;

-- Results:
--   1-7 days late    4,964  (63%)
--   8-30 days late   2,517  (32%)
--   30+ days late      345  ( 4%)
--
-- Findings:
--   - Orders arrive 11.9 days ahead of the promised date on average,
--     which means Olist sets deliberately conservative estimates
--   - Even against that generous window, 8.11% still miss it
--   - Most delays are minor (63% within a week), but 2,862 orders are
--     more than a week late and 345 exceed a month -- the latter are
--     effectively failed orders, not normal variance
--
-- Key point: the headline 8% understates the issue. Given how generous
--            the promise window is, the tail end represents genuine
--            fulfilment breakdowns.
--
-- Follow-up (not yet run): which states are worst? Join 04_customers
-- and GROUP BY customer_state, with HAVING COUNT(*) >= 500 to drop
-- states with too few orders to be meaningful.


-- ============================================================
-- Q6 — Does delivery delay affect review scores?  [TODO]
-- Suggested approach: reuse the delay buckets from Q5, join
-- 07_order_reviews, and compare AVG(review_score) per bucket.
-- This would show whether the delays found in Q5 actually matter.
-- ============================================================
