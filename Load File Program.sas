/*Create LP & MFP Loadfiles
  Created by - Intrasectoral SAS Team (Chris Morris, Jerin Varghese, Noah Yosif)
  Last Modified - 12/28/2016 
  Modifed by - Chris Morris */

/*********************************************/
/*Read in macro variables from external file */
/*********************************************/

/* This DATA step creates macro variables for the LP and MFP directories as well as for the most recent 
   Census year and most recent year of data. These variables are used throughout the IntraSectoral programs. */
data _null_;
	length filepath_lp $200 filepath_mfp $200 lastcensus 4 lastyear 4;
	infile "J:\SAS Testing\IntraSectoral\Programs\IntraSectoral_Parameters.csv" dlm =',' firstobs = 2;
	input filepath_lp $ filepath_mfp $ lastcensus lastyear;
	call symputx('filepath_lp',filepath_lp);
	call symputx('filepath_mfp',filepath_mfp);
	call symputx('lastcensus',lastcensus);
	call symputx('lastyear',lastyear);
run;

/****************************************/
/******* Create Load File 1997-EY *******/
/****************************************/

%macro CreateLoadFile_1997_EY (filepath = );
%do x = 1997 %to &lastcensus %by 5;

libname int&x "&filepath&x";
%let CensusPeriod = %sysevalf((0.2*&x) - 388.4); * Used linear relationship between year and Census period.;
%let TQ = "OUT%substr(&x,3,2)%substr(%eval(&x+5),3,2).xlsb";
%let TQ2 = OUT%substr(&x,3,2)%substr(%eval(&x+5),3,2)Paste;

	%macro TQPaste;
	%if &x < &lastcensus %then %do;
		%do year = &x %to &x+5;

		%let Yearno=%eval(&year-&x+1);
		%let YearID=C&CensusPeriod.Y&YearNo.A01;

		data work.matrix&year;
			set int&x..finalresults&year;
		run;

		Proc sql;
			Create table 	work.IntraInd&year as 
			select 			a.IndustryCodeID,a.IndustryID,"VSIntra" as DataSeriesCodeID,"XT41" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and (a.IndustryCodeID=b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra5Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect1" as DataSeriesCodeID,"XT08" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,5)=substr(b.consumer,1,5) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra4Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect2" as DataSeriesCodeID,"XT09" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,4)=substr(b.consumer,1,4) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra3Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect3" as DataSeriesCodeID,"XT10" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,3)=substr(b.consumer,1,3) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Join&year	as
			Select 			* 				from 	work.IntraInd&year 		union all
			Select 			* 				from 	work.Intra5Digit&year 	union all
			Select 			* 				from 	work.Intra4Digit&year	union all
			Select 			* 				from 	work.Intra3Digit&year;
		quit;

		%end;

	%let final = %eval(&x + 5);
	Proc Sql;
		Create table 		work.&TQ2 as 
		%do year = &x %to &final-1;
			Select 			* 				from	work.Join&year 	union all
		%end;
		Select 				* 				from	work.Join&final
		order by 			IndustryCodeID, Year, DataSeriesCodeID;
	quit;

	%end;

	%else %do; 
		%do year = &x %to &lastyear; * !!! For lastcensus year, only want the program to go up to lastyear.;

		%let Yearno=%eval(&year-&x+1);
		%let YearID=C&CensusPeriod.Y&YearNo.A01;

		data work.matrix&year;
			set int&x..finalresults&year;
		run;

		Proc sql;
			Create table 	work.IntraInd&year as 
			select 			a.IndustryCodeID,a.IndustryID,"VSIntra" as DataSeriesCodeID,"XT41" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and (a.IndustryCodeID=b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra5Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect1" as DataSeriesCodeID,"XT08" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,5)=substr(b.consumer,1,5) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra4Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect2" as DataSeriesCodeID,"XT09" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,4)=substr(b.consumer,1,4) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Intra3Digit&year as 
			select 			a.IndustryCodeID,a.IndustryID,"IntSect3" as DataSeriesCodeID,"XT10" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
							&TQ as TQFile,&Year as Year,"&YearID" as YearID,case when sum(b.value)is null then 0  else sum(b.value) end as Value,"TRUE" as Match 
			from 			int&x..TQFolders a 
			left join 		work.matrix&year b
			on 				(a.IndustryCodeID=b.producer) and substr(a.IndustryCodeID,1,3)=substr(b.consumer,1,3) and (a.IndustryCodeID ne b.consumer)
			group by 		a.IndustryCodeID, a.IndustryID;

			Create table 	work.Join&year as
			Select 			* 					from 	work.IntraInd&year 		union all
			Select 			* 					from 	work.Intra5Digit&year 	union all
			Select 			* 					from 	work.Intra4Digit&year 	union all
			Select 			* 					from 	work.Intra3Digit&year;
		quit;

		%end;

	Proc Sql;
		Create table work.&TQ2 as 
		%do year = &x %to &lastyear-1;
			Select 			* 				from	work.Join&year 	union all
		%end;
		Select 				* 				from 	work.Join&lastyear
		order by 			IndustryCodeID, Year, DataSeriesCodeID;
	quit;

	%end;

	data work.&TQ2;
		set work.&TQ2;
		Value=Round(Value/1000,.001);
	run;

	data int&x..&TQ2;
		set work.&TQ2;
	run;
	%mend TQPaste;
	%TQPaste;

