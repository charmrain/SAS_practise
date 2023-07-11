***********************************************************;
*  Activity 3.03                                          *;
*    1) Change the value in the %LET statement from NA to *;
*       SP.                                               *;
*    2) Run the program and carefully read the log.       *;
*       Which procedure did not produce a report?         *;
*       What is different about the WHERE statement in    *;
*       that step?                                        *;
***********************************************************;

%let BasinCode=SP;

proc means data=pg1.storm_summary;
	where Basin="&BasinCode";
	var MaxWindMPH MinPressure;
run;

proc freq data=pg1.storm_summary;
	where Basin="&BasinCode";
	tables Type;
run;

proc print data=pg1.storm_summary(obs=30);
	where Basin="&BasinCode";
/* 	tables Type; */
run;