set more off
clear
clear frames

cd "$root/main_survey/"

* This Stata script:
* 1. Imports survey data from CSV files for Italy, Germany, and US
* 2. Appends the datasets into one combined dataset
* 3. Performs extensive cleaning and variable transformations
* 4. Creates derived variables for analysis including:
* - Job impact perception variables
* - Treatment variables
* - Demographic classifications
* - Cultural worldview measures
* - Policy preference indices
* 5. Links occupation classifications across languages
* 6. Handles various data corrections and country-specific adjustments

* IMPORT DATASETS FROM CSV FILES

import delimited "./italy/final-2024-10-31.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)

rename (v87 v89 v91 v95 v96 v99 v100 v102 v103 v125 v126) ///
    (v89 v91 v93 v97 v98 v101 v102 v104 v105 v127 v128)
gen cntry = "IT"

tempfile tmp
save `tmp'

import delimited "./germany/final-2024-10-31.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)
gen cntry = "DE"

tempfile tmp2
save `tmp2'

import delimited "./us/final-2024-11-06.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)
rename (v86 v88 v90 v94 v95 v98 v99 v101 v102 v124 v125) ///
    (v89 v91 v93 v97 v98 v101 v102 v104 v105 v127 v128)
gen cntry = "US"

tempfile tmp3
save `tmp3'

* APPEND DATASETS

use `tmp', replace
append using `tmp2' `tmp3'

* CLEAN DATASETS

drop session*
rename participant* *
drop payoff
drop age gender region
rename initial1player* *
drop id_in_group role payoff
rename beliefs1player* *
drop id_in_group role payoff treat sharing_inn
rename narratives1player* *
drop id_in_group role payoff
rename final1player* *

keep if !missing(_current_page_name)
bys treat: fre _current_page_name  // looking at attrition

keep if _current_page_name == "Completion"
drop if id_cint == "prova" | id_cint == "prova2"

replace job_impact_robots = -job_impact_robots if v91 == "decrease"
encode ai_what_is, gen(ai_what)
replace ai_what = 1 if ai_what == 5 | ai_what == 7
replace ai_what = 2 if ai_what == 4 | ai_what == 8
replace ai_what = 3 if ai_what == 6 | ai_what == 9
label define ai 1 "prediction" 2 "intelligence" 3 "rules"
label values ai_what ai
gen ai_job_impact = v98
replace ai_job_impact = -v98 if v97 == "decrease"
gen ai_job_impact_low = v102
replace ai_job_impact_low = -v102 if v101 == "decrease"
gen ai_job_impact_high = v105
replace ai_job_impact_high = -v105 if v104 == "decrease"

foreach v of varlist job_impact_robots ai_job_impact ai_job_impact_high ///
    ai_job_impact_low {
    replace `v' = 100 if `v' > 100
    replace `v' = -100 if `v' < -100
    sum `v', de
    gen `v'_over = `v' < r(p25)
    gen `v'_under = `v' > r(p90)
    gen `v'_bad = `v' < 0
    gen res_`v' = (-`v' + 100)/200
}

label variable job_impact_robots_bad "robots decrease jobs"
label variable job_impact_robots_over "robots kill jobs"
label variable job_impact_robots_under "robots boost jobs"
label variable ai_job_impact_bad "ai decrease jobs"
label variable ai_job_impact_over "ai kill jobs"
label variable ai_job_impact_under "ai boost jobs"

gen sharing = sharing_inn != "not support"
replace treat = "balanced" if treat == "neutral"
encode treat, gen(d_treat)
recode d_treat (1 = 3 "balanced") (2 = 1 "baseline") (3 = 2 "optimistic") ///
    (4 = 4 "pessimistic"), gen(d_treat2)
drop d_treat
rename d_treat2 d_treat
tab d_treat, gen(d_treat)
replace sharing_inn = "balanced" if sharing_inn == "neutral"
replace sharing_inn = "" if sharing_inn == "ne podrške."
encode sharing_inn, gen(d_sharing_inn)
recode d_sharing_inn (1 = 3 "balanced") (2 = 1 "not support") ///
    (3 = 2 "optimistic") (4 = 4 "pessimistic"), gen(d_sharing_inn2)
drop d_sharing_inn
rename d_sharing_inn2 d_sharing_inn
tab d_sharing_inn, gen(d_sharing_inn)
label variable d_sharing_inn2 "Optimistic"
label variable d_sharing_inn3 "Balanced"
label variable d_sharing_inn4 "Pessimistic"
gen support = !d_sharing_inn1
label variable support "Willingness to sign"

egen mistakes = rowmax(mistake_answer1 mistake_answer2 mistake_answer3 ///
    mistake_answer4 mistake_answer5)

gen policy_intervention = inlist(policy_interven, "Ja", "Yes", "Sì")
label variable policy_intervention "Policy intervention"
label define yesno 0 "no" 1 "yes"
label values policy_intervention yesno

foreach v of varlist rank*_robots country_more_robot {
    replace `v' = "China" if `v' == "Cina"
    replace `v' = "Republic of Korea" if `v' == "Corea del Sud"
    replace `v' = "Germany" if `v' == "Germania"
    replace `v' = "Japan" if `v' == "Giappone"
    replace `v' = "Italy" if `v' == "Italia"
    replace `v' = "US" if `v' == "USA"
    replace `v' = "US" if `v' == "Stati Uniti"
    replace `v' = "Republic of Korea" if `v' == "Südkorea"
    replace `v' = "Germany" if `v' == "Deutschland"
    replace `v' = "Italy" if `v' == "Italien"
    replace `v' = "Russia" if `v' == "Russland"
}