%end;
%mend CreateLoadFile_1997_EY;

/******************************************/
/******* Create Load File 1987-1997 *******/
/******************************************/

%macro CreateLoadFile_1987_97 (filepath = );
libname intra "&filepath\1987_1997";
libname source "&filepath\1997";
run;

Proc sql;
	Create table 	work.IndYears as 
	Select			IndustryCodeID, DataSeriesCodeID, YearID, Year
	from 			intra.ValShip8797
	where			DataSeriesCodeID="ValShipP";
quit;

Proc sql;
	Create table	work.Shipments8797 as
	Select			IndustryCodeID, YearID, Year, sum(value) as Value
	from			intra.ValShip8797
	group by		IndustryCodeID, YearID, Year;
quit;

Proc sql;
	Create table	work.Shipments1997 as
	Select			IndustryCodeID, YearID, Year, sum(value) as Value
	from			intra.ValShip97
	group by		IndustryCodeID, YearID, Year;
quit;

Proc sql;
	Create table	work.Ratios1997 as
	Select 			a.*, a.Value/b.Value as Ratio
	from			source.Out9702paste a, work.Shipments1997 b
	where			(a.IndustryCodeID=b.IndustryCodeID) and (a.YearID="C11Y1A01");
quit;

Proc sql;
	Create table 	work.IntraInd as 
	select 			a.IndustryCodeID,b.IndustryID,"VSIntra" as DataSeriesCodeID,"XT41" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
					case when substr(a.YearID,1,3)="C09" then "OUT8792.xlsb" else "OUT9297.xlsb" end as TQFile,a.Year,a.YearID,a.Value*b.Ratio as Value,"FALSE" as Match 
	from 			work.Shipments8797 a, work.Ratios1997 b
	where 			(a.IndustryCodeID=b.IndustryCodeID) and b.DataSeriesID="XT41";
quit;

Proc sql;
	Create table 	work.Intra5Digit as 
	select 			a.IndustryCodeID,b.IndustryID,"IntSect1" as DataSeriesCodeID,"XT08" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
					case when substr(a.YearID,1,3)="C09" then "OUT8792.xlsb" else "OUT9297.xlsb" end as TQFile,a.Year,a.YearID,a.Value*b.Ratio as Value,"FALSE" as Match 
	from 			work.Shipments8797 a, work.Ratios1997 b
	where 			(a.IndustryCodeID=b.IndustryCodeID) and b.DataSeriesID="XT08";
quit;

Proc sql;
	Create table 	work.Intra4Digit as 
	select 			a.IndustryCodeID,b.IndustryID,"IntSect2" as DataSeriesCodeID,"XT09" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
					case when substr(a.YearID,1,3)="C09" then "OUT8792.xlsb" else "OUT9297.xlsb" end as TQFile,a.Year,a.YearID,a.Value*b.Ratio as Value,"FALSE" as Match 
	from 			work.Shipments8797 a, work.Ratios1997 b
	where 			(a.IndustryCodeID=b.IndustryCodeID) and b.DataSeriesID="XT09";
