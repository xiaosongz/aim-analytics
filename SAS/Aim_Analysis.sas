/*__________________________________________________________________________________*/
*/ Re-write University of Michigan Stat-250 Course Performance Analysis in SAS      */
*/ Created By: Xiaosong Zhang on 2/15/2017                                          */
*/ All the data and .sas programs are avaliable at git.xiaosongz.com                */
*/ under aim-analytics repository or use https://github.com/xiaosongz/aim-analytics */
/************************************************************************************/

*set library location(On 6700KGTX1080); 
LIBNAME Aim "C:\Users\xiaosong\Documents\GitHub\aim-analytics\SAS";
ods rtf file='output.rtf';
/* Some logs included to demostrate the dimension of the two data tables used in this analysis*/
/*
NOTE: There were 1327065 observations read from the data set AIM.STUDENTCOURSE.
NOTE: The data set AIM.SC has 1327065 observations and 8 variables.
NOTE: DATA statement used (Total process time):
      real time           0.31 seconds
      cpu time            0.29 seconds
NOTE: There were 138888 observations read from the data set AIM.STUDENTRECORD.
NOTE: The data set AIM.SR has 138888 observations and 23 variables.
NOTE: DATA statement used (Total process time):
      real time           0.14 seconds
      cpu time            0.14 seconds
*/

*load neccessary MACROs might be useful later;
%INCLUDE "density.sas";
%INCLUDE "boxglm.sas";
%INCLUDE "scatmat.sas";
%INCLUDE "cpplot.sas";
%INCLUDE "genscat.sas";
%INCLUDE "boxanno.sas";

*Import Student Course table from CSV;

PROC IMPORT OUT= Aim.StudentCourse 
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.course.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

*Import Student Records table from CSV;
PROC IMPORT OUT= Aim.StudentRecord
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.record.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

*Cleaning the table, define Char "NA" as missing value which could be interpreted by SAS;

%macro DefineNAs(want,have);
DATA  &want; 
SET &have;
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
%mend ;

%DefineNAs(Aim.SC, Aim.StudentCourse);
%DefineNAs(Aim.SR,Aim.StudentRecord);


*Using PROC SQL to JOIN Student records and Student Course table and select entries 
that only related to STATS250(Intro to Statistics);
PROC SQL;
	*TITLE "AggregatedStudentDataforSTAT250";
	CREATE TABLE AIM.STATS250 AS
	SELECT *
		FROM Aim.SR INNER JOIN Aim.SC
			ON SC.ANONID = SR.ANONID
		WHERE SC.SUBJECT = 'STATS' AND SC.CATALOG_NBR = 250
		ORDER BY SR.ANONID ASC;
QUIT;


*Some EDA and Data Cleaning steps;

*The Vars like LAST_ACT_ENGL_SCORE should be numerical but some how stored as Char
So we need to do some force type convert;
DATA Aim.STATS250C; 
	set Aim.STATS250;
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


/*EDA */
PROC FREQ data = Aim.STATS250C;
		tables SEX MAJOR1_DEPT;
	RUN;

PROC MEANS DATA = Aim.STATS250C;
	VAR HSGPA1 
		LAST_ACT_ENGL LAST_ACT_COMP LAST_ACT_MATH LAST_ACT_READ LAST_SATI_MATH LAST_ACT_SCIRE 
		LAST_SATI_VERB LAST_SATI_MATH LAST_SATI_TOTAL;
RUN;

proc univariate data=Aim.STATS250C;
histogram HSGPA1 
		LAST_ACT_COMP LAST_ACT_MATH LAST_SATI_MATH LAST_ACT_SCIRE 
		LAST_SATI_MATH;
run;

/*     Create a macro to do EDA, regression, and residual plotting      */
/*Retrieved from http://www.stat.cmu.edu/~hseltman/SASworkshop/macro.sas*/
/*     Modified by Xiaosong Zhang                                       */
%macro regAndPlot(data, y, x);
    /* Double quotes are needed to allow substitution */
    TITLE "EDA of &data: &y on &x";
    /* RL is regression, linear for adding a fit line to a plot */

	/*Creat scatter plot*/ 
    SYMBOL INTERPOL=RL VALUE=plus;
    PROC GPLOT DATA=&data;
      PLOT &y * &x;
    RUN;
	/*Creat univerate leastsquare regression solution*/
    TITLE "Regression analysis for &data";
    PROC GLM DATA=&data;
      MODEL &y = &x / SOLUTION;
      OUTPUT OUT=_temp RESIDUAL=res PREDICTED=pred;
    RUN;
	/*Calculate residual for later use*/
    TITLE;
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      OUTPUT OUT=_tmpstd STD=stdev;
    RUN;

    DATA _NULL_;
      SET _tmpstd;
      CALL SYMPUT('resSD',stdev);
    RUN;

	/*Q-Q plot for residual*/
    TITLE "Regression with &data data: &y on &x";
    TITLE2 'Quantile normal plot of residuals';
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      QQPLOT / NORMAL (MU=0 SIGMA=&resSD COLOR=red);
    RUN;
	/*Residual vs fit plot Visualization*/
    TITLE2 'Residual vs. fit plot';
    PROC GPLOT DATA=_temp;
      PLOT res*pred / VREF=0;
    RUN;  
%mend regAndPlot;


/* regAndPlot Macro retrieved from CMU SAS workshop website*/
/*Use regAndPlot to do  mutiple EDA, some lines quoted to reduce the length of output*/
*%regAndPlot(Aim.STATS250C, GRD_PTS_PER_UNIT, HSGPA1 );
%regAndPlot(Aim.STATS250C, GRD_PTS_PER_UNIT, GPAO);
*%regAndPlot(Aim.STATS250C, GRD_PTS_PER_UNIT, LAST_ACT_MATH);
*%regAndPlot(Aim.STATS250C, GRD_PTS_PER_UNIT, LAST_SATI_MATH);

RUN;

/*Showing fit a model using PROC GLM, more models and classifiers were tested using R and Python
code Can be re-write in SAS upon request */
PROC GLM DATA= Aim.STATS250C;
    CLASS SEX;
	MODEL GRD_PTS_PER_UNIT = GPAO SEX HSGPA1 LAST_ACT_MATH /SOLUTION;
	RUN;
ods rtf close;

/*This is the end of this program*/
/*If you have any questions please do not hesitate to contact me @ xiaosong.zhang@utoledo.edu*/