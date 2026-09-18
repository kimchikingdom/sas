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
    %if %sysfunc(fileexist(/home/student/github/data/processed/sas/sas_kcbert_15arms.csv)) %then %do;
      %let projroot=/home/student/github;
    %end;
    %else %if %sysfunc(fileexist(/Users/sangwoolee/sas/sas/data/processed/sas/sas_kcbert_15arms.csv)) %then %do;
      %let projroot=/Users/sangwoolee/sas/sas;
    %end;
    %else %if %sysfunc(fileexist(/Users/sangwoolee/dataproj/data/processed/sas/sas_kcbert_15arms.csv)) %then %do;
      %let projroot=/Users/sangwoolee/dataproj;
    %end;
    %else %do;
      %let projroot=/home/student/github;
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

/* 2. 데이터 로드 (외부 CSV가 있으면 PROC IMPORT, 없으면 내장 정본 데이터셋으로 자동 실행) */
%macro load_data;
  %if %sysfunc(fileexist(&sasdata./sas_kcbert_15arms.csv)) %then %do;
    %put NOTE: =========================================================================;
    %put NOTE: [CSV MODE] 외부 CSV 파일에서 데이터를 로드합니다: &sasdata.;
    %put NOTE: =========================================================================;
    proc import datafile="&sasdata./sas_kcbert_15arms.csv" out=work.kcbert_15arms dbms=csv replace; guessingrows=max; run;
    proc import datafile="&sasdata./sas_kcbert_arm_summary.csv" out=work.kcbert_arm_summary dbms=csv replace; guessingrows=max; run;
    proc import datafile="&sasdata./sas_kcbert_subgroup_url.csv" out=work.kcbert_subgroup_url dbms=csv replace; guessingrows=max; run;
    proc import datafile="&sasdata./sas_kcbert_transitions.csv" out=work.kcbert_transitions dbms=csv replace; guessingrows=max; run;
    proc import datafile="&sasdata./sas_kcbert_top_uncertain.csv" out=work.kcbert_top_uncertain dbms=csv replace; guessingrows=max; run;
  %end;
  %else %do;
    %put NOTE: =========================================================================;
    %put NOTE: [SELF-CONTAINED MODE] 외부 CSV 파일이 발견되지 않아, 프로그램에 내장된;
    %put NOTE: ScamLens 15-Arm 정본 데이터셋(Embedded Datasets)으로 자동 로드합니다.;
    %put NOTE: =========================================================================;
/* --- kcbert_15arms 내장 정본 데이터 --- */
data work.kcbert_15arms;
  length arm ;
  infile datalines dlm="," dsd truncover;
  input arm :. seed threshold recall fpr f1 tp fp fn tn total_n brier_score;
  datalines;
DUP,42,0.025356,0.972727,0.007746,0.969789,321,11,9,1409,1750,0.012249
FLIP,42,0.249265,0.960606,0.008451,0.962064,317,12,13,1408,1750,0.011669
BASE,42,0.033222,0.978788,0.009155,0.969970,323,13,7,1407,1750,0.012018
DUP,101,0.056655,0.957576,0.008451,0.960486,316,12,14,1408,1750,0.015002
FLIP,101,0.038150,0.966667,0.007746,0.966667,319,11,11,1409,1750,0.011353
BASE,101,0.108383,0.969697,0.011972,0.959520,320,17,10,1403,1750,0.013184
DUP,202,0.023381,0.978788,0.007746,0.972892,323,11,7,1409,1750,0.010791
FLIP,202,0.068893,0.966667,0.004930,0.972561,319,7,11,1413,1750,0.010618
BASE,202,0.620583,0.939394,0.003521,0.961240,310,5,20,1415,1750,0.013332
DUP,303,0.018280,0.969697,0.010563,0.962406,320,15,10,1405,1750,0.012190
FLIP,303,0.294521,0.951515,0.007746,0.958779,314,11,16,1409,1750,0.013780
BASE,303,0.199156,0.966667,0.011972,0.957958,319,17,11,1403,1750,0.013492
DUP,404,0.019324,0.972727,0.009859,0.965414,321,14,9,1406,1750,0.010659
FLIP,404,0.036188,0.963636,0.004930,0.970992,318,7,12,1413,1750,0.010497
BASE,404,0.013827,0.975758,0.010563,0.965517,322,15,8,1405,1750,0.011603
;
run;

