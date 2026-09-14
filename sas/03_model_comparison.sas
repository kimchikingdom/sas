/*---------------------------------------------------------------------------
  ScamLens 03 — 고정 test 점수의 ROC-AUC 비교 (DeLong ROCCONTRAST)

  선행 조건은 01(work.scores)이다. 02의 OOF 입력이 없더라도 문자 단독과
  고정가중 결합의 비교는 실행한다. 동일 세션에서 02가 성공한 경우에만 SAS
  추론용 메타 모형을 추가한다. Python 규제 메타 모형과는 별도 추정량이다.

  ROCCONTRAST는 ROC-AUC 차이를 검정하며 PR-AUC, F1, 고정 임계값의 FPR 차이를
  검정하지 않는다. AUC 차이와 신뢰구간을 함께 제시한다. p>=0.05는 차이를
  검출할 근거가 부족하다는 뜻이며 URL 무기여나 동등성을 입증하지 않는다.

  핵심 관용구: 이미 계산된 확률을 비교할 때는 model 문에 / nofit을 주고
  roc 문으로 각 확률 변수를 등록한다. PROC LOGISTIC이 새로 적합하지 않고
  주어진 점수의 ROC만 비교한다.
---------------------------------------------------------------------------*/

/* 선행 조건: 01_load_and_audit.sas가 같은 세션에서 먼저 실행돼야 한다. */
%macro require(dsname);
    %if not %sysfunc(exist(&dsname.)) %then %do;
        %put ERROR: &dsname. 이(가) 없습니다. 01_load_and_audit.sas를 먼저 실행하십시오.;
        %abort cancel;
    %end;
%mend;
%require(work.scores);

%let include_sas_meta = 0;
%macro choose_comparison;
    %if %symexist(sas_meta_fit_completed) %then %do;
        %if &sas_meta_fit_completed.=1 and %sysfunc(exist(work.test_scored)) %then
            %let include_sas_meta=1;
    %end;
    %if &include_sas_meta.=1 %then %do;
        data work.roc_comparison;
            set work.test_scored;
            where split='test';
        run;
        data _null_;
            set work.roc_comparison;
            if missing(meta_probability) then do;
                put "ERROR: SAS meta score missing; ROC comparisons must use the same rows.";
                abort cancel;
            end;
        run;
    %end;
    %else %do;
        %put NOTE: OOF SAS meta refit unavailable; comparing frozen base/fixed-fusion scores only.;
        data work.roc_comparison;
            set work.scores;
            where split='test';
            fixed_fusion=fixed_fusion_probability;
        run;
    %end;
%mend;
%choose_comparison;

/* Missing scores must not silently change the common comparison sample. */
data _null_;
    set work.roc_comparison;
    if missing(text_probability) or missing(fixed_fusion_probability) then do;
        put "ERROR: Missing fixed test scores. Re-export rather than silently drop rows.";
        abort cancel;
    end;
run;


/*--- 1. test 분할 전체에서 세 모델 비교 ----------------------------------*/
%macro compare(group=,filter=1);
    title "test &group. — ROC-AUC 비교";
    ods output ROCAssociation=work.roc_auc_&group.
               ROCContrastEstimate=work.roc_difference_&group.;
    proc logistic data=work.roc_comparison plots=roc;
        where &filter.;
        model target(event='1') = / nofit;
        roc '문자 단독' pred=text_probability;
        roc '고정가중 결합' pred=fixed_fusion_probability;
        %if &include_sas_meta.=1 %then %do;
            roc 'SAS OOF 추론 모형' pred=meta_probability;
        %end;
        roccontrast reference('문자 단독') / estimate=allpairs e;
    run;
    ods output close;
%mend;
%compare(group=all);


/*--- 2. URL 포함 표본만 비교 ---------------------------------------------
  결합 모델의 효과는 URL이 있는 문자에서만 나타날 수 있으므로 이 부분집합을
  따로 본다. Python 결과에서 오탐 차이가 가장 컸던 구간이다.
-------------------------------------------------------------------------*/
%compare(group=url,filter=has_url=1);


/*--- 3. URL 없는 표본 ----------------------------------------------------
  고정결합=문자 점수이므로 중복 ROC의 특이 공분산 검정을 만들지 않는다.
  메타 모형의 확률은 다른 변환일 수 있어 확률 자체의 동일성을 요구하지 않는다.
-------------------------------------------------------------------------*/
data _null_;
    set work.roc_comparison;
    where has_url = 0;
    if abs(fixed_fusion_probability-text_probability)>1e-12 then do;
        put "ERROR: Fixed fusion must equal text score on messages without a URL.";
        abort cancel;
    end;
run;

%macro no_url_comparison;
    %if &include_sas_meta.=1 %then %do;
        title "test no_url — 문자 단독과 SAS OOF 추론 모형의 ROC-AUC";
        proc logistic data=work.roc_comparison plots=roc;
            where has_url=0;
            model target(event='1') = / nofit;
            roc '문자 단독' pred=text_probability;
            roc 'SAS OOF 추론 모형' pred=meta_probability;
            /* URL 없음에서 메타 점수는 문자 점수의 단조 변환일 수 있다.
               이때 ROC가 같아 차이의 분산이 0이므로 이 구간은 기술적 ROC만 낸다. */
        run;
    %end;
%mend;
%no_url_comparison;

/*
  결과 읽는 법

  ROCCONTRAST의 p-value가 0.05보다 크면 "두 모델의 AUC가 다르다고 말할 수 없다"는
  뜻이다. "URL 정보가 없다" 또는 "동등하다"는 결론은 이 검정으로 내릴 수 없다.
  신뢰구간이 실무적으로 큰 차이까지 포함하는지와 고정 임계값 지표도 보고한다.

  주의: 표본이 test 2,317행이고 URL 포함은 896행, URL 없는 악성은 54행이다.
  작은 차이를 탐지할 검정력이 충분하지 않으므로, 유의하지 않다는 결과를
  "차이가 없다"로 단정하지 말고 신뢰구간의 폭을 함께 보고한다.
*/

title;
