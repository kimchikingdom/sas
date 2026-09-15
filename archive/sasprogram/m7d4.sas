libname shop '/home/student/shop_db';

proc contents data=shop.orders short; run;
proc contents data=shop.order_items short; run;
proc contents data=shop.products short; run;
proc contents data=shop.users short; run;



/* shop_orders 생성 */
proc sql;
	create table shop_orders as
	select o.order_id, o.user_id, o.order_date, o.status, o.total_amount,
	oi.product_id, oi.quantity, p.price, p.cost,
	p.price * oi.quantity as line_revenue,
	(p.price - p.cost) * oi.quantity as line_profit
	from shop.orders as o inner join shop.order_items as oi on o.order_id = oi.order_id
		inner join shop.products as p on oi.product_id = p.product_id;
quit;


proc contents data=shop_orders short; run;


/* 1. CAS 세션 시작 */
cas mySession;

/* 2. WORK.shop_orders 데이터를 CAS(casuser)로 로드 및 승격(VA에서 사용 가능하도록) */
proc casutil;
    load data=work.shop_orders 
         outcaslib="casuser" 
         casout="shop_orders" 
         promote;
quit;


/* 채널별 상품별 Drill-down */
/* 통합 사용 : Treemap Level 1 (채널 요약) + Drill-down(채널 -> 상품)
	- VA가 level 1 뷰에서 자동으로 channel 별 sum 집계
	- level2 (셀 더블클릭) 에서 product_id 별로 확대
계층을 만들려면 두 범주 () 가 한 테이블에 있어야 함
ppt treemap 매칭 ():
	organic 35%
	referral 12%
비율 칼럼 저장 X : VA가 SUM 집계하면 잘못됨 -> 계산 측도로 정의 
 */

/* channel_product_revenue */
proc sql;
	create table channel_product_revenue as
	select u.channel, o.product_id, sum(o.line_revenue) as revenue label='매출' format=comma20.,
			sum(o.line_profit) as profit, count(distinct o.order_id) as orders,
			count(distinct u.user_id) as users
	from work.shop_orders as o inner join shop.users as u on o.user_id=u.user_id
	group by channel, product_id;
quit;

proc print data=channel_product_revenue(obs=10) label noobs;
run;


proc casutil;
    load data=work.channel_product_revenue 
         outcaslib="casuser" 
         casout="channel_product_revenue" 
         promote;
quit;












/* ========================================================= 
   1. KPI 집계 테이블 생성 (WORK.KPI_SUMMARY) 수정본
   ========================================================= */ 
proc sql; 
    create table work.kpi_summary as 
    select  
        /* 월별 집계를 위한 년-월 기준 일자 */ 
        intnx('month', order_date, 0, 'beginning') as order_month format=yymmd7. label='주문월', 
         
        /* KPI 지표 계산 */ 
        sum(line_revenue) as total_revenue label='월 매출', 
        count(distinct user_id) as active_users label='활성 회원', 
        count(distinct order_id) as total_orders label='총 주문 수', 
        sum(case when status in ('cancelled', 'canceled') then 1 else 0 end) / count(distinct user_id) as churn_rate format=percent8.1 label='이탈률', 
        
        /* 💡 수정된 부분: nlmnl20. -> comma20. */
        sum(line_revenue) / count(distinct order_id) as avg_order_amount format=comma20. label='평균 주문액', 
        
        sum(line_profit) as total_profit label='총 마진', 
        sum(line_profit) / sum(line_revenue) as profit_margin format=percent8.1 label='마진율' 
    from work.shop_orders 
    group by calculated order_month 
    order by order_month; 
quit; 



/* =========================================================
   2. 생성된 KPI 테이블을 CAS 메모리로 로드 및 승격(Promote)
   ========================================================= */
cas mySession;

proc casutil;
    load data=work.kpi_summary 
         outcaslib="casuser" 
         casout="kpi_summary" 

         promote;
quit;


/* =========================================================
   3. 로드 결과 확인 (Log 및 Output)
   ========================================================= */
proc casutil;
    list tables incaslib="casuser";
quit;



/* 1. VA에서 사용할 KPI 요약 데이터 생성 */ 
proc sql; 
    create table work.kpi_summary as 
    select  
        intnx('month', order_date, 0, 'beginning') as order_month format=yymmd7. label='주문월', 
        sum(line_revenue) as total_revenue label='월 매출', 
        count(distinct user_id) as active_users label='활성 회원', 
        count(distinct order_id) as total_orders label='총 주문 수', 
        sum(case when status in ('cancelled', 'canceled') then 1 else 0 end) / count(distinct user_id) as churn_rate format=percent8.1 label='이탈률', 
        sum(line_revenue) / count(distinct order_id) as avg_order_amount format=comma20. label='평균 주문액', 
        sum(line_profit) as total_profit label='총 마진', 
        sum(line_profit) / sum(line_revenue) as profit_margin format=percent8.1 label='마진율' 
    from work.shop_orders 
    group by calculated order_month 
    order by order_month; 
quit; 

/* 2. 생성된 데이터를 CAS 메모리로 로드 및 승격 (VA 연결용) */
cas mySession;

proc casutil;
    load data=work.kpi_summary 
         outcaslib="casuser" 
         casout="kpi_summary2" 

         promote;
quit;

/* ========================================================= 
   1. VA 분석용 마스터 데이터 생성 (차원 결합)
   ========================================================= */ 
proc sql;
    create table work.va_master_data as
    select 
        /* 1) 기존 shop_orders의 모든 측정값/정보 가져오기 */
        o.*,
        
        /* 2) 시간 차원 추가: 월별 추세를 그리기 위한 월(Month) 변수 */
        intnx('month', o.order_date, 0, 'beginning') as order_month format=yymmd7. label='주문월',
        
        /* 3) 분석 차원 추가: 고객의 유입 채널과 상품의 카테고리 조인 */
        u.channel label='유입 채널',
        p.category label='제품 카테고리' /* 만약 products 테이블의 변수명이 다르면(예: product_category) 수정해 주세요 */
        
    from work.shop_orders as o
    left join shop.users as u on o.user_id = u.user_id
    left join shop.products as p on o.product_id = p.product_id;
quit;


/* ========================================================= 
   2. 마스터 데이터를 CAS 메모리로 로드 및 승격
   ========================================================= */ 
cas mySession;

proc casutil;
    load data=work.va_master_data 
         outcaslib="casuser" 
         casout="va_master_data" 

         promote;
quit;



proc contents data=shop.users short;run;



proc sql;
	create table kpi_gauge as 
	select 'Q1_revenue' 	as kpi length=30,
		sum(line_revenue) as actual format=comma20.,
		36000000000		as target format=comma20.,
		sum(line_revenue) / 36000000000 as progress format=percent.
	from shop_orders
	where order_date between '01JAN2026'd and '31MAR2026'd;
quit;

proc casutil;
    load data=kpi_gauge 
         outcaslib="casuser" 
         casout="kpi_gauge" 
         promote;
quit;






