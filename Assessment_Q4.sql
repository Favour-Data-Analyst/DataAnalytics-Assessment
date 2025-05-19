WITH customer_transactions AS (
    -- Calculate total transactions and total profit per customer (owner_id)
    SELECT 
        sa.owner_id,
        COUNT(*) AS total_transactions,  -- Total number of transactions by the customer
        -- Calculate total profit as 0.1% of the total confirmed amount (converted to float and scaled)
        ROUND(SUM(CAST(sa.confirmed_amount AS FLOAT)) / 100.0 * 0.001, 2) AS total_profit  
		  --ROUND(SUM(sa.confirmed_amount) / 100.0 * 0.001, 2) AS total_profit(uncomment and usse the code instaed for mysql)
    FROM savings_savingsaccount sa
    GROUP BY sa.owner_id
),
account_tenure AS (
    -- Calculate the tenure of each customer in months from the date they joined until today
    SELECT 
        id AS owner_id,
        DATEDIFF(MONTH, date_joined, GETDATE()) AS tenure_months  -- Difference in months between join date and today
		 --TIMESTAMPDIFF(MONTH, date_joined, CURDATE()) AS tenure_months(uncomment and use this code instead for mysql)
    FROM users_customuser
)
SELECT 
    u.id AS customer_id,
    u.name,
    at.tenure_months,
    ct.total_transactions,
    -- Calculate Estimated Customer Lifetime Value (CLV):
    -- 1. Average transactions per month = total_transactions / tenure_months
    -- 2. Annualize it by multiplying by 12 months
    -- 3. Multiply by average profit per transaction = total_profit / total_transactions
    -- Use NULLIF to avoid division by zero errors
    ROUND(
        (CAST(ct.total_transactions AS FLOAT) / NULLIF(at.tenure_months, 0)) * 12 * 
		--(ct.total_transactions / NULLIF(at.tenure_months, 0)) * 12 * (uncomment and use this line of code instead for mysql)
        (ct.total_profit / NULLIF(ct.total_transactions, 0)), 
        2
    ) AS estimated_clv
FROM customer_transactions ct
JOIN account_tenure at ON ct.owner_id = at.owner_id
JOIN users_customuser u ON u.id = ct.owner_id
ORDER BY estimated_clv DESC;  -- Sort customers by highest estimated CLV first