/*---------------------------------------------------------------------------
  ScamLens 02 — 문자·URL 결합 메타 분류기 (PROC LOGISTIC)

  Python의 scikit-learn 메타 분류기를 SAS로 다시 적합한다. 목적은 같은 계수를
  얻는 것이 아니라 sklearn이 주지 않는 것을 얻는 것이다.

    - 계수의 표준오차, Wald 검정, p-value
    - 오즈비와 95% 신뢰구간
    - 모형 적합도 검정

  train에는 행 ID·그룹·폴드·입력/모델 해시를 검증한 OOF 확률만 사용한다.
  저장 OOF가 없으면 고정된 기존 프로토콜로 train에서만 재생성할 수 있다.
  이 경우 provenance는 reconstructed_fixed_protocol이며 과거 학습 당시 저장된
  OOF 확률을 복구했다고 주장하지 않는다. OOF가 없거나 검증되지 않으면 중단한다.

  이 적합은 무가중·무규제 최대우도 추론 모형이다. Python 채택 모형은
  class_weight='balanced'인 규제 로지스틱이므로 같은 OOF 입력이어도 추정량이
  다르다. SAS Wald 검정을 Python 채택 모형 계수의 p-value로 해석하지 않는다.
  URL 두 변수의 공동 검정과 효과 크기·신뢰구간을 함께 보고한다.
  비유의한 결과는 무기여나 동등성의 증명이 아니다.
  표준 Wald 구간은 입력 점수를 고정한 조건부 탐색 결과이며 교차적합의 공유
  모형·유사 문구 의존성 및 기준 모델 재학습 불확실성 전체를 반영하지 않는다.

  임계값 정책은 Python과 동일하다. validation에서만 고르고 test는 1회 평가한다.

  선행 조건: 01_load_and_audit.sas를 같은 세션에서 먼저 실행해야 한다.
  work.scores가 없으면 여기서 멈춘다.
---------------------------------------------------------------------------*/

%let minimum_recall = 0.95;

%macro require(dsname);
    %if not %sysfunc(exist(&dsname.)) %then %do;
        %put ERROR: &dsname. 이(가) 없습니다. 01_load_and_audit.sas를 먼저 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%require(work.scores);
%let sas_meta_fit_completed = 0;

/* 이전 실행 결과가 이번 입력의 결과처럼 재사용되지 않도록 먼저 제거한다. */
proc datasets library=work nolist;
    delete metamodel scored test_scored meta_convergence;
quit;

%macro require_verified_oof;
    %local dsid rc name index bad_rows train_rows;
    %let dsid = %sysfunc(open(work.scores));
    %do index=1 %to 5;
        %let name=%scan(text_probability_meta_input text_probability_oof
                        oof_fold_id sas_meta_fit_eligible similarity_group_id,&index.);
        %if %sysfunc(varnum(&dsid.,&name.)) = 0 %then %do;
            %let rc=%sysfunc(close(&dsid.));
            %put ERROR: Missing verified OOF column &name.. Re-export with export_for_sas.py.;
            %abort cancel;
        %end;
    %end;
    %let rc=%sysfunc(close(&dsid.));
    proc sql noprint;
        select count(*) into :train_rows trimmed from work.scores where split='train';
        select count(*) into :bad_rows trimmed from work.scores
        where sas_meta_fit_eligible ne 1
           or missing(text_probability_meta_input)
           or text_probability_meta_input < 0 or text_probability_meta_input > 1
           or (split='train' and
               (missing(text_probability_oof) or missing(oof_fold_id)
                or text_probability_meta_input ne text_probability_oof));
    quit;
    %if &train_rows.=0 or &bad_rows.>0 %then %do;
        %put ERROR: SAS 02 blocked: OOF training inputs are missing or unverified.;
        %put ERROR- In-sample text_probability must never be used as a fallback.;
        %put ERROR- Verify/reconstruct train OOF artifacts and run export_for_sas.py.;
        %abort cancel;
    %end;
%mend;
%require_verified_oof;


/*--- 1. train 분할로 메타 분류기 적합 ------------------------------------
  event='1'을 반드시 쓴다. PROC LOGISTIC은 기본적으로 낮은 순서값(=0)의 확률을
  모형화하므로, 생략하면 부호가 전부 뒤집힌 모형을 얻는다.
-------------------------------------------------------------------------*/
title "OOF 특징 기반 SAS 추론용 메타 회귀 — Python 규제 모형과 별도";
ods output ParameterEstimates=work.meta_parameters
           OddsRatios=work.meta_odds_ratios
           CLOddsWald=work.meta_odds_ci
           TestStmts=work.meta_url_block_test
           FitStatistics=work.meta_fit_statistics
           ConvergenceStatus=work.meta_convergence;
