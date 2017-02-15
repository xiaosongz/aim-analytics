/*_________________________________________________________________*/
/* PROGRAM:  YA_mortality_inc03.sas                                */                                        
/* Created by: Nan J on 5/2/2016                                   */
/* Purpose: Used in creating CVD mortality figure for YA paper     */
/*******************************************************************/

%include "\\keccfs01\projects\usrds\Analysis\ADR\2016\Documentation\ADR_inc.sas";
Options nofmterr; **to suppress errors;
OPTIONS LS=110 PS=90 NOCENTER NODATE NONUMBER;

libname demo "\\keccfs01\projects\usrds\data\ADR\2016\CWF\ESRD";
libname inc "\\keccfs01\projects\usrds\data\ADR\2016\CWF\ESRD\Incident2\ALL\NO_60DAY\0_MONTH\W_CHGDATES";
libname ex "\\keccfs01\projects\usrds\data\ADR\2016\Chapter\ESRD\c08_Pediatric\ADR";
libname zip "\\keccfs01\projects\usrds\Analysis\Research\Manuscript\12_Young_Adult_Trends\YoungAdult";

proc format;
	value pri_diag 1= 'GN'
               2= 'SecGN'
               3= 'Cystic/here./Cong.'
               4= 'Other'
               ;
run;


DATA hd_nid;
 set inc.inc_1y03 inc.inc_1y04 inc.inc_1y05 inc.inc_1y06 inc.inc_1y07 inc.inc_1y08 inc.inc_1y09 inc.inc_1y10 inc.inc_1y11 inc.inc_1y12 inc.inc_1y13;
 by kecc_id;
 year=year(modaldat);
 modality=1; *HD;
run;

DATA pd_nid;
 set inc.inc_2y03 inc.inc_2y04 inc.inc_2y05 inc.inc_2y06 inc.inc_2y07 inc.inc_2y08 inc.inc_2y09 inc.inc_2y10 inc.inc_2y11 inc.inc_2y12 inc.inc_2y13;
 by kecc_id;
 year=year(modaldat);
 modality=2; *PD;
run;

DATA oth_nid;
 set inc.inc_5y03 inc.inc_5y04 inc.inc_5y05 inc.inc_5y06 inc.inc_5y07 inc.inc_5y08 inc.inc_5y09 inc.inc_5y10 inc.inc_5y11 inc.inc_5y12 inc.inc_5y13;
 by kecc_id;
 year=year(modaldat);
 modality=4; *Other;
run;

DATA tx_nid;
 set inc.inc_6y03 inc.inc_6y04 inc.inc_6y05 inc.inc_6y06 inc.inc_6y07 inc.inc_6y08 inc.inc_6y09 inc.inc_6y10 inc.inc_6y11 inc.inc_6y12 inc.inc_6y13;
 by kecc_id;
 year=year(modaldat);
 modality=3; *Tx;
run;

data esrd_nid;
 set hd_nid pd_nid oth_nid tx_nid;
 by kecc_id;
run;

%macro usrdsid(dat);
proc sql;
	create table &dat. as
	select a.*, b.usrds_id
	from &dat._nid as a, demo.adrind1 as b
	where a.kecc_id=b.kecc_id
	order by usrds_id;
	quit;
	
%mend;
%usrdsid(hd);
%usrdsid(pd);
%usrdsid(tx);
%usrdsid(oth);
%usrdsid(esrd);

	
* COMBINE INCIDENT DATA SET WITH DEMOGRAPHIC DATA;                            
proc sort data=demo.residenc (keep = usrds_id begres endres state) out=res2; by usrds_id  begres; run; 
%let year1=2003;
%let year2=2013;
%let residence=res2;
%macro res(DA);
	%do year=&year1. %to &year2.;			
		data res;
			set &residence.;
			where usrds_id not in(0,.) AND begres <= mdy(12,31,&year.) AND mdy(1,1,&year.) <= endres AND	
				state in('01','02','04','05','06','08','09','10','11','12',
							 '13','15','16','17','18','19','20','21','22','23',
							 '24','25','26','27','28','29','30','31','32','33',
							 '34','35','36','37','38','39','40','41','42','44',
							 '45','46','47','48','49','50','51','53','54','55',
							 '56','60','66','69','72','78')
			;
			*state = fipstate(statefips);
			keep usrds_id state begres endres;
		run;

		proc sort data=res;
			by usrds_id begres endres;
		run;
		
		data res&year.;
			set res;
			by usrds_id begres endres;
			if first.usrds_id;
			year=&year.;
		run;
		
		proc sql;
			create table &DA._&year. as
			select a.*,  b.state, b.begres, b.endres
			from &DA.  a , res&year. b
			where a.usrds_id=b.usrds_id and a.year=b.year
			order by usrds_id;
			quit;
     run;

	%end;
