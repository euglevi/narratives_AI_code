
**** TOTAL TIME 

set more off
clear
clear frames

cd "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey"

import delimited "./italy/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
reshape wide epoch, i(participant_code) j(page_index)
drop if session_code!="7f83jbg2"
drop if epoch20==.
drop in 1
gen total_time = epoch20-epoch0
gen total_time_min = total_time/60


import delimited "./germany/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
reshape wide epoch, i(participant_code) j(page_index)
drop if session_code!="e550d2ja"
drop if epoch20==.
drop in 1
gen total_time = epoch20-epoch0
gen total_time_min = total_time/60


import delimited "./us/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
reshape wide epoch, i(participant_code) j(page_index)
drop if session_code!="7vbha7nz"
drop if epoch20==.
drop in 1
gen total_time = epoch20-epoch0
gen total_time_min = total_time/60


**** TIME IN EACH PAGE


set more off
clear
clear frames

cd "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey"

import delimited "./italy/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
encode participant_code, gen(id)
xtset id page_index

drop if session_code!="7f83jbg2"
drop in 1
bys id: gen complete2 = page_index==20
bys id: egen complete = max(complete2)
drop if !complete

bys id (page_index): gen time_screen = epoch[_n] - epoch[_n-1] 
tab page_index, su(time_screen)
bys page_index: egen median_time_screen = median(time_screen)
tab page_index, su(median_time_screen)


import delimited "./germany/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
encode participant_code, gen(id)
xtset id page_index

drop if session_code!="e550d2ja"
drop in 1
bys id: gen complete2 = page_index==20
bys id: egen complete = max(complete2)
drop if !complete

bys id (page_index): gen time_screen = epoch[_n] - epoch[_n-1] 
tab page_index, su(time_screen)
bys page_index: egen median_time_screen = median(time_screen)
tab page_index, su(median_time_screen)


import delimited "./us/PageTimes-2024-10-14_morning.csv", varnames(1) clear

rename epoch_time_completed epoch
labmask page_index, values(page_name)
drop page_name app_name round_number timeout_happened is_wait_page participant_id_in_session
encode participant_code, gen(id)
xtset id page_index

drop if session_code!="7vbha7nz"
drop in 1
bys id: gen complete2 = page_index==20
bys id: egen complete = max(complete2)
drop if !complete

bys id (page_index): gen time_screen = epoch[_n] - epoch[_n-1] 
tab page_index, su(time_screen)
bys page_index: egen median_time_screen = median(time_screen)
tab page_index, su(median_time_screen)
