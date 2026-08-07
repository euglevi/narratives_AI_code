set more off
clear
clear frames

cd "$root/main_survey/"

use dataset, replace

global controls under35 over65 i.d_gender i.d_education i.occupation ///
    i.d_employment ib2.d_industry low_income i.d_cntry i.date i.hour

frame create simple
frame create additional_controls
frame create weights

 // ╭─────────────────────────────────────────╮
 // │ T: narratives on political mobilization │
 // ╰─────────────────────────────────────────╯

 // ╭───────────────────────────────────────────────╮
 // │ T: no parametric evidence │
 // ╰───────────────────────────────────────────────╯

* evidence on Change.org
mgof d_sharing_inn if signature & inlist(d_sharing_inn, 2, 3), ee ksmirnov
mgof d_sharing_inn if signature & inlist(d_sharing_inn, 2, 4), ee ksmirnov
mgof d_sharing_inn if signature & inlist(d_sharing_inn, 3, 4), ee ksmirnov

* which one is more popular in baseline?
mgof d_sharing_inn2 if (d_sharing_inn2 | d_sharing_inn4) & d_treat == 1, ///
    ee ksmirnov // optimistic is less popular than pessimistic
mgof d_sharing_inn3 if (d_sharing_inn4 | d_sharing_inn3) & d_treat == 1, ///
    ee ksmirnov // no significant differences between balanced and pessimistic
mgof d_sharing_inn2 if (d_sharing_inn3 | d_sharing_inn2) & d_treat == 1, ///
    ee ksmirnov // balanced is more popular than optimistic


* TABLE ON NON-PARAMETRIC EVIDENCE

collect clear
collect create table_tests

* evidence on support
collect: tab support d_treat if inlist(d_treat, 1, 2), chi
collect: tab support d_treat if inlist(d_treat, 1, 3), chi
collect: tab support d_treat if inlist(d_treat, 1, 4), chi
collect label values result1 p "not signing"
collect remap result = result1

* unconditional evidence

collect: tab d_sharing_inn2 d_treat if inlist(d_treat, 1, 2), chi column
collect: tab d_sharing_inn2 d_treat if inlist(d_treat, 1, 3), chi column
collect: tab d_sharing_inn2 d_treat if inlist(d_treat, 1, 4), chi column
collect label values result2 p "optimistic"
collect remap result = result2
collect remap cmdset[4 5 6] = cmdset[1 2 3]

collect: tab d_sharing_inn3 d_treat if inlist(d_treat, 1, 2), chi column
collect: tab d_sharing_inn3 d_treat if inlist(d_treat, 1, 3), chi column
collect: tab d_sharing_inn3 d_treat if inlist(d_treat, 1, 4), chi column
collect label values result3 p "balanced"
collect remap result = result3
collect remap cmdset[7 8 9] = cmdset[1 2 3]

collect: tab d_sharing_inn4 d_treat if inlist(d_treat, 1, 2), chi column
collect: tab d_sharing_inn4 d_treat if inlist(d_treat, 1, 3), chi column
collect: tab d_sharing_inn4 d_treat if inlist(d_treat, 1, 4), chi column
collect label values result4 p "pessimistic"
collect remap result = result4
collect remap cmdset[10 11 12] = cmdset[1 2 3]

collect label values cmdset 1 "optimistic" 2 "balanced" 3 "pessimistic", ///
    modify
collect style cell, nformat(%6.3f)
collect layout (cmdset) (result1[p] result2[p] result3[p] result4[p])
collect export "tests_mobilization.tex", replace tableonly



* evidence on conditional signatures
tab d_sharing_inn2 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 2), chi
tab d_sharing_inn2 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 3), chi
tab d_sharing_inn2 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 4), chi

tab d_sharing_inn3 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 2), chi
tab d_sharing_inn3 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 3), chi
tab d_sharing_inn3 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 4), chi

tab d_sharing_inn4 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 2), chi
tab d_sharing_inn4 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 3), chi
tab d_sharing_inn4 d_treat if d_sharing_inn != 1 & inlist(d_treat, 1, 4), chi

 // ╭───────────────────────────────────────────────╮
 // │ T: between-subjects parametric evidence │
 // ╰───────────────────────────────────────────────╯

* TABLE: multinomial logit on narratives

mlogit d_sharing_inn i.d_treat $controls

