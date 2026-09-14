/* Consensus comparison: metrics use original_label, never consensus as truth. */
%macro sc12_check;
  %if &syscc ne 0 or &syserr ne 0 %then %do;
    %put ERROR: SAS 12 stopped after an unsuccessful step.;
    %abort cancel;
  %end;
%mend;
%macro sc12_defaults;
  %global projroot sasdata runout;
  %global sc12_complete; %let sc12_complete=0;
  %if %length(%superq(projroot))=0 %then %let projroot=/home/student/github;
  %if %length(%superq(sasdata))=0 %then %let sasdata=&projroot./data/processed/sas;
  %if %length(%superq(runout))=0 %then %do; %put ERROR: Official runner must define runout.; %abort cancel; %end;
%mend;
%sc12_defaults;
%macro sc12_input_check;
  %if not %sysfunc(fileexist(&sasdata./sas_consensus_predictions_20260914.csv)) %then %do; %put ERROR: Missing consensus prediction input.; %abort cancel; %end;
%mend;
%sc12_input_check;
data work.sc12_p;
 infile "&sasdata./sas_consensus_predictions_20260914.csv" dsd dlm=',' firstobs=2 truncover encoding='utf-8' lrecl=32767;
 length review_id $32 model $12 seed fold 8 role $32 original_label $12 final_category 8 probability threshold prediction 8;
 input review_id $ model $ seed fold role $ original_label $ final_category probability threshold prediction;
run;
%sc12_check;
proc sql noprint;
 select count(*),count(distinct catx('|',review_id,model,put(seed,best.),put(fold,best.))) into :n,:u from work.sc12_p;
  select count(*) into :bad from work.sc12_p where missing(review_id) or missing(model) or missing(seed) or missing(fold) or missing(role) or missing(original_label) or missing(final_category) or missing(probability) or missing(threshold) or missing(prediction) or prediction not in (0,1) or probability<0 or probability>1 or threshold<0 or threshold>1.000001 or final_category not in (1,2,3,4) or original_label not in ('normal','smishing') or role ne 'development_readout' or fold ne 0 or model not in ('LR-A','LR-B','LR-C','Kc-A','Kc-C','FAGE','Stacking');
 select count(*) into :bad2 from work.sc12_p where prediction ne (probability>=threshold);
quit;
%sc12_check;
%macro sc12_validate;
  %local bad3 bad4 bad5 bad6 uid;
  %if &n ne 3122 or &u ne 3122 or &bad ne 0 or &bad2 ne 0 %then %do; %put ERROR: Invalid consensus prediction input rows=&n unique=&u bad=&bad threshold=&bad2.; %abort cancel; %end;
  proc sql noprint;
    select count(*) into :bad3 from (select seed,review_id from work.sc12_p group by seed,review_id having count(distinct model) ne 7);
    select count(*) into :bad4 from (select review_id,seed from work.sc12_p group by review_id,seed having count(distinct catx('|',original_label,put(final_category,best.))) ne 1);
    select count(*) into :bad5 from work.sc12_p where seed not in (42,101,202,303,404);
    select count(*) into :bad6 from (select seed,model,count(*) as nr from work.sc12_p group by seed,model having (seed=42 and nr ne 108) or (seed=101 and nr ne 88) or (seed=202 and nr ne 77) or (seed=303 and nr ne 71) or (seed=404 and nr ne 102));
    select count(distinct review_id) into :uid from work.sc12_p;
  quit;
%sc12_check;
  %if &bad3 ne 0 or &bad4 ne 0 or &bad5 ne 0 or &bad6 ne 0 or &uid ne 325 %then %do; %put ERROR: Model seed key metadata seed or row sets differ.; %abort cancel; %end;
%mend;
%sc12_validate;

data work.sc12_levels; do final_category=1 to 4; output; end; run;
%sc12_check;
data work.sc12_models;
  length model $12;
  do i=1 to 7;
    model=scan('LR-A LR-B LR-C Kc-A Kc-C FAGE Stacking',i,' ');
    output;
  end;
  keep model;
run;
%sc12_check;
data work.sc12_seeds;
  do seed=42,101,202,303,404; output; end;
