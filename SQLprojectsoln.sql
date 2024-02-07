select * from credit_card_transcations
-- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
-- solution 1
select top 5 city,sum(amount) as expense,CASE WHEN 1=1 then (select sum(amount) from credit_card_transcations) end as total_spent ,round(100*SUM(amount)/(select sum(amount) from credit_card_transcations),2) as prcnt_cnt
from credit_card_transcations
group by city
order by sum(amount) desc;


-- write a query to print highest spend month and amount spent in that month for each card type
-- solution 2
with cte as(
select card_type,DATEPART(year,transaction_date) as yo,DATENAME(month,transaction_date) as mo
, sum(amount) as monthly_expense
from credit_card_transcations
group by card_type,DATEPART(year,transaction_date),DATENAME(month,transaction_date))
select * from (select *,rank() over(partition by card_type order by monthly_expense desc) as rn
from cte) a
where rn=1;

-- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
-- solution 3
with cte as(
select *,SUM(amount) over(partition by card_type order by transaction_date,transaction_id) as run_sum
from credit_card_transcations),
cte2 as(
select *,RANK() over(partition by card_type order by run_sum) as rn from cte  where run_sum>=1000000)
select * from cte2 where rn=1;


-- write a query to find city which had lowest percentage spend for gold card type
-- solution 4
select city,sum(amount) as total_spend
,sum(case when card_type='Gold' then amount else 0 end) as gold_spend
,100*sum(case when card_type='Gold' then amount else 0 end)/sum(amount) as gold_cont
from credit_card_transcations 
group  by city
having sum(case when card_type='Gold' then amount else 0 end) > 0
order by gold_cont;

-- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
-- solution 5
with cte as (
select city,exp_type,sum(amount) as total_spend
from credit_card_transcations
group by city,exp_type)
--order by city,total_spend
, cte2 as (
select *
,rank() over(partition by city order by total_spend desc) rn_high
,rank() over(partition by city order by total_spend) rn_low
from cte)
select city
, max(case when rn_high=1 then exp_type end) as highest_expense_type
, max(case when rn_low=1 then exp_type end) as lowest_expense_type
from cte2
where rn_high=1 or rn_low=1
group by city;


-- write a query to find percentage contribution of spends by females for each expense type
-- solution 6
select exp_type,sum(amount) as total_spend
,sum(case when gender='F' then amount else 0 end) as female_Spend
,sum(case when gender='F' then amount else 0 end)/sum(amount)*100 as female_contribution
from credit_card_transcations
group by exp_type
order by female_contribution 


-- which card and expense type combination saw highest month over month growth in Jan-2014
-- solution 7
with cte as(
select card_type,exp_type,DATEPART(year,transaction_date) as yr,DATEPART(month,transaction_date) as mn, sum(amount) as amnt_spent
from credit_card_transcations
group by card_type,exp_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date)),
cte2 as (
select *, lag(amnt_spent,1) over(partition by card_type,exp_type order by yr,mn) as prev_amt_spent
from cte)
select top 1 *,amnt_spent-prev_amt_spent as grwth from cte2 where yr=2014 and mn=1
order by grwth desc;


-- during weekends which city has highest total spend to total no of transcations ratio 
-- solution 8
select city ,SUM(amount)/count(*) as trn_rt
from credit_card_transcations
where DATEPART(weekday,transaction_date) in (1,7)
group by city
order by trn_rt desc;


-- which city took least number of days to reach its 500th transaction after the first transaction in that city
-- solution 9
with cte as(
select *,ROW_NUMBER() over(partition by city order by transaction_date) as trans_num from credit_card_transcations 
where city in (select city from credit_card_transcations group by city having count(*)>=500 ))
select city,min(transaction_date) as first_transc,max(transaction_date) as last_transc,DATEDIFF(day,min(transaction_date),max(transaction_date)) as no_of_days from cte where trans_num<=500
group by city
order by no_of_days;
