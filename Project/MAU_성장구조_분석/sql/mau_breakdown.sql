/*
	 📌 목적: 월별 MAU를 new / resurrected / retained로 분해하여 집계
	 📢 주요 정의:
	 	  1. new : 이번 달 서비스에 처음으로 로그인한 신규 유저
	 	  2. resurrected : 지난 달에 로그인하지 않았지만, 과거 로그인 이력이 있으면서 이번 달에 다시 로그인한 복귀 유저
	 	  3. retained : 지난 달에도 로그인했고, 이번 달에도 로그인한 유지 유저
	 📁 사용 테이블: login_logs_ecom
*/

with step1 as (
	select distinct user_id
		   , date_format(login_date, '%Y-%m-01') as ym
	from login_logs_ecom
	where login_date is not null
	  and login_date between '2018-05-01' and '2020-04-30'
	-- 연월 단위로 로그인한 유저 기록을 중복없이 추출
	  
), step2 as (
	select user_id
	  	 , ym
		   , lag(ym, 1) over (partition by user_id order by ym) as last_login
	from step1
	-- 유저별 과거 로그인 월을 lag()로 가져옴
	
), step3 as (
	select user_id
		   , ym
	  	 , case
		 	  	when last_login is null then 'new'
		   		when timestampdiff(month, last_login, ym) > 1 then 'resurrected'
		 	  	when timestampdiff(month, last_login, ym) = 1 then 'retained'
		     end as user_type
	from step2
	-- 현재 로그인 월과 직전 로그인 월의 '월' 단위 차이에 따라 유저 타입 분류

), step4 as (
	select ym
		   , user_type
	  	 , count(distinct user_id) as user_cnt
	from step3
	group by ym, user_type
	order by ym, user_type
	-- 연월/유저 타입별 유저 수를 집계

)	-- 테이블 피봇
select ym 
	   , sum(user_cnt) as 'mau'
  	 , sum(case when user_type = 'new' then user_cnt else 0 end) as 'new'
	   , sum(case when user_type = 'resurrected' then user_cnt else 0 end) as 'resurrected'
	   , sum(case when user_type = 'retained' then user_cnt else 0 end) as 'retained'
from step4
group by ym