foreach v of varlist sector* v89 {
    replace `v' = "Food" if inlist(`v', "Alimentare", "Lebensmittel")
    replace `v' = "Automotive" if inlist(`v', "Automobile", "Automobilistico")
    replace `v' = "Electrics/Electronics" if inlist(`v', "Elektrik/Elektronik", ///
        "Elettrico/Elettronico")
    replace `v' = "Plastic and Chemical Products" if inlist(`v', ///
        "Kunststoff und chemische Produkte", "Prodotti plastici e chimici")
    replace `v' = "Metal and Machinery" if inlist(`v', "Metall und Maschinen", ///
        "Metalli e macchinari")
}

replace v93 = "decrease a lot" if inlist(v93, "diminuirebbe molto", ///
    "Es wird stark abnehmen" )
replace v93 = "decrease a little" if inlist(v93, "diminuirebbe un po'", ///
    "Es wird leicht abnehmen")
replace v93 = "increase a lot" if inlist(v93, "aumenterebbe molto", ///
    "Es wird stark zunehmen", "increase a lot")
replace v93 = "increase a little" if inlist(v93, "aumenterebbe un po'", ///
    "Es wird leicht zunehmen", "increase a little")
replace v93 = "remain the same" if inlist(v93, "rimarrebbe la stessa", ///
    "Es wird gleichbleiben", "remain the same")
gen job_impact_robots_overall = .
replace job_impact_robots_overall = 1 if inlist(v93, "diminuirebbe molto", ///
    "Es wird stark abnehmen", "decrease a lot")
replace job_impact_robots_overall = 2 if inlist(v93, "diminuirebbe un po'", ///
    "Es wird leicht abnehmen", "decrease a little")
replace job_impact_robots_overall = 5 if inlist(v93, "aumenterebbe molto", ///
    "Es wird stark zunehmen", "increase a lot")
replace job_impact_robots_overall = 4 if inlist(v93, "aumenterebbe un po'", ///
    "Es wird leicht zunehmen", "increase a little")
replace job_impact_robots_overall = 3 if inlist(v93, "rimarrebbe la stessa", ///
    "Es wird gleichbleiben", "remain the same")
labmask job_impact_robots_overall, values(v93)
label variable robots_per_1000_wo "Belief on robots per 1000 workers"
tab job_impact_robots_overall, gen(job_impact_robots_overall)
revrs job_impact_robots_overall
gen res_revjob_impact_robots_overall = (revjob_impact_robots_overall - 1)/4

gen job_robots = 0
replace job_robots = -1 if inrange(job_impact_robots, -100, -5)
replace job_robots = 1 if inrange(job_impact_robots, 5, 100)
label define job_robots -1 "decrease jobs" 0 "remain the same" 1 ///
    "increase jobs", modify
label values job_robots job_robots

gen job_ai = 0
replace job_ai = -1 if inrange(ai_job_impact, -100, -5)
replace job_ai = 1 if inrange(ai_job_impact, 5, 100)
label define job_ai -1 "decrease jobs" 0 "remain the same" 1 "increase jobs", ///
    modify
label values job_ai job_ai

gen job_ai_low = 0
replace job_ai_low = -1 if inrange(ai_job_impact_low, -100, -5)
replace job_ai_low = 1 if inrange(ai_job_impact_low, 5, 100)
label values job_ai_low job_ai

gen job_ai_high = 0
replace job_ai_high = -1 if inrange(ai_job_impact_high, -100, -5)
replace job_ai_high = 1 if inrange(ai_job_impact_high, 5, 100)
label values job_ai_high job_ai

encode cntry, gen(d_cntry)
label variable cntry "country"

encode survey_biased, gen(d_survey_biased)
replace d_survey_biased = 4 if inlist(d_survey_biased, 3, 5)
replace d_survey_biased = 8 if inlist(d_survey_biased, 1, 7)
replace d_survey_biased = 9 if inlist(d_survey_biased, 2, 6)
tab d_treat d_survey_biased, chi

* initial questionnaire

gen under35 = age <= 35
gen over65 = age >= 65

gen d_closeness = closeness_to_party > 4

encode gender, gen(d_gender2)
recode d_gender2 (1 6 7 = 3 "other") (4 5 8 = 1 "male") (2 3 9 = 2 "female"), ///
    gen(d_gender)
drop d_gender2
label variable d_gender "Gender"

encode nationality, gen(d_nationality2)
recode d_nationality2 (1 6 9 = 3 "other") (3 5 7 = 2 "bi-national") ///
    (2 4 8 = 1 "national"), gen(d_nationality)
drop d_nationality2
label variable d_nationality "Nationality"

encode highest_education, gen(d_education2)
recode d_education2 (1 25 7 12 = 1 "high school") ///
    (3 4 9 19 2 17 = 2 "vocational") ///
    (10 13 15 16 18 26 24 8 22 = 3 "university") ///
    (14 5 6 11 20 21 23 = 0 "primary school or nothing"), gen(d_education)
