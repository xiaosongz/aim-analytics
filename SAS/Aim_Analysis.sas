%macro numeric(var);
      &var._c=input(&var ,12.);
%mend numeric;
*/ Re-write University of Michigan Stat-250 Course Performance Analysis in SAS Code/*

*set library; 
LIBNAME Aim "C:\Users\xiaosong\Documents\GitHub\aim-analytics\SAS";

PROC IMPORT OUT= Aim.StudentCourse 
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.course.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


PROC IMPORT OUT= Aim.StudentRecord
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.record.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

DATA Aim.SR; SET Aim.StudentRecord;
array CHAR _character_ ; 
    array NUM _numeric_ ;
do over CHAR; 
    if CHAR="NA" then call missing(CHAR);
    else if missing(CHAR) then CHAR="WAS MISSING";
end;
do over NUM; 
    if NUM=1 then call missing(NUM);
    else if missing(NUM) then NUM=0;
end;
run;

DATA Aim.SC; SET Aim.StudentCourse;
array CHAR _character_ ; 
    array NUM _numeric_ ;
do over CHAR; 
    if CHAR="NA" then call missing(CHAR);
    else if missing(CHAR) then CHAR="WAS MISSING";
end;
do over NUM; 
    if NUM=1 then call missing(NUM);
    else if missing(NUM) then NUM=0;
end;
run;

PROC SQL;
	*TITLE "AggregatedStudentDataforSTAT250";
	CREATE TABLE AIM.ADSTAT250 AS
	SELECT *
		FROM Aim.SR INNER JOIN Aim.SC
			ON SC.ANONID = SR.ANONID
		WHERE SC.SUBJECT = 'STATS' AND SC.CATALOG_NBR = 250
		ORDER BY SR.ANONID ASC;
QUIT;


*Some EDA and Data Cleaning steps;

*The Vars like LAST_ACT_ENGL_SCORE should be numerical but some how stored as Char
So we need to do some force type convert;
DATA Aim.Aggregated; 
	set Aim.Adstat250;
	array cha{*} HSGPA 
		LAST_ACT_ENGL_SCORE LAST_ACT_COMP_SCORE LAST_ACT_MATH_SCORE LAST_ACT_READ_SCORE LAST_SATI_MATH_SCORE LAST_ACT_SCIRE_SCORE 
		LAST_SATI_VERB_SCORE LAST_SATI_MATH_SCORE LAST_SATI_TOTAL_SCORE;
	array num{*} HSGPA1 
		LAST_ACT_ENGL LAST_ACT_COMP LAST_ACT_MATH LAST_ACT_READ LAST_SATI_MATH LAST_ACT_SCIRE 
		LAST_SATI_VERB LAST_SATI_MATH LAST_SATI_TOTAL;
	do i = 1 to dim(cha);
		num(i) = input(cha(i),best12.);
	end;
RUN;

/*
data Aim.test; set Aim.Adstat250;

a = input(HSGPA,best12.);
run;
%macro numeric(var);
      &var._c=input(&var ,12.);
%mend numeric;

DATA trans; set aim.adstat250;
%numeric(LAST_ACT_ENGL_SCORE);
run;
*/

PROC FREQ data = Aim.Adstat250;
		tables SEX MAJOR1_DESCR TERM ADMIT_TERM;
	RUN;

PROC MEANS DATA = Aim.Aggregated;
	VAR HSGPA1 
		LAST_ACT_ENGL LAST_ACT_COMP LAST_ACT_MATH LAST_ACT_READ LAST_SATI_MATH LAST_ACT_SCIRE 
		LAST_SATI_VERB LAST_SATI_MATH LAST_SATI_TOTAL;
RUN;


PROC SUMMARY DATA = Aim.ADSTAT250;
	VAR  GRD_PTS_PER_UNIT GPAO;

RUN;

PROC MEANS DATA = Aim.adstat250;
 	VAR LAST_ACT_ENGL_SCORE;
RUN;

/* Create a macro to do EDA, regression, and residual plotting */
%macro regAndPlot(data, y, x);
    /* Double quotes are needed to allow substitution */
    TITLE "EDA of &data: &y on &x";
    /* RL is regression, linear for adding a fit line to a plot */
    SYMBOL INTERPOL=RL VALUE=plus;
    PROC GPLOT DATA=&data;
      PLOT &y * &x;
    RUN;

    TITLE "Regression analysis for &data";
    PROC GLM DATA=&data;
      MODEL &y = &x / SOLUTION;
      OUTPUT OUT=_temp RESIDUAL=res PREDICTED=pred;
    RUN;

    TITLE;
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      OUTPUT OUT=_tmpstd STD=stdev;
    RUN;

    DATA _NULL_;
      SET _tmpstd;
      CALL SYMPUT('resSD',stdev);
    RUN;

    TITLE "Regression with &data data: &y on &x";
    TITLE2 'Quantile normal plot of residuals';
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      QQPLOT / NORMAL (MU=0 SIGMA=&resSD COLOR=red);
    RUN;

    TITLE2 'Residual vs. fit plot';
    PROC GPLOT DATA=_temp;
      PLOT res*pred / VREF=0;
    RUN;  
%mend regAndPlot;

/* Test the macro on the algebra data */
/* Note: call does not end with a semicolon. */
%regAndPlot(Aim.Aggregated, GRD_PTS_PER_UNIT, GPAO)

