/*---------------------------------------------------------------------------
  ScamLens 04 — 한국어 문자 n-gram 모델 (SAS Viya)

  Python의 char TF-IDF(3~5) + Logistic Regression을 SAS에서 재현한다.
  두 가지 경로를 모두 담았다. 환경에 맞는 쪽만 실행한다.

  경로 A: PROC TEXTMINE (Viya, 한국어 언어 지원 필요)
  경로 B: DATA step 문자 n-gram (언어 지원 없이도 동작)

  ★ 한국어에서 가장 중요한 점 ★
  UTF-8에서 한글은 글자당 3바이트다. SUBSTR은 바이트 단위로 잘라 글자를
  깨뜨린다. 반드시 KSUBSTR/KLENGTH를 쓴다. 이 프로젝트는 자모 분리 난독화를
  평가하므로 이 차이가 결과를 직접 바꾼다.
---------------------------------------------------------------------------*/


/*===========================================================================
  경로 A — PROC TEXTMINE
  한국어 형태소 분석에는 SAS 한국어 언어 지원이 필요하다. 없으면 경로 B로 간다.
===========================================================================*/
/*
cas mysess;
libname caslib cas sessref=mysess;

proc casutil;
    load data=work.msgtext outcaslib="casuser" casout="msgtext" replace;
run;

proc textmine data=caslib.msgtext;
    doc_id message_id;
    var    text_normalized;
    parse  entities   = none
           nounGroups = no
           reducef    = 2
           language   = "korean"
           outterms   = caslib.terms
           outparent  = caslib.parent;
    svd    k          = 200
           outdocpro  = caslib.docpro;
run;

  SVD 200차원 문서 점수(caslib.docpro의 COL1~COL200)를 PROC LOGISTIC 입력으로
  쓴다. 120,000개 희소 특징을 SAS에서 그대로 다루는 것보다 훨씬 가볍다.

proc logistic data=caslib.docpro;
    model target(event='1') = COL1-COL200;
run;
*/


/*===========================================================================
  경로 B — DATA step 문자 n-gram
  언어 지원 없이 동작한다. K 함수로 글자 단위를 보장한다.
===========================================================================*/

/* 선행 조건: 01_load_and_audit.sas가 같은 세션에서 먼저 실행돼야 한다. */
%macro require(dsname);
    %if not %sysfunc(exist(&dsname.)) %then %do;
        %put ERROR: &dsname. 이(가) 없습니다. 01_load_and_audit.sas를 먼저 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%require(work.msgtext);

%let ngram_min = 3;
%let ngram_max = 5;

/* 어휘 크기. 학습 행이 12,100건이므로 특징 수가 그에 근접하면 HPLOGISTIC이
   거의 포화 적합이 되어 수렴이 불안정해진다. 1,500에서 시작해 필요하면
   올린다. 5,000은 n/p 비율이 2.4에 불과해 권하지 않는다. */
%let vocab_size = 1500;

/*--- 1. 문서를 문자 n-gram으로 분해 --------------------------------------
  행이 크게 늘어난다. 16,773개 메시지, 본문 중앙값 약 30자, 최대 약 1,800자에
  n을 3~5로 돌리므로 대략 600만~1,000만 행이 나온다. WORK 라이브러리 공간이
  부족하면 여기서 실패하므로, 처음 실행할 때는 obs= 로 일부만 돌려 확인한다.
    예) set work.msgtext(obs=500);
-------------------------------------------------------------------------*/
data work.ngrams(keep=message_id split target gram);
    set work.msgtext;
    length gram $30;                      /* 한글 5글자 = 15바이트 + 여유 */
    _len = klength(text_normalized);      /* ★ length()가 아니라 klength() */
    do n = &ngram_min. to &ngram_max.;
        do i = 1 to _len - n + 1;
            gram = ksubstr(text_normalized, i, n);   /* ★ substr 아님 */
            if not missing(gram) then output;
        end;
    end;
run;

/*--- 2. 문서빈도로 어휘 축소 ---------------------------------------------
  Python은 min_df=2, max_features=120000을 썼다. SAS에서는 희소 행렬을 그대로
  다루기 무거우므로 더 공격적으로 줄인다.
-------------------------------------------------------------------------*/
proc sql;
    create table work.gram_df as
    select gram, count(distinct message_id) as df
    from work.ngrams
    where split = 'train'
    group by gram
    having calculated df >= 5
    order by df desc;
quit;

data work.vocab;
    set work.gram_df(obs=&vocab_size.);
    gram_id = _n_;
run;

/*--- 3. TF-IDF 계산 ------------------------------------------------------*/
proc sql noprint;
    select count(distinct message_id) into :n_docs trimmed
    from work.ngrams where split = 'train';