drop d_education2
label variable d_education "Highest education"
recode d_education (0 = 0 "primary school or nothing") ///
    (1 2 = 1 "high school") (3 = 2 "university"), gen(d_education2)
recode d_education (0 1 2 = 0 "lower than university") (3 = 1 "university"), ///
    gen(d_education3)

encode current_employment, gen(d_employment2)
recode d_employment2 (1 14 20 = 7 "other") (4 6 24 = 3 "out of job market") ///
    (7 8 12 13 25 2 3 5 = 0 "employed") (9 11 23 = 2 "unemployed") ///
    (10 18 19 = 1 "self-employed") (15 16 17 = 4 "retired") ///
    (21 22 = 5 "student"), gen(d_employment)
drop d_employment2
label variable d_employment "Employment status"

gen d_eligible_vote = inlist(eligible_to_vote, "Ja", "Sì", "Yes")
label variable d_eligible_vote "Eligible to vote"

rename political_views_sc lr_scale
label variable lr_scale "Left/Right orientation"
recode lr_scale (1/4 = 1 "left") (5/7 = 0 "center") (8/11 = 2 "right"), ///
    gen(d_lr_scale)
tab d_lr_scale, gen(d_lr_scale)
label variable d_lr_scale1 "Center"
label variable d_lr_scale2 "Left"
label variable d_lr_scale3 "Right"

encode voting_intention, gen(d_voting2)
gen opposition = inlist(d_voting2, 1, 2, 4, 5, 6, 7, 8, 11, 12, 16, 17, 19, ///
    20, 21, 23)
recode d_voting2 (1 4 6 17 20 10 22 9 = 2 "centre-left") ///
    (3 14 8 13 21 = 3 "centre-right") (19 23 11 7 = 1 "far-left") ///
    (15 18 2 = 4 "far-right") (16 12 5 . = 5 "do not know"), gen(d_voting)
drop d_voting2
tab d_voting, gen(d_voting)

* cultural worldviews

