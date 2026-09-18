/*---------------------------------------------------------------------------
  ScamLens 14 — KcBERT 15-Arm 시각화 및 ODS 보고서 생성 (PROC SGPLOT / SGPANEL)

  프로젝트: ScamLens (안심문자 탐지 및 난독화 강건성 연구)
  작성일: 2026-09-18
  목적: Matched Control 15조건 실험(DUP, FLIP, BASE 각 5 Seeds),
        Brier Score 불확실성, 하위집단(URL 유무), 4대 오류 전이 분석 결과를
        SAS Studio 및 Viya Compute 세션에서 고해상도 그래픽스와 함께 시각화한다.

  ★ 안전 및 보안 원칙 ★
  1. 원문 메시지 텍스트나 개인식별정보(PII)는 일체 포함하지 않는다.
  2. 철저히 사전 검증된 오프라인 집계 데이터(CSV)만을 입력으로 사용한다.
  3. 모든 수치는 reports/generated/ 의 정본 결과와 100% 일치한다.
---------------------------------------------------------------------------*/

/* 1. 기본 경로 매크로 변수 설정 (자동 감지 및 오버라이드 지원) */
%macro init_paths;
  %global projroot sasdata outdir;
  %if not %symexist(projroot) %then %do;
    %if %sysfunc(fileexist(/Users/sangwoolee/sas/sas/data/processed/sas/sas_kcbert_15arms.csv)) %then %do;
      %let projroot=/Users/sangwoolee/sas/sas;
    %end;
    %else %if %sysfunc(fileexist(/Users/sangwoolee/dataproj/data/processed/sas/sas_kcbert_15arms.csv)) %then %do;
      %let projroot=/Users/sangwoolee/dataproj;
    %end;
    %else %do;
      %let projroot=.;
    %end;
  %end;
  %let sasdata=&projroot./data/processed/sas;
  %let outdir=&projroot./outputs/sas_kcbert_visuals;
%mend init_paths;
%init_paths;

/* 출력 폴더 확인 및 생성 */
data _null_;
  length created $1024;
  if not fileexist("&projroot./outputs") then created=dcreate('outputs',"&projroot.");
  if not fileexist("&outdir.") then created=dcreate('sas_kcbert_visuals',"&projroot./outputs");
run;

/* 2. 필수 CSV 입력 파일 존재 여부 검사 */
%macro check_inputs;
  %local missing;
  %let missing=;
  %if not %sysfunc(fileexist(&sasdata./sas_kcbert_15arms.csv)) %then
    %let missing=&missing. sas_kcbert_15arms.csv;
  %if not %sysfunc(fileexist(&sasdata./sas_kcbert_arm_summary.csv)) %then
    %let missing=&missing. sas_kcbert_arm_summary.csv;
  %if not %sysfunc(fileexist(&sasdata./sas_kcbert_subgroup_url.csv)) %then
    %let missing=&missing. sas_kcbert_subgroup_url.csv;
  %if not %sysfunc(fileexist(&sasdata./sas_kcbert_transitions.csv)) %then
    %let missing=&missing. sas_kcbert_transitions.csv;
  %if not %sysfunc(fileexist(&sasdata./sas_kcbert_top_uncertain.csv)) %then
    %let missing=&missing. sas_kcbert_top_uncertain.csv;

  %if %length(&missing.) > 0 %then %do;
    %put ERROR: 다음 필수 CSV 파일이 없습니다: &missing.;
    %abort cancel;
  %end;
%mend check_inputs;
%check_inputs;

/* 3. CSV 데이터 로드 (PROC IMPORT) */
proc import datafile="&sasdata./sas_kcbert_15arms.csv"
  out=work.kcbert_15arms dbms=csv replace;
  guessingrows=max;
run;

proc import datafile="&sasdata./sas_kcbert_arm_summary.csv"
  out=work.kcbert_arm_summary dbms=csv replace;
  guessingrows=max;
run;

proc import datafile="&sasdata./sas_kcbert_subgroup_url.csv"
  out=work.kcbert_subgroup_url dbms=csv replace;
  guessingrows=max;
run;

proc import datafile="&sasdata./sas_kcbert_transitions.csv"
  out=work.kcbert_transitions dbms=csv replace;
  guessingrows=max;
run;

proc import datafile="&sasdata./sas_kcbert_top_uncertain.csv"
  out=work.kcbert_top_uncertain dbms=csv replace;
  guessingrows=max;
run;

