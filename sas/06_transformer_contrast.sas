/*---------------------------------------------------------------------------
  ScamLens 06 — 트랜스포머·반사실 학습 모델의 통계 비교

  기존 Python의 짝지은 성능 비교에 같은 평가 행의 ROC-AUC 비교를 추가한다.

    1. KcBERT vs 문자 n-gram — AUC 차이의 DeLong 검정
    2. 반사실 학습 전후 — 같은 검정
    3. 온도 보정이 순위를 바꾸지 않았는지 확인 (단조 변환이므로 AUC 동일해야 함)
    4. 공격 유형별 재현율과 exact 신뢰구간

  선행 조건
    - 01_load_and_audit.sas 실행 (work.scores)
    - export_for_sas.py 를 KcBERT 학습 이후에 다시 실행했을 것

  중요: KcBERT 확률은 validation·test에만 있다. 미세조정 스크립트가 그 두
  분할만 저장하기 때문이며 결손이 아니다. train 행은 결측이므로 이 프로그램은
  test에서만 동작한다.
---------------------------------------------------------------------------*/

%macro require_columns;
    %local dsid rc missing;
    %let dsid = %sysfunc(open(work.scores));
    %if &dsid. = 0 %then %do;
        %put ERROR: work.scores 가 없습니다. 01_load_and_audit.sas 를 먼저 실행하십시오.;
        %abort cancel;
    %end;
    %let missing =;
    %if %sysfunc(varnum(&dsid., kcbert_probability)) = 0 %then
        %let missing = &missing. kcbert_probability;
    %if %sysfunc(varnum(&dsid., kcbert_cf_probability)) = 0 %then
        %let missing = &missing. kcbert_cf_probability;
    %if %sysfunc(varnum(&dsid., linear_cf_probability)) = 0 %then
        %let missing = &missing. linear_cf_probability;
    %let rc = %sysfunc(close(&dsid.));
    %if %length(&missing.) %then %do;
        %put ERROR: 다음 컬럼이 없습니다:&missing.;
        %put ERROR- KcBERT 학습 후 export_for_sas.py --overwrite 를 다시 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%require_columns;


/*--- 0. 비교용 test 테이블 ----------------------------------------------*/
data work.contrast;
    set work.scores;
    where split = 'test' and not missing(kcbert_probability);
    length url_group $12;
    if has_url = 1 then url_group = 'URL 있음';
    else                url_group = 'URL 없음';
run;

title "비교 대상 행 수 — 입력 manifest 및 모델 결측과 대조";
proc sql;
    select count(*) as rows, sum(target) as malicious, sum(has_url) as url_rows
    from work.contrast;
quit;


/*--- 1. KcBERT vs 문자 n-gram — DeLong 검정 -----------------------------
  기존 수치는 reports/generated/model_comparison.json을 따른다.
  DeLong은 ROC-AUC 차이만 다룬다. 비유의는 효과 부재·동등성·미채택의
  단독 근거가 아니며 F1/Recall의 기존 비교 결과와 혼동하지 않는다.
-------------------------------------------------------------------------*/
title "test 전체 — 문자 n-gram vs KcBERT vs 반사실 학습";
proc logistic data=work.contrast plots=roc;
    model target(event='1') = / nofit;
    roc '문자 n-gram'       pred = text_probability;
    roc 'KcBERT'            pred = kcbert_probability;
    roc 'KcBERT 반사실'     pred = kcbert_cf_probability;
    roc '문자 n-gram 반사실' pred = linear_cf_probability;
    roccontrast reference('문자 n-gram') / estimate=allpairs e;
run;


/*--- 2. URL 없는 구간에서의 비교 ----------------------------------------
  이 프로젝트가 실제로 신경 쓰는 구간이다. 표본이 정상 1,367 + 악성 54라
  악성 쪽 검정력이 매우 낮다. 유의하지 않다는 결과를 "차이 없음"으로 읽지 않는다.
-------------------------------------------------------------------------*/
title "test — URL 없는 문자만";
proc logistic data=work.contrast plots=roc;
    where has_url = 0;
    model target(event='1') = / nofit;
    roc '문자 n-gram'   pred = text_probability;
    roc 'KcBERT'        pred = kcbert_probability;
    roc 'KcBERT 반사실' pred = kcbert_cf_probability;
    roccontrast reference('문자 n-gram') / estimate=allpairs e;
