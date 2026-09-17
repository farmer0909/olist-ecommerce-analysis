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
-- Q3 — Which categories contribute the most GMV?
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(DISTINCT o.order_id)                                              AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)                              AS gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM `01_order` o
JOIN `02_order_items` oi ON o.order_id    = oi.order_id
JOIN `05_products`    p  ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY gmv DESC
LIMIT 20;

-- Results (top 5):
--   beleza_saude            8,647 orders | GMV 1,412,090 | AOV 163.30
--   relogios_presentes      5,495 orders | GMV 1,264,333 | AOV 230.09
--   cama_mesa_banho         9,272 orders | GMV 1,225,209 | AOV 132.14
--   esporte_lazer           7,530 orders | GMV 1,118,257 | AOV 148.51
--   informatica_acessorios  6,530 orders | GMV 1,032,724 | AOV 158.15
--
-- Findings:
--   - Category GMV is evenly spread: #1 to #5 differ by less than 40%
--   - This contrasts sharply with the geographic picture (SP alone = 37%)
--     -> concentration risk sits in geography, not in product mix
--   - Two distinct category profiles emerge:
--       relogios_presentes  fewest orders but 2nd highest GMV, AOV 230
--                           -> high-value, low-frequency
--       cama_mesa_banho     most orders but only 3rd in GMV, AOV 132
--                           -> high-volume, low-margin
--     The two require different operational strategies: the first depends
--     on conversion and basket value, the second on traffic and repeat purchase.



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
-- Q5b — Late delivery by state
-- HAVING filters out states with too few orders to be meaningful
-- ============================================================

SELECT
    c.customer_state,
    COUNT(*)                                                                AS delivered_orders,
    ROUND(AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100, 2)
                                                                            AS late_rate_pct,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1)
                                                                            AS avg_delivery_days
FROM `01_order` o
JOIN `04_customers` c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING delivered_orders >= 500
ORDER BY late_rate_pct DESC;

-- Results (worst 6):
--   MA     717 orders | 19.67% late
--   CE   1,279 orders | 15.32%
--   BA   3,256 orders | 14.04%
--   RJ  12,350 orders | 13.47%   <-- outlier
--   PA     946 orders | 12.37%
--   ES   1,995 orders | 12.23%
--
-- (National average: 8.11%)
--
-- Findings:
--   - Most poor performers are remote northern/northeastern states,
--     which is expected given the seller base is concentrated in SP
--   - RJ is the outlier: Brazil's 2nd largest market, 400km from SP,
--     with the highest AOV in the country (166) -- yet its late rate
--     is 1.7x the national average, close to remote-state levels
--   - Volume matters: RJ carries 12,350 orders against MA's 717, so RJ
--     alone produces more late deliveries than the other high-rate
--     states combined
--
-- Key point: RJ's delay is not distance-driven and may therefore be
--            fixable. The platform's most valuable customers are
--            receiving second-tier fulfilment. Worth investigating
--            carrier performance and last-mile coverage in RJ.


-- ============================================================
-- Q6 — Does delivery delay affect review scores?
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On time'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 7  THEN '1-7 days late'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 30 THEN '8-30 days late'
        ELSE '30+ days late'
    END                                                                     AS delay_bucket,
    COUNT(*)                                                                AS orders,
    ROUND(AVG(r.review_score), 2)                                           AS avg_score,
    ROUND(AVG(r.review_score = 1) * 100, 2)                                 AS one_star_pct
FROM `01_order` o
JOIN `07_order_reviews` r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delay_bucket
ORDER BY avg_score DESC;

-- Results:
--   On time        88,653 | avg 4.29 | 1-star  6.60%
--   1-7 days late   4,903 | avg 3.06 | 1-star 32.74%
--   30+ days late     331 | avg 2.05 | 1-star 63.14%
--   8-30 days late  2,466 | avg 1.65 | 1-star 70.56%
--
-- Findings:
--   - The penalty for lateness is a cliff, not a slope. A single day
--     late takes the 1-star rate from 6.6% to 32.7% -- a 5x jump
--   - This revises the Q5 reading: the 63% of delays falling under a
--     week are NOT harmless variance. Customers do not grade on a curve
--   - Measured by customers affected, minor delays do far more damage
--     than extreme ones: the 1-7 day bucket holds 4,903 orders against
--     331 in the 30+ bucket (15x)
--   - Anomaly: 30+ days late scores HIGHER (2.05) than 8-30 days (1.65).
--     Possible explanations include refund or resolution processes for
--     very late orders, or pre-order items where slow delivery was
--     expected. Not resolved -- flagged rather than explained away.
--
-- Key point: delivery reliability, not delivery speed, drives
--            satisfaction. Olist already beats its promised date by
--            11.9 days on average; it is the 8% that miss which cost
--            the platform its ratings.