quit;

proc sql;
    create table work.tf as
    select a.message_id, a.split, a.target, b.gram_id, b.df,
           count(*) as tf
    from work.ngrams as a
         inner join work.vocab as b
         on a.gram = b.gram
    group by a.message_id, a.split, a.target, b.gram_id, b.df;
quit;

data work.tfidf;
    set work.tf;
    /* Python은 sublinear_tf=True를 썼다: 1 + log(tf) */
    weight = (1 + log(tf)) * log(&n_docs. / df);
run;

/*--- 4. 문서×특징 행렬로 전치 -------------------------------------------
  PROC TRANSPOSE의 BY는 정렬된 입력을 요구한다. PROC SQL의 GROUP BY가 정렬된
  결과를 주는 것은 구현 부수효과일 뿐 보장이 아니므로 명시적으로 정렬한다.
  이걸 빼면 "BY variables are not properly sorted"로 죽는다.
-------------------------------------------------------------------------*/
proc sort data=work.tfidf; by message_id split target gram_id; run;

proc transpose data=work.tfidf out=work.docterm_hit(drop=_name_) prefix=g;
    by message_id split target;
    id gram_id;
    var weight;
run;

/*  어휘에 하나도 걸리지 않은 메시지는 work.tf에서 아예 빠져 여기까지 오지
    못한다. 그대로 두면 test 행이 조용히 사라져 평가 표본이 달라진다.
    전체 메시지 목록에 병합해 되살리고, 결측 특징은 0으로 채운다.

    SQL 좌결합 대신 MERGE를 쓰는 이유: 양쪽에 message_id/split/target이 모두
    있어 `b.*`가 이름 충돌을 일으킨다. 결합 키는 dataset 옵션으로 뺄 수도 없다.  */
proc sort data=work.docterm_hit; by message_id; run;

proc sort data=work.msgtext(keep=message_id split target)
          out=work.msgkeys;
    by message_id;
run;

data work.docterm;
    merge work.msgkeys(in=inall)
          work.docterm_hit(in=inhit drop=split target);
    by message_id;
    if inall;
    has_features = inhit;
    array g[*] g:;
    do i = 1 to dim(g);
        if missing(g[i]) then g[i] = 0;
    end;
    drop i;
run;

title "특징이 하나도 걸리지 않은 메시지 수 (분할별)";
proc sql;
    select split,
           count(*)                as rows,
           sum(1 - has_features)   as no_feature_rows
    from work.docterm
    group by split;
quit;

/*--- 5. 로지스틱 회귀 ----------------------------------------------------
  고차원이므로 PROC HPLOGISTIC이 PROC LOGISTIC보다 적합하다.

  적합은 train에서만 하고 채점은 전 분할에 해야 한다. WHERE 절은 프로시저
  전체에 걸리므로 OUTPUT 문만으로는 train 예측밖에 나오지 않는다.
  CODE 문으로 점수 코드를 뽑아 DATA 스텝에서 모든 행에 적용한다.
-------------------------------------------------------------------------*/
filename sascode temp;

title "문자 n-gram 로지스틱 회귀 (train 적합)";
proc hplogistic data=work.docterm;
    where split = 'train';
    model target(event='1') = g:;
    code file=sascode;
run;

data work.text_pred;
    set work.docterm;
    %include sascode;
    /* HPLOGISTIC이 만드는 예측 확률 변수명은 P_target1이다.
       버전에 따라 다르면 로그의 CODE 블록을 열어 실제 이름을 확인한다. */
    sas_text_probability = P_target1;
run;

filename sascode clear;

title "SAS 문자 n-gram 모델 — 분할별 평균 예측확률";
proc means data=work.text_pred mean n;
    class split target;
    var sas_text_probability;
run;

title;

/*
  Python 결과와 대조할 때 유의할 점

  - 어휘 크기가 다르다(Python 120,000 대 SAS 5,000). 성능이 낮게 나오는 것이
    정상이며, 같은 수치를 재현하는 것이 목적이 아니다.
  - Python은 class_weight='balanced'를 썼다. SAS에서 동일 효과가 필요하면
    가중치 변수를 만들어 weight 문에 준다.
  - 정규화가 다르다. sklearn LogisticRegression은 기본으로 L2 규제가 걸려 있고
    PROC HPLOGISTIC은 기본이 무규제다. 필요하면 SELECTION= 옵션을 검토한다.
  - 최종 보고에는 SAS와 Python 중 하나의 수치만 쓰고, 다른 쪽은 교차 확인용으로
    남긴다. 두 수치를 섞어 제시하지 않는다.
*/