run;


/*--- 3. 온도 보정이 순위를 보존했는지 -----------------------------------
  온도 스케일링은 sigmoid(logit(p)/T)로 단조 증가 변환이다. 따라서 AUC는
  정의상 바뀌지 않아야 한다. 여기서 차이가 나오면 보정 구현에 버그가 있다는
  뜻이므로, 이 검정은 성능 비교가 아니라 구현 검증이다.
-------------------------------------------------------------------------*/
title "온도 보정 전후 AUC — 같아야 한다 (구현 검증)";
proc logistic data=work.contrast plots=none;
    model target(event='1') = / nofit;
    roc 'KcBERT 원본'   pred = kcbert_probability;
    roc 'KcBERT 보정후' pred = kcbert_calibrated_probability;
    roccontrast reference('KcBERT 원본') / estimate e;
run;


/*--- 4. 공격 유형별 재현율 ----------------------------------------------
  attack_type 은 URL 없는 악성 380건에만 값이 있다. 그 안에서 "URL 없는 악성"이
  단일 현상이 아님을 SAS에서 재확인한다.

  임계값은 각 모델이 validation에서 고른 값이다. 바꾸지 않는다.
-------------------------------------------------------------------------*/
%let kcbert_threshold    = 0.95;
%let kcbert_cf_threshold = 0.195;
%let linear_cf_threshold = 0.400;

data work.by_attack;
    set work.contrast;
    where target = 1 and has_url = 0 and not missing(attack_type)
          and attack_type ne '';
    hit_text      = (text_probability      >= &text_threshold.);
    hit_kcbert    = (kcbert_probability    >= &kcbert_threshold.);
    hit_kcbert_cf = (kcbert_cf_probability >= &kcbert_cf_threshold.);
    hit_linear_cf = (linear_cf_probability >= &linear_cf_threshold.);
run;

proc sort data=work.by_attack; by attack_type; run;

title "공격 유형별 표본 수 — 유형당 표본이 매우 작다";
proc freq data=work.by_attack;
    tables attack_type / nocum;
run;

proc sql;
    create table work.attack_detection as
    select attack_type,
           count(*) as n,
           sum(hit_text) as hits_text,
           sum(hit_kcbert) as hits_kcbert
    from work.by_attack
    group by attack_type;
quit;

data work.attack_detection_ci;
    set work.attack_detection;
    array hits[2] hits_text hits_kcbert;
    length model $20;

    do model_index=1 to 2;
        if model_index=1 then model='문자 n-gram';
        else model='KcBERT';

        detected=hits[model_index];
        detection_rate=detected/n;

        if detected=0 then lower_95=0;
        else lower_95=quantile(
            'BETA', 0.025, detected, n-detected+1
        );

        if detected=n then upper_95=1;
        else upper_95=quantile(
            'BETA', 0.975, detected+1, n-detected
        );

        output;
    end;

    keep attack_type model n detected
         detection_rate lower_95 upper_95;
    format detection_rate lower_95 upper_95 percent8.2;
run;

title "공격 유형별 탐지율과 exact 95% 신뢰구간";
proc print data=work.attack_detection_ci noobs;
run;

/*
  결과 읽는 법

  유형당 표본이 3~25건이라 신뢰구간이 매우 넓다. 이것이 이 표의 핵심 메시지다.
  "메신저피싱 100%"는 14건 중 14건이라는 뜻이고 exact 하한은 76.8%다.
  발표에서는 점추정 대신 하한을 말한다.

  수사·사법기관 사칭은 테스트에 0건이라 표에 아예 나타나지 않는다. 이 공백이
  다음 데이터 수집의 1순위다.
*/

title;
