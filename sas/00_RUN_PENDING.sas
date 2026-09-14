/* Remaining SAS reproductions: 09 then 10, both historical reviewer-A analyses.
   Copy the complete handoff to /home/student. Run in a UTF-8 SAS session.
   Change run_tag for another run; existing output folders are never reused.
   08 already has returned results. This runner does not refit 08 or any model. */
%let projroot=/home/student;
%let run_tag=review_a_20260914;
%let runout=&projroot./outputs/&run_tag.;

%macro prepare_pending;
    %if %sysfunc(fileexist(&runout.)) %then %do;
        %put ERROR: Output folder already exists. Change run_tag to preserve the earlier run.;
        %abort cancel;
    %end;
    %if not %sysfunc(fileexist(&projroot./data/processed/sas/sas_reviewer_a_rows_20260912.csv))
        or not %sysfunc(fileexist(&projroot./data/processed/sas/sas_reviewer_a_pairs_20260912.csv))
        or not %sysfunc(fileexist(&projroot./data/processed/sas/sas_reviewer_a_oof_20260912.csv)) %then %do;
        %put ERROR: Missing reviewer-A input CSV. Copy all bundle folders before running.;
        %abort cancel;
    %end;
    data _null_;
        length created $1024;
        if not fileexist("&projroot./outputs") then created=dcreate('outputs',"&projroot.");
        created=dcreate("&run_tag.","&projroot./outputs");
        if missing(created) then do;
            put 'ERROR: Cannot create a fresh output folder.';
            abort cancel;
        end;
    run;
%mend;
%prepare_pending;

data work.pending_run_status;
    length stage $32 state $32 syserr syscc 8;
    stop;
run;

%macro pending_step(stage, program, expected);
    %local step_syserr step_syscc;
    %let syscc=0;
    proc printto log="&runout./&stage..log" new; run;
    %put NOTE: SCAMLENS_STAGE=&stage. SAS_VERSION=&sysvlong. DATE=&sysdate9. TIME=&systime.;
    proc options option=encoding; run;
    ods html path="&runout." (url=none) file="&stage..html" style=HTMLBlue;
    %include "&projroot./sas/&program.";
    %let step_syserr=&syserr.;
    %let step_syscc=&syscc.;
    ods html close;
    proc printto; run;
    data work.pending_step_status;
        length stage $32 state $32 syserr syscc 8;
        stage="&stage."; syserr=&step_syserr.; syscc=&step_syscc.;
        if syserr=0 and syscc=0 and exist("&expected.") then state='completed_check_log';
        else state='requires_review';
    run;
    proc append base=work.pending_run_status data=work.pending_step_status; run;
    proc export data=work.pending_run_status
        outfile="&runout./pending_run_status.csv" dbms=csv replace;
    run;
%mend;

%pending_step(09_reviewer_a,09_reviewer_a_descriptive.sas,work.review_a_pairs);
%pending_step(10_reviewer_a_oof,10_reviewer_a_oof.sas,work.review_a_oof);
proc print data=work.pending_run_status noobs; run;
%put NOTE: Return this entire output folder together with the input MANIFEST.json.;
%put NOTE: These tables reproduce reviewer A only, not the later A/B consensus.;
