proc import datafile="/home/u63487584/EPG1V2/data/np_traffic.csv"
dbms=csv out=traffic replace;

guessingrows=max;
/* as the output row 31 to 71, some cells are got truncked
using guessingrows syntax can exam all rows  */
run;

proc contents data=traffic;

run;