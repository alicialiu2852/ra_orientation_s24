/*
Do file to replicate ECON 135 Paper
*/

clear
cd "/Users/funny/Desktop/voterid_replication"

*------------------------------------------------------------------------------*
*PART 0: PACKAGE INSTALLATION (IF NEEDED, JUST UNCOMMENT)*
*------------------------------------------------------------------------------*
//ssc install bacondecomp
//net install ddtiming, from(https://tgoldring.com/code)
//github install lsun20/eventstudyinteract

*------------------------------------------------------------------------------*
*PART 1: CLEANING EAVS DATA*
*------------------------------------------------------------------------------*

*2004*
clear
cd "./input/EAVS/2004"

//Each state is in a separate excel sheet, first extracting provisional ballots
local filedir: dir "." files "*.xls"
foreach file of local filedir {
	preserve
	import excel "`file'", sheet("Provisional") clear 
	
	//Renaming and dropping variables
	rename (B C D G J) (state_abr fips jurisdiction provisional_ballots_cast provisional_accept)
	keep state_abr fips jurisdiction provisional_ballots_cast provisional_accept
	replace jurisdiction = strupper(jurisdiction)

	//Removing unnecessary lines and obsevations
	drop if regexm(state_abr, "^[A-Z]+[A-Z]$") == 0
	drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")
	
	save "temp2004prov.dta", replace
	restore
	append using "temp2004prov.dta"
}

save "temp2004prov.dta", replace

//Iterate over Excel sheets again to find total ballots counted
clear
local filedir: dir "." files "*.xls"
foreach file of local filedir {
	preserve
	import excel "`file'", sheet("Ballots Counted") clear 
	
	//Renaming and dropping variables
	rename (B C D H) (state_abr fips jurisdiction total_votes_count)
	replace jurisdiction = strupper(jurisdiction)
	keep state_abr fips jurisdiction total_votes_count
	
	//Removing unnecessary lines and observations
	drop if regexm(state_abr, "^[A-Z]+[A-Z]$") == 0
	drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

	save "temp2004ballots.dta", replace
	restore
	append using "temp2004ballots.dta"
}
save "temp2004ballots.dta", replace

//Merging provisional votes data with total ballots coutned
merge 1:1 state_abr fips jurisdiction using "temp2004prov.dta" 
drop _merge //_merge == 3 for all obs

//Destring variables
order fips state_abr jurisdiction provisional_ballots_cast provisional_accept total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	destring `var', replace
}

//Generate remaining vars, dropping provisional_accept
gen provisional_reject = provisional_ballots_cast - provisional_accept
gen year = 2004
drop provisional_accept

//Replace -99999 and other negative codes = .
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject  total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = . if `var' < 0
}

//Saving file in temp folder
save "/Users/funny/Desktop/voterid_replication/temp/eavs2004.dta", replace

//Removing the files
rm "temp2004ballots.dta"
rm "temp2004prov.dta" 

*2006*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2006" 
local sheets "juri_02_34 juri_set3a" //Iterating over the different sheets
foreach sheet of local sheets {
	import excel using "Copy of eacdata(3).xls", sheet("`sheet'") firstrow clear
	save `sheet'.dta, replace
}
merge 1:1 id state county place using juri_02_34.dta
drop _merge //_merge = 3 for all observations
keep id state county q33p q36total q37ni q34total
rename (id state county q33p q36total q37ni q34total) (fips state_name jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)

//DESTRINGING VARIABLES
order fips state_name jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = "0" if `var' == "None"
	destring `var', replace
}

replace state_name = strupper(state_name)
replace jurisdiction = strupper(jurisdiction)
gen year = 2006
drop if inlist(state_name, "AMERICAN SAMOA", "DISTRICT OF COLUMBIA", "GUAM", "VIRGIN ISLANDS" "PUERTO RICO", "NORTHERN MARIANA ISLANDS")
drop if regexm(fips, "^60")
drop if regexm(fips, "^66")
drop if regexm(fips, "^72")
drop if regexm(fips, "^78")

save "/Users/funny/Desktop/voterid_replication/temp/eavs2006.dta", replace

//Removing some of the temporary files
rm "juri_02_34.dta"
rm "juri_set3a.dta"

*2008*
*NOTE: NEW HAMPSHIRE DID NOT REPORT DATA FOR THIS YEAR*

clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2008" 
local excels "Combined_SectionE.xls Combined_SectionF.xls"
foreach excel of local excels {
	import excel using "`excel'", firstrow clear
	save `excel'.dta, replace
}

//Merging two sections together 
merge 1:1 JurisID JurisName STATE_NAME STATE_ using Combined_SectionE.xls.dta
drop if _merge != 3
drop _merge //_merge = 3 for all observations except for 2 obs, which are errors that have FIPS of 00000, so not actual places


//Dropping & renaming vars
keep STATE_ STATE_NAME JurisID JurisName E1 E2c E3d F1a
rename (STATE_ STATE_NAME JurisID JurisName E1 E2c E3d F1a) (state_abr state_name fips jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)

//Generating year, standardizing state and jurisdiction names
gen year = 2008
replace state_name = strupper(state_name)
replace jurisdiction = strupper(jurisdiction)

//Dropping obs of non states
drop if inlist(state_name, "AMERICAN SAMOA", "DISTRICT OF COLUMBIA", "GUAM", "VIRGIN ISLANDS", "PUERTO RICO", "NORTHERN MARIANA ISLANDS")

//Replace -99999 and other negative codes = .
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = . if `var' < 0
}

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2008.dta", replace