proc logistic data=work.scores outmodel=work.metamodel;
    where split = 'train';
    model target(event='1') = text_probability_meta_input
                              url_probability_filled
                              has_url
          / clodds=wald;
    URL_Block: test url_probability_filled=0, has_url=0;
run;
ods output close;

%require(work.meta_convergence);
data _null_;
    set work.meta_convergence;
    if status ne 0 then do;
        put "ERROR: SAS meta regression did not converge. Do not report Wald inference.";
        abort cancel;
    end;
run;


/*--- 2. validation·test 채점 --------------------------------------------*/
proc logistic inmodel=work.metamodel;
    score data=work.scores out=work.scored(rename=(P_1=meta_probability));
run;

data work.scored;
    set work.scored;
    /* 비교용 고정 가중치 결합: URL이 없으면 텍스트 확률을 그대로 쓴다. */
    fixed_fusion = fixed_fusion_probability;
run;


/*--- 3. validation에서 임계값 선택 ---------------------------------------
  Recall >= 0.95를 만족하는 임계값 중 FPR이 가장 낮은 값을 고른다.
  Python의 select_threshold와 같은 규칙이다.
-------------------------------------------------------------------------*/
data work.grid;
    set work.scored(where=(split='validation'));
    do threshold_index = 0 to 180;
        threshold = 0.05 + threshold_index * 0.005;
        predicted = (meta_probability >= threshold);
        output;
    end;
run;

proc sql;
    create table work.threshold_stats as
    select threshold,
           sum(case when target=1 and predicted=1 then 1 else 0 end) as tp,
           sum(case when target=0 and predicted=1 then 1 else 0 end) as fp,
           sum(case when target=1 and predicted=0 then 1 else 0 end) as fn,
           sum(case when target=0 and predicted=0 then 1 else 0 end) as tn
    from work.grid
    group by threshold;
quit;

data work.threshold_stats;
    set work.threshold_stats;
    recall    = tp / max(tp + fn, 1);
    precision = tp / max(tp + fp, 1);
    fpr       = fp / max(fp + tn, 1);
run;

/* 제약을 만족하는 임계값이 하나도 없으면 매크로 변수가 만들어지지 않고,
   이후 &meta_threshold. 참조가 해석되지 않은 채 이상한 오류를 낸다.
   개수를 먼저 세서 원인이 드러나는 자리에서 멈춘다. */
proc sql noprint;
    select count(*) into :qualifying trimmed
    from work.threshold_stats
    where recall >= &minimum_recall.;
quit;

%macro pick_threshold;
    %if &qualifying. = 0 %then %do;
        %put ERROR: validation에서 Recall >= &minimum_recall. 을 만족하는 임계값이 없습니다.;
        %put ERROR- 모형/입력 적합을 확인하십시오. test를 보고 제약을 낮추지 마십시오.;
        %abort cancel;
    %end;
    proc sql noprint outobs=1;
        select threshold into :meta_threshold trimmed
        from work.threshold_stats
        where recall >= &minimum_recall.
        order by fpr, precision desc, threshold desc;
    quit;
%mend;
%pick_threshold;

%put NOTE: validation에서 선택한 메타 임계값 = &meta_threshold.;

title "선택된 임계값의 validation 성능";
proc print data=work.threshold_stats noobs;
    where abs(threshold - &meta_threshold.) < 1e-8;
    var threshold recall precision fpr tp fp fn tn;
run;


/*--- 4. test 1회 평가 ----------------------------------------------------*/
data work.test_scored;
    set work.scored;
    where split = 'test';
    length url_group $12;
    meta_predicted = (meta_probability >= &meta_threshold.);
    if has_url = 1 then url_group = 'URL 있음';
    else                url_group = 'URL 없음';
run;

title "메타 분류기 test 혼동행렬";
proc freq data=work.test_scored;
    tables target*meta_predicted / nocol norow nopercent;
run;

title "메타 분류기 test 혼동행렬 — URL 유무별";
proc freq data=work.test_scored;
    tables url_group*target*meta_predicted / nocol norow nopercent;
run;

%let sas_meta_fit_completed = 1;
title;