data &DA.;
	set &DA._2003 &DA._2004 &DA._2005 &DA._2006 &DA._2007 &DA._2008 &DA._2009 &DA._2010 &DA._2011 &DA._2012 &DA._2013;
     by usrds_id;
run;
%mend;

%res(hd);
%res(pd);
%res(tx);
%res(esrd);


proc sort data=demo.patients out=patients; by usrds_id; run;
proc sort data =ex.excwt out=excwt; by usrds_id; run;	
data patients;
	merge patients (in=a)
	excwt (in=b);
	by usrds_id;
	if a=1 and b=0;
run;		
		
/*******************************   HD & PD  ************************************/                          

%MACRO DAT(DA);

DATA F8_10_&DA;
 merge &DA(in=a rename=(year=incyear))
       patients(in=b keep=usrds_id sex race inc_age hispanic born DIED incyear cdeath pdis tx1date);
 by usrds_id incyear;
 if a;

 if sex in ('1' '2');
 if state<='56';
 
 if sex in ('1','M') then sexgrp=1;
 else sexgrp=0;
 
 if hispanic in ('1','Y' ) then hisgrp=1; *hispanic;
 else hisgrp=2; *non hispanic or missing;
 
 if missing(born) then delete;
 if pdis=' ' then delete;
 if born=. then delete;
 
 age = INT(INTCK('MONTH', born, modaldat)/12); 
 if MONTH(born) = MONTH(modaldat) THEN age = age -(DAY(born)>DAY(modaldat)); 

   if 1 le age le 29; 
   if 1 le age lt 12 then age_grp=1;
   else if 12 le age le 21 then age_grp=2;
   else age_grp=3; 
 
if pdis ne '' then do;
  /***** GN************/