//Removing files
rm "Combined_SectionE.xls.dta"
rm "Combined_SectionF.xls.dta"

*2010*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2010"
local excels "EAVS_Section_E.xlsx EAVS_Section_F.xlsx"
foreach excel of local excels {
	import excel using "`excel'", firstrow clear
	save `excel'.dta, replace
}

//Merge two sections together
merge 1:1 State Jurisdiction FIPSCode using "EAVS_Section_E.xlsx.dta"
drop _merge //_merge == 3 for all obs

//Dropping & renaming vars, dropping obs
keep State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a
rename (State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a) (state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

//Replace -99999 = .
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = . if `var' == -999999 
}

//Generating year, standardizing state and jurisdiction names
gen year = 2010

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2010.dta", replace

//Removing files
rm "EAVS_Section_E.xlsx.dta"
rm "EAVS_Section_F.xlsx.dta"

*2012*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2012"
local excels "Section_E.xls Section_F.xls"
foreach excel of local excels {
	import excel using "`excel'", firstrow clear
	save `excel'.dta, replace
}

//Merge two sections together
merge 1:1 State Jurisdiction FIPSCode using "Section_E.xls.dta"
drop _merge //_merge == 3 for all obs

//Dropping & renaming vars, dropping non-US states
keep State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a
rename (State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a) (state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

//Replace -99999 = .
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = . if `var' < 0 
}

//Generating year, standardizing state and jurisdiction names
gen year = 2012

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2012.dta", replace

//Removing files
rm "Section_E.xls.dta" 
rm "Section_F.xls.dta"

*2014*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2014"
local excels "EAVS_Section_E.xlsx EAVS_Section_F.xlsx"
foreach excel of local excels {
	import excel using "`excel'", firstrow clear
	save `excel'.dta, replace
}

//Merge two sections together
merge 1:1 State Jurisdiction FIPSCode using "EAVS_Section_E.xlsx.dta"
drop _merge //_merge == 3 for all obs

//Dropping & renaming vars, dropping non-US state obs
keep State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a
rename (State Jurisdiction FIPSCode QE1a QE1d QE2d QF1a) (state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

//Replace -99999 and other negative codes = .
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = . if `var' < 0
}

//Generating year, standardizing state and jurisdiction names
gen year = 2014

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2014.dta", replace

//Removing files
rm "EAVS_Section_E.xlsx.dta"
rm "EAVS_Section_F.xlsx.dta"