foreach v of varlist charm cprotect climchoi hequal hrevdis2 hfeminin {
    revrs `v'
}

gen indiv = (iintrsts + iprotect + iprivacy + revcharm + revcprotect + ///
    revclimchoi)/36
gen equal = (revhequal + ewealth + eradeq + ediscrim + revhrevdis2 + ///
    revhfeminin)/36
gen fatalists = indiv > 0.6 & equal < 0.6
gen hierarchical = indiv <= 0.6 & equal <= 0.6
label variable fatalists "individ/not egal"
label variable hierarchical "communit/not egal"
replace indiv = indiv >= 0.6
replace equal = equal >= 0.6

gen gridgroup = 0
replace gridgroup = 1 if indiv < 0.5 & equal < 0.5
replace gridgroup = 2 if indiv < 0.5 & equal > 0.5
replace gridgroup = 3 if indiv > 0.5 & equal > 0.5
replace gridgroup = 4 if indiv > 0.5 & equal < 0.5
replace gridgroup = 5 if indiv > 0.5 & equal == 0.5
replace gridgroup = 6 if indiv < 0.5 & equal == 0.5
replace gridgroup = 7 if indiv == 0.5 & equal > 0.5
replace gridgroup = 8 if indiv == 0.5 & equal < 0.5
replace gridgroup = 9 if indiv == 0.5 & equal == 0.5
label define gridgroup 1 "hierarchical" 2 "egalitarian" 3 "individualist" 4 ///
    "fatalists" 5 "pure individualists" 6 "pure solidarist" 7 "pure egalitarian" ///
    8 "pure hierarchical" 9 "anomaly"
label values gridgroup gridgroup


* final questionnaire

encode civil_status, gen(d_civil_status2)
recode d_civil_status2 (3 15 17 = 1 "married") (2 8 12 = 2 "civil union") ///
    (1 9 10 4 14 11 = 3 "divorced or separated") (6 16 18 = 4 "widow") ///
    (5 7 13 = 5 "single"), gen(d_civil_status)
drop d_civil_status2
label variable d_civil_status "Civil status"

rename born_in_country immig

encode firm_use_robots_ai, gen(d_firm_use_robots_ai2)
recode d_firm_use_robots_ai2 (5 7 13 = 0 "none") (9 10 11 = 1 "robots") ///
    (1 4 = 2 "AI") (2 3 12 = 3 "both") (6 8 14 = 4 "not applicable"), ///
    gen(d_firm_use_robots_ai)
drop d_firm_use_robots_ai2
label variable d_firm_use_robots_ai "Firm uses robots/AI"

pca trust* if d_treat == 1
predict pca_trst, score

label variable trust_in_government "Government"
label variable trust_in_political_p "Political parties"
label variable trust_in_trade_union "Trade unions"
label variable trust_in_tech_tycoon "Tech tycoons"
label variable job_loss_chance "Job loss chance"

encode religious_community, gen(d_religious_community2)
recode d_religious_community2 (4 5 20 = 0 "do not belong") ///
    (2 11 18 = 1 "catholic") (9 15 21 = 2 "protestant") (3 12 13 = 3 "orthodox") ///
    (6 16 19 = 4 "islamic") (1 7 8 14 10 17 = 5 "other"), ///
    gen(d_religious_community)
drop d_religious_community2
label variable d_religious_community "Religion"

replace smartphone_os = "other" if inlist(smartphone_os, "Altro", "Other", ///
    "andere")

rename hours_computer_use_f hours_computer
sum hours_computer, de
replace hours_computer = . if hours_computer >= r(p95)
gen d_hours_computer = .
replace d_hours_computer = 1 if hours_computer <= 2
replace d_hours_computer = 2 if inrange(hours_computer, 2.01, 5)
replace d_hours_computer = 3 if inrange(hours_computer, 5, 14)

rename annual_gross_househo hincome
gen low_income = 0
sum hincome if d_cntry == 1, de
replace hincome = r(p50) if hincome == . & d_cntry == 1
replace low_income = 1 if hincome < r(p50) & d_cntry == 1
sum hincome if d_cntry == 2, de
replace hincome = r(p50) if hincome == . & d_cntry == 2
replace low_income = 1 if hincome < r(p50) & d_cntry == 2
sum hincome if d_cntry == 3, de
replace hincome = r(p50) if hincome == . & d_cntry == 3
replace low_income = 1 if hincome < r(p50) & d_cntry == 3
label variable low_income "low income"
* keep if cntry == "US"
* export delimited label cntry using participants_US.csv, replace

* index for misperceptions

rename robots_per_1000_wo question1
rename country_more_robot question3
rename sector_more_robots question4
rename v89 question5

gen question1_ok = 0
replace question1_ok = 1 if inrange(question1, 23, 33) & cntry == "US"
replace question1_ok = 1 if inrange(question1, 36, 46) & cntry == "DE"
replace question1_ok = 1 if inrange(question1, 17, 27) & cntry == "IT"
gen question2_ok = inlist(rank1_robots, "Republic of Korea", "Germany", ///
    "Japan")
gen question3_ok = question3 == "China"
gen question4_ok = question4 == "Electrics/Electronics"
gen question5_ok = 0
replace question5_ok = 1 if question5 == "Automotive" & cntry == "DE"
replace question5_ok = 1 if question5 == "Automotive" & cntry == "US"
replace question5_ok = 1 if question5 == "Metal and Machinery" & ///
    cntry == "IT"

egen bad_answers = rowtotal(question1_ok question2_ok question3_ok ///
    question4_ok question5_ok)
replace bad_answers = 5 - bad_answers
gen r_bad_answers = bad_answers/5

gen question1_low = 0
replace question1_low = 1 if question1 < 18 & cntry == "US"
replace question1_low = 1 if question1 < 31 & cntry == "DE"
replace question1_low = 1 if question1 < 12 & cntry == "IT"
gen question1_high = 0
replace question1_high = 1 if question1 > 43 & cntry == "US"
replace question1_high = 1 if question1 > 56 & cntry == "DE"
replace question1_high = 1 if question1 > 37 & cntry == "IT"
label variable question1_low "under. no. robots"
label variable question1_high "over. no. robots"

tab ai_what, gen(ai_what)
label variable ai_what1 "AI prediction"
label variable ai_what2 "AI intelligence"
label variable ai_what3 "AI rules"

gen question_robots = 0
replace question_robots = -1 if question1_low
replace question_robots = 1 if question1_high
label define question_robots -1 "underestimate" 0 "correct" 1 "overestimate"
label values question_robots question_robots

gen ai_what_wrong = ai_what != 1
label define ai_what_wrong 0 "correct" 1 "wrong"
label values ai_what_wrong ai_what_wrong

gen ignorant = ai_what_wrong & bad_answers >= 3
label variable ignorant "Low knowledge"


* index for policies

egen proinn = rowmean(tax_credits_inn education_polic)
egen redistr = rowmean(universal_incom minimum_wage_po unemployment_be ///
    lower_taxes_on_)
egen targ = rowmean(stronger_regula breaking_up_tec)

egen max_policies = rowtotal(tax_credits_inn education_polic universal_incom ///
    minimum_wage_po unemployment_be stronger_regula breaking_up_tec ///
    lower_taxes_on_ higher_taxes_on)
egen max_proinn = rowtotal(tax_credits_inn education_polic)
egen max_redistr = rowtotal(universal_incom minimum_wage_po lower_taxes_on_ ///
    unemployment_be)
egen max_targ = rowtotal(stronger_regula breaking_up_tec)

gen int_proinn = proinn if proinn != 0
gen int_redistr = redistr if redistr != 0
gen int_targ = targ if targ != 0

label variable proinn "Pro-innovation"
label variable redistr "Redistribution"
label variable targ "Constraints on big tech"

label variable max_proinn "Pro-innovation"
label variable max_redistr "Undiscriminated pro-welfare"
label variable max_targ "Targeted policies"

label variable universal_incom "BI"
label variable tax_credits_inn "Tax cred"
label variable stronger_regula "Regul"
label variable education_polic "Education"
label variable breaking_up_tec "Break"
label variable lower_taxes_on_ "Low tax lab"
label variable higher_taxes_on "Tax robots"
label variable minimum_wage_po "Min wage"
label variable unemployment_be "Unemp ben"

* time
gen double time = clock(time_started_utc, "YMDhm#")
format time % tc

gen double date = date(time_started_utc, "YMD###")
format date % td

gen double hour = clock(time_started_utc, "###h##")
format hour % tc

* variables for web
bys d_cntry d_sharing_inn: gen indicator = _n
gen signature = 0
replace signature = 1 if d_cntry == 1 & d_sharing_inn == 2 & indicator <= 13
replace signature = 1 if d_cntry == 1 & d_sharing_inn == 4 & indicator <= 47
replace signature = 1 if d_cntry == 1 & d_sharing_inn == 3 & indicator <= 85
replace signature = 1 if d_cntry == 2 & d_sharing_inn == 2 & indicator <= 13
replace signature = 1 if d_cntry == 2 & d_sharing_inn == 4 & indicator <= 45
replace signature = 1 if d_cntry == 2 & d_sharing_inn == 3 & indicator <= 57
replace signature = 1 if d_cntry == 3 & d_sharing_inn == 2 & indicator <= 12
replace signature = 1 if d_cntry == 3 & d_sharing_inn == 4 & indicator <= 22
replace signature = 1 if d_cntry == 3 & d_sharing_inn == 3 & indicator <= 26

gen signature2 = 0
replace signature2 = 2 if d_cntry == 1 & d_sharing_inn == 2 & indicator <= 13
replace signature2 = 4 if d_cntry == 1 & d_sharing_inn == 4 & indicator <= 47
replace signature2 = 3 if d_cntry == 1 & d_sharing_inn == 3 & indicator <= 85
replace signature2 = 2 if d_cntry == 2 & d_sharing_inn == 2 & indicator <= 13
replace signature2 = 4 if d_cntry == 2 & d_sharing_inn == 4 & indicator <= 45
replace signature2 = 3 if d_cntry == 2 & d_sharing_inn == 3 & indicator <= 57
replace signature2 = 2 if d_cntry == 3 & d_sharing_inn == 2 & indicator <= 12
replace signature2 = 4 if d_cntry == 3 & d_sharing_inn == 4 & indicator <= 22
replace signature2 = 3 if d_cntry == 3 & d_sharing_inn == 3 & indicator <= 26

tab signature2, gen(d_signature)

gen clicks = button_link > 0

foreach treat in 1 2 3 4 {
    foreach cntry in 1 2 3 {
        foreach share in 2 3 4 {
            count if d_sharing_inn == `share' & clicks & d_treat == `treat' & ///
                d_cntry == `cntry'
            local clicks_s`share'_t`treat'_c`cntry' = r(N)
        }
    }
}

foreach cntry in 1 2 3 {
    foreach share in 2 3 4 {
        count if d_sharing_inn == `share' & signature & d_cntry == `cntry'
        local signatures_s`share'_c`cntry' = r(N)
    }
}