if pdis in (/*old ME form*/'5800C','5804B','5820A','5821A','5829A','5831A','5832A','5832C','5834C','58381B','58381C',/**/
'5800Z','5804Z','5820Z','5821Z','5829Z','5831Z','5832Z','5834Z','58381Z','5829Y','5821Y','5831Y','58321Y','58322Y','58381Y','58382Y','5834Y','5800Y','5820Y','44621Y' /*put into GN by MMRF*/
,'4431Z','5809Z','5811Z','5818Z','5819Z','587Z','5811','5819','5832'/*per Deb and David*/
/*new ME form*/,'5829','5821','5831','58321','58322','58381','58382','5834','5800','5820','44621') 
then nas_diag=1;
/*****sec GN************/
else if pdis in (/*old ME form*/'2831A','2870A','4460C','4462A','4464B','5839B','5839C','7100E','7101B',/**/
'2831Z','2870Z','4460Z','4462Z','4464Z','5839Z','7100Z','7101Z','7100Y','58391Y',
'6954Z','2870Y','4460Y','4464Y','44620Y',/*per Deb and David*/
/*new ME form*/'7100','2870','7101','28311','4460','4464','58392','44620','4462','58391')
then nas_diag=2;
/*****cystic/hereditary/congenital************/
else if pdis in (/*old ME form*/'2700A','2718B','2727A','5839D','7530B','75313A','75314A','75316A','7532A','7533A','7567A','7595A','7598A','7598B',/**/
'2700Z','2718Z','2727Z','75313Z','7532Z','7533Z','7567Z','7595Z','7598Z','75313Y','75314Y','75316Y','7595Y',
'7598Y','2700Y','2718Y','2727Y','7533Y','5839Y','75321Y','75322Y','75329Y','75671Y','75989Y',
'5890Z','5891Z','5899Z','591Z','59389Z','753Z','7530Z','7531Z','7539Z','7539','7531',/*per Deb and David*/
/*new ME form*/'75313','75314','75316','7595','7598','2700','2718','2727','7533','5839','75321','75322','75329','7530','75671','75989')
then nas_diag=3;
else nas_diag=4;
end;
 
 if race = '4' then racegrp='1'; *white;
 else if race = '3' then racegrp='2'; *blk;
 else racegrp='3'; *other;
 

 * follow up from day 1 censored at recovered function;
 surtime=min(died,ltfudate, tx1date, mdy(12,31,2014),recvrdat)-modaldat+1;
 if modaldat<died<=min(died,ltfudate,tx1date,mdy(12,31,2014),recvrdat) then dead=1;
 else dead=0;
 
  *CVD;
  if cdeath in ('01', '02', '03', '04','1','2','3','4','23','25','26','27','28','29','30','32','36','61') then dcause=1;

 * Infection;
 /*else if cdeath in ('10','11','12','13','33','34','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59','60','61','62','63','64','65','70','71','74') then dcause=2;*/

 * Other;
 else dcause=2;
 
   
 all_CVD=0; /*all_infect=0;*/ all_other=0;
 if dead=1 and dcause=1 then all_CVD=1;
 /*if dead=1 and dcause=2 then all_infect=1;*/
 if dead=1 and dcause=2 then all_other=1;
run;

 %MEND;
 
%DAT(hd);
%DAT(pd);

/*******************************   TX  ************************************/                          

data F8_10_tx;
set patients (drop=incyear state);
by usrds_id;

* define incident year as tx year;
incyear=year(tx1date);

if 2003<=incyear<=2013;
run;

proc sort data=demo.residenc (keep = usrds_id begres endres state) out=res2; by usrds_id  begres; run; 

%let year1=2003;
%let year2=2013;
%let residence=res2;
%macro res(DA);
	%do year=&year1. %to &year2.;			
		data res;
			set &residence.;
			where usrds_id not in(0,.) AND begres <= mdy(12,31,&year.) AND mdy(1,1,&year.) <= endres AND	
				state in('01','02','04','05','06','08','09','10','11','12',
							 '13','15','16','17','18','19','20','21','22','23',
							 '24','25','26','27','28','29','30','31','32','33',
							 '34','35','36','37','38','39','40','41','42','44',
							 '45','46','47','48','49','50','51','53','54','55',
							 '56','60','66','69','72','78')
			;
			*state = fipstate(statefips);
			keep usrds_id state begres endres;
		run;

		proc sort data=res;
			by usrds_id begres endres;
		run;
		
		data res&year.;
			set res;
			by usrds_id begres endres;
			if first.usrds_id;
			year=&year.;
		run;
		
		
		proc sql;
			create table &DA._&year. as
			select a.*,  b.state, b.begres, b.endres
			from &DA.  a , res&year. b
			where a.usrds_id=b.usrds_id and a.incyear=b.year
			order by usrds_id;
			quit;
     run;

	%end;
data &DA.;
	set &DA._2003 &DA._2004 &DA._2005 &DA._2006 &DA._2007 &DA._2008 &DA._2009 &DA._2010 &DA._2011 &DA._2012 &DA._2013;
     by usrds_id;
run;
%mend;

%res(F8_10_tx);


data F8_10_tx;
 set F8_10_tx;
 by usrds_id;

 if sex in ('1' '2');
 if state<='56';
 
 if sex in ('1','M') then sexgrp=1;
 else sexgrp=0;
 
 if hispanic in ('1','Y' ) then hisgrp=1; *hispanic;
 else hisgrp=2; *non hispanic or missing;
 
