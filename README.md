Firstly i ran the code given on ssms and it didn't work and then i loaded the code on MYSQL because it was for MYSQL and executed it to create my database and tables and then i exported to ssms and also had my database and each table in the database then i properly read the questions to understand and i began answering the questions

For Assessment_Q1.sql which is to write a query to find customers with at least one funded savings plan and one funded investment plan, sorted by total deposits

I used three  Table Expressions in the CTE to get relevant plan and customer details:
1. transaction_rank: Assigned row numbers to each transaction per plan by ordering them by date, so the most recent transaction has row number 1.
2. qualified_customers: Selected customers who have at least one savings and one investment plan.
3. total_deposits: Calculated the total confirmed deposits for each customer.
After the defining the table expression s, I performed joins across the tables to gather:
* Each customer’s name,count of savings and investment plans and their latest balances.
I also updated the users_customuser table to set the name as a combination of first and last names using CONCAT.
Then, I: filtered to only keep the latest transaction per plan (where row_number = 1), Grouped the result by customer, Ensured the customer has positive balances greater than zero in both savings and investment accounts to define it being funded and finally, sorted the result by total deposits in descending order to get the customer with the highest deposits at the top.

For Assessment_Q2.sql which is to calculate the average number of transactions per customer per month and categorize them:

I created three Common Table Expressions (CTEs) to analyze how often customers transact:
1.customer_monthly_transaction
    Retrieved the owner_id, year, and month of each transaction.
    Counted the total number of transactions per customer per month.
    Grouped by owner_id and the formatted date (year and month).
2. average_transaction_per_customer
  Calculated the average number of transactions per month for each customer.
   Used the AVG() function on the monthly transaction counts.
   Rounded the result to two decimal places for readability.
3. categorized_customer
Categorized customers into High, Medium, or Low Frequency based on their average monthly transactions:
High: More than 10 transactions per month, Medium: Between 4 and 10 transactions, Low: 3 or fewer transactions
Used a CASE statement to assign these categories.
Finally, we selected and grouped the results by frequency category, returning:
* The number of customers in each category.
* The average transaction frequency for each group.

For Assessment_Q3.sql which is to find all active accounts (savings or investments) with no transactions in the last 1 year (365 days):

I wrote a table  to return the last transaction date using Max aggregation. 
On my main query I returned the plan ID, owner ID and the Account type, the last transaction date, and the inactivity period using DATEDIFF function between the current and last transaction date.
Filtered for all active accounts savings and investment with no activity in the last 365 days.

For Assessment_Q4.sql which is for each customer, assuming the profit_per_transaction is 0.1% of the transaction value, calculate:

I created a table expression to get profit from each customer by suming up the total confirmed deposit of each customer dividing by 100 to convert to naira, multiplying by 0.1 percent and rounding up to 2 decimal places. 
A second table expression account tenure to get the difference between the current date and the date the the account was created. 
Then retire the customer I'd, name tenure in month and total transaction from the main query body.