*2016*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2016"
foreach sheet in "SECTION_E" "SECTION_F" {
	import excel using "EAVS 2016 Final Data for Public Release v.4.xls", sheet("`sheet'") firstrow clear
	save `sheet'.dta, replace
}

//Merge two sections together
merge 1:1 State Jurisdiction FIPSCode using "Section_E.dta"
drop _merge //_merge == 3 for all obs

//Dropping & renaming vars, dropping obs
keep State Jurisdiction FIPSCode E1a E1d E2d F1a
rename (State Jurisdiction FIPSCode E1a E1d E2d F1a) (state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

//Replace -888888: Not Applicable and destring
order fips state_abr jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = "" if `var' == "-888888: Not Applicable"
	replace `var' = "" if `var' == "-999999: Data Not Available"
	destring `var', replace
}

//Generating year
gen year = 2016

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2016.dta", replace

//Removing files
rm "Section_E.dta"
rm "Section_F.dta"

*2018*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2018"
import excel using "EAVS_2018_for_Public_Release_Updates3.xlsx", firstrow

//Dropping & renaming vars, dropping obs
keep State_Full State_Abbr Jurisdiction FIPSCode E1a E1d E2e F1a
rename (State_Full State_Abbr Jurisdiction FIPSCode E1a E1d E2e F1a) (state_name state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR")

//Destringing
order fips state_abr state_name jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = "" if `var' == "Data not available"
	replace `var' = "" if `var' == "Does not apply"
	destring `var', replace
}

//Generating year
gen year = 2018

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2018.dta", replace
 

*2020*
clear
cd "/Users/funny/Desktop/voterid_replication/input/EAVS/2020"
import excel "2020_EAVS_for_Public_Release_V2.xlsx", firstrow

//Dropping & renaming vars, dropping obs
keep State_Full State_Abbr Jurisdiction FIPSCode E1a E1d E2e F1a
rename (State_Full State_Abbr Jurisdiction FIPSCode E1a E1d E2e F1a) (state_name state_abr jurisdiction fips provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count)
drop if inlist(state_abr, "AS", "GU", "DC", "VI", "PR", "MP")

//Destringing
order fips state_abr state_name jurisdiction provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count
foreach var of varlist provisional_ballots_cast-total_votes_count{
	replace `var' = "" if `var' == "Data not available"
	replace `var' = "" if `var' == "Does not apply"
	destring `var', replace
}

//Generating year
gen year = 2020

//Saving file in temp
save "/Users/funny/Desktop/voterid_replication/temp/eavs2020.dta", replace

*Appending all the years together*
clear
cd "/Users/funny/Desktop/voterid_replication/temp"
local filedir: dir "/Users/funny/Desktop/voterid_replication/temp" files "*.dta"
foreach file of local filedir {
	append using `file'
}


*Some years only have state abbreviations, some only the name. Merging to fix this*

*Importing Excel that just has the state name and abbreviation*
frame create state_match
frame change state_match
import excel using "/Users/funny/Desktop/voterid_replication/input/statenames_abrs.xlsx", firstrow
replace state_name = strupper(state_name)
save "/Users/funny/Desktop/voterid_replication/temp/state_match.dta", replace
frame change default

*Merging with original data*
merge m:1 state_abr using "state_match.dta", update replace
merge m:1 state_name using "state_match.dta", update replace gen(_merge_final)
drop _merge _merge_final 


*Collapse by year state*
collapse (sum) provisional_ballots_cast provisional_reject provisional_id_reject total_votes_count, by(state_abr state_name year)

*------------------------------------------------------------------------------*
*PART 2: ADDING VOTER ID LAW AND INFORMATION AND COMPETITIVENESS*
*------------------------------------------------------------------------------*
//coding state competitiveness
*data from NCSL, attached in email*
generate split = 0
replace split = 1 if state_name== "ALASKA" & year <= 2012 & year >= 2008
replace split = 1 if state_name== "COLORADO" & year == 2012
replace split = 1 if state_name== "DELAWARE" & year <= 2006
replace split = 1 if state_name== "ALASKA" & year <= 2010 & year >= 2006
replace split = 1 if state_name== "IOWA" & year == 2012
replace split = 1 if state_name== "KENTUCKY" & year <= 2012
replace split = 1 if state_name== "MICHIGAN" & year <= 2010 & year >= 2006
replace split = 1 if state_name== "MINNESOTA" & year == 2004
replace split = 1 if state_name== "MONTANA" & year <= 2010 & year >= 2004
replace split = 1 if state_name== "NEVADA" & year <= 2006 & year >= 2004
replace split = 1 if state_name== "NEW YORK" & year <= 2006 & year >= 2004 | state_name== "NEW YORK" & year == 2012
replace split = 1 if state_name== "ALASKA" & year <= 2010 & year >= 2008
replace split = 1 if state_name== "ALASKA" & year <= 2006 & year >= 2004
replace split = 1 if state_name== "ALASKA" & year <= 2012 & year >= 2008
replace split = 1 if state_name== "IOWA" & year == 2014
replace split = 1 if state_name== "KENTUCKY" & year == 2014
replace split = 1 if state_name== "NEW HAMPSHIRE" & year == 2014
replace split = 1 if state_name== "COLORADO" & year == 2016
replace split = 1 if state_name== "IOWA" & year == 2016
replace split = 1 if state_name== "KENTUCKY" & year == 2016
replace split = 1 if state_name== "MAINE" & year == 2016
replace split = 1 if state_name== "MINNESOTA" & year == 2016
replace split = 1 if state_name== "NEW MEXICO" & year == 2016
replace split = 1 if state_name== "NEW YORK" & year == 2016
replace split = 1 if state_name== "WASHINGTON" & year == 2016
replace split = 1 if state_name== "COLORADO" & year == 2018
replace split = 1 if state_name== "CONNECTICUT" & year == 2018
replace split = 1 if state_name== "MAINE" & year == 2018
replace split = 1 if state_name== "NEW YORK" & year == 2018
replace split = 1 if state_name== "MINNESOTA" & year == 2020