run;
%sc12_check;
data work.sc12_labels; length original_label $12; original_label='normal'; output; original_label='smishing'; output; run;
%sc12_check;

proc sql;
 create table work.sc12_grid as select m.model,s.seed,l.original_label,c.final_category
 from work.sc12_models m cross join work.sc12_seeds s cross join work.sc12_labels l cross join work.sc12_levels c;
 create table work.sc12_strata as select g.model,g.seed,g.original_label,g.final_category,count(p.review_id) as n,
   sum(p.original_label='smishing' and p.prediction=1) as tp,
   sum(p.original_label='smishing' and p.prediction=0) as fn,
   sum(p.original_label='normal' and p.prediction=1) as fp,
   sum(p.original_label='normal' and p.prediction=0) as tn
 from work.sc12_grid g left join work.sc12_p p on p.model=g.model and p.seed=g.seed and p.original_label=g.original_label and p.final_category=g.final_category group by g.model,g.seed,g.original_label,g.final_category order by g.model,g.seed,g.original_label,g.final_category;
quit;
%sc12_check;
data work.sc12_strata; set work.sc12_strata; if (tp+fn)>0 then recall=tp/(tp+fn); else recall=.; if (fp+tn)>0 then fpr=fp/(fp+tn); else fpr=.; keep model seed original_label final_category n tp fn fp tn recall fpr; run;
%sc12_check;

proc sql;
 create table work.sc12_metrics as select model,seed,count(*) as rows,
   sum(p.original_label='smishing' and p.prediction=1) as tp,sum(p.original_label='smishing' and p.prediction=0) as fn,sum(p.original_label='normal' and p.prediction=1) as fp,sum(p.original_label='normal' and p.prediction=0) as tn
 from work.sc12_p p group by model,seed order by model,seed;
quit;
%sc12_check;
data work.sc12_metrics; set work.sc12_metrics; if tp+fn>0 then recall=tp/(tp+fn); else recall=.; if fp+tn>0 then fpr=fp/(fp+tn); else fpr=.; if 2*tp+fp+fn>0 then f1=2*tp/(2*tp+fp+fn); else f1=.; keep model seed rows tp fn fp tn recall fpr f1; run;
%sc12_check;
proc sql; create table work.sc12_seed_means as select model,mean(recall) as recall,mean(fpr) as fpr,mean(f1) as f1 from work.sc12_metrics group by model order by model; quit;
%sc12_check;
proc sort data=work.sc12_p out=work.sc12_p_sorted; by model seed original_label; run;
%sc12_check;
title 'Original-label and consensus strata: stored development predictions';
proc freq data=work.sc12_p_sorted; by model seed original_label; tables final_category*prediction / nopercent norow nocol; run;
%sc12_check;
proc datasets library=work nolist; modify sc12_metrics; format recall fpr f1 best32.; quit;
%sc12_check;
proc datasets library=work nolist; modify sc12_strata; format recall fpr best32.; quit;
%sc12_check;
proc datasets library=work nolist; modify sc12_seed_means; format recall fpr f1 best32.; quit;
%sc12_check;
proc export data=work.sc12_metrics outfile="&runout./12_metrics.csv" dbms=csv replace; run;
%sc12_check;
proc export data=work.sc12_strata outfile="&runout./12_strata.csv" dbms=csv replace; run;
%sc12_check;
proc export data=work.sc12_seed_means outfile="&runout./12_seed_means.csv" dbms=csv replace; run;
%sc12_check;
title 'Original-label metrics for each model and seed';
proc print data=work.sc12_metrics noobs; run;
%sc12_check;
title 'Unweighted means of per-seed metrics: selected URL-free development rows';
proc print data=work.sc12_seed_means noobs; run;
%sc12_check;
title;
%macro sc12_finish;
  %if &syserr ne 0 or &syscc ne 0 %then %do; %put ERROR: SCAMLENS_12 failed before completion.; %abort cancel; %end;
  %let sc12_complete=1;
  %put NOTE: Evidence is descriptive selected development URL-free rows;
  %put A was AI-assisted and B was no-AI/no-prior-exposure attested. Consensus is not used as truth for metrics.;
  %put NOTE: SCAMLENS_12_COMPLETE;
%mend;
%sc12_finish;
