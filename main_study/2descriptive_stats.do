set more off
clear
clear frames

cd "$root/main_survey/"

use dataset, replace

* T: descriptive stats tables

frame copy default descriptives, replace
frame change descriptives

recode question_robots (1 = 0 "overestimate") (0 = 1 "correct") ///
    (-1 = 2 "underestimate"), gen(question_robots_pie)
graph pie if d_treat == 1, over(question_robots_pie) ///
    title("No. of robots in country", size(small)) saving(question_robots, ///
    replace) plabel(_all percent, color(black) size(small) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(small) gap(26)) pie(1, ///
    color(pessimistic)) pie(2, color(baseline)) pie(3, color(optimistic))

recode ai_what_wrong (1 = 0 "wrong") (0 = 1 "correct"), ///
    gen(ai_what_wrong_pie)
graph pie if d_treat == 1, over(ai_what_wrong_pie) ///
    title("How ChatGPT, Claude, Gemini, etc." "work?", size(small)) ///
    saving(ai_what_wrong, replace) plabel(_all percent, color(black) size(small) ///
    gap(-5)) legend(off) plabel(_all name, color(navy) size(small) gap(26))

graph pie if d_treat == 1, over(job_robots) ///
    title("Do {bf:industrial robots} affect" "employment?", size(small)) ///
    saving(job_robots, replace) plabel(_all percent, color(black) size(small) ///
    gap(-5)) legend(off) plabel(_all name, color(navy) size(small) gap(26)) ///
    pie(1, color(pessimistic)) pie(2, color(baseline)) pie(3, color(optimistic))

graph pie if d_treat == 1, over(job_ai) ///
    title("Will {bf:AI} affect" "employment?", size(small)) saving(job_ai, ///
    replace) plabel(_all percent, color(black) size(small) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(small) gap(26)) pie(1, ///
    color(pessimistic)) pie(2, color(baseline)) pie(3, color(optimistic))

grc1leg2 "question_robots" "ai_what_wrong" "job_robots" "job_ai", ///
    loff ysize(20) xsize(25) ///
    title("Knowledge and beliefs about automation and AI") saving(pie_knowledge, ///
    replace) row(1)

recode policy_intervention (1 = 0 "yes") ( 0 = 1 "no"), ///
    gen(policy_intervention2)
graph pie if d_treat == 1, over(policy_intervention2) ///
    title("Policy intervention", size(small)) saving(policy_intervention, ///
    replace) plabel(_all percent, color(black) size(small) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(small) gap(26))

recode d_sharing_inn (1 = 1 "not signing") (2 = 4 "optimistic") ///
    (3 = 3 "balanced") (4 = 2 "pessimistic"), gen(d_sharing_inn_pie)
graph pie if d_treat == 1, over(d_sharing_inn_pie) title("Signed petition", ///
    size(small)) saving(sharing, replace) plabel(_all percent, color(black) ///
    format(%4.1f) size(small) gap(-5)) legend(off) plabel(_all name, color(navy) ///
    size(small) gap(26)) pie(1, color(baseline)) pie(4, color(optimistic)) pie(3, ///
    color(balanced)) pie(2, color(pessimistic))

frame copy default pie_arguments, replace
frame change pie_arguments

expand 2, gen(number)
replace classification0 = classification1 if number == 1
encode classification0, gen(classification_pie)
recode classification_pie (4 = 1 "Job losses") (10 = 2 "Security risks") ///
    (9 = 3 "Need for regulation") (2 = 4 "Bad for humanity") ///
    (6 = 5 "Mistrusts towards AI companies") (1 = 6 "Pro-technology") ///
    (7 = 7 "Politics should not interfere") (5 = 8 "Pro-markets") (3 8 = 9), ///
    gen(classification_pie2)

graph pie if d_treat == 1 & classification_pie2 != 9, ///
    over(classification_pie2) title("Arguments", size(small)) ///
    saving(classification, replace) plabel(_all percent, gap(-5) color(black) ///
    format(%4.1f) size(small)) legend(off) plabel(_all name, color(navy) ///
    size(small) gap(26)) pie(1, color("83 45 136")) pie(2, color("110 65 160")) ///
    pie(3, color("140 95 185")) pie(4, color("175 140 210")) pie(5, ///
    color("205 170 230")) pie(6, color("65 180 168")) pie(7, ///
    color("45 155 143")) pie(8, color("25 130 118"))
frame change default

grc1leg2 "policy_intervention" "classification" "sharing", loff ysize(20) ///
    xsize(25) title("Policy preferences and political mobilization") ///
    saving(pie_prefs, replace) row(1)


grc1leg2 "pie_knowledge" "pie_prefs", ysize(30) xsize(50) row(2) loff

