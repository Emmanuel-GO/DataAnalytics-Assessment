-- =============================================================================
-- Query: Estimate Customer Lifetime Value (CLV) Based on Transaction Behavior
-- Purpose: Estimate CLV using transaction frequency and tenure in months
-- Formula: (Total Transactions ÷ Tenure Months) × 12 months × 0.001 conversion rate
-- =============================================================================

-- CTE: customer_txn_summary
-- Step 1: Aggregate transaction count and value per customer
WITH customer_txn_summary AS (
    SELECT 
        sa.owner_id,
        COUNT(*) AS total_transactions,               -- Total number of confirmed transactions
        SUM(confirmed_amount) AS total_transaction_value -- Total confirmed amount (raw)
    FROM 
        savings_savingsaccount sa
    GROUP BY 
        sa.owner_id
),

-- CTE: tenure_calc
-- Step 2: Calculate the customer's tenure in months from their first transaction to today
tenure_calc AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name, -- Customer full name
        TIMESTAMPDIFF(MONTH, MIN(sa.transaction_date), CURRENT_DATE) AS tenure_months -- Tenure in months
    FROM 
        users_customuser u
    JOIN 
        savings_savingsaccount sa ON u.id = sa.owner_id
    GROUP BY 
        u.id, u.first_name, u.last_name
),

-- CTE: combined
-- Step 3: Combine transaction summary and tenure, calculate estimated CLV
combined AS (
    SELECT 
        t.customer_id,
        t.name,
        t.tenure_months,
        cts.total_transactions,
        
        -- Estimated CLV formula:
        -- (Monthly transaction rate) × 12 months × multiplier (e.g. 0.001 as a placeholder)
        ROUND(((cts.total_transactions * 1.0 / NULLIF(t.tenure_months, 0)) * 12 * 0.001), 2) AS estimated_clv
    FROM 
        tenure_calc t
    JOIN 
        customer_txn_summary cts ON t.customer_id = cts.owner_id
)

-- Final Output: List of customers sorted by their estimated CLV in descending order
SELECT * 
FROM combined
ORDER BY estimated_clv DESC;

