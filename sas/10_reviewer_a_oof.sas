/*---------------------------------------------------------------------------
  ScamLens 10 — 검수자 A 판단 × 저장 선형 OOF (PROC FREQ)

  Python `scripts/analyze_reviewer_a_oof_20260912.py`가 만든 본문 없는 표를 읽는다.
  원래 train 학습 제외 점수만 들어 있다. 원래 validation/test를 넣지 않는다.
  적합·임계값 재선택·원 라벨 수정은 하지 않는다. A 판단을 정답으로 쓰지 않는다.

  기본 교차는 결과 확인 행(role=development_readout)이다.

  독립 실행. 선행: data/processed/sas/sas_reviewer_a_oof_20260912.csv
---------------------------------------------------------------------------*/

%if not %symexist(projroot) %then %let projroot = /home/student;
%let sasdata  = &projroot./data/processed/sas;

proc options option=encoding value; run;
%macro assert_utf8;
    %local enc;
    %let enc=%upcase(%sysfunc(getoption(encoding)));
    %if "&enc" ne "UTF8" and "&enc" ne "UTF-8" %then %do;
        %put ERROR: 세션 인코딩이 UTF-8이 아닙니다 (&enc).;
        %put ERROR- SAS Viya 세션을 UTF-8로 다시 시작한 뒤 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%assert_utf8;

data work.review_a_oof;
    infile "&sasdata./sas_reviewer_a_oof_20260912.csv"
           dsd dlm=',' firstobs=2 truncover encoding='utf-8' lrecl=32767;
    length review_id $32 message_id $40 original_label $12 text_judgment $48
           a_risk_bucket $40 role $32 arm $8
           seed fold prediction 8 probability 8;
    input review_id $ message_id $ original_label $ text_judgment $
          a_risk_bucket $ seed fold role $ arm $ probability prediction;
run;

%macro assert_oof_input;
    %local rows bad;
    proc sql noprint;
        select count(*) into :rows trimmed from work.review_a_oof;
        select count(*) into :bad trimmed from work.review_a_oof
            where missing(review_id) or missing(text_judgment)
               or original_label not in ('smishing', 'normal')
               or arm not in ('A', 'C')
               or role not in ('threshold_calibration', 'development_readout')
               or prediction not in (0,1)
               or probability < 0 or probability > 1;
    quit;
    %if &rows=0 or &bad>0 %then %do;
        %put ERROR: A-OOF 입력 무결성 실패. 행=&rows. 불량=&bad.;
        %abort cancel;
    %end;
%mend;
%assert_oof_input;

proc sort data=work.review_a_oof;
    by seed;
run;

title '선형 C 결과 확인: 원 라벨 악성, A 판단 x 저장 이진 판정';
proc freq data=work.review_a_oof;
    where arm='C' and role='development_readout' and original_label='smishing';
    tables text_judgment * prediction / nocol norow nopercent;
    by seed;
run;

title '선형 C 결과 확인: 원 라벨 정상, A 판단 x 저장 이진 판정';
proc freq data=work.review_a_oof;
    where arm='C' and role='development_readout' and original_label='normal';
    tables text_judgment * prediction / nocol norow nopercent;
    by seed;
run;

title;
%put NOTE: 10은 저장 점수와 A 판단의 기술 교차만 산출한다. 임계값과 원 라벨은 변경하지 않는다.;
