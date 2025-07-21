/*
	 📌 목적: 범위 리텐션 측정 단위를 설정하기 위함
	 📢 방법: 사용자별 평균 진료 간격을 산출한 뒤, 전체 사용자의 중앙값과 평균을 집계
	 📁 사용 테이블: drnow_consultations
*/

with step1 as ( -- 사용자별 진료 일자 간 간격 계산
	select user_id
		 , DATEDIFF(consult_date, prev_consult_date) as interval_days
	from (
		select user_id
			 , consult_date
			 , LAG(consult_date, 1) over (partition by user_id order by consult_date) prev_consult_date
		from drnow_consultations
	) base

), step2 as ( -- 사용자별 평균 진료 주기 집계
	select user_id 
		 , AVG(interval_days) as avg_interval
	from step1
	where interval_days is not null
	group by user_id

) -- 전체 사용자 평균 진료 주기로부터 중앙값 계산
select PERCENTILE_CONT(0.5) within group (order by avg_interval) as median_interval
--      , AVG(avg_interval) as avg_interval
from step2
