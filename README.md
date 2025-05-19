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
