*/ Re-write University of Michigan Stat-250 Course Performance Analysis in SAS Code/*

*set library; 
LIBNAME Aim "C:\Users\xiaosong\Documents\GitHub\aim-analytics\SAS";

PROC IMPORT OUT= Aim_sas.StudentCourse 
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.course.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


PROC IMPORT OUT= Aim_sas.StudentRecord
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.record.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

DATA new; SET Aim.StudentRecord Aim.StudentCourse;
run;

PROC SQL;
	*TITLE "AggregatedStudentDataforSTAT250";
	CREATE TABLE AIM.ADSTAT250 AS
	SELECT *
		FROM Aim.StudentRecord SR INNER JOIN Aim.StudentCourse SC
			ON SC.ANONID = SR.ANONID
		WHERE SC.SUBJECT = 'STATS' AND SC.CATALOG_NBR = 250
		ORDER BY SR.ANONID ASC;
QUIT;


DATA new; SET Aim.Adstat250;
run;

PROC FREQ data = Aim.Adstat250;
		tables SEX;
	RUN;





