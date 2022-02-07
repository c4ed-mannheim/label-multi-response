********************************************************************************
* INPUTS
********************************************************************************

global qx "$ONEDRIVE\P20204b_EUTF_GMB - Documents\03_Questionnaires\03_Endline\Programming\Pre-test tool\Tekki_Fii_PV_Endline_WIP_pt.xlsx" // enter path of SurveyCTO form
global path "H:\exported\Tekki_Fii_PV_3_pt.dta" // Enter paths to data 


*** Survey Sheet
global qlabel_language "label" // question label column for the required language - Main sheet
global qname "name" // variable name column

*** Choices Sheet
global clabel_language "label" // choice label column for the required language - choices sheet
global cvalue "value" // choice value column
global list_name "list_name" // list name column

use "$path", clear

/*
This do-file:
1. Takes the option label for a multiple response question variable
2. Truncates the existing variable label to ensure that the option label can be added to the variable label
3. Adds the option label to the variable label e.g. Which of the following crops do you grow? [MAIZE]

To do:
- Add in roster row for variable label e.g. Which of the following crops do you grow? [MAIZE] [PLOT 1] - desirable?


*/


********************************************************************************
* LABELLING MULTI RESPONSE OPTIONS 
********************************************************************************


preserve
import excel using "$qx", clear first sheet("survey")   
keep if strpos(type, "multiple")
gen $list_name = subinstr(type, "select_multiple ", "", 1)
rename $qlabel_language question_label

replace question_label = subinstr(question_label, char(34), "", .)

tempfile x 
save `x'

import excel using "$qx", clear first sheet("choices")

keep $list_name $cvalue $clabel_language 

replace $clabel_language = subinstr($clabel_language, char(34), "", .)


joinby $list_name using `x' 


keep $list_name $cvalue $clabel_language $qname question_label

capture confirm numeric variable $cvalue
	if !_rc {
		tostring $cvalue, gen(${cvalue}_str)
		drop $cvalue
		rename ${cvalue}_str $cvalue
	}

replace $cvalue = subinstr($cvalue, "-", "_", 1)

gen variable_name = $qname + "_" + $cvalue
levelsof variable_name, l(l_mulvals)

di `"`l_mulvals'"'

tokenize `"`l_mulvals'"'
while "`*'" != "" {
tempfile begin
save `begin'
	di "`1'"
	keep if variable_name == "`1'"
	local `1'_val = question_label + ". [" + upper(label) + "]" 
	local label_length = strlen("``1'_val'")
	di "`label_length'"
	di "``1'_val'"
	if `label_length' > 80 {
	local length_diff = `label_length' - 80
	di "LENGTH DIFFERENCE: `length_diff'"
	local `1'_val_orig = question_label 
	local `1'_val_orig_length = strlen("``1'_val_orig'")
	di "ORIGINAL Q LENGTH: ``1'_val_orig_length'"
	local length_keep = ``1'_val_orig_length' - `length_diff' - 4 
	di "NEW Q LENGTH: `length_keep'"
	if `length_keep' > 9 {
	local `1'_val_orig  = substr(question_label, 1, `length_keep')
	}
	if `length_keep' < 10 {
	local `1'_val_orig  = substr(question_label, 1, 10)
	}
	di "``1'_val_orig'"
	local `1'_val = "``1'_val_orig'" + "... [" + upper(label) + "]"
	di "NEW VARIABLE LABEL: ``1'_val'"
	}

di "``1'_val'"
macro shift
use `begin', clear
}

restore 
 
di `"`l_mulvals'"'


tokenize `"`l_mulvals'"'


while "`*'" != "" {
	local n = 999 // No idea why I added this in
	di "Going through: `1'"	
	capture confirm variable `1'
	if !_rc {
	di "`1' EXISTS"	
	unab vars : `1'*
	local n `: word count `vars''
	di "Number of variables with prefix: `n'"
	
	if `n' == 1 {
		label var `1' "``1'_val'"	
	}
	if `n' > 1 {
	local varcount = ""
	capture unab varcount : `1'_*
	di "Total Number of stubs from pre_fix: `varcount'"
	local k `: word count `varcount''
	di "`k'"	
	if `k' > 0 {	
			foreach var of varlist `1'_* {
			di "`var'"
			label var `var' "``1'_val'" 
			}
	}
	}
	}
	else {
	local varcount2 = ""
	capture unab varcount2 : `1'_*
	di "Total Number of stubs from pre_fix: `varcount2'"
	local h `: word count `varcount2''
	di "`h'"	
	if `h' > 0 {	
			foreach var of varlist `1'_* {
			di "`var'"
			label var `var' "``1'_val'" 
			}
	}		
		
		
		
	}

	macro shift
}