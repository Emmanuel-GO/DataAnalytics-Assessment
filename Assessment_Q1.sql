-- =============================================
-- Query: High-Value Customers with Both Savings and Investment Plans
-- Purpose: Identify customers who have at least one funded savings plan
--          AND one funded investment plan, and sort them by their 
--          total confirmed deposits in descending order
-- =============================================

-- CTE: savings
-- Gets the count of funded savings plans per user
WITH savings AS (
    SELECT 
        owner_id, 
        COUNT(*) AS savings_count
    FROM 
        plans_plan
    WHERE 
        is_regular_savings = 1       -- Only include regular savings plans
        AND amount > 0               -- Must be funded (amount > 0)
    GROUP BY 
        owner_id
),

-- CTE: investments
-- Gets the count of funded investment plans per user
investments AS (
    SELECT 
        owner_id, 
        COUNT(*) AS investment_count
    FROM 
        plans_plan
    WHERE 
        is_a_fund = 1                -- Only include investment plans
        AND amount > 0              -- Must be funded (amount > 0)
    GROUP BY 
        owner_id
),

-- CTE: deposits
-- Calculates total confirmed deposit amounts per user
deposits AS (
    SELECT 
        owner_id, 
        ROUND(SUM(confirmed_amount) / 100.0, 2) AS total_deposits -- Convert from kobo to Naira (or appropriate currency)
    FROM 
        savings_savingsaccount
    GROUP BY 
        owner_id
)

-- Final Selection: Join users with their respective savings, investments, and deposit data
SELECT 
    u.id AS customer_id,                                       -- Unique user ID
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,       -- Full name of the user
    COALESCE(s.savings_count, 0) AS number_of_savings_plans,   -- Number of funded savings plans
    COALESCE(i.investment_count, 0) AS number_of_investment_plans, -- Number of funded investment plans
    COALESCE(d.total_deposits, 0.0) AS total_deposits_in_currency -- Total confirmed deposits
FROM 
    users_customuser u
LEFT JOIN 
    savings s ON u.id = s.owner_id
LEFT JOIN 
    investments i ON u.id = i.owner_id
LEFT JOIN 
    deposits d ON u.id = d.owner_id
WHERE 
    COALESCE(s.savings_count, 0) > 0 AND      -- Must have at least 1 savings plan
    COALESCE(i.investment_count, 0) > 0       -- Must have at least 1 investment plan
ORDER BY 
    total_deposits_in_currency DESC;          -- Sort by highest deposit amount
