select * from online_sales;    -- [1]
select * from marketing_spend; -- [2]
select * from discount_coupon; -- [3]
select * from customersdata;   -- [4]
select * from tax_amount;      -- [5]
-- 
select `Month`
	  ,Product_Category
	  ,count(Product_Category) as cnt 
from discount_coupon 
group by 1,2 -- 상품카테고리 17개 

select count(distinct Product_Category) as cnt from online_sales -- 20개

-- [1] 테이블 가공
select *
	  ,substring(date_format(str_to_date(Transaction_Date,'%m/%d/%Y'), '%Y-%m-%d'),6,2) as Transaction_Date 
from online_sales;

-- [5] 테이블 가공 
select *
	  ,cast(replace(GST,'%','') as signed) as GST
from tax_amount

-- 거래별 총 invoice 계산
-- [1],[3],[5] JOIN 
with T1 as (
	select Product_Category
		  ,case when `Month` = 'Jan' then '01'
		  		when `Month` = 'Feb' then '02'
		  		when `Month` = 'Mar' then '03'
		  		when `Month` = 'Apr' then '04'
		  		when `Month` = 'May' then '05'
		  		when `Month` = 'Jun' then '06'
		  		when `Month` = 'Jul' then '07'
		  		when `Month` = 'Aug' then '08'
		  		when `Month` = 'Sep' then '09'
		  		when `Month` = 'Oct' then '10'
		  		when `Month` = 'Nov' then '11'
		  		else '12' end as Transaction_Month
		  ,Discount_pct
	from discount_coupon
), T2 as (
	select A.CustomerID
	  	  ,A.Transaction_ID
	  	  ,date_format(str_to_date(A.Transaction_Date,'%m/%d/%Y'), '%Y-%m-%d') as Transaction_Date
	  	  ,substring(date_format(str_to_date(A.Transaction_Date,'%m/%d/%Y'), '%Y-%m-%d'),6,2) as Transaction_Month
	  	  ,A.Product_SKU
	  	  ,A.Product_Category
	  	  ,A.Quantity
	  	  ,A.Avg_Price
	  	  ,A.Delivery_Charges
	  	  ,A.Coupon_Status
	  	  -- ,B.Product_Category
	  	  ,cast(replace(B.GST,'%','') as signed) as GST
	from online_sales A 
	left join tax_amount B on A.Product_Category = B.Product_Category
	-- where B.Product_Category is null
	),T3 as (
	select CustomerID
	      ,Transaction_ID
	      ,Transaction_Date
	      ,T2.Transaction_Month
	      ,T2.Product_Category
	      ,Quantity
	      ,Avg_Price
	      ,Delivery_Charges
	      ,Coupon_Status
	      ,GST
	      -- ,Transaction_Month
	      ,Discount_pct 
	from T2 left join T1 on T2.Transaction_Month = T1.Transaction_Month and T2.Product_Category = T1.Product_Category
	-- where T2.Transaction_Month = '03'
	), T4 as (
	select T3.*
		  ,case when Coupon_Status = 'Used' then 1
		  		else 0 end as Coupon_Applied
	from T3
	-- where Discount_pct is not null and (Coupon_Status = 'Not Used' or Coupon_Status = 'Clicked') #행 존재
	-- where Discount_pct is null and Coupon_Status = 'Used' #행 존재
	-- where Discount_pct is null and (Coupon_Status = 'Not Used' or Coupon_Status = 'Clicked') #행 존재
	-- where Discount_pct is not null and Coupon_Status = 'Used' #행 존재
	), T5 as (
	select T4.*
	      ,case when Coupon_Applied = 1 and Discount_pct is not null
	      			then (Quantity*Avg_price)*(1-Discount_pct/100)*(1+GST/100)+Delivery_Charges
	      		when Coupon_Applied = 1 and Discount_pct is null
	      			then (Quantity*Avg_price)*(1+GST/100)+Delivery_Charges
	      		when Coupon_Applied = 0 and Discount_pct is not null
	      			then (Quantity*Avg_price)*(1+GST/100)+Delivery_Charges
	      		when Coupon_Applied = 0 and Discount_pct is null
	      			then (Quantity*Avg_price)*(1+GST/100)+Delivery_Charges
	      		end as invoice
	from T4
 	), T6 as (
 	select T5.*
 		  ,C.Gender
 		  ,C.Location
 		  ,C.Tenure_Months
 	from T5 inner join customersdata C on T5.CustomerID = C.CustomerID
 	)
 	select T6.*
 		  ,M.Offline_Spend
 		  ,M.Online_Spend
 	from T6 left join (select date_format(str_to_date(Date,'%m/%d/%Y'), '%Y-%m-%d') as marketing_date
 		                     ,Offline_Spend
 		                     ,Online_Spend
 					   from marketing_spend) M on T6.Transaction_Date = M.marketing_date