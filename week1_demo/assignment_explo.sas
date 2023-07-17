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

/* use a function to create new columns */

data storm_length;
	set pg1.storm_summary;
	drop Hem_EW Hem_NS Lat Lon;
	StormLength = EndDate - StartDate +1;
	*Add assignment statement;
run;


data storm_wingavg;
	set pg1.storm_range;
	*Add assignment statements;
	WindAvg = mean(wind1, wind2, wind3, wind4);
	WindRange = Range(wind1, wind2, wind3, wind4);
run;

/* the substr usage */
data pacific;
	set pg1.storm_summary;
	drop Type Hem_EW Hem_NS MinPressure Lat Lon;
	*Add a WHERE statement that uses the SUBSTR function;
	where SUBSTR(Basin, 2, 1) = 'P';
run;


/* format the new columns */
data np_summary_update;
    set pg1.np_summary;
    keep Reg ParkName DayVisits OtherLodging Acres 
         SqMiles Camping;
    SqMiles=Acres*.0015625;
    Camping=sum(OtherCamping,TentCampers,
                RVCampers,BackcountryCampers);
    format SqMiles comma6. Camping comma10.;
run;


/* compare the key and my answer */
/* key: */
data eu_occ_total;
    set pg1.eu_occ;
    Year=substr(YearMon,1,4);
    Month=substr(YearMon,6,2);
    ReportDate=MDY(Month,1,Year);
    Total=sum(Hotel,ShortStay,Camp);
    format Hotel ShortStay Camp Total comma17.
           ReportDate monyy7.;
    keep Country Hotel ShortStay Camp ReportDate Total;
run;

/* my answer */
data eu_ooc_total;
    set pg1.eu_occ;
    Year = substr(YearMon, 1, 4);
    Month = substr(YearMon, 6, 2);
    ReportDate = MDY(Month, 1, Year);
    Total = sum(hotel, shortstay, camp);
    Format hotel shortstay camp total comma. reportdate MONYY7.;
    keep country hotel shortstay camp reportdate total;
    run;

/* if else flow */

data storm_cat;
	set pg1.storm_summary;
	keep Name Basin MinPressure StartDate PressureGroup;
	*add ELSE keyword and remove final condition;
	if MinPressure=. then PressureGroup=.;
	else if MinPressure<=920 then PressureGroup=1;
	else PressureGroup=0;
run;

proc freq data=storm_cat;
	tables PressureGroup;
run;


/* the position of length statement is important */

data storm_summary2;

	set pg1.storm_summary;
	*Add a LENGTH statement;
    length Ocean $10.;	
	keep Basin Season Name MaxWindMPH Ocean;
	*Add assignment statement;
	Basin = upcase(Basin);
	OceanCode=substr(Basin,2,1);
	if OceanCode="I" then Ocean="Indian";
	else if OceanCode="A" then Ocean="Atlantic";
	else Ocean="Pacific";


run;

/* a if then else statements */

data park_type;
	set pg1.np_summary;
	*Add IF-THEN-ELSE statements;
	if type = 'NM' Then ParkType = 'Monument';
	else if type = 'NP' Then ParkType = 'Park';
	else if type in ('NPRE', 'PRE', 'PRESERVE') Then ParkType = 'Preserve';
	else if type = 'NS' THEN ParkType = 'Seashore';
	else ParkType = 'River';
run;

proc freq data=park_type;
	tables ParkType;
run;

/* create two tables, assign different rows by condition */
data parks monuments;
    set pg1.np_summary;
    where type in ('NM', 'NP');
    Campers=sum(OtherCamping, TentCampers, RVCampers,
                BackcountryCampers);
    format Campers comma17.;
    length ParkType $ 8;
    if type='NP' then do;
        ParkType='Park';
        output parks;
    end;
    else do;
        ParkType='Monument';
        output monuments;
    end;
    keep Reg ParkName DayVisits OtherLodging Campers 
         ParkType;
run;

/* set the titile with a %let clause to use the same data several times */