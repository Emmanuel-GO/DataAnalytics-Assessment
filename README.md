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

### Step 2: CTE - customer_avg_txn

```
customer_avg_txn AS (
    SELECT 
        owner_id,
        AVG(txn_count) AS avg_transactions_per_month
    FROM monthly_transactions
    GROUP BY owner_id
),
```

- Calculates the average monthly transaction count per user.

- Uses the monthly data from the first CTE to compute per-user activity level.

### Step 3: CTE - categorized

```
categorized AS (
    SELECT 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        COUNT(*) AS customer_count,
        ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
    FROM customer_avg_txn
    GROUP BY frequency_category
)

```
- Buckets customers based on their average monthly transactions:

    - High Frequency: ≥ 10 transactions/month

    - Medium Frequency: 3–9 transactions/month

   - Low Frequency: < 3 transactions/month

*Aggregates:*

- Total number of customers in each bucket

- Average transaction count per category (rounded to 1 decimal place)


### Final Query Output

```
SELECT * FROM categorized;
```


##  Challenges & 🛠️ Resolutions

While working on segmenting customers by their transaction frequency, I ran into a few common data processing challenges. Here's a breakdown of what came up and how I tackled each one:

### Challenge: Normalizing transaction dates by month  
**Resolution:**  
I needed to analyze transactions on a monthly basis, but the raw data had full date stamps. To standardize this, I used:
```sql
DATE_FORMAT(transaction_date, '%Y-%m-01')
```
This transformed every transaction date into the first day of its respective month, making it easier to group and analyze transactions consistently.

### Challenge: Determining transaction frequency per user
**Resolution:**
To figure out how often each user transacts, I created a CTE (Common Table Expression) that counted the number of transactions per user per month. Then I used AVG() over these monthly counts to compute each user's average monthly transaction frequency.

## Conclusion 
This approach gave me a clear and practical way to group customers by how often they transact. By looking at their monthly activity and averaging it out, I could easily sort them into High, Medium, or Low Frequency tiers. It’s a helpful way to spot active users, identify those dropping off, and plan smarter engagement—like who to reward or re-engage. Using CTEs made the logic clean and easy to follow, which will be handy as the data grows.



# Approach Breakdown for Identifying Inactive Savings/Investment Plans

## Objective

Identify users who have either a **savings** or **investment** plan but have not performed **any savings transaction in the past year**.

---

### Step 1: CTE - `last_savings_txn`

**Purpose:** Determine the **most recent transaction date** for each user based on their savings activity.

```sql
WITH last_savings_txn AS (
    SELECT 
        owner_id,
        MAX(transaction_date) AS last_transaction_date
    FROM 
        savings_savingsaccount
    GROUP BY 
        owner_id
),
```

- ` MAX(transaction_date)` gives the latest known savings activity per user.

- This data helps us determine how long it's been since each user last engaged.

### Step 2: CTE - `active_plans`
Purpose: Retrieve all active plans that are either regular savings or investment products and tag them by type.

```
active_plans AS (
    SELECT 
        id AS plan_id,
        owner_id,
        CASE 
            WHEN is_regular_savings = 1 THEN 'Savings'
            WHEN is_a_fund = 1 THEN 'Investment'
            ELSE 'Other'
        END AS type
    FROM 
        plans_plan
    WHERE 
        is_regular_savings = 1 OR is_a_fund = 1
),

```

- Filters for plans where:

  - is_regular_savings = 1 (Savings plans)

  -  is_a_fund = 1 (Investment plans)

- Labels them for clarity using a CASE statement.

- The fallback "Other" shouldn't appear but is included for robustness.

### Step 3: CTE - `plan_with_last_txn`
Purpose: Combine each active plan with the owner’s last known savings activity, and compute inactivity in days.

```
plan_with_last_txn AS (
    SELECT 
        ap.plan_id,
        ap.owner_id,
        ap.type,
        lst.last_transaction_date,
        DATEDIFF(CURRENT_DATE, lst.last_transaction_date) AS inactivity_days
    FROM 
        active_plans ap
    LEFT JOIN 
        last_savings_txn lst ON ap.owner_id = lst.owner_id
)

```
- `LEFT JOIN` ensures that users with plans but no savings transactions at all still show up.

- `DATEDIFF(CURRENT_DATE, lst.last_transaction_date)` calculates how long since the last transaction.

- This prepares the data for filtering inactive users.

### Final Output: Inactive Plans Filter

```
SELECT 
    * 
FROM 
    plan_with_last_txn
WHERE 
    inactivity_days > 365;

```

- Filters to show only those plans with more than 365 days of inactivity.

- Returns:

- Plan ID

 - Owner ID

 - Plan type (Savings or Investment)

 - Last activity date

 - Number of days since last activity



## Challenges & Resolutions

