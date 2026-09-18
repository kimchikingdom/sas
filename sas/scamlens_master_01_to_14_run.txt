/*---------------------------------------------------------------------------
  ScamLens 00_RUN_MASTER_01_TO_14 — 전체 분석 파이프라인 (01 ~ 14) 마스터 실행기

  프로젝트: ScamLens (안심문자 탐지 및 난독화 강건성 연구)
  작성일: 2026-09-18
  버전: v1.0
  
  [전체 파이프라인 구성]
  1단계: 01 ~ 08 베이스라인 ML & 감사 파이프라인 (%include 00_RUN_ALL.sas)
         - 01_load_and_audit, 07_composition, 02_meta, 03_roc, 06_transformer, 
           05_visuals, 04_text(optional), 08_fage
  2단계: 11 ~ 13 인간-AI 합의 및 A/B CAS 배포 파이프라인 (%include 00_RUN_AB_CAS.sas)
         - 11_reviewer_ab_agreement, 12_consensus_model_comparison, 13_publish_ab_to_cas
  3단계: 14 심층 KcBERT 강건성 시각화 및 CAS 배포 (%include 14_kcbert_visuals.sas)
         - 5대 정본 테이블 생성, 5종 고해상도 그래픽스, Visual Analytics 글로벌 승격

  [실행 방법]
  - SAS Studio에서 본 프로그램을 열거나 복사해 넣고 F3을 누르면 01부터 14까지 전 과정이 순차 완주됩니다.
---------------------------------------------------------------------------*/

%macro init_master_env;
  %global projroot;
  %if not %symexist(projroot) %then %do;
    %if %sysfunc(fileexist(/home/student/github/sas/14_kcbert_visuals.sas)) %then %do;
      %let projroot=/home/student/github;
    %end;
    %else %if %sysfunc(fileexist(/Users/sangwoolee/sas/sas/sas/14_kcbert_visuals.sas)) %then %do;
      %let projroot=/Users/sangwoolee/sas/sas;
    %end;
    %else %do;
      %let projroot=/home/student/github;
    %end;
  %end;
%mend init_master_env;
%init_master_env;

%macro run_master_pipeline;
  %local t_start t_end;
  %let t_start=%sysfunc(datetime());

  %put NOTE: =========================================================================;
  %put NOTE: ScamLens 전체 분석 파이프라인 (01 ~ 14) 마스터 실행 시작;
  %put NOTE: 실행 환경 루트: &projroot.;
  %put NOTE: 시작 시각: %sysfunc(datetime(), datetime20.);
  %put NOTE: =========================================================================;

  /* --- [1단계: 01 ~ 08 파이프라인] --- */
  %put NOTE: [STEP 1/3] 01 ~ 08 베이스라인 및 감사 파이프라인 실행 중...;
  %include "&projroot./sas/00_RUN_ALL.sas";
  %if &syscc ne 0 or &syserr ne 0 %then %do;
    %put ERROR: 00_RUN_ALL.sas 실행 중 오류 발생. 파이프라인을 중단합니다.;
    %abort cancel;
  %end;
  %put NOTE: [SUCCESS] 01 ~ 08 파이프라인 완주 완료.;

  /* --- [2단계: 11 ~ 13 파이프라인] --- */
  %put NOTE: [STEP 2/3] 11 ~ 13 인간-AI 합의 및 A/B CAS 배포 실행 중...;
  %include "&projroot./sas/00_RUN_AB_CAS.sas";
  %if &syscc ne 0 or &syserr ne 0 %then %do;
    %put ERROR: 00_RUN_AB_CAS.sas 실행 중 오류 발생. 파이프라인을 중단합니다.;
    %abort cancel;
  %end;
  %put NOTE: [SUCCESS] 11 ~ 13 파이프라인 완주 완료.;

  /* --- [3단계: 14 파이프라인 (14+15 올인원)] --- */
  %put NOTE: [STEP 3/3] 14 KcBERT 고해상도 시각화 및 CAS 적재 실행 중...;
  %include "&projroot./sas/14_kcbert_visuals.sas";
  %if &syscc ne 0 or &syserr ne 0 %then %do;
    %put ERROR: 14_kcbert_visuals.sas 실행 중 오류 발생. 파이프라인을 중단합니다.;
    %abort cancel;
  %end;
  %put NOTE: [SUCCESS] 14 KcBERT 시각화 및 CAS 배포 완주 완료.;

  %let t_end=%sysfunc(datetime());
  %put NOTE: =========================================================================;
  %put NOTE: ScamLens 01 ~ 14 전체 마스터 파이프라인이 성공적으로 완주되었습니다!;
  %put NOTE: 총 소요 시간: %sysfunc(round(%sysevalf(&t_end. - &t_start.), 0.01)) 초;
  %put NOTE: SAS Visual Analytics(VA)에서 배포된 테이블들을 즉시 조회할 수 있습니다.;
  %put NOTE: =========================================================================;

  /* 최종 요약 테이블 생성 및 출력 */
  data work.scamlens_pipeline_summary;
    length track $40 stages $30 status $20 details $60;
    track = "Track 1: Baseline ML & Audit";
    stages = "01 ~ 08";
    status = "COMPLETED";
    details = "데이터 감사, 메타 분류, ROC, 트랜스포머 대조, FAGE";
    output;

    track = "Track 2: Human-AI Consensus & CAS";
    stages = "11 ~ 13";
    status = "COMPLETED";
    details = "검수자 A/B 합의, Kappa 일치도, 7종 테이블 CAS 적재";
    output;

    track = "Track 3: KcBERT Robustness & CAS";
    stages = "14 (14+15)";
    status = "COMPLETED";
    details = "15-Arm 5대 테이블, 5종 ODS 그래픽스, VA 글로벌 승격";
    output;
  run;

  title1 "ScamLens 01 ~ 14 전체 파이프라인 종합 실행 결과 요약";
  proc print data=work.scamlens_pipeline_summary noobs;
  run;
  title;
%mend run_master_pipeline;

%run_master_pipeline;