*------------------------------------------------------------------------------*
*Cleaning VID data*
*------------------------------------------------------------------------------*

//coding Voter ID laws (VIS) laws
*data also from NCSL, also attached
//coding non-strict non-photo NSNP
generate NSNP = 0 
replace NSNP = 1 if state_name == "ALABAMA" & year < 2014
replace NSNP = 1 if state_name == "ALASKA"
replace NSNP = 1 if state_name == "ARKANSAS" & year < 2018
replace NSNP = 1 if state_name == "COLORADO" & year < 2014
replace NSNP = 1 if state_name == "CONNECTICUT"
replace NSNP = 1 if state_name == "DELAWARE"
replace NSNP = 1 if state_name == "GEORGIA" & year < 2008
replace NSNP = 1 if state_name == "KENTUCKY"
replace NSNP = 1 if state_name == "MISSOURI"
replace NSNP = 1 if state_name == "MONTANA"
replace NSNP = 1 if state_name == "NEW HAMPSHIRE" 
replace NSNP = 1 if state_name == "NORTH DAKOTA" & year < 2014 | state_name== "NORTH DAKOTA" & year == 2016
replace NSNP = 1 if state_name == "OKLAHOMA" & year > 2010
replace NSNP = 1 if state_name == "RHODE ISLAND" & year == 2012
replace NSNP = 1 if state_name == "CONNECTICUT"
replace NSNP = 1 if state_name == "SOUTH CAROLINA" & year < 2020
replace NSNP = 1 if state_name == "TENNESSEE" & year < 2012
replace NSNP = 1 if state_name == "TEXAS" & year < 2014
replace NSNP = 1 if state_name == "UTAH" & year > 2008
replace NSNP = 1 if state_name == "VIRGINIA" & year < 2012
replace NSNP = 1 if state_name == "WASHINGTON" & year > 2006 & year < 2012
replace NSNP = 1 if state_name == "WEST VIRGINIA" & year > 2016

//coding non-strict photo NSP
generate NSP = 0
replace NSP = 1 if state_name == "ALABAMA" & year >= 2014
replace NSP = 1 if state_name == "ARKANSAS" & year >= 2018
replace NSP = 1 if state_name == "FLORIDA"
replace NSP = 1 if state_name == "HAWAII"
replace NSP = 1 if state_name == "IDAHO" & year >= 2010
replace NSP = 1 if state_name == "LOUISIANA"
replace NSP = 1 if state_name == "MICHIGAN"
replace NSP = 1 if state_name == "RHODE ISLAND" & year >= 2014
replace NSP = 1 if state_name == "SOUTH DAKOTA" & year >= 206
replace NSP = 1 if state_name == "TEXAS" & year >= 2018

//coding strict non-photo SNP
generate SNP = 0
replace SNP = 1 if state_name == "ARIZONA" & year >= 2006
replace SNP = 1 if state_name == "NORTH DAKOTA" & year >= 2018 | state_name== "NORTH DAKOTA" & year == 2014
replace SNP = 1 if state_name == "OHIO" & year >= 2006
replace SNP = 1 if state_name == "VIRGINIA" & year == 2012