collect clear
collect, tags(outcome["not signing"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(1)) // + optimistic and balanced
collect, tags(outcome["optimistic"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(2)) // - balanced and (almost significant) optimistic
collect, tags(outcome["balanced"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(3)) // nothing
collect, tags(outcome["pessimistic"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(4)) // - optimistic and (almost significant) balanced


collect layout (colname[i.d_treat]#result[_r_b _r_se] result[N]) ///
    (title#cmdset#outcome)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se], nformat(%5.3f)
collect style cell result[N], border(top)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" 6 "(6)" ///
    7 "(7)" 8 "(8)" 9 "(9)"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, country, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "willingness.tex", replace tableonly


mlogit d_sharing_inn i.d_treat $controls

margins, dydx(d_treat) expression(predict(pr outcome(2)) / ///
    (1 - predict(pr outcome(1))))

margins, dydx(d_treat) expression(predict(pr outcome(3)) / ///
    (1 - predict(pr outcome(1))))

margins, dydx(d_treat) expression(predict(pr outcome(4)) / ///
    (1 - predict(pr outcome(1))))


* FIGURE: multinomial logit on narratives

mlogit d_sharing_inn i.d_treat $controls

margins, dydx(d_treat) pr(out(1)) saving(marg1, replace)
margins, dydx(d_treat) pr(out(2)) saving(marg2, replace)
margins, dydx(d_treat) pr(out(3)) saving(marg3, replace)
margins, dydx(d_treat) pr(out(4)) saving(marg4, replace)

frame change simple
use marg1, clear
append using marg2 marg3 marg4
rename _* *
gen outcome = ""
replace outcome = "not signing" in 1/3
replace outcome = "optimistic" in 4/6
replace outcome = "balanced" in 7/9
replace outcome = "pessimistic" in 10/12

gen id = _N - _n + 1

local variables `""pessimistic" "balanced" "optimistic" "not signing""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if outcome == "`var'"
    local i = `i' + 1
}

graph twoway (rcap ci_ub ci_lb id if deriv == 1, ///
    horizontal lcolor(optimistic)) (rcap ci_ub ci_lb id if deriv == 2, ///
    horizontal lcolor(balanced)) (rcap ci_ub ci_lb id if deriv == 3, ///
    horizontal lcolor(pessimistic)) (scatter id margin if deriv == 1, ///
    color(optimistic)) (scatter id margin if deriv == 2, color(balanced)) ///
    (scatter id margin if deriv == 3, color(pessimistic)), ///
    ylabel(3 `""Pessimistic" "petition""' 7 `""Balanced" "petition""' 11 ///
    `""Optimistic" "petition""' 15 `""Not" "signing""', labsize(vsmall) noticks) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) xline(0) ///
    saving(simple, replace)

graph export "./graphs/regressions_mobilization.png", replace width(2000)

frame change default

mlogit d_sharing_inn i.d_treat $controls i.d_expectation

margins, dydx(d_treat) pr(out(1)) saving(marg1, replace)
margins, dydx(d_treat) pr(out(2)) saving(marg2, replace)
margins, dydx(d_treat) pr(out(3)) saving(marg3, replace)
margins, dydx(d_treat) pr(out(4)) saving(marg4, replace)

frame change additional_controls
use marg1, clear
append using marg2 marg3 marg4
rename _* *
gen outcome = ""
replace outcome = "not signing" in 1/3
replace outcome = "optimistic" in 4/6
replace outcome = "balanced" in 7/9
replace outcome = "pessimistic" in 10/12

gen id = _N - _n + 1

local variables `""pessimistic" "balanced" "optimistic" "not signing""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if outcome == "`var'"
    local i = `i' + 1
}

graph twoway (rcap ci_ub ci_lb id if deriv == 1, ///
    horizontal lcolor(optimistic)) (rcap ci_ub ci_lb id if deriv == 2, ///
    horizontal lcolor(balanced)) (rcap ci_ub ci_lb id if deriv == 3, ///
    horizontal lcolor(pessimistic)) (scatter id margin if deriv == 1, ///
    color(optimistic)) (scatter id margin if deriv == 2, color(balanced)) ///
    (scatter id margin if deriv == 3, color(pessimistic)), ///
    ylabel(3 `""Pessimistic" "petition""' 7 `""Balanced" "petition""' 11 ///
    `""Optimistic" "petition""' 15 `""Not" "signing""', labsize(vsmall) noticks) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) xline(0)
* subtitle("Controlling" "for prior beliefs", size(small) * box bexpand bcolor(gs13)) saving(additional_controls, replace)

graph export "./graphs/regressions_mobilization_beliefs.png", ///
    replace width(2000)

frame change default

mlogit d_sharing_inn i.d_treat $controls [pw = weight_alt]

margins, dydx(d_treat) pr(out(1)) saving(marg1, replace)
margins, dydx(d_treat) pr(out(2)) saving(marg2, replace)
margins, dydx(d_treat) pr(out(3)) saving(marg3, replace)
margins, dydx(d_treat) pr(out(4)) saving(marg4, replace)

frame change weights
use marg1, clear
append using marg2 marg3 marg4
rename _* *
gen outcome = ""
replace outcome = "not signing" in 1/3
replace outcome = "optimistic" in 4/6
replace outcome = "balanced" in 7/9
replace outcome = "pessimistic" in 10/12

gen id = _N - _n + 1

local variables `""pessimistic" "balanced" "optimistic" "not signing""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if outcome == "`var'"
    local i = `i' + 1
}

graph twoway (rcap ci_ub ci_lb id if deriv == 1, ///
    horizontal lcolor(optimistic)) (rcap ci_ub ci_lb id if deriv == 2, ///
    horizontal lcolor(balanced)) (rcap ci_ub ci_lb id if deriv == 3, ///
    horizontal lcolor(pessimistic)) (scatter id margin if deriv == 1, ///
    color(optimistic)) (scatter id margin if deriv == 2, color(balanced)) ///
    (scatter id margin if deriv == 3, color(pessimistic)), ///
    ylabel(3 `""Pessimistic" "petition""' 7 `""Balanced" "petition""' 11 ///
    `""Optimistic" "petition""' 15 `""Not" "signing""', labsize(vsmall) noticks) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) xline(0)

graph export "./graphs/regressions_mobilization_weights.png", ///
    replace width(2000)

 // ╭───────────────────────────────────────────────╮
 // │ T: whitin-subjects parametric evidence │
 // ╰───────────────────────────────────────────────╯

expand 2, gen(post)
label variable post "post"

gen d_opinion = .
replace d_opinion = d_expectation if post == 0
replace d_opinion = d_sharing_inn if post == 1

label define options 1 "not support" 2 "optimistic" 4 "pessimistic" 3 ///
    "balanced"
label values d_opinion options

mlogit d_opinion c.post c.post#i.d_treat $controls

collect clear
collect, tags(outcome["not signing"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(1)) // + optimistic and balanced
collect, tags(outcome["optimistic"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(2)) // - balanced and (almost significant) optimistic
collect, tags(outcome["balanced"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(3)) // nothing
collect, tags(outcome["pessimistic"] title["signatures"]): margins, ///
    dydx(d_treat) pr(out(4)) // - optimistic and (almost significant) balanced


collect layout (colname[i.d_treat]#result[_r_b _r_se] result[N]) ///
    (title#cmdset#outcome)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se], nformat(%5.3f)
collect style cell result[N], border(top)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" 6 "(6)" ///
    7 "(7)" 8 "(8)" 9 "(9)"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, country, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "willingness_within.tex", replace tableonly


reg clicks i.d_treat##i.d_sharing_inn $controls if d_sharing_inn != 1


* FIGURE: multinomial logit on narratives

mlogit d_opinion c.post c.post#i.d_treat $controls

margins, dydx(d_treat) pr(out(1)) saving(marg1, replace)
margins, dydx(d_treat) pr(out(2)) saving(marg2, replace)
margins, dydx(d_treat) pr(out(3)) saving(marg3, replace)
margins, dydx(d_treat) pr(out(4)) saving(marg4, replace)

use marg1, clear
append using marg2 marg3 marg4
rename _* *
gen outcome = ""
replace outcome = "not signing" in 1/3
replace outcome = "optimistic" in 4/6
replace outcome = "balanced" in 7/9
replace outcome = "pessimistic" in 10/12

gen id = _N - _n + 1

local variables `""pessimistic" "balanced" "optimistic" "not signing""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if outcome == "`var'"
    local i = `i' + 1
}

graph twoway (rcap ci_ub ci_lb id if deriv == 1, ///
    horizontal lcolor(optimistic)) (rcap ci_ub ci_lb id if deriv == 2, ///
    horizontal lcolor(balanced)) (rcap ci_ub ci_lb id if deriv == 3, ///
    horizontal lcolor(pessimistic)) (scatter id margin if deriv == 1, ///
    color(optimistic)) (scatter id margin if deriv == 2, color(balanced)) ///
    (scatter id margin if deriv == 3, color(pessimistic)), ///
    ylabel(3 `""Pessimistic" "petition""' 7 `""Balanced" "petition""' 11 ///
    `""Optimistic" "petition""' 15 `""Not" "signing""', labsize(vsmall) noticks) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6)) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
    xline(0) subtitle("Within-subjects", size(small) box bexpand bcolor(gs13)) ///
    saving(within_subjects, replace)

grc1leg2 between_subjects.gph within_subjects.gph
graph export "./graphs/regressions_mobilization.png", replace width(2000)