graph export "./graphs/pie_charts_v2.png", replace width(2000)


* T: factual knowledge and beliefs

graph bar, over(question_robots) subtitle(No. of robots in country, ///
    box bexpand bcolor(gs13)) graphregion(margin(0 0 9 0)) ///
    saving(no_robots, replace)
gr_edit subtitle.DragBy 2 0
graph bar, over(ai_what_wrong) ///
    subtitle("How ChatGPT, Claude, Gemini, etc. work?", ///
    box bexpand bcolor(gs13)) graphregion(margin(0 0 9 0)) saving(ai_wrong, ///
    replace)
gr_edit subtitle.DragBy 2 0
grc1leg2 "no_robots" "ai_wrong", xsize(7) ysize(4) ytol1title ytsize(0) loff
graph export "./graphs/knowledge.png", replace width(1000)

graph bar, over(job_robots) ///
    subtitle("Do {bf:industrial robots} affect employment?", ///
    box bexpand bcolor(gs13)) graphregion(margin(0 0 9 0)) saving(robots, ///
    replace)
gr_edit subtitle.DragBy 2 0
graph bar, over(job_ai) subtitle("Will {bf:AI} affect employment?", ///
    box bexpand bcolor(gs13)) graphregion(margin(0 0 9 0)) saving(ai, replace)
gr_edit subtitle.DragBy 2 0
grc1leg2 "robots" "ai", xsize(7) ysize(4) ytol1title ytsize(0) loff ycommon
graph export "./graphs/beliefs.png", replace width(1000)


* T: pie graphs by country on policy intervention and political mobilization

recode policy_intervention (1 = 0 "yes") ( 0 = 1 "no"), ///
    gen(policy_intervention2)

graph pie if d_treat == 1 & d_cntry == 3, over(policy_intervention2) ///
    title("US", size(small)) saving(policy_intervention_us, replace) ///
    plabel(_all percent, color(black) size(vsmall) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(vsmall) gap(26))

graph pie if d_treat == 1 & d_cntry == 1, over(policy_intervention2) ///
    title("DE", size(small)) saving(policy_intervention_de, replace) ///
    plabel(_all percent, color(black) size(vsmall) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(vsmall) gap(26))

graph pie if d_treat == 1 & d_cntry == 2, over(policy_intervention2) ///
    title("IT", size(small)) saving(policy_intervention_it, replace) ///
    plabel(_all percent, color(black) size(vsmall) gap(-5)) legend(off) ///
    plabel(_all name, color(navy) size(vsmall) gap(26))

grc1leg2 "policy_intervention_us" "policy_intervention_de" ///
    "policy_intervention_it", row(1) ysize(20) xsize(30) ///
    title("Policy intervention by country", size(small)) ///
    saving(policy_intervention_cntry, replace)

recode d_sharing_inn (1 = 1 "not signing") (2 = 4 "optimistic") ///
    (3 = 3 "balanced") (4 = 2 "pessimistic"), gen(d_sharing_inn_pie)

graph pie if d_treat == 1 & d_cntry == 3, over(d_sharing_inn_pie) title("US", ///
    size(small)) saving(sharing_us, replace) plabel(_all percent, color(black) ///
    format(%4.1f) size(vsmall) gap(-5)) legend(off) plabel(_all name, ///
    color(navy) size(vsmall) gap(26)) pie(1, color(baseline)) pie(4, ///
    color(optimistic)) pie(3, color(balanced)) pie(2, color(pessimistic))

graph pie if d_treat == 1 & d_cntry == 1, over(d_sharing_inn_pie) title("DE", ///
    size(small)) saving(sharing_de, replace) plabel(_all percent, color(black) ///
    format(%4.1f) size(vsmall) gap(-5)) legend(off) plabel(_all name, ///
    color(navy) size(vsmall) gap(26)) pie(1, color(baseline)) pie(4, ///
    color(optimistic)) pie(3, color(balanced)) pie(2, color(pessimistic))

graph pie if d_treat == 1 & d_cntry == 2, over(d_sharing_inn_pie) title("IT", ///
    size(small)) saving(sharing_it, replace) plabel(_all percent, color(black) ///
    format(%4.1f) size(vsmall) gap(-5)) legend(off) plabel(_all name, ///
    color(navy) size(vsmall) gap(26)) pie(1, color(baseline)) pie(4, ///
    color(optimistic)) pie(3, color(balanced)) pie(2, color(pessimistic))

grc1leg2 "sharing_us" "sharing_de" "sharing_it", row(1) ysize(20) xsize(30) ///
    title("Signed petition by country", size(small)) saving(sharing_cntry, ///
    replace)

