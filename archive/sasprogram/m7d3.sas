cas mysession terminate;

cas mysession;

/* cas lib목록 확인 */
caslib _all_ assign;

proc cas;
	table.caslibinfo;
quit;

/* cas 서버 정보 */
proc cas;
	builtins.serverstatus;
	table.tableinfo / caslib="CASUSER";
quit;

cas mysession terminate;



libname shop "/home/student/shop_db";
cas mysession;
caslib _all_ assign;


/* [실습] 디스크 vs CAS 벤치마크 */
%LET t1 = %SYSFUNC(DATETIME());
PROC SQL;
SELECT COUNT(*), SUM(total_amount) FROM shop.orders;
QUIT;
%PUT [디스크] %SYSEVALF(%SYSFUNC(DATETIME())-&t1) 초;
/* CAS 인메모리 */
PROC CASUTIL;
LOAD DATA=shop.orders OUTCASLIB="CASUSER"
CASOUT="orders" REPLACE;
QUIT;
%LET t2 = %SYSFUNC(DATETIME());
PROC FEDSQL SESSREF=mySession;
SELECT COUNT(*), SUM(total_amount) FROM CASUSER.orders;
QUIT;
%PUT [CAS] %SYSEVALF(%SYSFUNC(DATETIME())-&t2) 초;




/* 실행 시간 측정 */

/* 방법 1 - SYSFUNC(DATETIME) */
%LET t = %SYSFUNC(DATETIME());
%PUT %SYSEVALF(%SYSFUNC(DATETIME())-&t) 초;
/* 방법 2 - FULLSTIMER (자동 LOG) */
OPTIONS FULLSTIMER;
/* CPU 시간 + 실제 시간 */
proc sql;
	select channel, count(*) from shop.orders group by channel;
quit;
OPTIONS FULLSTIMER;
/* 방법 1 - SYSFUNC(DATETIME) */
%LET t = %SYSFUNC(DATETIME());
%PUT %SYSEVALF(%SYSFUNC(DATETIME())-&t) 초;
/* 방법 2 - FULLSTIMER (자동 LOG) */


proc cas;
	simple.summary / 
		table = {name="orders", caslib="CASUSER"},
		inputs = {"total_amount"};
quit;

proc cas;
	session.metrics;
quit;
/* CPU 시간 + 실제 시간

/* CAS sever 정보 */
proc cas;
	builtins.about;
quit;

proc cas;
	builtins.serverStatus;
	session.listSessions;
	session.listSessions;  /*활성 세션 목록 */
quit;


cas secondSession;

/* 자원 사용량 확인 */
proc cas;
	session.sessionId;
	session.metrics;
quit;

/* 로드된 액션 셋 + 액션 목록 */
proc cas;
	builtins.actionsetinfo;
	builtins.listactions / actionset='simple';
	builtins.listactions / actionset='table';

quit;

cas _all_ terminate;


cas mysession sessopts=(caslib='casuser' timeout=1800);

proc cas;
	session.sessionId;
	session.metrics;
quit;


caslib _all_ assign;


/* orders -> cas memory road */
proc casutil;
	load data=shop.orders
		 outcaslib="CASUSER"
		 casout="orders" replace;
quit;

proc casutil;
	promote casdata='orders' incaslib='casuser' outcaslib='public';
quit;

proc casutil;
	list tables incaslib='casuser';
	list tables incaslib='public';
quit;



/* PATH로 업무별 접근 권한 설정 */
caslib mylib path="/home/student/shop_db";

proc casutil;
	list files incaslib='mylib';
	list tables incaslib='mylib';
quit;


caslib mycsv path="/home/student/shop_csv";
proc casutil;
	list files incaslib='mycsv';
	list tables incaslib='mycsv';
quit;


/* casuser 메모리의 데이터를 mylib에 파일로 저장 -> 실행시 write 권한이 없어 에러 발생  */
proc casutil;
	save casdata='shop_joined_data' incaslib='casuser'
		outcaslib='mylib' casout='shop_joined_data.sashdat' replace;
quit;


/* 채널별 매출의 합계  : 3가 분석 방법 */
/* 1. proc means 사용 */
libname shop "/home/student/shop_db";
proc means data=shop.users sum mean;
	class channel;
	var total_spent;
quit;


/* 2. proc fedsql - ANSI SQL표준 */
proc fedsql sessref=mysession;
	select channel, sum(total_spent) as total_revenue, 
			mean(total_spent) as avg_revenue,
			count(*) as cnt
	from casuser.users
	group by channel;
quit;

/* 3. action -> simple.summary로 */
proc cas;
	simple.summary /
		table={name='users',
				caslib= 'casuser',
				groupby={'channel'}},
		inputs = {'total_spent'},
		subset={'sum', 'mean', 'n'};
quit;

proc fedsql sessref=mysession;
	create table casuser.category_vip_revenue as
	select c.category_name,
			u.vip_grade, sum(o.total_amount) as revenue, count(distinct o.order_id) as n_orders
	from casuser.orders as o 
		inner join casuser.users as u on  o.user_id = u.user_id
		inner join casuser.order_items as oi on o.order_id = oi.order_id
		inner join casuser.products as p on oi.product_id = p.product_id
		inner join casuser.categories as c on p.category_id = c.category_id
	where o.status = 'paid'
	group by c.category_name, u.vip_grade;
/* 	order by 1, 3 desc; */
quit;

proc casutil;
	promote casdata='category_vip_revenue' casout='category_vip_revenue'
			incaslib='casuser' outcaslib='casuser';
quit;


/* 빈도분포 */
proc cas;
	simple.freq / 
		table = {name="users", caslib='casuser'},
		inputs={'channel'};
quit;

/* 상관 계수 */
proc cas;
	simple.correlation /
		table={name='users', caslib='casuser'},
		inputs={'age','total_spent','order_count'};
quit;

/* 백분위수 */
proc cas;
	simple.percentile /
		table={name='users', caslib='casuser'},
		inputs={'total_spent'},
		values = {25,50,75,90,95,99};
quit;


/* 고유값 개수 */
proc cas;
	simple.distinct /
		table={name='users', caslib='casuser'},
		inputs={'channel','vip_grade','gender'};
quit;




/* 교차 집계 (피벗) */
proc cas;
	simple.crosstab /
		table={name='orders', caslib='casuser'},
		row='channel',
		col='payment_method',
		aggregator='sum',
		weight='total_amount';
quit;