if sex in (' ','U') then delete;
if sex in ('1','M') then sexgrp=1;
else sexgrp=0;

 if hispanic in ('1','Y' ) then hisgrp=1; *hispanic;
 else hisgrp=2; *non hispanic or missing;

 if missing(born) then delete;
 if pdis=' ' then delete;
 if born=. then delete;

 age = INT(INTCK('MONTH', born, tx1date)/12); 
 if MONTH(born) = MONTH(tx1date) THEN age = age -(DAY(born)>DAY(tx1date));
 
   if 1 le age le 29; 
   if 1 le age lt 12 then age_grp=1;
   else if 12 le age le 21 then age_grp=2;
   else age_grp=3;
 
    if pdis ne '' then do;
  /***** GN************/
if pdis in (/*old ME form*/'5800C','5804B','5820A','5821A','5829A','5831A','5832A','5832C','5834C','58381B','58381C',/**/
'5800Z','5804Z','5820Z','5821Z','5829Z','5831Z','5832Z','5834Z','58381Z','5829Y','5821Y','5831Y','58321Y','58322Y','58381Y','58382Y','5834Y','5800Y','5820Y','44621Y' /*put into GN by MMRF*/
,'4431Z','5809Z','5811Z','5818Z','5819Z','587Z','5811','5819','5832'/*per Deb and David*/
/*new ME form*/,'5829','5821','5831','58321','58322','58381','58382','5834','5800','5820','44621') 
then nas_diag=1;
/*****sec GN************/
else if pdis in (/*old ME form*/'2831A','2870A','4460C','4462A','4464B','5839B','5839C','7100E','7101B',/**/
'2831Z','2870Z','4460Z','4462Z','4464Z','5839Z','7100Z','7101Z','7100Y','58391Y',
'6954Z','2870Y','4460Y','4464Y','44620Y',/*per Deb and David*/
/*new ME form*/'7100','2870','7101','28311','4460','4464','58392','44620','4462','58391')
then nas_diag=2;
/*****cystic/hereditary/congenital************/
else if pdis in (/*old ME form*/'2700A','2718B','2727A','5839D','7530B','75313A','75314A','75316A','7532A','7533A','7567A','7595A','7598A','7598B',/**/
'2700Z','2718Z','2727Z','75313Z','7532Z','7533Z','7567Z','7595Z','7598Z','75313Y','75314Y','75316Y','7595Y',
'7598Y','2700Y','2718Y','2727Y','7533Y','5839Y','75321Y','75322Y','75329Y','75671Y','75989Y',
'5890Z','5891Z','5899Z','591Z','59389Z','753Z','7530Z','7531Z','7539Z','7539','7531',/*per Deb and David*/
/*new ME form*/'75313','75314','75316','7595','7598','2700','2718','2727','7533','5839','75321','75322','75329','7530','75671','75989')
then nas_diag=3;
else nas_diag=4;
end;
 
  if race = '4' then racegrp='1'; *white;
else if race = '3' then racegrp='2'; *blk;
else racegrp='3'; *other;

  surtime=min(died,mdy(12,31,2014))-tx1date + 1;
 if min(died,mdy(12,31,2014))=died then dead=1;
 else dead=0;

 
  *CVD;
  if cdeath in ('01', '02', '03', '04','1','2','3','4','23','25','26','27','28','29','30','32','36','61') then dcause=1;

 * Infection;
 /*else if cdeath in ('10','11','12','13','33','34','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59','60','61','62','63','64','65','70','71','74') then dcause=2;*/

 * Other;
 else dcause=2;
    

 all_CVD=0; /*all_infect=0;*/ all_other=0;
 if dead=1 and dcause=1 then all_CVD=1;
 /*if dead=1 and dcause=2 then all_infect=1;*/
 if dead=1 and dcause=2 then all_other=1;
run;


/*******************************   ESRD  ************************************/ 

%MACRO DAT(DA);

