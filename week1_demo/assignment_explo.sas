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

/* display the label in print by add the label option */
data cars_update;
    set sashelp.cars;
	keep Make Model MSRP Invoice AvgMPG;
	AvgMPG=mean(MPG_Highway, MPG_City);
	label MSRP="Manufacturer Suggested Retail Price"
          AvgMPG="Average Miles per Gallon"
          Invoice= "Invoice price";
run;

proc means data=cars_update min mean max;
    var MSRP Invoice;
run;

proc print data=cars_update label;
    var Make Model MSRP Invoice AvgMPG;
run;


/* freq report by month and suppress the print */

title "Frequency Report for Basin and Storm Month";

proc freq data=pg1.storm_final order=freq noprint ;
	tables StartDate / out=storm_count ;
	format StartDate monname.;
run;


/* nocum to suppress culmulative columns */
title "Categories of reported Species";
proc freq data=pg1.np_species order=freq;
tables Category/nocum;



ods graphics on;
ods noproctitle;
title1 "Categories of Reported Species";
title2 "in the Everglades";
proc freq data=pg1.np_species order=freq;
    tables Category / nocum plots=freqplot;
    where Species_ID like "EVER%" and 
          Category ne "Vascular Plant";
run;
title;

/* notice!!! order=freq is the proc option not tables option */
title "Park Types and Regions";
proc freq data=pg1.np_codelookup ORDER = freq;
tables Type*Region / nopercent ;
where Type not like "Other"; 
run;

/* my work */
title "Selected Park Types and Regions";
proc freq data=pg1.np_codelookup ORDER = freq ;
tables Type*Region / nocol nopercent crosslist 
plots=freqplot(Groupby=ROW orient=HORIZONTAL Scale=Percent) ;
where Type in ("National Historic Site","National Monument", "National Park"); 
run;


/* key */
title1 'Selected Park Types by Region';
ods graphics on;
proc freq data=pg1.np_codelookup order=freq;
    tables Type*Region /  nocol crosslist 
           plots=freqplot(groupby=row scale=grouppercent 
           orient=horizontal);
    where Type in ('National Historic Site', 
                   'National Monument', 
                   'National Park');
run;
title;

proc means data=pg1.storm_final N Mean Min Maxdec=0;
	var MinPressure;
	class Season Ocean;
	ways 1;
	where Season >=2010;
run;


/* a typical mean procedure */
proc means data=pg1.storm_final noprint;
	var MaxWindMPH;
	class BasinName;
	ways 1;
	output out=wind_stats mean=Avgwind max=Maxwind;
run;

/* Mean statistic */
title1 'Weather Statistics by Year and Park';
proc means data=pg1.np_westweather mean min max 
           maxdec=2;
    var Precip Snow TempMin TempMax;
    class Year Name;
run;



/* my answer, which is not correct */
proc means data=pg1.np_westweather N sum noprint;
    var precip;
    where Precip ne 0;
    class Name Year;
    output out=rainstats (where=(_type_=3))
               n=RainDays sum=TotalRain;
    /* label N="Raindays" */
    /* Sum="TotalRain"; */
    ways 2;
    run;
    
    
    
    title "Rain statistics by year and park";
    proc print data=rainstats noobs;
    var Name Year RainDays TotalRain;
    label Name="Park Name"
    RainDays="Number of Rains"
    TotalRain="Total Rain Amount(Inches)";
    run;


/* the right answer */

proc means data=pg1.np_westweather noprint;
    where Precip ne 0;
    var Precip;
    class Name Year;
    ways 2;
    output out=rainstats n=RainDays sum=TotalRain;
run;

title1 'Rain Statistics by Year and Park';
proc print data=rainstats label noobs;
    var Name Year RainDays TotalRain;
    label Name='Park Name'
          RainDays='Number of Days Raining'
          TotalRain='Total Rain Amount (inches)';
run;
title;


/* a long synatx */

%let Year=2016;
%let basin=NA;

**************************************************;
*  Creating a Map with PROC SGMAP                *;
*   Requires SAS 9.4M5 or later                  *;
**************************************************;

*Preparing the data for map labels;
data map;
	set pg1.storm_final;
	length maplabel $ 20;
	where season=&year and basin="&basin";
	if maxwindmph<100 then MapLabel=" ";
	else maplabel=cats(name,"-",maxwindmph,"mph");
	keep lat lon maplabel maxwindmph;
run;

*Creating the map;
title1 "Tropical Storms in &year Season";
title2 "Basin=&basin";
footnote1 "Storms with MaxWind>100mph are labeled";

proc sgmap plotdata=map;
    *openstreetmap;
    esrimap url='https://services.arcgisonline.com/arcgis/rest/services/World_Physical_Map';
            bubble x=lon y=lat size=maxwindmph / datalabel=maplabel datalabelattrs=(color=red size=8);
run;
title;footnote;

**************************************************;
*  Creating a Bar Chart with PROC SGPLOT         *;
**************************************************;
title "Number of Storms in &year";
proc sgplot data=pg1.storm_final;
	where season=&year;
	vbar BasinName / datalabel dataskin=matte categoryorder=respdesc;
	xaxis label="Basin";
	yaxis label="Number of Storms";
run;

**************************************************;
*  Creating a Line PLOT with PROC SGPLOT         *;
**************************************************;
title "Number of Storms By Season Since 2010";
proc sgplot data=pg1.storm_final;
	where Season>=2010;
	vline Season / group=BasinName lineattrs=(thickness=2);
	yaxis label="Number of Storms";
	xaxis label="Basin";
run;

**************************************************;
*  Creating a Report with PROC TABULATE          *;
**************************************************;

proc format;
    value count 25-high="lightsalmon";
    value maxwind 90-high="lightblue";
run;

title "Storm Summary since 2000";
footnote1 "Storm Counts 25+ Highlighted";
footnote2 "Max Wind 90+ Highlighted";

proc tabulate data=pg1.storm_final format=comma5.;
	where Season>=2000;
	var MaxWindMPH;
	class BasinName;
	class Season;
	table Season={label=""} all={label="Total"}*{style={background=white}},
		BasinName={LABEL="Basin"}*(MaxWindMPH={label=" "}*N={label="Number of Storms"}*{style={background=count.}} 
		MaxWindMPH={label=" "}*Mean={label="Average Max Wind"}*{style={background=maxwind.}}) 
		ALL={label="Total"  style={vjust=b}}*(MaxWindMPH={label=" "}*N={label="Number of Storms"} 
		MaxWindMPH={label=" "}*Mean={label="Average Max Wind"})/style_precedence=row;
run;
title;
footnote;