//coding strict photo SP
generate SP = 0
replace SP = 1 if state_name == "GEORGIA" & year >= 2008
replace SP = 1 if state_name == "INDIANA" & year >= 2008
replace SP = 1 if state_name == "KANSAS" & year >= 2012
replace SP = 1 if state_name == "MISSISSIPPI" & year >= 2014
replace SP = 1 if state_name == "TENNESSEE" & year >= 2012
replace SP = 1 if state_name == "TEXAS" & year == 2014 | state_name== "TEXAS" & year == 2016
replace SP = 1 if state_name == "VIRGINIA" & year <= 2018 & year >= 2014
replace SP = 1 if state_name == "WISCONSIN" & year >= 2016

*------------------------------------------------------------------------------*
*PART 3: CLEANING CVAP*
*------------------------------------------------------------------------------*

frame create CVAP
frame change CVAP
clear

cd "/Users/funny/Desktop/voterid_replication/input/CVAP"
local filedir: dir "/Users/funny/Desktop/voterid_replication/input/CVAP" files "*.csv"
foreach file of local filedir {
	preserve
	import delimited using  `file', clear
	
	//Renaming variables
	rename geoname state_name
	replace state_name = strupper(state_name)
	
	//Keeping only state totals and US states
	keep if lntitle == "Total"
	keep state_name cvap_est
	drop if inlist(state_name, "DISTRICT OF COLUMBIA", "PUERTO RICO")
	
	//Generating a year variable
	generate file_name = "`file'"
	generate year = real(substr(file_name, 6, 4))
	drop file_name
	
	save "CVAPtemp.dta", replace
	restore
	append using "CVAPtemp.dta"
}
rm "CVAPtemp.dta"

//Due to data unavailability, I need to use 2005 data for 2004 and 2017 data for 2018-2020
replace year = 2004 if year == 2005
replace year = 2018 if year == 2017
expand 2 if year == 2018, generate(controls2020)
replace year = 2020 if controls2020 == 1
drop controls2020


//Saving file in temp folder
save "/Users/funny/Desktop/voterid_replication/temp/CVAP.dta", replace
*------------------------------------------------------------------------------*
*PART 4: CLEANING CENSUS CONTROLS FROM ACS*
*------------------------------------------------------------------------------*
//Can clean in the foreach loop type thing
frame create census_controls
frame change census_controls

clear
cd "/Users/funny/Desktop/voterid_replication/input/ACS_1yr_estimates"
local filedir: dir "/Users/funny/Desktop/voterid_replication/input/ACS_1yr_estimates" files "*.csv"
foreach file of local filedir {
	preserve
		import delimited using "`file'", varnames(1) clear

	//Dropping variable labels and variables
	drop if inlist(fips,  "Geo_FIPS", "11", "72") //Dropping label, DC, and Puerto Rico


	gen file_name = "`file'"
	gen year = substr(file_name, 8, 4)
	destring year, replace
		
	save "ACStemp.dta", replace
	restore
	append using "ACStemp.dta"
}
rm "ACStemp.dta"
tabulate year