DATA F8_10_&DA;
 merge &DA(in=a rename=(year=incyear))
       patients(keep=usrds_id sex race hispanic born DIED incyear cdeath pdis );
 by usrds_id incyear;
 if a;

 if sex in ('1' '2');
 if state<='56';
 
 if sex in ('1','M') then sexgrp=1;
 else sexgrp=0;
 
 if missing(born) then delete;
 if pdis=' ' then delete;
 if born=. then delete;
 
  if hispanic in ('1','Y' ) then hisgrp=1; *hispanic;
    else hisgrp=2; *non hispanic or missing;
    
 age = INT(INTCK('MONTH', born, modaldat)/12); 
 IF MONTH(born) = MONTH(modaldat) THEN age = age -(DAY(born)>DAY(modaldat));
 
   if 1 le age le 29; 
   if 1 le age lt 12 then age_grp=1;
   else if 12 le age le 21 then age_grp=2;
   else age_grp=3; 
 
    if pdis ne '' then do;
  /***** GN************/
if pdis in (/*old ME form*/'5800C','5804B','5820A','5821A','5829A','5831A','5832A','5832C','5834C','58381B','58381C',/**/
'5800Z','5804Z','5820Z','5821Z','5829Z','5831Z','5832Z','5834Z','58381Z','5829Y','5821Y','5831Y','58321Y','58322Y','58381Y','58382Y','5834Y','5800Y','5820Y','44621Y' /*put into GN by MMRF*/
,'4431Z','5809Z','5811Z','5818Z','5819Z','587Z','5811','5819','5832'/*per Deb and David*/
/*new ME form*/,'5829','5821','5831','58321','58322','58381','58382','5834','5800','5820','44621') 
then nas_diag=1;
/*****sec GN************/
else if pdis in (/*old ME form*/'2831A','2870A','4460C','4462A','4464B','5839B','5839C','7100E','7101B',/**/
'2831Z','2870Z','4460Z','4462Z','4464Z','5839Z','7100Z','7101Z','7100Y','58391Y',
'6954Z','2870Y','4460Y','4464Y','44620Y',/*per Deb and David*/
/*new ME form*/'7100','2870','7101','28311','4460','4464','58392','44620','4462','58391')
then nas_diag=2;
/*****cystic/hereditary/congenital************/
else if pdis in (/*old ME form*/'2700A','2718B','2727A','5839D','7530B','75313A','75314A','75316A','7532A','7533A','7567A','7595A','7598A','7598B',/**/
'2700Z','2718Z','2727Z','75313Z','7532Z','7533Z','7567Z','7595Z','7598Z','75313Y','75314Y','75316Y','7595Y',
'7598Y','2700Y','2718Y','2727Y','7533Y','5839Y','75321Y','75322Y','75329Y','75671Y','75989Y',
'5890Z','5891Z','5899Z','591Z','59389Z','753Z','7530Z','7531Z','7539Z','7539','7531',/*per Deb and David*/
/*new ME form*/'75313','75314','75316','7595','7598','2700','2718','2727','7533','5839','75321','75322','75329','7530','75671','75989')
then nas_diag=3;
else nas_diag=4;
end;
 
  if race = '4' then racegrp='1'; *white;
else if race = '3' then racegrp='2'; *blk;
else racegrp='3'; *other;

  * follow up from day 1;

 surtime=min(died,ltfudate, mdy(12,31,2014),recvrdat)-modaldat+1;
 if modaldat<died<=min(died,ltfudate,mdy(12,31,2014),recvrdat) then dead=1;
 else dead=0;
 
  *CVD;
  if cdeath in ('01', '02', '03', '04','1','2','3','4','23','25','26','27','28','29','30','32','36','61') then dcause=1;

 * Infection;
 /*else if cdeath in ('10','11','12','13','33','34','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59','60','62','63','64','65','70','71','74') then dcause=2;*/

 * Other;
 else dcause=2;
    

 all_CVD=0; /*all_infect=0;*/ all_other=0;
 if dead=1 and dcause=1 then all_CVD=1;
 /*if dead=1 and dcause=2 then all_infect=1;*/
 if dead=1 and dcause=2 then all_other=1;
run;

 %MEND;
 
%DAT(esrd);


*************************************************************************;
************** 2010-2011 ESRD data is used to as reference   ************;
*************************************************************************;

