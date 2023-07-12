proc print data=pg1.np_summary;
	var Type ParkName;
	where Parkname like '%Preserve%';
	*Add a WHERE statement;
run;




%let ParkCode = ZION;
%let SpeciesCat = Bird;



proc freq data=pg1.np_species;
 tables Abundance Conservation_status;
 where species_ID like "&ParkCode%" and Category = "&SpeciesCat";
 run;
 
 proc print data=pg1.np_species;
 var Species_ID Category Scientific_name Common_names;
 where species_ID like "&ParkCode%" and Category = "&SpeciesCat";
 run;
 
 /* below is the formatting  */

 proc print data=pg1.storm_summary(obs=20);
	format Lat Lon 4. StartDate EndDate date11.;
run;

proc freq data=pg1.storm_summary order=freq;
	tables StartDate;
	*Add a FORMAT statement;
	format  StartDate  MONNAME.;
run;


proc sort data=pg1.np_summary out=np_sort;
    by Reg descending DayVisits;
    where Type='NP';
    
    run;

 proc print data=pg1.np_largeparks ;
        where State = 'MN';
        run;
        

proc sort data=pg1.np_largeparks out=park_clean
        nodupkey dupout=park_dups;
        by _all_;
        run;


        
/* create data table */

data Storm_cat5;
    set pg1.storm_summary;
    where MaxWindMPH>=156 and StartDate>="01Jan2000"d;
    keep Season Basin Name Type MaxWindMPH;
    run;


/* create a temporary table */

data eu_occ2016  ;
	set pg1.eu_occ ;
	where YearMon like '2016%';
	format Hotel ShortStay Camp Comma17. ;
	drop Geo;
run;


/* below shows how to create a permanent table under an existed folder */

libname out "~/EPG1V2/output";

data out.fox;
    set pg1.np_species;
    where Category='Mammal' and Common_Names like 
          '%Fox%' and Common_Names not like 
          '%Squirrel%';    
    drop Category Record_Status Occurrence Nativeness;
run;

proc sort data=out.fox;
    by Common_Names;
run;