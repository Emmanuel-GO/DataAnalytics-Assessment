-- ================================================================
-- Query: Identify Inactive Savings/Investment Plans
-- Purpose: Find users with savings or investment plans who have 
--          not performed any savings transaction in over a year
-- ================================================================

-- CTE: last_savings_txn
-- Step 1: Get the most recent transaction date per user
WITH last_savings_txn AS (
    SELECT 
        owner_id,
        MAX(transaction_date) AS last_transaction_date -- Latest savings activity
    FROM 
        savings_savingsaccount
    GROUP BY 
        owner_id
),

-- CTE: active_plans
-- Step 2: Select only active plans (Savings or Investment) and tag them by type
active_plans AS (
    SELECT 
        id AS plan_id,
        owner_id,
        CASE 
            WHEN is_regular_savings = 1 THEN 'Savings'        -- Tag as Savings
            WHEN is_a_fund = 1 THEN 'Investment'              -- Tag as Investment
            ELSE 'Other'                                      -- Should not appear, but added as fallback
        END AS type
    FROM 
        plans_plan
    WHERE 
        is_regular_savings = 1 OR is_a_fund = 1              -- Only consider valid active plans
),

-- CTE: plan_with_last_txn
-- Step 3: Join each plan with the last transaction date of its owner
--         and calculate number of days since last activity
plan_with_last_txn AS (
    SELECT 
        ap.plan_id,
        ap.owner_id,
        ap.type,
        lst.last_transaction_date,
        DATEDIFF(CURRENT_DATE, lst.last_transaction_date) AS inactivity_days -- Days since last txn
    FROM 
        active_plans ap
    LEFT JOIN 
        last_savings_txn lst ON ap.owner_id = lst.owner_id
)

-- Final Selection: Filter only plans with more than 365 days of inactivity
SELECT 
    * 
FROM 
    plan_with_last_txn
WHERE 
    inactivity_days > 365; -- Inactive for over 1 year

