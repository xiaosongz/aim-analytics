PROC IMPORT OUT= AIM.STUDENTRECORD 
            DATAFILE= "C:\Users\xiaosong\Documents\GitHub\aim-analytics\
SAS\student.record.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