bys d_cntry d_sharing_inn d_treat: gen indicator2 = _n
gen d_signaturet = 0
forvalues s = 2/4 {
    forvalues t = 1/4 {
        forvalues c = 1/3 {
            replace d_signaturet = `s' if d_cntry == `c' & d_treat == `t' & ///
                d_sharing_inn == `s' & ///
                indicator2 <= round((`signatures_s`s'_c`c''/(`clicks_s`s'_t1_c`c'' + ///
                `clicks_s`s'_t2_c`c'' + `clicks_s`s'_t3_c`c'' + `clicks_s`s'_t4_c`c'')) ///
*             `clicks_s`s'_t`t'_c`c'')
        }
    }
}

tab d_signaturet, gen(d_signaturet)

* industry and occupation classification
frame create jobs_en
frame change jobs_en
import excel using "./classification_gpt/jobs_classified_en.xlsx", ///
    clear firstrow
frame create jobs_de
frame change jobs_de
import excel using "./classification_gpt/jobs_classified_de.xlsx", ///
    clear firstrow
frame create jobs_it
frame change jobs_it
import excel using "./classification_gpt/jobs_classified_it.xlsx", ///
    clear firstrow
frame change default

frlink 1:1 id_cint, frame(jobs_en) gen(en)
frlink 1:1 id_cint, frame(jobs_it) gen(it)
frlink 1:1 id_cint, frame(jobs_de) gen(de)
frget soc_code_en = soc_code vulnerability_en = vulnerability soc_title_en = ///
    title soc_description_en = description, from(en)
frget soc_code_it = soc_code vulnerability_it = vulnerability soc_title_it = ///
    title soc_description_it = description, from(it)
frget soc_code_de = soc_code vulnerability_de = vulnerability soc_title_de = ///
    title soc_description_de = description, from(de)
gen soc_code = ""
replace soc_code = soc_code_en if soc_code == ""
replace soc_code = soc_code_it if soc_code == ""
replace soc_code = soc_code_de if soc_code == ""
gen vulnerability_frey = .
replace vulnerability_frey = vulnerability_en if vulnerability_frey == .
replace vulnerability_frey = vulnerability_it if vulnerability_frey == .
replace vulnerability_frey = vulnerability_de if vulnerability_frey == .
gen soc_title = ""
replace soc_title = soc_title_en if soc_title == ""
replace soc_title = soc_title_it if soc_title == ""
replace soc_title = soc_title_de if soc_title == ""
gen soc_description = ""
replace soc_description = soc_description_en if soc_description == ""
replace soc_description = soc_description_it if soc_description == ""
replace soc_description = soc_description_de if soc_description == ""
drop soc_code_en soc_code_it soc_code_de vulnerability_en vulnerability_it ///
    vulnerability_de en it de soc_title_en soc_title_it soc_title_de ///
    soc_description_en soc_description_it soc_description_de
gen high_vulnerability = vulnerability_frey >= 0.5
replace high_vulnerability = . if vulnerability_frey == .

replace soc_code = "37-2012" if soc_code == "Cleaning"
replace soc_code = "35-2014" if soc_code == "Cook"
replace soc_code = "41-2031" if soc_code == "Retail Salespersons" | ///
    soc_code == "Retail salespersons"
replace soc_code = "95" if soc_code == "Unemployed"
replace soc_code = "96" if soc_code == "Retired"
replace soc_code = "97" if soc_code == "Housewife"
replace soc_code = "98" if soc_code == "Disabled"
replace soc_code = "99" if soc_code == "" | soc_code == "No code available"

gen occupation = usubstr(soc_code, 1, 2)
label define soc_occ 11 "Management" 13 "Business and Financial Operations" ///
    15 "Computer and Mathematical" 17 "Architecture and Engineering" 19 ///
    "Life, Physical, and Social Science" 21 "Community and Social Service" 23 ///
    "Legal" 25 "Educational Instruction and Library" 27 ///
    "Arts, Design, Entertainment, Sports, and Media" 29 ///
    "Healthcare Practitioners and Technical" 31 "Healthcare Support" 33 ///
    "Protective Service" 35 "Food Preparation and Serving Related" 37 ///
    "Building and Grounds Cleaning and Maintenance" 39 ///
    "Personal Care and Service" 41 "Sales and Related" 43 ///
    "Office and Administrative Support" 45 "Farming, Fishing, and Forestry" 47 ///
    "Construction and Extraction" 49 "Installation, Maintenance, and Repair" 51 ///
    "Production" 53 "Transportation and Material Moving" 95 "Unemployed" 96 ///
    "Retired" 97 "Housewife" 98 "Disabled" 99 "Other/Not Available"

* Apply the label to the occupation variable
destring occupation, replace
label values occupation soc_occ


frame create industries_en
frame change industries_en
import excel using "./classification_gpt/industries_classified_en.xlsx", ///
    clear firstrow
frame create industries_de
frame change industries_de
import excel using "./classification_gpt/industries_classified_de.xlsx", ///
    clear firstrow
frame create industries_it
frame change industries_it
import excel using "./classification_gpt/industries_classified_it.xlsx", ///
    clear firstrow
frame change default

frlink 1:1 id_cint, frame(industries_en) gen(en)
frlink 1:1 id_cint, frame(industries_it) gen(it)
frlink 1:1 id_cint, frame(industries_de) gen(de)
frget nace_code_en = nace_code industry_en = NAME, from(en)
frget nace_code_it = nace_code industry_it = NAME, from(it)
frget nace_code_de = nace_code industry_de = NAME, from(de)
gen nace_code = ""
replace nace_code = nace_code_en if nace_code == ""
replace nace_code = nace_code_it if nace_code == ""
replace nace_code = nace_code_de if nace_code == ""
gen industry = ""
replace industry = industry_en if industry == ""
replace industry = industry_it if industry == ""
replace industry = industry_de if industry == ""
drop nace_code_en nace_code_it nace_code_de industry_en industry_it ///
    industry_de en it de
replace nace_code = subinstr(nace_code, "NACE code: ", "", .)
replace nace_code = subinstr(nace_code, `""""', "", .)
replace nace_code = subinstr(nace_code, "NACE code ", "", .)
replace nace_code = "K" if inlist(nace_code, "60", "61", "62")
replace nace_code = "G" if inlist(nace_code, "47", "47.2", "47.5")
replace nace_code = "L" if inlist(nace_code, "65", "K L")
replace nace_code = "O" if inlist(nace_code, "69")
replace nace_code = "N" if inlist(nace_code, "74.10")
replace nace_code = "T" if inlist(nace_code, "80", "Securitas", ///
    "Sicherheit: Werkschutz NACE Code: O", "81.21")
replace nace_code = "R" if inlist(nace_code, "86", "87")
replace nace_code = "C" if inlist(nace_code, "95")
gsort nace_code -industry
replace industry = industry[_n-1] if industry == "" & ///
    nace_code == nace_code[_n-1]
replace industry = "NONE" if nace_code == "None" | industry == ""

encode industry, gen(d_industry)

gen sector = .
replace sector = 1 if inlist(d_industry, 10, 11, 5, 7, 20)  // Manufacturing
replace sector = 2 if d_industry == 3  // Agriculture
replace sector = 3 if inlist(d_industry, 1, 2, 4, 6, 8, 9, 12, 13, 14, 15, ///
    16, 17, 18, 19, 21) // Services
label define sector 1 "Manufacturing" 2 "Agriculture" 3 "Services"
label values sector sector

frame create felten
frame change felten
import excel using "./classification_gpt/AIOE_DataAppendix.xlsx", ///
    clear firstrow sheet("Appendix A")
rename (SOCCode AIOE) (soc_code vulnerability_felten)
frame change default

frlink m:1 soc_code, frame(felten) gen(felten)
frget vulnerability_felten, from(felten)

frame create science
frame change science
import delimited using "./classification_gpt/science_autoScores.csv", ///
    clear varnames(1)
drop if year != 2019
rename simpleocc soc_code
frame change default

frlink m:1 soc_code, frame(science) gen(science)
frget freyosborne pct_* msml norm* felten_raj_seamans, from(science)

frame create science2
frame change science2
import delimited using "./classification_gpt/science_exposure.csv", ///
    clear varnames(1)
drop if substr(onetsoccode, -2, .) != "00"
rename occ_code soc_code
frame change default

frlink m:1 soc_code, frame(science2) gen(science2)
frget gpt4* human* automation, from(science2)
rename gpt4_beta vulnerability_gpt4
rename human_beta vulnerability_human
rename pct_ai vulnerability_webb_ai
rename pct_robot vulnerability_webb_robot
rename pct_software vulnerability_webb_software

* classify open questions by expectations and certainty

frame create openquestions_en
frame change openquestions_en
import excel using "./classification_gpt/open_opinion_classified_en.xlsx", ///
    clear firstrow
frame create openquestions_de
frame change openquestions_de
import excel using "./classification_gpt/open_opinion_classified_it.xlsx", ///
    clear firstrow
frame create openquestions_it
frame change openquestions_it
import excel using "./classification_gpt/open_opinion_classified_de.xlsx", ///
    clear firstrow
frame change default

frlink 1:1 id_cint, frame(openquestions_en) gen(en)
frlink 1:1 id_cint, frame(openquestions_it) gen(it)
frlink 1:1 id_cint, frame(openquestions_de) gen(de)
frget expectation_en = expectation certainty_en = certainty, from(en)
frget expectation_it = expectation certainty_it = certainty, from(it)
frget expectation_de = expectation certainty_de = certainty, from(de)
gen expectation = ""
replace expectation = expectation_en if expectation == ""
replace expectation = expectation_it if expectation == ""
replace expectation = expectation_de if expectation == ""
gen certainty = ""
replace certainty = certainty_en if certainty == ""
replace certainty = certainty_it if certainty == ""
replace certainty = certainty_de if certainty == ""
drop expectation_en expectation_it expectation_de certainty_en certainty_it ///
    certainty_de en it de

encode expectation, gen(d_expectation)
recode d_expectation (5 2 = 1 "do not know") (3 = 2 "optimist") ///
    (4 = 4 "pessimist") (1 = 3 "balanced"), gen(d_expectation2)
recode d_expectation (5 = 1 "do not know") (3 = 2 "optimist") ///
    (1 = 3 "balanced") (4 = 4 "pessimist") (2 = 5 "not related"), ///
    gen(d_expectation_all)
drop d_expectation
rename d_expectation2 d_expectation
replace d_expectation = 1 if d_expectation == .
gen support_initial = d_expectation == d_sharing_inn
tab d_expectation, gen(d_expectation)

encode certainty, gen(d_certainty)

recode d_certainty (1 = 3 "high") (2 = 1 "low") (3 = 2 "medium"), ///
    gen(d_certainty2)
drop d_certainty
rename d_certainty2 d_certainty
gen d_low_certainty = inlist(d_certainty, 1, 2)

global controls under35 over65 i.d_gender i.d_education i.occupation ///
    i.d_employment ib2.d_industry low_income i.d_cntry i.date i.hour

* prepare variable for heterogeneity analysis on individual characteristics
gen female = d_gender == 2
drop university
gen university = d_education == 3
gen blue_collar = inrange(occupation, 45, 53)
gen service_worker = inrange(occupation, 31, 43)
gen unemp = d_employment == 2
gen neet = inrange(d_employment, 3, 5)
gen manufacturing = inlist(d_industry, 5, 10, 11, 20)

* prepare variable for heterogeneity analysis on attitudes
gen risk_averse = risk_willingness <= 4
gen negative_tech = feelings_towards_tec <= 4
sum vulnerability_felten, de
replace vulnerability_felten = (vulnerability_felten - r(min))/(r(max) ///
    - r(min))
sum vulnerability_webb_software, de
replace vulnerability_webb_software = (vulnerability_webb_software - ///
    r(min))/(r(max) - r(min))
sum vulnerability_webb_robot, de
replace vulnerability_webb_robot = (vulnerability_webb_robot - ///
    r(min))/(r(max) - r(min))
sum vulnerability_webb_ai, de
replace vulnerability_webb_ai = (vulnerability_webb_ai - r(min))/(r(max) ///
    - r(min))
foreach var of varlist vulnerability_* {
    gen high_`var' = `var' > 0.5
}


* MATCH WITH FOLLOW UP

frame create match
frame change match

import delimited ///
    "/home/eugenio/Dropbox/political_economy_techchange/data/follow-up/match_ids.csv", clear varnames(1)
replace follow_up = ustrlower(follow_up)
replace main_survey = ustrlower(main_survey)
drop if main_survey == "#n/a" | main_survey == ""  // no matches for 5 italian guys and 11 guys that do not match Tejas' file

frame change default
frlink 1:1 id_cint cntry, frame(match main_survey cntry) gen(link)
frget id_cint_follow = follow_up, from(link)

frame create match_follow
frame change match_follow

use ///
    "/home/eugenio/Dropbox/political_economy_techchange/data/follow-up/dataset", ///
    replace

frame change default
frlink m:1 id_cint_follow cntry, frame(match_follow id_cint cntry) gen(link2)
frget l_b_most_com* narr_emotion happiness anger fear political_corr, ///
    from(link2)


* merge with data on arguments

frame create arguments_en
frame change arguments_en
import excel using "./lda_arguments/arguments_classified_en.xlsx", ///
    clear firstrow
gen d_expand = expand == "Duplicated observation"
drop argument expand
reshape wide classification, i(id_cint) j(d_expand)
frame create arguments_de
frame change arguments_de
import excel using "./lda_arguments/arguments_classified_it.xlsx", ///
    clear firstrow
gen d_expand = expand == "Duplicated observation"
drop argument expand
reshape wide classification, i(id_cint) j(d_expand)
frame create arguments_it
frame change arguments_it
import excel using "./lda_arguments/arguments_classified_de.xlsx", ///
    clear firstrow
gen d_expand = expand == "Duplicated observation"
drop argument expand
reshape wide classification, i(id_cint) j(d_expand)
frame change default

frlink 1:1 id_cint, frame(arguments_en) gen(en)
frlink 1:1 id_cint, frame(arguments_it) gen(it)
frlink 1:1 id_cint, frame(arguments_de) gen(de)
frget classification0_en = classification0 classification1_en = ///
    classification1, from(en)
frget classification0_it = classification0 classification1_it = ///
    classification1, from(it)
frget classification0_de = classification0 classification1_de = ///
    classification1, from(de)
gen classification0 = ""
replace classification0 = classification0_en if classification0 == ""
replace classification0 = classification0_it if classification0 == ""
replace classification0 = classification0_de if classification0 == ""
gen classification1 = ""
replace classification1 = classification1_en if classification1 == ""
replace classification1 = classification1_it if classification1 == ""
replace classification1 = classification1_de if classification1 == ""
drop classification0_en classification1_en classification0_it ///
    classification1_it classification0_de classification1_de en it de

forvalues i = 0/1 {
    replace classification`i' = "Labour" if ustrpos(classification`i', "Labour") ///
        != 0
    replace classification`i' = "Regulation" if ustrpos(classification`i', ///
        "Regulation") != 0
    replace classification`i' = "Not related" if ustrpos(classification`i', ///
        "Please") != 0
}

gen arg_labour = classification0 == "Labour" | classification1 == "Labour"
gen arg_security = classification0 == "Security" | ///
    classification1 == "Security"
gen arg_humanity = classification0 == "Humanity" | ///
    classification1 == "Humanity"
gen arg_regulation = classification0 == "Regulation" | ///
    classification1 == "Regulation"
gen arg_mistAIcom = (classification0 == "Mistrust towards AI companies" | ///
    classification1 == "Mistrust towards AI companies")
gen arg_againstinn = classification0 == "Security" | ///
    classification1 == "Security" | ///
    classification0 == "Mistrust towards AI companies" | ///
    classification1 == "Mistrust towards AI companies" | ///
    classification0 == "Humanity" | classification1 == "Humanity" | ///
    | classification0 == "Regulation" | classification1 == "Regulation"

gen arg_market = (classification0 == "Market" | classification1 == "Market")
gen arg_mistpol = (classification0 == ///
    "Mistrust towards politicians and the government" | ///
    classification1 == "Mistrust towards politicians and the government")
gen arg_confidence = (classification0 == "Confidence in automation and AI") ///
    | (classification1 == "Confidence in automation and AI")
gen arg_proinn = (classification0 == "Market" | classification1 == "Market") ///
    | (classification0 == "Mistrust towards politicians and the government" | ///
    classification1 == "Mistrust towards politicians and the government") | ///
    (classification0 == "Confidence in automation and AI") | ///
    (classification1 == "Confidence in automation and AI")
gen arg_no = (classification0 == "Not related" & ///
    classification1 == "Not related")


label variable arg_labour "Job losses"
label variable arg_againstinn "Other anti-AI"
label variable arg_proinn "Pro-markets"
label variable policy_intervention "Policy intervention"
label variable max_policies "No. of supported policies"

gen usage_ai_never = usage_ai == 1
gen usage_ai_frequent = usage_ai > 2


* T: weighting

gen d_gender2 = d_gender
replace d_gender2 = 2 if d_gender2 == 3
tab d_gender2, gen(d_gender_)
tab d_education, gen(d_education_)
tab d_employment, gen(d_employment_)
tab sector, gen(d_sector_)

recode d_employment (0 1 = 0 "employed") ( 2 = 1 "unemployed") ///
    (3 5 4 7 = 2 "not in labor force"), gen(d_employment2)
tab d_employment2, gen(d_employment2_)

levelsof d_treat, local(treats)
foreach t of local treats {
    frame copy default d_treat`t', replace
    frame change d_treat`t'
    keep if d_treat == `t'
    local N = _N
    contract under35 over65 low_income d_gender_* d_education_* d_employment2_*, ///
        freq(sample_n)
    generate sample`t'_pct = sample_n / `N'
    
    frame change default
    frlink m:1 under35 over65 low_income d_gender_* d_education_* ///
        d_employment2_*, frame(d_treat`t') gen(link`t'0)
    frget sample`t'_pct, from(link`t'0)
}

gen weight_alt = 1
replace weight_alt = sample1_pct / sample2_pct if d_treat == 2
replace weight_alt = sample1_pct / sample3_pct if d_treat == 3
replace weight_alt = sample1_pct / sample4_pct if d_treat == 4

save dataset.dta, replace