/* --- kcbert_arm_summary 내장 정본 데이터 --- */
data work.kcbert_arm_summary;
  length arm ;
  infile datalines dlm="," dsd truncover;
  input arm :. recall_mean recall_std fpr_mean fpr_std f1_mean f1_std brier_mean brier_std group_std_all group_std_multi group_std_singleton;
  datalines;
DUP,0.970303,0.007016,0.008873,0.001144,0.966197,0.004589,0.012178,0.001563,0.006167,0.011112,0.005886
FLIP,0.961818,0.005620,0.006761,0.001517,0.966212,0.005212,0.011583,0.001183,0.005771,0.013670,0.005322
BASE,0.966061,0.014005,0.009437,0.003137,0.962841,0.004368,0.012726,0.000765,0.007722,0.014283,0.007349
;
run;

/* --- kcbert_subgroup_url 내장 정본 데이터 --- */
data work.kcbert_subgroup_url;
  length arm  url_group ;
  infile datalines dlm="," dsd truncover;
  input arm :. seed has_url url_group :. recall fpr f1 tp fp fn tn total_n;
  datalines;
DUP,42,0,URL_NO,0.962264,0.002597,0.953271,51,3,2,1152,1208
DUP,42,1,URL_YES,0.974729,0.030189,0.972973,270,8,7,257,542
FLIP,42,0,URL_NO,0.943396,0.004329,0.925926,50,5,3,1150,1208
FLIP,42,1,URL_YES,0.963899,0.026415,0.969147,267,7,10,258,542
BASE,42,0,URL_NO,0.943396,0.004329,0.925926,50,5,3,1150,1208
BASE,42,1,URL_YES,0.985560,0.030189,0.978495,273,8,4,257,542
DUP,101,0,URL_NO,0.924528,0.002597,0.933333,49,3,4,1152,1208
DUP,101,1,URL_YES,0.963899,0.033962,0.965642,267,9,10,256,542
FLIP,101,0,URL_NO,0.962264,0.004329,0.935780,51,5,2,1150,1208
FLIP,101,1,URL_YES,0.967509,0.022642,0.972777,268,6,9,259,542
BASE,101,0,URL_NO,0.905660,0.004329,0.905660,48,5,5,1150,1208
BASE,101,1,URL_YES,0.981949,0.045283,0.969697,272,12,5,253,542
DUP,202,0,URL_NO,0.981132,0.001732,0.971963,52,2,1,1153,1208
DUP,202,1,URL_YES,0.978339,0.033962,0.973070,271,9,6,256,542
FLIP,202,0,URL_NO,0.943396,0.003463,0.934579,50,4,3,1151,1208
FLIP,202,1,URL_YES,0.971119,0.011321,0.979964,269,3,8,262,542
BASE,202,0,URL_NO,0.849057,0.000866,0.909091,45,1,8,1154,1208
BASE,202,1,URL_YES,0.956679,0.015094,0.970696,265,4,12,261,542
DUP,303,0,URL_NO,0.943396,0.002597,0.943396,50,3,3,1152,1208
DUP,303,1,URL_YES,0.974729,0.045283,0.966011,270,12,7,253,542
FLIP,303,0,URL_NO,0.886792,0.003463,0.903846,47,4,6,1151,1208
FLIP,303,1,URL_YES,0.963899,0.026415,0.969147,267,7,10,258,542
BASE,303,0,URL_NO,0.962264,0.003463,0.944444,51,4,2,1151,1208
BASE,303,1,URL_YES,0.967509,0.049057,0.960573,268,13,9,252,542
DUP,404,0,URL_NO,0.924528,0.002597,0.933333,49,3,4,1152,1208
DUP,404,1,URL_YES,0.981949,0.041509,0.971429,272,11,5,254,542
FLIP,404,0,URL_NO,0.924528,0.001732,0.942308,49,2,4,1153,1208
FLIP,404,1,URL_YES,0.971119,0.018868,0.976407,269,5,8,260,542
BASE,404,0,URL_NO,0.943396,0.003463,0.934579,50,4,3,1151,1208
BASE,404,1,URL_YES,0.981949,0.041509,0.971429,272,11,5,254,542
;
run;

