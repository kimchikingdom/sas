cas mysession;
caslib _all_ assign;

cas mysession terminate;




proc cas;
	table.partition / 
		table = {name='orders',
				caslib = 'casuser',
				groupby = {'user_id'}},
		casout = {name='orders_p',
				caslib='casuser',
				replace= true};
quit;


/* partition 확인 */
proc casutil;
	contents casdata='orders' incaslib='casuser';
	contents casdata='orders_p' incaslib='casuser';
quit;

/* 저장된 데이터 확인 */
proc cas;
	table.fetch result = res /
		table = {name='orders_p', caslib='casuser', groupby={'user_id'}};
		top = 10;
	print res;
quit;

options fullstimer;
proc means data=casuser.orders sum;
	where user_id < 1000;
	var total_amount;
	output out=work.summary_out mean=avg_amount sum=sum_amount;
run;

proc means data=casuser.orders_p sum;
	where user_id < 1000;
	var total_amount;
	output out=work.summary_out mean=avg_amount sum=sum_amount;
run;


options nofullstimer;   /* 실행 시간 안 보이게 */


/* 복제 users -> worker에 복제, 데이터 보안 */
/* 1. 데이터셋 삭제 후 복제 */
proc casutil;
	droptable casdata='users_c' incaslib='casuser' quiet;
quit;

libname shop"/home/student/shop_db";
proc casutil;
	load data=shop.users
		outcaslib='casuser' casout='users_c' copies=4 promote;
quit;


proc cas;
	table.tableinfo / caslib='casuser', name='users_c';
quit;

proc casutil;
	droptable casdata='orders_paid_p' incaslib='public' quiet;
/* 조건에 맞는 데이터만 파티션 분리  */
proc cas;
	table.partition /
		table = {name='orders', caslib='casuser', where='status="paid"',groupBy={'channel'}},
		casout={name='orders_paid_p', caslib='public', promote=true};
quit;