quit;

Proc sql;
	Create 			table work.Intra3Digit as 
	select 			a.IndustryCodeID,b.IndustryID,"IntSect3" as DataSeriesCodeID,"XT10" as DataSeriesID,"00" as DataArrayID,"" as DataArrayCode,"" as DataArrayTitle,
					case when substr(a.YearID,1,3)="C09" then "OUT8792.xlsb" else "OUT9297.xlsb" end as TQFile,a.Year,a.YearID,a.Value*b.Ratio as Value,"FALSE" as Match 
	from 			work.Shipments8797 a, work.Ratios1997 b
	where 			(a.IndustryCodeID=b.IndustryCodeID) and b.DataSeriesID="XT10";
quit;

Proc Sql;
	Create table 	work.JoinAll as
	Select 			* 					from work.IntraInd 		union all
	Select 			* 					from work.Intra5Digit	union all
	Select 			* 					from work.Intra4Digit 	union all
	Select 			* 					from work.Intra3Digit
	order by 		IndustryCodeID, YearID, DataSeriesCodeID;
quit;

data work.Out8797Paste;
	set work.JoinAll;
	Value=Round(Value,.001);
run;

data intra.Out8797Paste;
	set work.Out8797Paste;
run;

%mend CreateLoadFile_1987_97;

/***************************************************/
/********** Compile LP Load Files 1987-EY **********/
/***************************************************/

libname final "J:\SAS Testing\IntraSectoral\Libraries\Final";

%CreateLoadFile_1997_EY (filepath = &filepath_lp);
%CreateLoadFile_1987_97 (filepath = &filepath_lp);

%macro concat_LPPaste;
Proc sql;
	Create table work.LPPaste
	(IndustryCodeID char, IndustryID char, DataSeriesCodeID char, DataSeriesID char, DataArrayID char, DataArrayCode char, DataArrayTitle char, TQFile char, Year num, YearID char, Value num, Match char);
quit;

Proc sql noprint;
	Select memname
		Into :PasteFileBuilder separated by " "
	From Sashelp.vmember 
	where libname = "WORK" and substr(memname,1,3) = "OUT";
quit;

%local i dataset;
%do i = 1 %to %sysfunc(countw(&PasteFileBuilder));
	%let dataset = %scan(&PasteFileBuilder, &i);
	Proc Sql;
		Create table	work.LPPaste as
		Select			*	from work.LPPaste	union all
		Select			*	from work.&dataset;
	quit;
%end;

data final.Outpaste_Lp;
	set work.LPPaste;
run;

proc datasets library=work kill noprint;
	run;
quit;

%mend concat_LPPaste;

%concat_LPPaste;
/***************************************************/
/********** Compile MFP Load Files 1987-EY **********/
/***************************************************/
	
%CreateLoadFile_1997_EY (filepath = &filepath_mfp);
%CreateLoadFile_1987_97 (filepath = &filepath_mfp);

%macro concat_MFPPaste;
Proc sql;
	Create table work.MFPPaste
	(IndustryCodeID char, IndustryID char, DataSeriesCodeID char, DataSeriesID char, DataArrayID char, DataArrayCode char, DataArrayTitle char, TQFile char, Year num, YearID char, Value num, Match char);
quit;

Proc SQL noprint;
	Select memname
		Into :PasteFileBuilder separated by " "
	From Sashelp.vmember 
	where libname = "WORK" and substr(memname,1,3) = "OUT";
Quit;

%local i dataset;
%do i = 1 %to %sysfunc(countw(&PasteFileBuilder));
	%let dataset = %scan(&PasteFileBuilder, &i);
	Proc Sql;
		Create table	work.MFPPaste as
		Select			*	from work.MFPPaste	union all
		Select			*	from work.&dataset;
	quit;
%end;

data final.Outpaste_Mfp;
	set work.MFPPaste;
run;

proc datasets library=work kill noprint;
	run;
quit;

%mend concat_MFPPaste;

%concat_MFPPaste;
