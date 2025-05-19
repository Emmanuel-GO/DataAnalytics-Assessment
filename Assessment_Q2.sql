-- =============================================
-- Query: Categorize Customers by Average Monthly Transaction Frequency
-- Purpose: Group customers based on how frequently they transact per month
--          and calculate average transaction frequency per category
-- =============================================

-- CTE: monthly_transactions
-- Step 1: Count the number of transactions per customer for each month
WITH monthly_transactions AS (
    SELECT 
        owner_id,
        DATE_FORMAT(transaction_date, '%Y-%m-01') AS txn_month, -- Normalize to first day of the month
        COUNT(*) AS txn_count                                   -- Number of transactions in that month
    FROM 
        savings_savingsaccount
    GROUP BY 
        owner_id, DATE_FORMAT(transaction_date, '%Y-%m-01')
),

-- CTE: customer_avg_txn
-- Step 2: Calculate the average monthly transaction count for each customer
customer_avg_txn AS (
    SELECT 
        owner_id,
        AVG(txn_count) AS avg_transactions_per_month -- Average across all months with transactions
    FROM 
        monthly_transactions
    GROUP BY 
        owner_id
),

-- CTE: categorized
-- Step 3: Group customers into frequency categories and summarize them
categorized AS (
    SELECT 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'      -- Active transactors
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency' -- Moderately active
            ELSE 'Low Frequency'                                             -- Infrequent transactors
        END AS frequency_category,
        
        COUNT(*) AS customer_count, -- Number of customers in each category

        ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month -- Average across customers in the category
    FROM 
        customer_avg_txn
    GROUP BY 
        frequency_category
)

-- Final output: Frequency category summary
SELECT 
    * 
FROM 
    categorized;

