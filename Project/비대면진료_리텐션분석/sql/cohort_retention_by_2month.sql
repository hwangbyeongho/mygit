/*
	 📌 목적: 사용자 코호트(첫 진료월)별 이후 1~12개월 간의 범위 리텐션을 2개월 단위로 집계하여 잔존율을 확인하기 위함
	 📢 주요 정의:
	 	1. first_consult_month : 첫 진료월이 동일한 사용자 집단(=코호트)
	 	2. Volume : 각 코호트에 속한 사용자 수
	 	3. 'M1~M2', 'M3~M4' ··· : 첫 진료월 이후 해당 구간 동안 진료를 받은 사용자 수
	 📁 사용 테이블: drnow_consultations 
*/

with first_consult as ( -- 사용자별 첫 진료일 산출
	select user_id 
		 , MIN(consult_date) as first_consult_date
	from drnow_consultations
	group by user_id

), user_cohort as ( -- 첫 진료일과 이후 모든 진료일 연결
select c.user_id
	 , DATE_FORMAT(fc.first_consult_date, '%Y-%m-01') as first_consult_month
	 , DATE_FORMAT(c.consult_date, '%Y-%m-01') as consult_month
from drnow_consultations c
	join first_consult fc on c.user_id = fc.user_id

) -- 코호트별 첫 진료월 이후 2개월 단위 구간 동안 진료를 받은 사용자 수 집계
select first_consult_month -- 코호트 : 첫 진료월이 동일한 사용자 집단
	 , COUNT(distinct user_id) as Volume -- 코호트별 사용자 수
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 1 month) and DATE_ADD(first_consult_month, interval 2 month) then user_id end) as 'M1~M2'
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 3 month) and DATE_ADD(first_consult_month, interval 4 month) then user_id end) as 'M3~M4'
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 5 month) and DATE_ADD(first_consult_month, interval 6 month) then user_id end) as 'M5~M6'
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 7 month) and DATE_ADD(first_consult_month, interval 8 month) then user_id end) as 'M7~M8'
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 9 month) and DATE_ADD(first_consult_month, interval 10 month) then user_id end) as 'M9~M10'
	 , COUNT(distinct case when consult_month between DATE_ADD(first_consult_month, interval 11 month) and DATE_ADD(first_consult_month, interval 12 month) then user_id end) as 'M11~M12'
from user_cohort
group by first_consult_month
order by first_consult_month