proc format;
        value racegrp      1='White' 2='Black' 3='Other';
        value sexgrp       1='Male' 2='Female';
        value hisgrp       1='Hispanic' 2='Non-hispanic';
        value diaggrp      1='GN' 2='Sec GN' 3='Cystic/Hereditary/Congenital' 4='other';
        value all 1="ALL";
run;


********************* reference 2009-2010 ESRD ***********;
data ref2;
  set F8_10_ESRD;
  if incyear in (2010,2011);
  surtime=surtime/30.5;
  by usrds_id;
  surstat=dead;
	 
  if racegrp=2 then race1=1;else race1=0;
  if racegrp=3 then race2=1;else race2=0;
  if nas_diag=2 then diab1=1;else diab1=0;
  if nas_diag=3 then diab2=1;else diab2=0;
  if nas_diag=4 then diab3=1;else diab3=0;
  if age_grp=1 then age1=1; else age1=0;
  if age_grp=2 then age2=1; else age2=0;
  if hisgrp=2 then hisgrp1=1; else hisgrp1=0;

  keep surtime surstat sexgrp racegrp race1 race2 age1 age2 nas_diag diab1 diab2 diab3 incyear hisgrp hisgrp1;
run;


%MACRO CAUSE(CAU,DAT);
data all;
  set F8_10_&DAT( rename=(incyear=incyear0));
  surstat=&CAU;
run;
	
proc sort data=all; by usrds_id;

data &DAT&CAU;
  set all; 
  
  if racegrp=2 then race1=1;else race1=0;
  if racegrp=3 then race2=1;else race2=0;
  if nas_diag=2 then diab1=1;else diab1=0;
  if nas_diag=3 then diab2=1;else diab2=0;
  if nas_diag=4 then diab3=1;else diab3=0;
  if age_grp=1 then age1=1; else age1=0;
  if age_grp=2 then age2=1; else age2=0;
  if hisgrp=2 then hisgrp1=1;else hisgrp1=0;

  keep surtime surstat sexgrp racegrp race1 race2 age1 age2 nas_diag diab1 diab2 diab3 hisgrp hisgrp1 age_grp;
run;

proc print data=&DAT&CAU (obs=15);run;
%MEND;
%CAUSE(dead,HD);
%CAUSE(all_CVD,HD);
*%CAUSE(all_infect,HD);
%CAUSE(dead,PD);
%CAUSE(all_CVD,PD);
*%CAUSE(all_infect,PD);
%CAUSE(dead,tx);
%CAUSE(all_CVD,tx);
*%CAUSE(all_infect,tx);
%CAUSE(all_CVD,ESRD);


%MACRO CAUSE(CAU,DAT);
%macro result;

%let refdata=ref2;
%let data=&DAT&CAU;
options mprint;


/**********  Survival Prob for All **********************/

%let covariat=sexgrp age1 age2 diab1 diab2 diab3 race1 race2 hisgrp1;
%let last1=hisgrp1;

%macro all(gender);
proc sort data=&refdata;
by &covariat;
run;

data covmean;
    set &refdata;
    by &covariat;
    if last.&last1;
keep &covariat;
run;

data covmean;
    set covmean;
    group=_n_;
    run;

data txca1;
  merge &refdata covmean;
  by &covariat;
  run;

proc sort data=&data;
by &covariat;
run;

data txca2;
  merge &data covmean;
  by &covariat;
  run;

/***************  Adjusted Survival  ****************/

proc freq data=txca1;
  table group/out=prop;
run;

proc phreg data=txca2;
  model surtime*surstat(0)=&covariat;
  baseline out=adjust covariates=covmean survival=s stderr=err l=lcl u=ucl/nomean;
  id group;
run;

data adjust1;
  set adjust;
  if surtime<&time;
  run;

proc sort data=adjust1;
  by group surtime;
run;

data adjust2;
  set adjust1;
  by group surtime;
  if last.group;
  rate=-log(s)*1000;
run;

proc sort;
  by group;
  run;

