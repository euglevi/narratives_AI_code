set more off
clear
clear frames

cd "$root/follow-up/"

* IMPORT DATASETS FROM CSV FILES

import delimited "./italy/all_apps_wide-2025-01-13_final.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)

gen cntry = "IT"

tempfile tmp
save `tmp'

import delimited "./germany/all_apps_wide-2025-01-13_final.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)
gen cntry = "DE"

tempfile tmp2
save `tmp2'

import delimited "./us/all_apps_wide-2025-01-13_final.csv", varnames(1) ///
    clear bindquote(strict) maxquotedrows(unlimited)
gen cntry = "US"

tempfile tmp3
save `tmp3'

* APPEND DATASETS

use `tmp', replace
append using `tmp2' `tmp3'

* CLEAN DATASET

drop session*
rename participant* *
drop payoff
drop age gender region treat
rename follow_up1player* *
drop beliefs1*
drop initial1*
drop final1*
drop narratives1*
drop v137-v246
drop follow_up1*
drop id_in_group role payoff
keep if _current_page_name == "Completion"
drop if id_cint == "prova" | id_cint == "prova2"

* MATCH WITH MAIN SURVEY

frame create match
frame change match

import delimited "./match_ids.csv", clear varnames(1)
replace follow_up = ustrlower(follow_up)
replace main_survey = ustrlower(main_survey)

frame change default
frlink 1:1 id_cint cntry, frame(match follow_up cntry) gen(link)
frget id_cint_main = main_survey, from(link)

frame create match_main
frame change match_main

use ///
    "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/dataset", replace
rename initial1* *
drop groupid_in_subsession subsessionround_number
rename beliefs1* *
drop groupid_in_subsession
rename narratives1* *
drop groupid_in_subsession subsessionround_number
rename final1* *
rename job_impact_robots_overall* job_impact_robots_o*
rename *job_impact_robots_overall *job_impact_robots_o
rename high_vulnerability* h_vul*

frame change default
drop if id_cint_main == "#n/a" | id_cint_main == ""  // no matches for 5 italian guys and 11 guys that do not match Tejas' file
frlink 1:1 id_cint_main cntry, frame(match_main id_cint cntry) gen(link2)
frget *, from(link2) prefix(m_)

gen same_age = age == m_age | age == m_age+1
gen same_gender = gender == m_gender

encode treat, gen(narr_emotion2)
recode narr_emotion2 (1 = 2 "balanced") (2 = 1 "optimistic") ///
    (3 = 3 "pessimistic"), gen(narr_emotion)
drop narr_emotion2

save dataset, replace

 // ╭───────────────────────╮
 // │ T: policy preferences │
 // ╰───────────────────────╯

gen policy_intervention = inlist(policy_interven, "Ja", "Yes", "Sì")
gen s_policy_intervention = policy_intervention - m_policy_intervention

label variable s_policy_intervention "Differences in policy intervention"

egen proinn = rowmean(tax_credits_inn education_polic)
egen undiscr_antinn = rowmean(universal_incom minimum_wage_po ///
    unemployment_be)
egen targ_antinn = rowmean(stronger_regula breaking_up_tec lower_taxes_on_ ///
    higher_taxes_on)

label variable proinn "Pro-innovation"
label variable undiscr_antinn "Undiscriminated pro-welfare"
label variable targ_antinn "Targeted policies"

rename (universal_income tax_credits_inno stronger_regulat education_polici ///
    breaking_up_tech lower_taxes_on_l higher_taxes_on_ minimum_wage_pol ///
    unemployment_ben) ///
    (universal_incom tax_credits_inn stronger_regula education_polic ///
    breaking_up_tec lower_taxes_on_ higher_taxes_on minimum_wage_po ///
    unemployment_be)
label variable universal_incom "BI"
label variable tax_credits_inn "Tax cred"
label variable stronger_regula "Regul"
label variable education_polic "Education"
label variable breaking_up_tec "Break"
label variable lower_taxes_on_ "Low tax lab"
label variable higher_taxes_on "High tax cap"
label variable minimum_wage_po "Min wage"
label variable unemployment_be "Unemp ben"

