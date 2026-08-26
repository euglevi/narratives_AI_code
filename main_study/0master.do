* 0master.do
* Master file for "Why Artificial Intelligence is not a Salient Issue"
* Battiston, Boffa, Levi, Parmigiani, Stillman
* Set the two paths below, then run this file end to end.

clear
set more off
version 18

* PATHS
* code: folder containing main_study/ and follow_up/ (this repository)
* root: folder containing main_survey/ and follow-up/ (the data)

global code "/home/eugenio/git/narratives_AI_code"
global root "/home/eugenio/Dropbox/political_economy_techchange/data"

* TOGGLES
* Set to 0 to skip a block on reruns

global install_packages 1
global build_palette 1
global run_main 1
global run_followup 1

* ENVIRONMENT

capture mkdir "$root/main_survey/graphs"
capture mkdir "$root/main_survey/tables"
capture mkdir "$root/follow-up/graphs_tables"
capture mkdir "$root/logs"

if $install_packages {
foreach pkg in spmap shp2dta wyoung coefplot catplot labmask xframeappend palettes colrspace ftest schemepack mplotoffset fre {
capture which `pkg'
if _rc ssc install `pkg', replace
}
capture which grc1leg2
if _rc net install grc1leg2, from("http://digital.cgdev.org/doc/stata/MO/Misc") replace
}

* Custom colour styles used by every graph in the package
* Only needs to run once per machine

if $build_palette {
colorpalette optimism, select(1 2 4 5) stylefiles(baseline pessimistic balanced optimistic, personal replace)
}

log using "$root/logs/master.log", replace text

* MAIN STUDY

if $run_main {
do "$code/main_study/1prepare_dataset.do"
do "$code/main_study/2descriptive_stats.do"
do "$code/main_study/3policies.do"
do "$code/main_study/4signatures.do"
do "$code/main_study/5hetsignatures.do"
do "$code/main_study/6robustness_cntry.do"
do "$code/main_study/7robustness_inattentive.do"
do "$code/main_study/summary_table.do"
}

* FOLLOW-UP STUDY

if $run_followup {
do "$code/follow_up/1prepare_dataset.do"
do "$code/follow_up/2descriptive_stats.do"
}

log close