grc1leg2 "policy_intervention_cntry" "sharing_cntry", row(2) ysize(30) ///
    xsize(50) loff

graph export "./graphs/pie_charts_cntry.png", replace width(2000)


* T: knowledge graph appendix

catplot if d_treat == 1, over(cntry) over(rank1_robots, ///
    label(labsize(small))) horizontal asyvars percent(cntry) ///
    title("Country with more robots", size(small)) saving(rank_robots, replace) ///
    ylabel(, labsize(vsmall)) ytitle("percent", size(vsmall))
catplot if d_treat == 1, over(cntry) over(question3, label(labsize(small))) ///
    horizontal asyvars percent(cntry) ///
    title("Country adopting more robots in the last 10 years", size(small)) ///
    saving(adopt_robots, replace) ylabel(, labsize(vsmall)) ytitle("percent", ///
    size(vsmall))
catplot if d_treat == 1, over(cntry) over(question4, label(labsize(vsmall))) ///
    horizontal asyvars percent(cntry) title("Sector with more robots", ///
    size(small)) saving(sector_robots, replace) ylabel(, labsize(vsmall)) ///
    ytitle("percent", size(vsmall))
catplot if d_treat == 1, over(cntry) over(question5, label(labsize(vsmall))) ///
    horizontal asyvar percent(cntry) ///
    title("Sector with more robots in your country", size(small)) ///
    saving(sector2_robots, replace) ylabel(, labsize(vsmall)) ytitle("percent", ///
    size(vsmall))
grc1leg2 "rank_robots" "adopt_robots" "sector_robots" "sector2_robots", ///
    row(2) lrow(1)
graph export "./graphs/appendix_knowledge.png", replace width(2000)

* T: functioning of AI

catplot, over(cntry) over(ai_what) asyvar percent(cntry)
graph export "./graphs/ai_what_is.png", replace width(1000)


* T: beliefs graph appendix

graph pie if d_treat == 1, over(job_ai_low) ///
    title("Will {bf:AI} affect" "employment of {bf:low-skilled} individuals?", ///
    size(small)) saving(job_ai_low, replace) plabel(_all percent, color(black) ///
    size(vsmall) gap(-5)) pie(1, color(pessimistic)) pie(2, color(baseline)) ///
    pie(3, color(optimistic))

graph pie if d_treat == 1, over(job_ai_high) ///
    title("Will {bf:AI} affect" "employment of {bf:high-skilled} individuals?", ///
    size(small)) saving(job_ai_high, replace) plabel(_all percent, color(black) ///
    size(vsmall) gap(-5)) pie(1, color(pessimistic)) pie(2, color(baseline)) ///
    pie(3, color(optimistic))

grc1leg2 "job_ai_low" "job_ai_high", row(1) lrow(1)
graph export "./graphs/appendix_beliefs.png", replace width(2000)

* T: balance checks

frame copy default balance, replace
frame change balance

tab d_gender, gen(d_gender_)
tab d_education, gen(d_education_)
tab occupation, gen(occupation_)
tab d_employment, gen(d_employment_)
tab d_industry, gen(d_industry_)

iebaltab under35 over65 d_gender_* d_education_* occupation_* d_employment_* ///
    d_industry_* low_income, grpvar(d_treat) control(1) savex(balance.xls) ///
    ftest savet(balance.tex) replace


* T:policy preferences

cibar policy_intervention, over1(d_treat) ///
    graphopts(ytitle(Share of respondents, size(small)) saving(intervene, ///
    replace) subtitle(Policy intervention, bexpand bcolor(gs13) box) ///
    legend(position(6) rows(1)) fxsize(60)) ///
    barcolor(baseline optimistic balanced pessimistic)
catcibar arg_labour arg_againstinn arg_proinn, over(d_treat) ylabel(, ///
    labsize(small)) colors(baseline optimistic balanced pessimistic ) ///
    xlabel(1 "Job losses" 2 "Other anti-AI" 3 "Pro-markets", labsize(small)) ///
    legend(position(6) row(1) ///
    order(1 "baseline" 2 "optimistic" 3 "balanced" 4 "pessimistic") size(small)) ///
    saving(arguments, replace) ytitle(Share of respondents, size(small)) ///
    subtitle(Arguments for/against policy intervention, bexpand bcolor(gs13) ///
    box) fxsize(140)