foreach var of varlist universal_incom tax_credits_inn stronger_regula ///
    education_polic breaking_up_tec lower_taxes_on_ higher_taxes_on ///
    minimum_wage_po unemployment_be {
    gen s_`var' = `var' - m_`var'
}
label variable s_universal_incom "BI"
label variable s_tax_credits_inn "Tax cred"
label variable s_stronger_regula "Regul"
label variable s_education_polic "Education"
label variable s_breaking_up_tec "Break"
label variable s_lower_taxes_on_ "Low tax lab"
label variable s_higher_taxes_on "High tax cap"
label variable s_minimum_wage_po "Min wage"
label variable s_unemployment_be "Unemp ben"

 // ╭─────────────────────────────────────────────────────────╮
 // │ T: news articles │
 // ╰─────────────────────────────────────────────────────────╯

gen s_ai_what_is = m_ai_what_is == ai_what_is

replace news_articles_re = "Yes, 1 article/post" if inlist(news_articles_re, ///
    "Ja, 1 Artikel/Beitrag", "Sì, 1 articolo")
replace news_articles_re = "Yes, between 2 and 5 articles/posts" if ///
    inlist(news_articles_re, "Ja, zwischen 2 und 5 Artikel/Beiträge", ///
    "Sì, tra 2 e 5 articoli")
replace news_articles_re = "Yes, between 5 and 10 articles/posts" if ///
    inlist(news_articles_re, "Ja, zwischen 5 und 10 Artikel/Beiträge", ///
    "Sì tra 5 e 10 articoli")
replace news_articles_re = "Yes, more than 10 articles/posts" if ///
    inlist(news_articles_re, "Ja, mehr als 10 Artikel/Beiträge", ///
    "Sì, più di 10 articoli")
replace news_articles_re = "No, I have not read anything" if ///
    inlist(news_articles_re, "Nein, ich habe nichts gelesen", ///
    "No, non ho letto nulla")
encode news_articles_re, gen(read_news)
tab read_news, gen(d_read_news)

label variable d_read_news1 "No"
label variable d_read_news2 "1 article/post"
label variable d_read_news3 "2-5 articles/posts"
label variable d_read_news4 "5-10 articles/posts"
label variable d_read_news5 "More than 10 articles/posts"

gen d_search_candidate = inlist(search_candidate, "Yes", ///
    "Yes, but only of one candidate")
label variable d_search_candidate "Search for candidates' statements"
tab search_candidate, gen(d_search_candidate)
label variable d_search_candidate1 "No"
label variable d_search_candidate2 "Yes"
label variable d_search_candidate3 "Yes, but only of one candidate"
rename search_candidate old_search_candidate

local outlets = ///
    `""blogs" "facebook" "google" "instagram" "newspaper" "other_soc" "podcasts" "radio" "speech" "tiktok" "tvnews" "twitter" "verbal" "websites""'

foreach v of local outlets {
    label variable search_`v' `v'
}

tab active, gen(d_active)
label variable d_active1 "No"
label variable d_active2 "Yes"
label variable d_active3 "In the future"

local where = ///
    `""community" "family" "friends" "neighborh" "social_me" "work""'

foreach v of local where {
    label variable active_`v' `v'
}

 // ╭─────────────────────────────────────────────────────────╮
 // │ T: political variables │
 // ╰─────────────────────────────────────────────────────────╯

encode candidate_voted, gen(d_voting2)
recode d_voting2 (4 6 17 20 10 22 24 29 = 2 "centre-left") ///
    (3 14 8 13 27 = 3 "centre-right") (19 23 11 7 = 1 "far-left") ///
    (15 18 26 = 4 "far-right") (16 5 25 28 . = 5 "other"), gen(d_voting)
drop d_voting2
recode d_voting (1 2 = 1 "left") (3 4 = 0 "right") (5 = 2 "do not know"), ///
    gen(d_voting2)

encode party_for_ai, gen(d_party_for_ai2)
recode d_party_for_ai2 (1 4 6 16 19 10 21 9 = 2 "centre-left") ///
    (3 14 8 13 20 = 3 "centre-right") (18 22 11 7 = 1 "far-left") ///
    (15 17 2 = 4 "far-right") (12 5 . = 5 "do not know"), gen(d_party_for_ai)
drop d_party_for_ai2
recode d_party_for_ai (1 2 = 1 "left") (3 4 = 0 "right") ///
    (5 = 2 "do not know"), gen(d_party_for_ai2)
tab d_party_for_ai, gen(l_party_for_ai)
label variable l_party_for_ai1 "Far-left"
label variable l_party_for_ai2 "Centre-left"
label variable l_party_for_ai3 "Centre-right"
label variable l_party_for_ai4 "Far-right"
label variable l_party_for_ai5 "Do not know"

