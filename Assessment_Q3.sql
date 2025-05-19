-- Step 1: Get the most recent transaction date for each plan
WITH latest_transaction AS (
    SELECT 
        sa.plan_id,
        MAX(sa.transaction_date) AS last_transaction_date -- Latest transaction per plan
    FROM savings_savingsaccount sa
    GROUP BY sa.plan_id
)

-- Step 2: Identify savings or investment plans that have been inactive for over a year
SELECT 
    p.id AS plan_id,
    p.owner_id,
    -- Categorize plan type based on flags
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
    END AS type,
    CAST(lt.last_transaction_date AS DATE) AS last_transaction_date, -- Show only the date part
    DATEDIFF(DAY, lt.last_transaction_date, GETDATE()) AS inactivity_days -- Days since last transaction

	 --DATE(lt.last_transaction_date) AS last_transaction_date, 
  --  DATEDIFF(CURDATE(), lt.last_transaction_date) AS inactivity_days (Uncomment and use this two line of code and coment the first one instead for MYSQL)

FROM plans_plan p
LEFT JOIN latest_transaction lt ON p.id = lt.plan_id -- Include plans even if they’ve never had a transaction
WHERE 
    -- Focus only on savings or investment plans
    (p.is_regular_savings = 1 OR p.is_a_fund = 1)
    AND (
        lt.last_transaction_date IS NULL OR -- No transaction at all
        lt.last_transaction_date < DATEADD(DAY, -365, GETDATE()) -- Last transaction was over a year ago
    )
	--lt.last_transaction_date < DATE_SUB(CURDATE(), INTERVAL 365 DAY) -- Last transaction was over a year ago (uncomment to use this line of code instead for MYSQL)
ORDER BY inactivity_days DESC; -- Show longest inactive plans first