keep qualifyingname totalpopulation totalpopulationwhitealone totalpopulationblackorafricaname totalpopulationamericanindianand totalpopulationasianalone totalpopulationnativehawaiianand totalpopulationsomeotherracealon totalpopulationtwoormoreraces population25yearsandover population25yearsandoverlessthan population25yearsandoverhighscho population25yearsandoversomecoll population25yearsandoverbachelor population25yearsandovermastersd population25yearsandoverprofessi population25yearsandoverdoctorat medianhouseholdincomein2014infla file_name year medianhouseholdincomein2016infla medianhouseholdincomein2012infla medianhouseholdincomein2006infla medianhouseholdincomein2010infla medianhouseholdincomein2008infla medianhouseholdincomein2018infla medianhouseholdincomein2019infla
	

	//Destring variables
	destring totalpopulation totalpopulationwhitealone totalpopulationblackorafricaname totalpopulationamericanindianand totalpopulationasianalone totalpopulationnativehawaiianand totalpopulationsomeotherracealon totalpopulationtwoormoreraces population25yearsandover population25yearsandoverlessthan population25yearsandoverhighscho population25yearsandoversomecoll population25yearsandoverbachelor population25yearsandovermastersd population25yearsandoverprofessi population25yearsandoverdoctorat medianhouseholdincomein2014infla medianhouseholdincomein2016infla medianhouseholdincomein2012infla medianhouseholdincomein2006infla medianhouseholdincomein2010infla medianhouseholdincomein2008infla medianhouseholdincomein2018infla medianhouseholdincomein2019infla, replace
	

	//Generating % minority and % college
	egen pct_minority = rowtotal(totalpopulationblackorafricaname totalpopulationamericanindianand totalpopulationasianalone totalpopulationnativehawaiianand totalpopulationsomeotherracealon totalpopulationtwoormoreraces)
	replace pct_minority = pct_minority / totalpopulation * 100
	gen pct_college = population25yearsandoverbachelor / population25yearsandover * 100

	//Renaming variables
	rename qualifyingname state_name
	replace state_name = strupper(state_name)

	
	//Combining the different median income variables into one variable 
	egen medhhinc = rowtotal(medianhouseholdincomein2014infla medianhouseholdincomein2016infla medianhouseholdincomein2006infla medianhouseholdincomein2012infla medianhouseholdincomein2010infla medianhouseholdincomein2008infla medianhouseholdincomein2018infla medianhouseholdincomein2019infla)

	//Dropping variables
	drop totalpopulation totalpopulationwhitealone totalpopulationblackorafricaname totalpopulationamericanindianand totalpopulationasianalone totalpopulationnativehawaiianand totalpopulationsomeotherracealon totalpopulationtwoormoreraces population25yearsandover population25yearsandoverlessthan population25yearsandoverhighscho population25yearsandoversomecoll population25yearsandoverbachelor population25yearsandovermastersd population25yearsandoverprofessi population25yearsandoverdoctorat file_name medianhouseholdincomein2014infla medianhouseholdincomein2016infla medianhouseholdincomein2006infla medianhouseholdincomein2012infla medianhouseholdincomein2010infla medianhouseholdincomein2008infla medianhouseholdincomein2018infla medianhouseholdincomein2019infla
	
	//Duplicating 2006 for 2004, then renaming 2019 as 2020
	replace year = 2020 if year == 2019
	expand 2 if year == 2006, generate(controls2004)
	replace year = 2004 if controls2004 == 1
	drop controls2004

	//Saving file in temp folder
save "/Users/funny/Desktop/voterid_replication/temp/ACS_controls.dta", replace
*------------------------------------------------------------------------------*
*PART 5: MERGING DATA*
*------------------------------------------------------------------------------*
frame change default
cd "/Users/funny/Desktop/voterid_replication/temp"
merge 1:1 state_name year using "CVAP.dta", gen(cvap_merge)
merge 1:1 state_name year using "ACS_controls.dta", gen(census_merge)
drop cvap_merge census_merge

gen turnout = total_votes_count/cvap_est

*------------------------------------------------------------------------------*
*PART 6: PARALLEL TRENDS GRAPHS*
*------------------------------------------------------------------------------*
cd "/Users/funny/Desktop/voterid_replication/output"
*NOTE: DIVIDED GRAPHS BY YEAR DUE TO DIFFERENTIAL TREATMENT TIMING

*Laws enacted by 2012*
//Combining the other states into one turnout var, graphing it w/treatment state
local sp_states_2012 "KANSAS TENNESSEE"
foreach state of local sp_states_2012 {
	egen non_sp_turnout = mean(turnout) if !inlist(state_name, "KANSAS", "TENNEESSEE"), by(year)
	twoway (line turnout year if state_name == "`state'" & year < 2012, lcolor(red) legend(label(1 "`state'"))) ///
	(line non_sp_turnout year if year < 2012, lcolor(green) sort legend(label(2 "UNTREATED US STATES"))), ///
	title("Pre-Treatment Trends") legend(order(1 2)) ytitle("Turnout") xtitle("Year")
	graph export "`state'.png", as(png) name("Graph") replace
	drop non_sp_turnout
}

*Laws enacted by 2014*
//Combining the other states into one turnout var, graphing it w/treatment state
local sp_states_2014 "MISSISSIPPI TEXAS VIRGINIA"
foreach state of local sp_states_2014 {
	egen non_sp_turnout = mean(turnout) if !inlist(state_name, "KANSAS", "TENNEESSEE", "MISSISSIPPI", "TEXAS", "VIRGINIA"), by(year)
	twoway (line turnout year if state_name == "`state'" & year < 2014, lcolor(red) legend(label(1 "`state'"))) ///
	(line non_sp_turnout year if year < 2014, lcolor(green) sort legend(label(2 "UNTREATED US STATES"))), ///
	title("Pre-Treatment Trends") legend(order(1 2)) ytitle("Turnout") xtitle("Year")
	graph export "`state'.png", as(png) name("Graph") replace
	drop non_sp_turnout
}

