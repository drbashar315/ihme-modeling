// *********************************************************************************************************************************************************************
// *********************************************************************************************************************************************************************
// Purpose:		This step template should be submitted from the 00_master.do file either by submitting all steps or selecting one or more steps to run in "steps" global
// Author:		
// Last updated:	04/21/16
// Description:	Mutliply etiology fractions by meningitis_parent prevalence draws to obtain severe_infection sequelae (acute)
// Number of output files: 12576
// *********************************************************************************************************************************************************************
// *********************************************************************************************************************************************************************
// LOAD SETTINGS FROM MASTER CODE (NO NEED TO EDIT THIS SECTION)

	// prep stata
	clear all
	set more off
	set maxvar 32000
	if c(os) == "Unix" {
		global prefix "/home/j"
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global prefix "J:"
	}

	// base directory on J
	local root_j_dir `1'
	// base directory on clustertmp
	local root_tmp_dir `2'
	// timestamp of current run (i.e. 2014_01_17)
	local date `3'
	// step number of this step (i.e. 01a)
	local step_num `4'
	// name of current step (i.e. first_step_name)
	local step_name `5'
	// step numbers of immediately anterior parent step (i.e. for step 2: 01a 01b 01c)
	local hold_steps `6'
	// step numbers for final steps that you are running in the current run (i.e. 11a 11b 11c)
	local last_steps `7'
	// directory where the code lives
	local code_dir `8'
	// directory for external inputs
	local in_dir `9'
	// directory for output on the J drive
	local out_dir "FILEPATH"
	// directory for output on clustertmp
	local tmp_dir "FILEPATH"
	// shell file
	local shell_file "FILEPATH"
	// functional
	local functional "meningitis"
	//  etiologies
	local etiologies "meningitis_pneumo meningitis_hib meningitis_meningo meningitis_other"
	// healthstate
	local healthstate "inf_sev"
	// metric -- measure_id for prevalence (5)
	local metric 5
	// type
	local type "prev"

	// directory for standard code files
	adopath + "FILEPATH"

	// get locations
	get_location_metadata, location_set_id(9) clear
	keep if most_detailed == 1 & is_estimate == 1
	levelsof location_id, local(locations)
	clear

	//test locations
	local locations 92 44645 44668 44649 112 44656 44712 509 44652 44679 44658 543 184 50559 44662 44726

	//get demographics
	get_demographics, gbd_team(epi) clear
	local years = r(year_id)
	local sexes = r(sex_id)
	clear
	
	
	// write log if running in parallel and log is not already open
	cap log using "FILEPATH", replace
	if !_rc local close_log 1
	else local close_log 0
	
	// check for finished.txt produced by previous step
	cap erase "`out_dir'/finished.txt"
	if "`hold_steps'" != "" {
		foreach step of local hold_steps {
			local dir: dir "`root_j_dir'" dirs "`step'_*", respectcase
			// remove extra quotation marks
			local dir = subinstr(`"`dir'"',`"""',"",.)
			capture confirm file "`root_j_dir'/`dir'/finished.txt"
			if _rc {
				di "`dir' failed"
				BREAK
			}
		}
	}

// *********************************************************************************************************************************************************************
// *********************************************************************************************************************************************************************
// WRITE CODE HERE
	local n = 0
	// erase and make directory for finished checks
	! mkdir "FILEPATH"
	local datafiles: dir "`tmp_dir'/02_temp/01_code/checks" files "finished_*.txt"
	foreach datafile of local datafiles {
		rm "FILEPATH"
	}
	
	foreach location of local locations {
		// submit job
		local job_name "`type'_`location'_`step_num'"
		local slots = 4
		local mem = `slots' * 2

		! qsub -P proj_custom_models -N "`job_name'" -pe multi_slot `slots' -l mem_free=`mem' "`shell_file'" "`code_dir'/`step_num'_parallel.do" ///
		"`date' `step_num' `step_name' `location' `code_dir' `in_dir' `out_dir' `tmp_dir' `root_tmp_dir' `root_j_dir'"
		
		local ++ n		
		sleep 100
	}
	
	sleep 150000

// wait for jobs to finish ebefore passing execution back to main step file
	local i = 0
	while `i' == 0 {
		local checks : dir "`tmp_dir'/02_temp/01_code/checks" files "finished_*.txt", respectcase
		local count : word count `checks'
		di "checking `c(current_time)': `count' of `n' jobs finished"
		if (`count' == `n') continue, break
		else sleep 60000
	}

	di "`step_num' sequential runs completed"

	clear
	
// *********************************************************************************************************************************************************************
// *********************************************************************************************************************************************************************
// CHECK FILES (NO NEED TO EDIT THIS SECTION)

	// write check file to indicate step has finished
		file open finished using "`out_dir'/finished.txt", replace write
		file close finished
		
	// if step is last step, write finished.txt file
		local i_last_step 0
		foreach i of local last_steps {
			if "`i'" == "`this_step'" local i_last_step 1
		}
		
		// only write this file if this is one of the last steps
		if `i_last_step' {
		
			// account for the fact that last steps may be parallel and don't want to write file before all steps are done
			local num_last_steps = wordcount("`last_steps'")
			
			// if only one last step
			local write_file 1
			
			// if parallel last steps
			if `num_last_steps' > 1 {
				foreach i of local last_steps {
					local dir: dir "`root_j_dir" dirs "`i'_*", respectcase
					local dir = subinstr(`"`dir'"',`"""',"",.)
					cap confirm file "`root_j_dir'/`dir'/finished.txt"
					if _rc local write_file 0
				}
			}
			
			// write file if all steps finished
			if `write_file' {
				file open all_finished using "`root_j_dir'/finished.txt", replace write
				file close all_finished
			}
		}
		
	// close log if open
		if `close_log' log close
		
		clear all
	