catcibar higher_taxes_on targ redistr education_polic tax_credits_inn, ///
    over(d_treat) ylabel(, labsize(small)) ///
    colors(baseline optimistic balanced pessimistic ) legend(position(6) row(1) ///
    order(1 "baseline" 2 "optimistic" 3 "balanced" 4 "pessimistic") size(small)) ///
    saving(policies, replace) xlabel(, labsize(small)) ///
    ytitle("Share of supported policies" "within the category", size(small)) ///
    subtitle(Policies, bexpand bcolor(gs13) box) fxsize(140) ///
    xlabel(4 "Education" 5 "Tax credits" 3 "Redistribution" 2 ///
    `""Constraints" "on big tech""' 1 "Tax robots")
grc1leg2 "intervene" "arguments" "policies", lrows(4) position(8) ring(0) ///
    lxoffset(7) lyoffset(5) holes(3) ysize(8) xsize(13) ltitle("statement seen") ///
    ltsize(small)

graph export "./graphs/backlash.png", replace width(2000)

* T: political mobilization

graph bar d_signature2 d_signature3 d_signature4 if signature2 != 0, ///
    stack title("Change.org") bar(1, color(optimistic)) bar(3, ///
    color(pessimistic)) bar(2, color(balanced)) blabel(bar, box margin(small) ///
    color(black) position(inside) format(%4.2f) size(vsmall) gap(0.7)) ///
    saving(publ, replace) legend(off) fxsize(60) plotregion(margin(4 4 5 0)) ///
    fysize(70)
gr_edit title.DragBy 3 0
graph save publ.gph, replace
graph bar d_sharing_inn1 d_sharing_inn2 d_sharing_inn3 d_sharing_inn4, ///
    over(d_treat, label(labsize(small))) stack title("Survey") bar(1, ///
    color(baseline)) bar(2, color(optimistic)) bar(3, color(balanced)) bar(4, ///
    color(pessimistic)) blabel(bar, box margin(small) color(black) ///
    position(inside) format(%4.2f) size(vsmall) gap(0.7)) saving(priv, replace) ///
    legend(title("signed petition", size(small) position(6)) ///
    order(1 "none" 2 "optimistic" 3 "balanced" 4 "pessimistic") size(vsmall) ///
    rows(1) position(6)) ysize(10) fxsize(140) b1title("statement seen", ///
    size(small)) fysize(100)
grc1leg2 "publ" "priv", rows(1) legendfrom(priv) ysize(7) xsize(10)

graph export "./graphs/signatures.png", replace width(2000)


* T: index of polarization

foreach var of varlist d_expectation d_sharing_inn d_signaturet {
    forvalues l = 1/4 {
        forvalues i = 2/4 {
            sum `var'`i' if d_treat == `l' & `var'1 != 1, meanonly
            local `var'`i'_`l' = r(mean)
        }
    }
}

forvalues i = 2/4 {
    sum d_signature`i' if d_signature1 != 1, meanonly
    local d_signature`i' = r(mean)
}

gen d_expectation_pol = 0
gen d_sharing_inn_pol = 0
gen d_signaturet_pol = 0

forvalues i = 1/4 {
    replace d_expectation_pol = 4 * `d_expectation4_`i'' * `d_expectation2_`i'' ///
        if d_treat == `i'
}

forvalues i = 1/4 {
    replace d_sharing_inn_pol = 4 * `d_sharing_inn4_`i'' * `d_sharing_inn2_`i'' ///
        if d_treat == `i'
}

forvalues i = 1/4 {
    replace d_signaturet_pol = 4 * `d_signaturet4_`i'' * `d_signaturet2_`i'' if ///
        d_treat == `i'
}

gen d_signature_pol = 4 * `d_signature4' * `d_signature2'

gen diff_pol1 = d_sharing_inn_pol - d_expectation_pol
sum diff_pol1 if d_treat == 1
replace diff_pol1 = diff_pol1 - r(mean)

gen diff_pol2 = d_signaturet_pol - d_expectation_pol

gen diff_pol3 = d_signaturet_pol - d_sharing_inn_pol

bys d_treat: egen num = count(id_cint)
asgen d_expectation_pol_agg = d_expectation_pol, weight(num)
gen diff_change = d_signature_pol - d_expectation_pol_agg

tabstat d_expectation_pol_agg
tabstat diff_pol1 diff_pol2 diff_pol3, by(d_treat)
tabstat diff_change

forvalues i = 1/4 {
    count if d_treat == `i'
    local tot`i' = r(N)
    sum diff_pol2 if d_treat == `i'
    local change`i' = r(mean)
}

local total = `change1' * `tot1' + `change2' * `tot2' + `change3' * `tot3' + ///
    `change4' * `tot4'

local contr1 = `change1' * `tot1' / `total'
local contr2 = `change2' * `tot2' / `total'
local contr3 = `change3' * `tot3' / `total'
local contr4 = `change4' * `tot4' / `total'

di "Contribution of treatment 1: " `contr1'
di "Contribution of treatment 2: " `contr2'
di "Contribution of treatment 3: " `contr3'
di "Contribution of treatment 4: " `contr4'