| Challenge                  | Resolution                                                                                      |
|----------------------------|-------------------------------------------------------------------------------------------------|
| Identifying plan type      | Used `CASE` to clearly tag plans as `"Savings"` or `"Investment"` based on binary flags in `plans_plan`. |
| Missing transaction records| Used a `LEFT JOIN` so users with plans but no recorded transactions still appear with `NULL` values.  |
| Inactivity calculation     | Used `DATEDIFF(CURRENT_DATE, last_transaction_date)` to compute days since last interaction.   |
| Filtering long-term inactivity | Applied a `WHERE inactivity_days > 365` to target plans idle for over a year.                   |
| Edge case handling         | Included a fallback in the `CASE` statement (`ELSE 'Other'`) to catch unexpected data without breaking the pipeline. |


## Conclusion

This query provides a clear, actionable view into dormant customer plans, enabling:

- Re-engagement campaigns targeting inactive users.
- Early detection of plan abandonment trends.
- Personalized outreach based on plan type and inactivity duration.

With a modular design and defensive handling of edge cases, it's easy to extend this query for:

- Shorter or dynamic inactivity thresholds.
- Plan performance summaries.
- Integration with CRM alerts or automated workflows.


# Approach Breakdown for Estimating Customer Lifetime Value (CLV) Based on Transaction Behavior

##  Objective

Estimate each customer’s **Customer Lifetime Value (CLV)** using:

- Their total confirmed transactions.
- Their tenure (in months) since first transaction.
- A standard CLV formula:  
  > `(Total Transactions ÷ Tenure Months) × 12 × 0.001`

---

## Step 1: CTE - `customer_txn_summary`

**Purpose:** Aggregate total number and value of confirmed transactions for each customer.

```sql
WITH customer_txn_summary AS (
    SELECT 
        sa.owner_id,
        COUNT(*) AS total_transactions,
        SUM(confirmed_amount) AS total_transaction_value
    FROM 
        savings_savingsaccount sa
    GROUP BY 
        sa.owner_id
),
```

- COUNT(*) counts all confirmed transactions by each customer.

- SUM(confirmed_amount) gives the total raw value of transactions.

- This builds the base for understanding how active each customer is.

## Step 2: CTE - `tenure_calc`

**Purpose:**  
Calculate each customer’s tenure in months — the duration from their first transaction to the current date.

```
tenure_calc AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, MIN(sa.transaction_date), CURRENT_DATE) AS tenure_months
    FROM 
        users_customuser u
    JOIN 
        savings_savingsaccount sa ON u.id = sa.owner_id
    GROUP BY 
        u.id, u.first_name, u.last_name
),
```
- Uses MIN(sa.transaction_date) to get the earliest transaction date.

- TIMESTAMPDIFF(MONTH, ..., CURRENT_DATE) computes total months active.

- Joins with users_customuser for customer metadata (e.g., full name).

Step 3: CTE - `combined`
Purpose: Merge tenure and transaction activity to compute estimated CLV using a standardized formula.

```
combined AS (
    SELECT 
        t.customer_id,
        t.name,
        t.tenure_months,
        cts.total_transactions,
        ROUND(((cts.total_transactions * 1.0 / NULLIF(t.tenure_months, 0)) * 12 * 0.001), 2) AS estimated_clv
    FROM 
        tenure_calc t
    JOIN 
        customer_txn_summary cts ON t.customer_id = cts.owner_id
)

```
- Combines transaction summary and tenure data.

- Calculates estimated CLV as:

```
(total_transactions / tenure_months) × 12 × 0.001

```
- NULLIF(t.tenure_months, 0) safely avoids division-by-zero errors.

### Final Output
```
SELECT * 
FROM combined
ORDER BY estimated_clv DESC;
```

# Customer Value Query Summary

## Displays:

| Field              | Description                      |
|--------------------|--------------------------------|
| Customer ID        | Unique identifier for the customer |
| Name               | Full customer name (first + last) |
| Tenure in months   | Active customer duration in months |
| Total transactions | Number of transactions made by the customer |
| Estimated CLV      | Customer Lifetime Value estimate |

**Ordered in descending CLV to highlight the most valuable customers.**

---

## Challenges & Resolutions

| Challenge                  | Resolution                                                                                 |
|----------------------------|--------------------------------------------------------------------------------------------|
| Handling zero tenure        | Used `NULLIF(t.tenure_months, 0)` to prevent division-by-zero errors.                      |
| Interpreting CLV formula   | Broke down the CLV formula into frequency × annualization × conversion factor.             |
| Accurate tenure calculation | Used `TIMESTAMPDIFF(MONTH, MIN(transaction_date), CURRENT_DATE)` for precise active duration. |
| Full customer name in output| Used `CONCAT(first_name, ' ', last_name)` for better readability.                          |
| Ensuring reliable joins    | Applied only necessary JOINs after ensuring presence in both transaction and user tables. |

---

## Conclusion

This query offers a data-driven estimate of customer value over time based on actual behavior. It supports:

- Identifying high-value customers.
- Prioritizing retention or cross-sell campaigns.
- Personalizing customer journeys.

By structuring with modular CTEs, it’s easy to extend for:

- Tiered CLV calculation.
- Time-filtered analysis.
- Integration with customer segmentation models.




























