/*---------------------------------------------------------------------------
  ScamLens 09 — 검수자 A 단독 기술 통계 (PROC FREQ)

  Python `scripts/analyze_reviewer_a_only_20260912.py`가 만든 본문 없는 표를 읽는다.
  원래 train URL 없는 악성 278행과 짝 정상 278행이다. 원래 validation/test를
  넣지 않는다. 적합·임계값 변경·원 라벨 수정은 하지 않는다.

  본문 판단은 보이는 요구의 기록이다. 교차표를 정확도로 읽지 않는다.
  검수자 B가 오기 전에는 kappa를 계산하지 않는다.

  독립 실행. 01의 work.scores를 요구하지 않는다.
  선행: data/processed/sas/sas_reviewer_a_rows_20260912.csv
        data/processed/sas/sas_reviewer_a_pairs_20260912.csv
---------------------------------------------------------------------------*/
proc printto; run;
%let projroot=/home/student/github;
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

data work.review_a;
    infile "&sasdata./sas_reviewer_a_rows_20260912.csv"
           dsd dlm=',' firstobs=2 truncover encoding='utf-8' lrecl=32767;
    length review_id $32 message_id $40 original_label $12 heuristic_code $32
           text_judgment $48
           is_url_free_malicious is_quarantined wave note_chars n_actions
           action_payment action_credentials action_app action_channel
           action_callback action_none action_unclear 8;
    input review_id $ message_id $ original_label $ is_url_free_malicious
          is_quarantined heuristic_code $ text_judgment $ wave note_chars
          n_actions action_payment action_credentials action_app action_channel
          action_callback action_none action_unclear;
run;

data work.review_a_pairs;
    infile "&sasdata./sas_reviewer_a_pairs_20260912.csv"
           dsd dlm=',' firstobs=2 truncover encoding='utf-8' lrecl=32767;
    length pair_id $32 target_review_id $32 control_review_id $32
           target_judgment $48 control_judgment $48
           same_judgment 8 cosine_similarity 8;
    input pair_id $ target_review_id $ control_review_id $ target_judgment $
          control_judgment $ same_judgment cosine_similarity;
run;

%macro assert_review_a_input;
    %local rows pairs bad_rows bad_pairs;
    proc sql noprint;
        select count(*) into :rows trimmed from work.review_a;
        select count(*) into :pairs trimmed from work.review_a_pairs;
        select count(*) into :bad_rows trimmed from work.review_a
            where missing(review_id) or missing(text_judgment)
               or original_label not in ('smishing', 'normal')
               or is_url_free_malicious not in (0,1)
               or wave not in (1,2)
               or action_none not in (0,1) or action_unclear not in (0,1);
        select count(*) into :bad_pairs trimmed from work.review_a_pairs
            where missing(pair_id) or missing(target_judgment)
               or same_judgment not in (0,1)
               or cosine_similarity < 0 or cosine_similarity > 1;
    quit;
    %if &rows ne 556 or &pairs ne 278 or &bad_rows>0 or &bad_pairs>0 %then %do;
        %put ERROR: A 단독 입력 무결성 실패. 행=&rows. 짝=&pairs. 불량행=&bad_rows. 불량짝=&bad_pairs.;
        %abort cancel;
    %end;
%mend;
%assert_review_a_input;

title '검수자 A 본문 판단 x 원 라벨 (정확도가 아님)';
proc freq data=work.review_a;
    tables original_label * text_judgment / nocol norow nopercent;
run;

title '검수자 A 본문 판단 x 완료 순서';
proc freq data=work.review_a;
    tables wave * text_judgment / nocol norow nopercent;
run;

title 'URL 없는 악성 대상: 규칙 단서 x 본문 판단';
proc freq data=work.review_a;
    where is_url_free_malicious=1;
    tables heuristic_code * text_judgment / nocol norow nopercent;
run;

title '유사 정상 짝: 대상 판단 x 짝 판단';
proc freq data=work.review_a_pairs;
    tables target_judgment * control_judgment / nocol norow nopercent;
    tables same_judgment;
run;

title;
%put NOTE: 09는 기술 통계만 산출한다. 원 라벨·임계값·학습 자료는 변경하지 않는다.;
%put NOTE: 검수자 B 없이 kappa를 계산하지 않는다.;
