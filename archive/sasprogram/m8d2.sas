/* public 파일로 저장된 데이터를 load -> casuser */
cas mySess;
caslib mylib datasource=(srctype="path") path="/home/student/bank_csv";
caslib _all_ assign;

/* public 파일로 저장된 데이터를 load -> mylib */
/* mylib은 글로벌로 못쓰니까 mylib은 ㄴㄴ */
%let publiclib = public;
%macro load_data(name=);
	proc casutil;
		load casdata="&name..sashdat" incaslib="&publiclib"
			casout="&name" outcaslib=casuser promote;

	list tables incaslib=casuser;
%mend;

%load_data(name=customers);
%load_data(name=cards);
%load_data(name=loans);
%load_data(name=sessions);
%load_data(name=transactions);

/* 등급별 + 채널별 KPI -> 건수, 총금액 => grade_kpi */
proc cas;
	fedsql.execdirect query = "
	create table casuser.grade_kpi as
	select c.grade, t.channel, count(*) as n_tx, sum(t.amount) as amount_sum
	from casuser.customers as c inner join casuser.transactions as t
		on c.customer_id = t.customer_id
	group by c.grade, t.channel
	";
quit;

/* global로 승격 */
proc casutil;
	promote casdata='grade_kpi' casout='grade_kpi' incaslib='casuser' outcaslib='casuser';
quit;

/* aggregation 실행 */
proc cas;
	aggregation.aggregate / 
	table={name="grade_kpi", caslib='casuser', groupby={'grade'}}
	inputs={'amount_sum'}
	casout={name='sample_grade', caslib='mylib', replace=true};
quit;

/* 여러개 */
proc cas;
	aggregation.aggregate / 
	table={name="grade_kpi", caslib='casuser', groupby={'grade'}}
	varspecs={{name='amount_sum', summarysubset={'sum', 'mean', 'n'}}}
	casout={name='sample_grade', caslib='mylib', replace=true};

	table.fetch / table={name='sample_grade', caslib='mylib'};
quit;



proc cas;
	fedsql.execdirect query = "
	create table casuser.cus_trans as
	select c.grade, t.channel,
			t.transaction_date,
			count(*) as n_tx,
			sum(t.amount) as amount_sum
	from casuser.customers as c inner join casuser.transactions as t
		on c.customer_id = t.customer_id
	group by c.grade, t.channel, t.transaction_date
	";
quit;



proc cas;
source my_sql;
create table casuser.cus_trans2 as 
select c.grade,
       t.channel,
       t.transaction_date,
       t.amount,
       count(*) as n_tx,
       sum(t.amount) as amount_sum,
       c.customer_id
from casuser.customers as c
inner join casuser.transactions as t
   on c.customer_id = t.customer_id
group by c.grade, t.channel, t.transaction_date, t.amount, c.customer_id;
endsource;

fedsql.execdirect query = my_sql;
quit;



/* global로 승격 */
proc casutil;
	promote casdata='cus_trans2' casout='cus_trans2' incaslib='casuser' outcaslib='casuser';
quit;