/* 4. 포맷 및 라벨 정의 */
proc format;
  value $armkr
    'DUP'  = '중복제거 (DUP)'
    'FLIP' = '난독화반전 (FLIP)'
    'BASE' = '기본모델 (BASE)';

  value $urlgrp
    'URL_NO'  = 'URL 미포함 문자'
    'URL_YES' = 'URL 포함 문자';

  value $transkr
    'resolved_fp' = '정상 오탐 해소'
    'lost_tp'     = '악성 정탐 손실'
    'new_fp'      = '신규 정상 오탐'
    'rescued_fn'  = '악성 미탐 구제';
run;

/* 데이터셋에 라벨 및 포맷 적용 */
data work.kcbert_15arms;
  set work.kcbert_15arms;
  format arm $armkr. recall fpr f1 percent8.2 brier_score 8.5 threshold 8.4;
  label arm='실험 조건(Arm)' seed='난수 시드' threshold='최적 임계값'
        recall='재현율 (Recall)' fpr='오탐률 (FPR)' f1='F1 점수'
        brier_score='Brier 점수' total_n='평가 건수';
run;

data work.kcbert_subgroup_url;
  set work.kcbert_subgroup_url;
  format arm $armkr. url_group $urlgrp. recall fpr f1 percent8.2;
  label arm='실험 조건(Arm)' url_group='URL 포함 여부'
        recall='재현율 (Recall)' fpr='오탐률 (FPR)' f1='F1 점수';
run;

data work.kcbert_transitions;
  set work.kcbert_transitions;
  format url_1_ratio percent8.1;
  label transition_name_kr='오류 전이 유형'
        total_count='발생 건수'
        unique_messages='고유 메시지 수'
        url_1_ratio='URL 포함 비율'
        net_effect='순효과 구분';
run;

/* 5. ODS 리포트 시작 (HTML 및 고해상도 그래픽스) */
ods html path="&outdir." file="scamlens_kcbert_visuals_report.html" style=Plateau;
ods graphics on / reset=all width=960px height=580px outputfmt=png imagename="scamlens_kcbert";

/*---------------------------------------------------------------------------
  차트 1: 15-Arm FPR vs Recall 트레이드오프 산점도 (핵심 결론)
  - X축: 오탐률(FPR), Y축: 재현율(Recall)
  - FPR 1.0% 규제 상한선 표시
  - FLIP 조건(녹색 계열)의 안전성 및 파레토 최적 입증
---------------------------------------------------------------------------*/
title1 "ScamLens KcBERT 15개 조건 성능 트레이드오프 (Recall vs FPR)";
title2 "5개 시드(42, 101, 202, 303, 404)별 FPR 1.0% 규제 상한 준수 여부";
proc sgplot data=work.kcbert_15arms;
  scatter x=fpr y=recall / group=arm markerattrs=(size=12) filledoutlinedmarkers
          datalabel=seed datalabelattrs=(size=9 weight=bold)
          name="scatter_arms";
  refline 0.01 / axis=x lineattrs=(pattern=dash color=crimson thickness=2)
          label="FPR 1.0% 규제 상한선" labelloc=inside;
  xaxis label="오탐률 (False Positive Rate)" valuesformat=percent8.2
        grid min=0.002 max=0.014;
  yaxis label="재현율 (Recall)" valuesformat=percent8.1
        grid min=0.93 max=0.99;
  keylegend "scatter_arms" / title="실험 조건" location=outside position=bottom;
run;

/*---------------------------------------------------------------------------
  차트 2: Arm별 오탐률(FPR) 및 재현율(Recall) 분포 박스플롯
  - 조건별 중앙값 및 시드 간 변동성(안정성) 비교
---------------------------------------------------------------------------*/
title1 "실험 조건(Arm)별 오탐률(FPR) 분포 비교";
title2 "FLIP 조건의 일관된 낮은 오탐률 및 낮은 편차 입증";
proc sgplot data=work.kcbert_15arms;
  vbox fpr / category=arm fillattrs=(transparency=0.3)
             boxwidth=0.45 datalabel;
  refline 0.01 / axis=y lineattrs=(pattern=dash color=crimson thickness=2)
          label="FPR 1.0% 기준";
  yaxis label="False Positive Rate" valuesformat=percent8.2 grid;
  xaxis label="실험 조건 (Arm)";
run;