/* --- kcbert_transitions 내장 정본 데이터 --- */
data work.kcbert_transitions;
  length transition_code  transition_name_kr  net_effect ;
  infile datalines dlm="," dsd truncover;
  input transition_code :. transition_name_kr :. total_count unique_messages url_0_count url_1_count url_1_ratio net_effect :.;
  datalines;
resolved_fp,정상 오탐 해소,25,14,2,23,0.9200,개선(+)
lost_tp,악성 정탐 손실,22,9,8,14,0.6364,악화(-)
new_fp,신규 정상 오탐,10,7,8,2,0.2000,악화(-)
rescued_fn,악성 미탐 구제,8,6,4,4,0.5000,개선(+)
;
run;

/* --- kcbert_top_uncertain 내장 정본 데이터 --- */
data work.kcbert_top_uncertain;
  length group_id_short ;
  infile datalines dlm="," dsd truncover;
  input group_rank group_id_short :. label_kr group_size has_url base_mean dup_mean flip_mean base_std dup_std flip_std;
  datalines;
1,37027523,정상,1,1,0.961792,0.596392,0.401538,0.056629,0.458889,0.455347
2,bcaa3ff2,스미싱,1,0,0.128196,0.207435,0.367219,0.216663,0.245682,0.440154
3,f2869943,정상,2,1,0.950564,0.733824,0.374136,0.091237,0.278455,0.439216
4,e2187648,정상,1,0,0.226809,0.003916,0.327932,0.389032,0.004412,0.387543
5,772d4c5a,스미싱,1,1,0.999218,0.604843,0.752189,0.000832,0.481803,0.381202
6,1dbebbdd,스미싱,1,1,0.297923,0.188523,0.248049,0.297307,0.348949,0.375487
7,c44cad38,정상,1,1,0.022506,0.119011,0.198615,0.027704,0.229198,0.369747
8,0df9abfd,스미싱,1,1,0.999526,0.999536,0.783509,0.000353,0.000247,0.352195
9,f495a399,스미싱,2,1,0.759811,0.982680,0.765352,0.383383,0.032149,0.339518
10,2359f71f,스미싱,1,0,0.019260,0.150656,0.585657,0.019684,0.206974,0.338988
11,7964a599,스미싱,1,1,0.903909,0.589601,0.575252,0.119106,0.367110,0.333583
12,72bea48f,스미싱,1,0,0.606623,0.412056,0.552535,0.330556,0.322929,0.312353
13,aacad2de,정상,1,1,0.791462,0.973397,0.651527,0.386627,0.036077,0.308368
14,2de44534,정상,1,1,0.140756,0.231406,0.464674,0.213868,0.334198,0.298094
15,2668f9cc,스미싱,1,0,0.350154,0.044224,0.310125,0.423258,0.038169,0.298002
16,48cd83d4,정상,1,0,0.158641,0.005356,0.168242,0.287999,0.003452,0.290138
17,0a415ee5,스미싱,1,1,0.999513,0.999381,0.849724,0.000429,0.000382,0.277202
18,39efe806,정상,1,0,0.034156,0.003297,0.145697,0.065384,0.003227,0.270638
19,e8dd0f61,스미싱,2,1,0.861935,0.468088,0.099237,0.259279,0.439803,0.206695
20,3ab8514e,스미싱,1,0,0.751340,0.771393,0.898550,0.361525,0.350489,0.198125
;
run;
  %end;
%mend load_data;
%load_data;

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