data adjust3;
  merge adjust2 prop;
  by group;
  if percent^=.;
run;


proc means mean noprint data=adjust3;
  var rate; 
  weight percent;
  output out=adfinal mean(rate)=rate;
run;

data adfinal;
 set adfinal;
 s=exp(-rate/1000)*100;
run;

data &gender;
     set adfinal;
     all=1;
 run;
%mend;

%all(allg);


/**********  Survival Prob for Age **********************/

%let covariat=sexgrp diab1 diab2 diab3 race1 race2 hisgrp1;
%let last1=hisgrp1;

%macro all(gender);
proc sort data=&refdata;
by &covariat;
run;

data covmean;
    set &refdata;
    by &covariat;
    if last.&last1;
keep &covariat;
run;

data covmean;
    set covmean;
    group=_n_;
    run;

data txca1;
  merge &refdata covmean;
  by &covariat;
  run;

proc sort data=&data;
by &covariat;
run;

data txca2;
  merge &data covmean;
  by &covariat;
  run;

/***************  Adjusted Survival  ****************/

proc freq data=txca1;
  table group/out=prop;
run;

proc phreg data=txca2;
  model surtime*surstat(0)=&covariat;
  strata age_grp;
  baseline out=adjust covariates=covmean survival=s stderr=err l=lcl u=ucl/nomean;
  id group;
run;

data adjust1;
  set adjust;
  if surtime<&time;
  run;

proc sort data=adjust1;
  by age_grp group surtime;
run;

data adjust2;
  set adjust1;
  by age_grp group surtime;
  if last.group;
  rate=-log(s)*1000;
run;

proc sort;
  by group;
  run;

data adjust3;
  merge adjust2 prop;
  by group;
  if percent^=.;
run;

proc sort;
  by age_grp;
run;

proc means mean noprint data=adjust3;
  var rate; 
  weight percent;
  by age_grp;
  output out=adfinal mean(rate)=rate;
run;

data adfinal;
 set adfinal;
 s=exp(-rate/1000)*100;
run;

data &gender;
     set adfinal;
     all=1;
 run;
%mend;

%all(allg);

data m1&DAT&CAU;
set allg;
run;

%mend;

%let time=365.25; **one year;

%result;

%MEND;
%CAUSE(dead,HD);
%CAUSE(all_CVD,HD);
*%CAUSE(all_infect,HD);
%CAUSE(dead,PD);
%CAUSE(all_CVD,PD);
*%CAUSE(all_infect,PD);
%CAUSE(dead,TX);
%CAUSE(all_CVD,TX);
*%CAUSE(all_infect,TX);
%CAUSE(all_CVD,ESRD);

*******************************************************************;
*************************** OUTput ********************************;
*******************************************************************;

options ls=100;

%MACRO CAUSE(CAU,DAT,num);

data &DAT&CAU&NUM;
 set M1&DAT&CAU;
 mod=&num;
run;

%MEND;
%CAUSE(dead,HD,1);
%CAUSE(all_CVD,HD,1);
*%CAUSE(all_infect,HD,1);
%CAUSE(dead,PD,2);
%CAUSE(all_CVD,PD,2);
*%CAUSE(all_infect,PD,2);
%CAUSE(dead,TX,3);
%CAUSE(all_CVD,TX,3);
*%CAUSE(all_infect,TX,3);
%CAUSE(all_CVD,ESRD);


data allcause;
 set HDdead1 PDdead2 TXdead3;
run;

data CVD;
 set HDall_cvd1 PDall_cvd2 TXall_cvd3;
run;


** Only output CVD rate;
ODS CSV file="\\......\One_year_CVD_mortality_inc03.csv";

proc tabulate data=cvd noseps missing fc='|           ';
class age_grp mod;
var rate;
table age_grp='', mod=''*(rate='')*mean=''/rts=10;
title "CVD";
run;
proc tabulate data=cvd noseps missing fc='|           ';
class age_grp;         
var rate;
table age_grp='', (rate='')*mean=''/rts=10;
title "CVD all";
run;

ODS CSV close;