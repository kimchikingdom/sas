/*
  ScamLens 00_RUN_KCBERT_VISUALS_CAS — KcBERT 시각화 및 CAS 적재 통합 실행기
  
  작성일: 2026-09-18
  역할:
    1. 14_kcbert_visuals.sas 를 실행하여 5종 요약 테이블 생성 및 고해상도 ODS 시각화 리포트 출력
    2. run_cas=1 설정 시 15_publish_kcbert_to_cas.sas 를 순차 실행하여 CASUSER 라이브러리에 적재/승격
*/

/* 1. 기본 환경 설정 */
%macro init_kcbert_runner;
  %global projroot run_cas slkc_caslib slkc_promote slkc_save;
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
  %if not %symexist(run_cas) %then %let run_cas=1;
  %if not %symexist(slkc_caslib) %then %let slkc_caslib=CASUSER;
  %if not %symexist(slkc_promote) %then %let slkc_promote=1;
  %if not %symexist(slkc_save) %then %let slkc_save=0;
%mend init_kcbert_runner;
%init_kcbert_runner;

%put NOTE: ========================================================;
%put NOTE: ScamLens KcBERT 시각화 & CAS 통합 워크플로 시작;
%put NOTE: 프로젝트 루트 : &projroot.;
%put NOTE: CAS 적재 활성화: &run_cas.;
%put NOTE: 대상 CASLIB  : &slkc_caslib.;
%put NOTE: ========================================================;

/* 2. 단계 14: 시각화 생성 및 WORK 테이블 임포트 */
%include "&projroot./sas/14_kcbert_visuals.sas";

%if &syscc ne 0 or &syserr ne 0 %then %do;
  %put ERROR: 14_kcbert_visuals.sas 실행 중 오류 발생. 파이프라인을 중단합니다.;
  %abort cancel;
%end;
%put NOTE: [SUCCESS] 14_kcbert_visuals.sas 실행 완료. ODS 리포트가 생성되었습니다.;

/* 3. 단계 15: CAS 적재 및 승격 (선택적) */
%if &run_cas. = 1 %then %do;
  %put NOTE: [INFO] 15_publish_kcbert_to_cas.sas 실행을 시작합니다.;
  %include "&projroot./sas/15_publish_kcbert_to_cas.sas";

  %if &syscc ne 0 or &syserr ne 0 or &slkc_complete. ne 1 %then %do;
    %put ERROR: 15_publish_kcbert_to_cas.sas 실행 중 오류 발생.;
    %abort cancel;
  %end;
  %put NOTE: [SUCCESS] KcBERT 테이블이 &slkc_caslib. 에 적재 및 승격되었습니다.;
%end;
%else %do;
  %put NOTE: [INFO] run_cas=0 설정으로 CAS 적재 단계를 건너뜁니다.;
%end;

%put NOTE: ========================================================;
%put NOTE: ScamLens KcBERT 시각화 통합 워크플로가 성공적으로 완료되었습니다.;
%put NOTE: ========================================================;
