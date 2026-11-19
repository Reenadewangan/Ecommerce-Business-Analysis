/*
E-COMMERCE BUSINESS ANALYSIS — OLIST DATASET
Database: SQLite
Tables expected:
  customers, orders, order_items, products, payments, reviews

Run each query separately in your SQLite environment / Google Colab.
If using the notebook helper, pass each query string to run_query(query).

Notes:
- Monetary values are in Brazilian Real (BRL), not INR.
- Revenue definitions differ by analysis: payment_value is customer payment;
  order_items.price is item-price revenue excluding freight.
- The customer segments use illustrative thresholds: >1000, >=250, and <250 BRL.
*/

-- ============================================================
-- 1. MONTHLY REVENUE
-- Payment revenue for delivered orders, grouped by month.
-- ============================================================
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY month;


-- ============================================================
-- 2. TOP 10 PRODUCT CATEGORIES BY ITEM SALES
-- Uses item price (excludes freight).
-- ============================================================
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(p.product_category_name, 'Unknown')
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- 3. TOP 10 CUSTOMERS BY SPENDING
-- Uses customer_unique_id to identify customers across orders.
-- ============================================================
SELECT
    c.customer_unique_id,
    ROUND(SUM(p.payment_value), 2) AS total_spending,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spending DESC
LIMIT 10;


-- ============================================================
-- 4. REPEAT PURCHASE RATE
-- Counts delivered orders per unique customer.
-- ============================================================
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_purchase_rate
FROM customer_orders;


-- ============================================================
-- 5. AVERAGE ORDER VALUE (AOV)
-- Average total payment per distinct order.
-- This version includes all orders represented in payments.
-- ============================================================
SELECT
    ROUND(
        SUM(payment_value) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM payments;


-- ============================================================
-- 6. MONTH-OVER-MONTH REVENUE GROWTH
-- Creates a continuous calendar-month series, filling missing
-- months with zero. Growth is NULL if previous month revenue is 0.
-- ============================================================
WITH RECURSIVE months(month) AS (
    SELECT date(MIN(order_purchase_timestamp), 'start of month')
    FROM orders

    UNION ALL

    SELECT date(month, '+1 month')
    FROM months
    WHERE month < (
        SELECT date(MAX(order_purchase_timestamp), 'start of month')
        FROM orders
    )
),
monthly_revenue AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
),
complete_revenue AS (
    SELECT
        strftime('%Y-%m', m.month) AS month,
        COALESCE(r.revenue, 0) AS revenue
    FROM months m
    LEFT JOIN monthly_revenue r
        ON strftime('%Y-%m', m.month) = r.month
),
growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM complete_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    CASE
        WHEN previous_revenue > 0 THEN
            ROUND(
                (revenue - previous_revenue) * 100.0 / previous_revenue,
                2
            )
        ELSE NULL
    END AS growth_percentage
FROM growth
ORDER BY month;


-- ============================================================
-- 7. DELIVERY PERFORMANCE
-- Compares actual delivery date with estimated delivery date.
-- Average delivery days is measured from purchase to delivery.
-- ============================================================
SELECT
    COUNT(*) AS total_delivered_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS on_time_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_percentage,
    ROUND(
        AVG(
            julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)
        ),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- 8. TOP 10 PRODUCTS BY ITEM REVENUE
-- Product category is taken directly from products table.
-- ============================================================
WITH product_sales AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price) AS total_revenue
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id
),
ranked_products AS (
    SELECT
        product_id,
        total_orders,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS product_rank
    FROM product_sales
)
SELECT
    rp.product_id,
    COALESCE(p.product_category_name, 'Unknown') AS category,
    rp.total_orders,
    ROUND(rp.total_revenue, 2) AS total_revenue,
    rp.product_rank
FROM ranked_products rp
LEFT JOIN products p
    ON rp.product_id = p.product_id
WHERE rp.product_rank <= 10
ORDER BY rp.product_rank;


-- ============================================================
-- 9. CUSTOMER SEGMENTATION
-- Spending is based on delivered orders and payment values.
-- ============================================================
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spending,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
segmented_customers AS (
    SELECT
        customer_unique_id,
        total_spending,
        total_orders,
        CASE
            WHEN total_spending > 1000 THEN 'High Value'
            WHEN total_spending >= 250 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_spending
)
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(total_spending), 2) AS average_spending,
    ROUND(AVG(total_orders), 2) AS average_orders
FROM segmented_customers
GROUP BY customer_segment
ORDER BY average_spending DESC;


-- ============================================================
-- 10. REVENUE CONTRIBUTION BY CUSTOMER SEGMENT
-- ============================================================
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
segmented AS (
    SELECT
        total_spending,
        CASE
            WHEN total_spending > 1000 THEN 'High Value'
            WHEN total_spending >= 250 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS segment
    FROM customer_spending
)
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_spending), 2) AS total_revenue,
    ROUND(
        100.0 * SUM(total_spending)
        / (SELECT SUM(total_spending) FROM segmented),
        2
    ) AS revenue_contribution_percentage
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;
