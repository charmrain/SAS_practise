***********************************************************;
*  LESSON 2, PRACTICE 1 SOLUTION                          *;
***********************************************************;

*Modify the path if necessary;
/* the approach is to import excel
the table is saved in the work library, this is a snapshot data */
proc import datafile="/home/u63487584/EPG1V2/data/eu_sport_trade.xlsx" 
			dbms=xlsx
			out=eu_sport_trade 
			replace;
run;

proc contents data=eu_sport_trade;
run;

