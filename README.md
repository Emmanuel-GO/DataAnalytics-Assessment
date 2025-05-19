# DataAnalytics-Assessment
#  SQL Proficiency Assessment Report

**Candidate:** Adewale Emmanuel  
**Role Target:** Data Analyst  
**Focus Areas:** SQL Querying, Business Problem Solving, Data Aggregation, Joins, and Reporting

---

##  Introduction

This SQL Proficiency Assessment was conducted to evaluate my ability to work with relational databases by writing accurate, efficient, and business-driven SQL queries. The assessment provided a dataset consisting of four interrelated tables:

- **`users_customuser`**: Contains customer demographic and profile information.  
- **`savings_savingsaccount`**: Records of deposit transactions into savings accounts.  
- **`plans_plan`**: Details of various savings and investment plans.  
- **`withdrawals_withdrawal`**: Records of customer withdrawal transactions.

The challenge required the application of key SQL concepts such as filtering, joining, aggregation, conditional logic, and date manipulation to solve real-world business scenarios. The aim was not just to demonstrate technical skill but to apply critical thinking to derive insights that would inform marketing, finance, operations, and product strategy.

---

##  Objectives

The assessment was divided into four core business objectives that reflect everyday analytics needs in a data-driven organization:

### 1. Identify High-Value Customers with Multiple Financial Products  
To detect cross-selling opportunities by finding customers who have at least one funded savings plan **and** one funded investment plan. These customers were ranked by their total confirmed deposits.

### 2. Analyze Transaction Frequency and Segment Users  
To help the finance team segment users based on how frequently they transact. This involved calculating the average number of transactions per customer per month and assigning them into frequency categories: **High**, **Medium**, or **Low**.

### 3. Detect Inactive Accounts for Operational Follow-Up  
To identify accounts with no deposit activity in the past **365 days** despite having at least one funded plan. This enables the operations team to trigger reactivation campaigns or account closure considerations.

### 4. Estimate Customer Lifetime Value (CLV)  
To assist the marketing team in estimating CLV by calculating each customer's account tenure, total transaction volume, and profit-based projection using a simplified model. Customers were ranked by their estimated CLV to inform retention and up-selling strategies.

---


## Approach Breakdown for Identifying High-Value Customers with Multiple Financial Products

## Objective

Identify high-value customers who:

- Have at least one funded savings plan.
- Have at least one funded investment plan.
- Are ranked by their total confirmed deposits (descending order).

### Step 1: CTE - `savings`
Get users with **funded savings plans**.

```sql
WITH savings AS (
    SELECT 
        owner_id, 
        COUNT(*) AS savings_count
    FROM 
        plans_plan
    WHERE 
        is_regular_savings = 1
        AND amount > 0
    GROUP BY 
        owner_id
),
```
- Filters for only regular savings plans that are funded (amount > 0).

- Groups by owner_id to get the count of such plans per user.



### Step 2: CTE - `Investments`
```
investments AS (
    SELECT 
        owner_id, 
        COUNT(*) AS investment_count
    FROM 
        plans_plan
    WHERE 
        is_a_fund = 1
        AND amount > 0
    GROUP BY 
        owner_id
),
```
- Filters for only investment plans that are funded.

- Again, groups by owner_id to get investment plan counts per user.

### Step 3: CTE - `Deposits`
```
deposits AS (
    SELECT 
        owner_id, 
        ROUND(SUM(confirmed_amount) / 100.0, 2) AS total_deposits
    FROM 
        savings_savingsaccount
    GROUP BY 
        owner_id
)
```
- Aggregates the total confirmed_amount per user.

- Amount is divided by 100 assuming the original value is in kobo (common in Nigerian systems), converting it to Naira.

- ROUND(..., 2) ensures monetary values are two decimal places.

### Final Query

```
SELECT 
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    COALESCE(s.savings_count, 0) AS number_of_savings_plans,
    COALESCE(i.investment_count, 0) AS number_of_investment_plans,
    COALESCE(d.total_deposits, 0.0) AS total_deposits_in_currency
FROM 
    users_customuser u
LEFT JOIN savings s ON u.id = s.owner_id
LEFT JOIN investments i ON u.id = i.owner_id
LEFT JOIN deposits d ON u.id = d.owner_id
WHERE 
    COALESCE(s.savings_count, 0) > 0 AND
    COALESCE(i.investment_count, 0) > 0
ORDER BY 
    total_deposits_in_currency DESC;
```

- Joins users with their respective savings, investments, and deposit values.
- Filters to only include users who have:
  - At least one funded savings plan (`savings_count > 0`)
  - At least one funded investment plan (`investment_count > 0`)
- Uses `COALESCE` to handle users who may not exist in all joined CTEs (null-safe).
- Sorts by total deposits in descending order, highlighting high-value customers first.

## Challenges & How They Were Resolved

During this SQL assessment, I encountered a few challenges while working through the requirements. Here’s how I approached and resolved each:

| Challenge                                   | Resolution                                                                                                                        |
|---------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| Differentiating between plan types (savings vs investments) | I needed to clearly separate savings plans from investment plans. To do this, I leveraged the flags available in the `plans_plan` table: `is_regular_savings = 1` for savings and `is_a_fund = 1` for investments. This ensured accurate categorization of plans in my query. |
| Avoiding null values when joining            | Since not all users have plans or deposit records, joining these tables directly could produce nulls or exclude users incorrectly. To handle this, I used `LEFT JOIN` combined with `COALESCE`. This approach allowed me to safely handle missing data by substituting nulls with zero or default values, while still filtering out irrelevant users logically later in the query. |
| Currency formatting                         | I realized that deposit amounts were stored in the smallest currency unit (kobo). To present the deposit totals in a readable currency format (Naira), I divided the sum by `100.0` and rounded it to 2 decimal places. This gave me clean and accurate financial figures for reporting. |
| Accurate customer identification           | To ensure the report focused only on real customers with complete demographic info, I used the `users_customuser` table as the base for all joins. This also enabled me to easily retrieve customer names by concatenating `first_name` and `last_name`, providing clear, personalized output. |

---

By addressing these challenges thoughtfully, I was able to build a robust query that correctly identifies high-value customers with multiple products, while maintaining data integrity and readability.


## Conclusion
This query accurately identifies and ranks customers who actively engage in savings and investment plans, making it ideal for cross-selling opportunities or VIP customer targeting. Modular CTEs enhance clarity, ease of maintenance, and scalability, allowing for straightforward future enhancements such as filtering by date, region, or product type.


## Approach Breakdown for for Customer Frequency Categorization

### Objective
Categorize customers into frequency tiers (High, Medium, Low) based on their average monthly transaction count using data from the savings_savingsaccount table. Return the count of customers in each category and their average transaction frequency.

### Step 1: CTE - monthly_transactions
```
WITH monthly_transactions AS (
    SELECT 
        owner_id,
        DATE_FORMAT(transaction_date, '%Y-%m-01') AS txn_month,
        COUNT(*) AS txn_count
    FROM savings_savingsaccount
    GROUP BY owner_id, DATE_FORMAT(transaction_date, '%Y-%m-01')
),
```
- Extracts transaction counts for each user per month.

- DATE_FORMAT(transaction_date, '%Y-%m-01') normalizes dates to the first of the month for grouping (e.g., 2025-05-01).

- GROUP BY ensures transactions are aggregated by user and month.

### Output 

| owner\_id | txn\_month | txn\_count |
| --------- | ---------- | ---------- |
| 101       | 2025-01-01 | 7          |
| 101       | 2025-02-01 | 5          |
| 102       | 2025-01-01 | 12         |
| ...       | ...        | ...        |



































