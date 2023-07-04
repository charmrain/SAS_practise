libname np xlsx "/home/u63487584/EPG1V2/data/np_info.xlsx";

options validvarname=v7;

proc contents data=NP.Parks;

run;

libname NP clear;