-- ============================================================
-- 01 — Data Exploration
-- Purpose: confirm the size, structure, grain and quality of the
--          data before starting any analysis
-- ============================================================

USE olist_ecommerce;


-- ------------------------------------------------------------
-- 1. Schema: every column in every table
--    Sorting by column name reveals which columns appear in
--    multiple tables — those are the join keys
-- ------------------------------------------------------------
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'olist_ecommerce'
ORDER BY column_name, table_name;


-- ------------------------------------------------------------
-- 2. Row counts: verify the import is complete and infer
--    the grain relationship between tables
-- ------------------------------------------------------------
SELECT '01_order'                AS table_name, COUNT(*) AS n FROM `01_order`
UNION ALL SELECT '02_order_items',          COUNT(*) FROM `02_order_items`
UNION ALL SELECT '03_order_payments',       COUNT(*) FROM `03_order_payments`
UNION ALL SELECT '04_customers',            COUNT(*) FROM `04_customers`
UNION ALL SELECT '05_products',             COUNT(*) FROM `05_products`
UNION ALL SELECT '06_sellers',              COUNT(*) FROM `06_sellers`
UNION ALL SELECT '07_order_reviews',        COUNT(*) FROM `07_order_reviews`
UNION ALL SELECT '08_geolocation',          COUNT(*) FROM `08_geolocation`
UNION ALL SELECT '09_category',             COUNT(*) FROM `09_category`;


-- ------------------------------------------------------------
-- 3. Grain check: is order → order_items one-to-one or one-to-many?
--    If item_rows > item_orders, a single order contains multiple items
--    → all order counts must use COUNT(DISTINCT order_id)
-- ------------------------------------------------------------
SELECT
    (SELECT COUNT(DISTINCT order_id) FROM `01_order`)       AS orders,
    (SELECT COUNT(*)                 FROM `02_order_items`) AS item_rows,
    (SELECT COUNT(DISTINCT order_id) FROM `02_order_items`) AS item_orders;


-- ------------------------------------------------------------
-- 4. Fix data types
--    Every column imports from CSV as text. Date columns must be
--    converted to DATETIME, otherwise DATEDIFF() and monthly
--    grouping will not work correctly.
-- ------------------------------------------------------------
ALTER TABLE `01_order`
    MODIFY order_purchase_timestamp      DATETIME,
    MODIFY order_approved_at             DATETIME,
    MODIFY order_delivered_carrier_date  DATETIME,
    MODIFY order_delivered_customer_date DATETIME,
    MODIFY order_estimated_delivery_date DATETIME;

-- If this fails with "Incorrect datetime value: ''", convert empty
-- strings to NULL first:
-- UPDATE `01_order` SET order_delivered_customer_date = NULL
-- WHERE order_delivered_customer_date = '';


-- ------------------------------------------------------------
-- 5. Order status distribution — determines the analysis filter
-- ------------------------------------------------------------
SELECT order_status, COUNT(*) AS n
FROM `01_order`
GROUP BY order_status
ORDER BY n DESC;


-- ------------------------------------------------------------
-- 6. Time span — determines the range for trend analysis
--    Watch out: the final month may be incomplete, which would
--    show up as a false decline in a trend chart
-- ------------------------------------------------------------
SELECT
    MIN(order_purchase_timestamp) AS earliest,
    MAX(order_purchase_timestamp) AS latest
FROM `01_order`;


-- ------------------------------------------------------------
-- 7. Missing values — orders without a delivery date must be
--    excluded from any delivery-time analysis
-- ------------------------------------------------------------
SELECT COUNT(*) AS missing_delivery_date
FROM `01_order`
WHERE order_delivered_customer_date IS NULL
   OR order_delivered_customer_date = '';


-- ------------------------------------------------------------
-- 8. Numeric ranges — check for outliers
--    Compare max against avg: a large gap means extreme values
--    are pulling the mean and a median may be more appropriate
-- ------------------------------------------------------------
SELECT
    MIN(price)         AS min_price,
    MAX(price)         AS max_price,
    AVG(price)         AS avg_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight
FROM `02_order_items`;