title1 "실험 조건(Arm)별 재현율(Recall) 분포 비교";
title2 "96% 이상의 고성능 재현율 유지 상태 검증";
proc sgplot data=work.kcbert_15arms;
  vbox recall / category=arm fillattrs=(transparency=0.3)
              boxwidth=0.45 datalabel;
  yaxis label="Recall" valuesformat=percent8.1 grid;
  xaxis label="실험 조건 (Arm)";
run;

/*---------------------------------------------------------------------------
  차트 3: URL 유무에 따른 하위집단 오탐률(FPR) 패널 분석
  - 정상 문자에 URL이 포함되었을 때 모델이 오탐하는 취약점 분석
  - FLIP의 URL 편향 해소 효과를 명확히 입증
---------------------------------------------------------------------------*/
title1 "URL 유무별 하위집단 오탐률(FPR) 비교 (SGPANEL)";
title2 "URL 포함 시 DUP의 오탐률 급증(약 3.0%) 대비 FLIP의 강력한 방어력(0.6%)";
proc sgpanel data=work.kcbert_subgroup_url;
  panelby url_group / columns=2 spacing=10 novarname;
  vbar arm / response=fpr group=arm stat=mean limits=both
             datalabel datalabelattrs=(size=9 weight=bold);
  rowaxis label="평균 오탐률 (Mean FPR)" valuesformat=percent8.2 grid;
  colaxis label="실험 조건";
run;

/*---------------------------------------------------------------------------
  차트 4: 모델별 Brier Score 불확실성 및 보정(Calibration) 오차
  - Brier 점수는 낮을수록 확률 추정 신뢰도가 높음을 의미
  - FLIP(0.01158)이 가장 우수한 보정 성능을 보임
---------------------------------------------------------------------------*/
title1 "실험 조건별 Brier Score 및 확률 보정(Calibration) 오차";
title2 "Brier 점수: FLIP(0.01158) < DUP(0.01218) < BASE(0.01273) — 낮을수록 우수";
proc sgplot data=work.kcbert_arm_summary;
  vbar arm / response=brier_mean fillattrs=(color=vibg transparency=0.4)
             datalabel datalabelattrs=(size=10 weight=bold);
  yaxis label="평균 Brier Score (낮을수록 우수)" valuesformat=8.5 grid
        min=0.010 max=0.014;
  xaxis label="실험 조건 (Arm)";
run;

/*---------------------------------------------------------------------------
  차트 5: FLIP 전환 시 4대 오류 전이(Transition) 발생 건수 및 URL 비율
  - 25건 정상 오탐 해소(URL 92%) vs 22건 악성 정탐 손실(URL 63.6%)
---------------------------------------------------------------------------*/
title1 "FLIP 도입에 따른 4대 오류 전이(Transition) 건수 분석";
title2 "오탐 해소 25건(URL 92%)으로 대다수의 URL 편향 오탐을 성공적으로 복구";
proc sgplot data=work.kcbert_transitions;
  vbar transition_name_kr / response=total_count group=net_effect
         datalabel datalabelattrs=(size=10 weight=bold);
  yaxis label="발생 건수 (건)" grid min=0 max=30;
  xaxis label="오류 전이 범주";
  keylegend / title="순효과 구분" location=outside position=bottom;
run;

title1 "오류 전이 유형별 URL 포함 비율(%)";
title2 "정상 오탐 해소의 92.0%가 URL 포함 정상 문자에서 발생";
proc sgplot data=work.kcbert_transitions;
  vbar transition_name_kr / response=url_1_ratio
         fillattrs=(color=steel) datalabel;
  yaxis label="URL 포함 비율" valuesformat=percent8.1 grid min=0 max=1.0;
  xaxis label="오류 전이 범주";
run;

/* 6. 주요 요약 테이블 출력 */
title1 "ScamLens KcBERT 15개 실험 조건 세부 수치 요약표";
proc print data=work.kcbert_15arms noobs label;
  var arm seed threshold recall fpr f1 tp fp fn tn brier_score;
run;

title1 "실험 조건별 종합 통계 요약 (평균 및 표준편차)";
proc print data=work.kcbert_arm_summary noobs;
  var arm recall_mean recall_std fpr_mean fpr_std f1_mean f1_std brier_mean brier_std;
run;

title1 "FLIP vs DUP 4대 오류 전이 요약표";
proc print data=work.kcbert_transitions noobs label;
  var transition_name_kr total_count unique_messages url_0_count url_1_count url_1_ratio net_effect;
run;

title;
ods html close;
ods graphics off;
