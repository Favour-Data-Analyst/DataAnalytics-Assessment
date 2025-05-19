-- Step 1: Calculate the number of transactions each customer made per month
WITH customer_monthly_txn AS (
    SELECT 
        sa.owner_id,
        -- Extract the first day of each month to represent the month
        DATEFROMPARTS(YEAR(sa.transaction_date), MONTH(sa.transaction_date), 1) AS month,
		--STR_TO_DATE(DATE_FORMAT(sa.transaction_date, '%Y-%m-01'), '%Y-%m-%d') AS month, (uncomment and use this line of code instead for MYSQL)
        COUNT(*) AS txn_count
    FROM savings_savingsaccount sa
    GROUP BY sa.owner_id, DATEFROMPARTS(YEAR(sa.transaction_date), MONTH(sa.transaction_date), 1)
	--GROUP BY sa.owner_id, month (uncomment and use this line of code insted for MYSQL)
),

-- Step 2: Calculate the average monthly transaction count per customer
avg_txn_per_customer AS (
    SELECT 
        owner_id,
        -- Convert count to float to ensure accurate average, round to 2 decimal places
        ROUND(AVG(CAST(txn_count AS FLOAT)), 2) AS avg_txn_per_month
		 --ROUND(AVG(txn_count), 2) AS avg_txn_per_month (uncomment and use this line of code instead for MYSQL)
    FROM customer_monthly_txn
    GROUP BY owner_id
),

-- Step 3: Categorize customers based on their average transaction frequency
categorized_customers AS (
    SELECT 
        owner_id,
        CASE 
            WHEN avg_txn_per_month >= 10 THEN 'High Frequency'  -- Very active customers
            WHEN avg_txn_per_month >= 3 THEN 'Medium Frequency' -- Moderately active
            ELSE 'Low Frequency'                                -- Less active
        END AS frequency_category,
        avg_txn_per_month
    FROM avg_txn_per_customer
)

-- Step 4: Summarize how many customers fall into each category and their average transactions
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,                          -- Total customers in each category
    ROUND(AVG(avg_txn_per_month), 1) AS avg_transactions_per_month -- Avg txn per customer in each category
FROM categorized_customers
GROUP BY frequency_category
ORDER BY 
    -- Sort categories in logical order: High > Medium > Low
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
