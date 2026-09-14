cas mysession terminate;

cas mysession;

proc cas;
	table.caslibinfo;
quit;

cas secondsession;

proc cas;
	sessionstatus;
	listsessions;
quit;

caslib _all_ assign;

cas _all_ terminate;

caslib mylib
	datasource=(srctype='PATH')
	path='/home/student/bank_csv';
proc cas;
	table.caslibinfo; quit;


%let csvdir= /home/student/bank_csv;
%let  cas_lib = mylib;
%MACRO cas_load(name=);
	PROC IMPORT DATAFILE="&CSVDIR/&name..csv"
               OUT=&name
               DBMS=CSV 
			   REPLACE;
      GETNAMES=YES;
      GUESSINGROWS=MAX;
	RUN;
	proc casutil;
		droptable casdata="&name" incaslib="&cas_lib" quiet;
		load data=&name
			outcaslib="&cas_lib"
			casout="&name"
			replace;
	quit;

	%put [setup] data load &name 완료;
%mend;

%cas_load(name=customers);
%cas_load(name=cards);
%cas_load(name=loans);
%cas_load(name=sessions);
%cas_load(name=transactions);








/* caslib, file 정보 확인 */
proc cas;
	table.caslibinfo;
	table.fileinfo / caslib='mylib';
	table.tableinfo / caslib='mylib';
quit;


/* 부서별 lib 생성 */
caslib saleslib
	datasource=(srctype='PATH')
	path='/home/student/sales' global
	description="영업 부서 공용";


proc cas;
	table.dropcaslib/
		caslib="mylib";
quit;





cas _all_ terminate;
cas mysess;

caslib mylib
	datasource=(srctype='PATH')
	path='/home/student/bank_csv';
caslib _all_ assign;

/* mylib(물리적 디렉토리)의  *.csv -> caslib mylib로 load */
proc casutil;
	load casdata='customers.csv' incaslib='mylib' casout='customers' replace;
	load casdata='loans.csv' incaslib='mylib' casout='loans' replace;
	load casdata='cards.csv' incaslib='mylib' casout='cards' replace;
	load casdata='sessions.csv' incaslib='mylib' casout='sessions' replace;
	load casdata='transactions.csv' incaslib='mylib' casout='transactions' replace;
quit;


%macro load_casdata(name=);
	proc casutil; load casdata="&name..csv" incaslib='mylib' casout="&name" replace;

%mend;
proc cas;
	table.caslibinfo;
	table.fileinfo / caslib='mylib';
	table.tableinfo / caslib='mylib';
quit;

/* 등록된 테이블의 데이터 일부 검증 */
proc cas;
	table.columninfo / table={name='customers', caslib="&cas_lib"};
	table.fetch / table={name='customers', caslib="&cas_lib"} to=10;
	table.tableinfo / caslib="&cas_lib";
quit;

%load_casdata(name=customers);
%load_casdata(name=loans);
%load_casdata(name=cards);
%load_casdata(name=sessions);
%load_casdata(name=transactions);


/* mylib의 customers -> customers.sashdata 로 저장(물리적 저장 장소 mylib) */
proc casutil;
	save casdata="customers" incaslib="&cas_lib" 
	casout="customers.sashdat" outcaslib="casuser" replace;
quit;

proc cas;
	table.caslibinfo;
	table.fileinfo / caslib='casuser';
	table.tableinfo / caslib='casuser';
quit;

/* 저장된 파일 삭제 (대소문자 구분 해야함) */
proc casutil;
	deletesource casdata="customers.sashdat" incaslib="casuser" quiet;
quit;
/* 리눅스랑 sas 대소문자 확인 */

/* cards -> 1. csv -> cas에 load -> 
 2. casuser lib에 영구 저장
 3. cas memory의 cards 삭제
 4. 저장된 파일을 load
 5. 저장된 파일 삭제
 */

%let my_lib = mylib;
%let cas_lib = casuser;
/* 1 mylib -> csv 파일을 -> casuser에 load */
proc casutil;
	load casdata="cards.csv" incaslib="&my_lib"
		outcaslib="casuser" casout="cards" replace;
quit;

/* 2. 영구 저장 */
proc casutil;
	save casdata="cards" incaslib="casuser"
		outcaslib="casuser" casout="cards.sashdat" replace;
quit;

proc casutil;
	list files incaslib="casuser";
quit;

/* 3. */
proc casutil;
	droptable casdata="cards" incaslib="casuser" quiet;
quit;