encode party_for_worker, gen(d_party_for_worker2)
recode d_party_for_worker2 (1 4 6 16 19 10 21 9 = 2 "centre-left") ///
    (3 14 8 13 20 = 3 "centre-right") (18 22 11 7 = 1 "far-left") ///
    (15 17 2 = 4 "far-right") (12 5 . = 5 "do not know"), gen(d_party_for_worker)
drop d_party_for_worker2
recode d_party_for_worker (1 2 = 1 "left") (3 4 = 0 "right") ///
    (5 = 2 "do not know"), gen(d_party_for_worker2)
tab d_party_for_worker, gen(l_party_for_worker)
label variable l_party_for_worker1 "Far-left"
label variable l_party_for_worker2 "Centre-left"
label variable l_party_for_worker3 "Centre-right"
label variable l_party_for_worker4 "Far-right"
label variable l_party_for_worker5 "Do not know"

gen s_job_loss_chance = job_loss_chance - m_job_loss_chance
label variable s_job_loss_chance "Differences in job loss chance"

 // ╭─────────────────────────────────────────────────────────╮
 // │ T: remembering │
 // ╰─────────────────────────────────────────────────────────╯

gen count_answers = 0
foreach var of varlist answer* {
    replace count_answers = count_answers + `var'
}

gen perfect = 0
replace perfect = 1 if m_d_treat == 1 & answer8 == 1 & count_answers == 1
replace perfect = 1 if m_d_treat == 2 & answer1 == 1 & answer6 == 1 & ///
    count_answers == 2
replace perfect = 1 if m_d_treat == 3 & answer7 == 1 & answer3 == 1 & ///
    count_answers == 2
replace perfect = 1 if m_d_treat == 4 & answer7 == 1 & answer3 == 1 & ///
    answer1 == 1 & answer6 == 1 & count_answers == 4

gen no_gross_mistakes = !answer2 & !answer4 & !answer5

rename (answer1 answer2 answer3 answer4 answer5 answer6 answer7 answer8) ///
    (answer1 answer6 answer3 answer8 answer7 answer2 answer4 answer5)

label variable answer1 "Higher Productivity"
label variable answer2 "Higher Quality of jobs"
label variable answer3 "More Inequality"
label variable answer4 "Lower Employment"
label variable answer5 "No statement"
label variable answer6 "War - F"
label variable answer7 "Tumors - F"
label variable answer8 "Interest rates - F"

 // ╭─────────────────────────────────────────────────────────╮
 // │ T: beliefs │
 // ╰─────────────────────────────────────────────────────────╯

rename selected_most_co b_most_com
encode b_most_com, gen(b_most_com2)
drop b_most_com
recode b_most_com2 (1 = 3 "balanced") (2 = 2 "optimistic") ///
    (3 = 4 "pessimistic"), gen(b_most_com)
drop b_most_com2

tab b_most_com, gen(l_b_most_com)
label variable l_b_most_com1 "Optimistic petition"
label variable l_b_most_com3 "Pessimistic petition"
label variable l_b_most_com2 "Balanced petition"

rename (beliefs_optimist beliefs_pessimis beliefs_balanced) ///
    (b_optimist b_pessimist b_balanced)
gen sum_beliefs = b_optimist + b_pessimist + b_balanced
replace b_optimist = . if sum_beliefs == 0
replace b_pessimist = . if sum_beliefs == 0
replace b_balanced = . if sum_beliefs == 0

label variable happiness "Happiness"
label variable anger "Anger"
label variable fear "Fear"
label variable political_corr "Political correctness"

** beliefs are not significantly different across treatments, ///
    nor are emotions and political correctness; so we can combine them together ///
    to use them to explain differences in the main survey

 // ╭─────────────────────────────────────────────────────────╮
 // │ T: News consumption │
 // ╰─────────────────────────────────────────────────────────╯

gen social_media = facebook | twitter | instagram | tiktok | other_social
gen social_alone = social_media & !tvnews & !google & !radio & !blogs & ///
    !newspapers & !podcasts & !verbal
gen old_news = radio | newspapers
gen no_news = !social_media & !tvnews & !google & !radio & !blogs & ///
    !newspapers & !podcasts & !verbal

rename m_d_treat d_treat

save dataset, replace
