-- Index on savings_savingsaccount.plan_id since it's used in JOIN and partitioning
CREATE INDEX idx_savings_plan_id ON savings_savingsaccount(plan_id);

-- Index on savings_savingsaccount.transaction_date for efficient ordering in ROW_NUMBER
CREATE INDEX idx_savings_transaction_date ON savings_savingsaccount(transaction_date);

-- Index on plans_plan.id (usually primary key, so likely already indexed)
-- But also index on plans_plan.owner_id since it's heavily used in JOINs and GROUP BY
CREATE INDEX idx_plans_owner_id ON plans_plan(owner_id);

-- Index on plans_plan.is_regular_savings and is_a_fund for filtering in WHERE and HAVING
CREATE INDEX idx_plans_regular_a_fund ON plans_plan(is_regular_savings, is_a_fund);

-- Index on savings_savingsaccount.confirmed_amount if summing on it is slow (optional)
CREATE INDEX idx_savings_confirmed_amount ON savings_savingsaccount(confirmed_amount);

-- Index on users_customuser.id (likely primary key, usually indexed)
-- If not indexed, create:
CREATE INDEX idx_users_id ON users_customuser(id);


---- Uncomment this query to disable safe update mode only for MYSQL DBMS
--SET SQL_SAFE_UPDATES = 0;

-- Step 1 Run the update to set full name
UPDATE users_customuser
SET name = CONCAT(first_name, ' ', last_name);

---- Uncomment this query to re-enable safe update mode  only for MYSQL DBMS
--SET SQL_SAFE_UPDATES = 1;

-- Step 2: Assign row numbers to all transactions per plan with the most recent transaction having a row number of 1
WITH transaction_rank AS (
    SELECT 
        sa.plan_id,
        ROUND(sa.new_balance / 100.0, 2) AS new_balance, -- Normalize kobo to naira
        p.owner_id,
        p.is_regular_savings,
        p.is_a_fund,
        ROW_NUMBER() OVER (
            PARTITION BY sa.plan_id
            ORDER BY sa.transaction_date DESC -- Get the latest transaction
        ) AS rn
    FROM savings_savingsaccount sa
    JOIN plans_plan p ON sa.plan_id = p.id
    WHERE p.is_regular_savings = 1 OR p.is_a_fund = 1 -- Filter for relevant plan types if it is savings or investment
),

-- Step 3: Select customers who have at least one savings plan AND one investment plan
qualified_customers AS (
    SELECT owner_id
    FROM plans_plan
    GROUP BY owner_id
    HAVING 
        SUM(CASE WHEN is_regular_savings = 1 THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN is_a_fund = 1 THEN 1 ELSE 0 END) > 0
),

-- Step 4: Calculate total confirmed deposits per customer
total_deposits AS (
    SELECT 
        p.owner_id,
        ROUND(SUM(sa.confirmed_amount) / 100.0, 2) AS total_deposits -- Normalize to naira
    FROM savings_savingsaccount sa
    JOIN plans_plan p ON sa.plan_id = p.id
    GROUP BY p.owner_id
)

-- Step 5: Final result combining customer info, savings/investment counts, and total deposits
SELECT 
    tr.owner_id,
    u.name,
    COUNT(CASE WHEN tr.is_regular_savings = 1 THEN 1 END) AS savings_count,
    COUNT(CASE WHEN tr.is_a_fund = 1 THEN 1 END) AS investment_count,
    td.total_deposits
FROM transaction_rank tr
JOIN qualified_customers qc ON tr.owner_id = qc.owner_id
JOIN total_deposits td ON tr.owner_id = td.owner_id
JOIN users_customuser u ON tr.owner_id = u.id
WHERE tr.rn = 1 -- Only keep latest transaction per plan
GROUP BY tr.owner_id, u.name, td.total_deposits
HAVING 
    SUM(CASE WHEN tr.is_regular_savings = 1 THEN tr.new_balance ELSE 0 END) > 0 -- Must have non-zero balance in savings
    AND SUM(CASE WHEN tr.is_a_fund = 1 THEN tr.new_balance ELSE 0 END) > 0     -- Must have non-zero balance in investment
ORDER BY td.total_deposits DESC; -- Sort by total deposits in descending order