/* 4. */
proc casutil;
	load casdata="cards.sashdat" incaslib="casuser"
		casout="cards" outcaslib="casuser" replace;
quit;

/* 5. */
proc casutil;
	deletesource casdata="cards.sashdat" incaslib="casuser" quiet;
quit;
proc casutil;
	list files incaslib="casuser";
quit;


%let my_lib = mylib;

%macro save_all(caslib=public);
	proc casutil;
		save casdata="customers" incaslib="&my_lib"
			casout="customers.sashdat" outcaslib="&caslib" replace;
		save casdata="transactions" incaslib="&my_lib"
			casout="transactions.sashdat" outcaslib="&caslib" replace;
		save casdata="cards" incaslib="&my_lib"
			casout="cards.sashdat" outcaslib="&caslib" replace;
		save casdata="loans" incaslib="&my_lib"
			casout="loans.sashdat" outcaslib="&caslib" replace;
		save casdata="sessions" incaslib="&my_lib"
			casout="sessions.sashdat" outcaslib="&caslib" replace;
	quit;
%mend;
%save_all;

proc casutil;
	list files incaslib="public";quit;

%let my_lib = public;
%macro load_all(caslib=casuser);
	proc casutil;
		load casout="customers" incaslib="&my_lib"
			casdata="customers.sashdat" outcaslib="&caslib" replace;
		load casout="transactions" incaslib="&my_lib"
			casdata="transactions.sashdat" outcaslib="&caslib" replace;
		load casout="cards" incaslib="&my_lib"
			casdata="cards.sashdat" outcaslib="&caslib" replace;
		load casout="loans" incaslib="&my_lib"
			casdata="loans.sashdat" outcaslib="&caslib" replace;
		load casout="sessions" incaslib="&my_lib"
			casdata="sessions.sashdat" outcaslib="&caslib" replace;
	quit;
%mend;
%load_all;


/* session5 -> casuser lib의 내용으로 transaction summary(amount), freq(staus) */
/* 1. casuser lib에 로드된 테이블 목록 확인 */
proc cas;
	table.tableinfo / caslib="casuser"; quit;

/* 2. transaction 칼럼 정보 확인 */
proc cas;
	table.columninfo / table={name="transactions", caslib="casuser"}; quit;

/* 3. amount 칼럼에 대해 통계 정보 확인 */
proc cas;
	simple.summary / table={name="transactions", caslib="casuser"}
		inputs={"amount"}; quit;

/* 4. status 칼럼에 대한 값의 분포 */
proc cas;
	simple.freq / table={name="transactions", caslib="casuser"}
		inputs={"channel", "category", "status"}; quit;

/* 5. 상위 10행 미리 보기 */
proc cas;
	table.fetch / table={name="transactions", caslib="casuser"} to=10; quit;

/* 데이터 품질 검증 */
/* 1. summary -> 이상값 감지 : 결제액이 음수인 경우가 있는지, 결측 데이터가 있는지 확인 */
proc cas;
	simple.summary / 
		table={name="transactions", caslib="casuser"}
		inputs={"amount"}
		subset={"min", "max", "mean", "std", "n", "nmiss"};
quit;

/* 2. 이상값 카운트 */
proc cas;
	fedsql.execdirect / 
	query = "
		select sum(case when amount < 0 then 1 else 0 end) as n_negative,
			sum(case when amount = 0 then 1 else 0 end) as n_zero,
			sum(case when amount > 500000 then 1 else 0 end) as n_outlier,
			count(*) as n_total
		from casuser.transactions
	";
quit;

/* 3. 데이터 정제 - 음수 결제 분리 */
proc cas;
	fedsql.execdirect / query = "
	create table casuser.transactions_refund {options replace=true} as
	select * from casuser.transactions where amount < 0
	";

	fedsql.execdirect / query = "
	create table casuser.transactions_clean {options replace=true} as
	select * from casuser.transactions where amount < 0
	";
quit;

/* 4. 정제된 데이터 검증 */
proc cas;
	simple.summary / 
		table={name="transactions", caslib="casuser"}
		inputs={"amount"}
		subset={"min", "max", "mean", "std", "n", "nmiss"};
quit;


/* session 6 : aggregation */
proc cas;
	aggregation.aggregate / 
	table = {name="transactions", caslib="casuser", groupby={"channel"}}
	varspecs = {{name="amount", summarysubset={"mean", "sum", "n"}}}
	casout={name="channel_kpi", caslib="casuser", replace=true};
	
	table.fetch / table={name="channel_kpi", caslib="casuser"};
quit;






