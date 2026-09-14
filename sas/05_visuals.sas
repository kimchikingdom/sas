/*---------------------------------------------------------------------------
  ScamLens 05 — 결과 시각화 (PROC SGPLOT)

  보고서·발표용 그림을 만든다. 대시보드를 SAS Visual Analytics로 대체할 경우
  같은 테이블(work.test_scored)을 VA 데이터 소스로 올려 쓰면 된다.

  ★ 안전 원칙 ★
  어떤 그림에도 URL을 클릭 가능한 형태로 노출하지 않는다. 원문 메시지도
  출력하지 않는다. 이 프로그램은 집계값과 확률만 다룬다.
---------------------------------------------------------------------------*/

/* 선행 조건: 01(work.scores, &text_threshold.). 메타 곡선은 02 성공 시에만 추가. */
%macro require_prereqs;
    %local missing;
    %if not %sysfunc(exist(work.scores)) %then %let missing=work.scores;
    %if not %symexist(text_threshold) %then %let missing=&missing. macro:text_threshold;
    %if %length(&missing.) %then %do;
        %put ERROR: 선행 산출물이 없습니다: &missing.;
        %put ERROR- 01_load_and_audit.sas를 먼저 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%require_prereqs;

ods graphics on / width=900px height=600px;

/*--- 1. URL 유무별 오탐률 ------------------------------------------------
  프로젝트의 핵심 발견을 한 장으로 보여주는 그림이다.
-------------------------------------------------------------------------*/
proc sql;
    create table work.fpr_by_url as
    select case when has_url = 1 then 'URL 있음' else 'URL 없음' end as url_group,
           sum(case when text_probability >= &text_threshold. then 1 else 0 end)
               / count(*) as fpr format=percent8.2,
           count(*) as normal_rows
    from work.scores
    where split = 'test' and target = 0
    group by calculated url_group;
quit;

title "URL 유무별 정상 문자 오탐률";
proc sgplot data=work.fpr_by_url;
    vbar url_group / response=fpr datalabel;
    yaxis label="False Positive Rate" valuesformat=percent8.1;
    xaxis label="정상 문자 구간";
run;

/*--- 2. URL 유무별 미탐률 ------------------------------------------------*/
proc sql;
    create table work.fnr_by_url as
    select case when has_url = 1 then 'URL 있음' else 'URL 없음' end as url_group,
           sum(case when text_probability < &text_threshold. then 1 else 0 end)
               / count(*) as fnr format=percent8.2,
           count(*) as malicious_rows
    from work.scores
    where split = 'test' and target = 1
    group by calculated url_group;
quit;

title "URL 유무별 악성 문자 미탐률";
proc sgplot data=work.fnr_by_url;
    vbar url_group / response=fnr datalabel;
    yaxis label="False Negative Rate" valuesformat=percent8.1;
    xaxis label="악성 문자 구간";
run;

/*--- 3. 확률 분포 --------------------------------------------------------
  정상과 악성의 예측확률이 임계값을 기준으로 어떻게 겹치는지 본다.
-------------------------------------------------------------------------*/
data work.dist;
    set work.scores;
    where split = 'test';
    length label_kr $8;
    if target = 1 then label_kr = '악성';
    else               label_kr = '정상';
run;

title "예측확률 분포와 임계값";
proc sgplot data=work.dist;
    histogram text_probability / group=label_kr transparency=0.4 binwidth=0.02;
    refline &text_threshold. / axis=x lineattrs=(pattern=dash thickness=2)
            label="임계값 &text_threshold." labelloc=inside;
    xaxis label="문자 모델 예측확률";
    yaxis label="비율";
run;

/*--- 4. ROC 곡선 비교 ----------------------------------------------------
  03 프로그램의 ROCCONTRAST가 그림도 함께 만들지만, 발표용으로 세 모델을
  한 축에 겹쳐 그린다.
-------------------------------------------------------------------------*/
data work.visual_roc;
    set work.scores;
    where split='test';
    fixed_fusion=fixed_fusion_probability;
run;
%global include_visual_meta;
%let include_visual_meta=0;
%macro add_visual_meta;
    %if %symexist(sas_meta_fit_completed) %then %do;
        %if &sas_meta_fit_completed.=1 and %sysfunc(exist(work.test_scored)) %then %do;
            proc sql;
                create table work.visual_roc_joined as
                select a.*, b.meta_probability
                from work.visual_roc as a left join work.test_scored as b
                on a.message_id=b.message_id;
            quit;
            data work.visual_roc; set work.visual_roc_joined; run;
            %let include_visual_meta=1;
        %end;
    %end;
%mend;
%add_visual_meta;
%macro optional_meta_curve;
    %if &include_visual_meta.=1 %then %do;
            roc 'SAS OOF 메타' pred=meta_probability;
    %end;
%mend;
title "ROC 곡선 — 기존 평가 점수 비교";
proc logistic data=work.visual_roc plots(only)=roc;
    model target(event='1') = / nofit;
    roc '문자 단독'     pred = text_probability;
    roc '고정가중 결합' pred = fixed_fusion;
    %optional_meta_curve;
run;

/*--- 5. 난독화 강건성 ----------------------------------------------------
  scripts/export_sas_support.py가 robustness_evaluation.json에서 생성한다.
  수기 숫자를 넣지 않으며 전처리 전후를 별도 패널로 보인다.
-------------------------------------------------------------------------*/
proc import datafile="&projroot./data/processed/sas/sas_robustness.csv"
    out=work.robustness dbms=csv replace;
    guessingrows=max;
run;
title "난독화 변형별 악성 Recall — 저장된 Python 평가";
proc sgpanel data=work.robustness;
    panelby stage / columns=1;
    vbar variant / response=recall group=model groupdisplay=cluster;
    rowaxis label="Recall" values=(0 to 1 by 0.1);
    colaxis label="변형";
run;

title;
ods graphics off;