*Laws enacted prior by 2016*
//Combining the other states into one turnout var, graphing it w/treatment state
	egen non_sp_turnout = mean(turnout) if !inlist(state_name, "KANSAS", "TENNEESSEE", "MISSISSIPPI", "TEXAS", "VIRGINIA", "WISCONSIN"), by(year)
	twoway (line turnout year if state_name == "WISCONSIN" & year < 2016, lcolor(red) legend(label(1 "WISCONSIN"))) ///
	(line non_sp_turnout year if year < 2016, lcolor(green) sort legend(label(2 "UNTREATED US STATES"))), ///
	title("Pre-Treatment Trends") legend(order(1 2)) ytitle("Turnout") xtitle("Year")
	graph export "WISCONSIN.png", as(png) name("Graph") replace
	drop non_sp_turnout

*------------------------------------------------------------------------------*
*PART 7: BACON DECOMPOSITION*
*------------------------------------------------------------------------------*

//Declaring panel data
drop if state_name == "" 
*NOTE: THERE IS ONE BLANK OBSERVATION

egen state_id = group(state_name)
xtset state_id year 
*NOTE: PANEL SHOULD BE 50 STATES, 9 ELECTIONS (YEARS), 450 OBS Panel 

//Bacon decomposition
ddtiming turnout SP, i(state_id) t(year)
graph export "bacondecomp_graph.png", as(png) name("Graph") replace

bacondecomp turnout SP pct_minority  pct_hs_below  medhhincome NSNP NSP SNP
eststo bacondecomp
esttab bacondecomp using "bacondecomp.rtf", label title("Bacon Decomposition") mtitles("Bacon Decomposition") replace 

*------------------------------------------------------------------------------*
*PART 8: REGRESSIONS*
*------------------------------------------------------------------------------*

*TWFE Conventional Diff-Diff*
xtreg turnout SP split pct_minority pct_college medhhinc
eststo twfe


*Exploratory regressions (NOT IN PAPER)*
xtreg provisional_ballots_cast SP split NSNP NSP SNP pct_minority pct_college medhhinc
xtreg provisional_reject SP split NSNP NSP SNP pct_minority pct_college medhhinc, absorb(state_name year)
xtreg provisional_id_reject SP split NSNP NSP SNP pct_minority pct_college medhhinc, absorb(state_name year)
 
*Sun and Abraham*

//Specifying groups, time period, and control group
generate group = 0
replace group = 1 if state_name == "GEORGIA" & SP == 1 | state_name == "INDIANA" & SP == 1
replace group = 2 if state_name == "TENNESSEE" & SP == 1 | state_name == "KANSAS" & SP == 1
replace group = 3 if state_name == "MISSISSIPPI" & SP == 1 | state_name == "TEXAS" & SP == 1 | state_name == "VIRGINIA" & SP == 1
replace group = 4 if state_name == "WISCONSIN" & SP == 1 

generate rel_time = 0
replace rel_time = 1 if state_name == "GEORGIA" & SP == 1 | state_name == "INDIANA" & SP == 1
replace rel_time = 2 if state_name == "TENNESSEE" & SP == 1 | state_name == "KANSAS" & SP == 1
replace rel_time = 3 if state_name == "MISSISSIPPI" & SP == 1 | state_name == "TEXAS" & SP == 1 | state_name == "VIRGINIA" & SP == 1
replace rel_time = 4 if state_name == "WISCONSIN" & SP == 1 

generate control = 1
replace control = 0 if SP == 1

//Sun and Abraham Estimator
eventstudyinteract turnout rel_time  pct_minority pct_college medhhinc, cohort(group) control_cohort(control) absorb(state_id year) 
eststo eventstudyest
esttab eventstudyest using "eventstudyest.rtf", se mtitles("Sun and Abraham Event Study Estimator") replace

esttab twfe eventstudyest using "twfe_and_eventstudyest.rtf", se mtitles("Two Way Fixed Effects" "Sun and Abraham Event Study Estimator") varlabels("Strict Photo" "Split Legislature" "Non-Strict Non-Photo" "Non-Strict Photo" "Strict Non-Photo" "% Minority" "% College" "Median Household Income") replace

//Saving dataset in temp folder
save "/Users/funny/Desktop/voterid_replication/temp/final_data.dta", replace

