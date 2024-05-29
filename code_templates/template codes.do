*Code Templates

*Appending CSVs or Excels into one DTA

clear
cd //raw directory

local filedir: dir "" files "*.csv"
foreach file of local filedir {
preserve
import using  `file', clear //csv or excel
//clean CSV/excel

save temp, replace //temp.dta 
restore
append using temp
}
rm temp

cd //clean or temp folder
save full_data.dta, replace

//Outputting regression tables

//save each reg with code below

eststo [model name]

esttab [model name] [using file name, normally .rtf], [options se r2 ar2 varlabels
(vars, "labels") mlabels (//labels row)]
