set more off
clear
clear frames

cd "$root/main_survey/"

use dataset, replace

global controls under35 over65 i.d_gender i.d_education i.occupation ///
    i.d_employment ib2.d_industry low_income i.d_cntry i.date i.hour


* T: tests on main outcomes
prtest policy_intervention if inlist(d_treat, 1, 2), by(d_treat)
prtest policy_intervention if inlist(d_treat, 1, 3), by(d_treat)
prtest policy_intervention if inlist(d_treat, 1, 4), by(d_treat)
prtest policy_intervention if inlist(d_treat, 3, 2), by(d_treat)
prtest policy_intervention if inlist(d_treat, 3, 4), by(d_treat)
 // all tests are significant

prtest arg_labour if inlist(d_treat, 1, 2), by(d_treat)
prtest arg_labour if inlist(d_treat, 1, 3), by(d_treat)
prtest arg_labour if inlist(d_treat, 1, 4), by(d_treat)
prtest arg_labour if inlist(d_treat, 3, 2), by(d_treat)
prtest arg_labour if inlist(d_treat, 3, 4), by(d_treat)

prtest arg_againstinn if inlist(d_treat, 1, 2), by(d_treat)
prtest arg_againstinn if inlist(d_treat, 1, 3), by(d_treat)
prtest arg_againstinn if inlist(d_treat, 1, 4), by(d_treat)
prtest arg_againstinn if inlist(d_treat, 3, 2), by(d_treat)
prtest arg_againstinn if inlist(d_treat, 3, 4), by(d_treat)
prtest arg_againstinn if inlist(d_treat, 2, 4), by(d_treat)

prtest arg_proinn if inlist(d_treat, 1, 2), by(d_treat)
prtest arg_proinn if inlist(d_treat, 1, 3), by(d_treat)
prtest arg_proinn if inlist(d_treat, 1, 4), by(d_treat)
prtest arg_proinn if inlist(d_treat, 3, 2), by(d_treat)
prtest arg_proinn if inlist(d_treat, 3, 4), by(d_treat)
prtest arg_proinn if inlist(d_treat, 2, 4), by(d_treat)


* TABLE WITH TESTS ON POLICIES

recode targ (0.5 = 1)
recode redistr (0.25 0.75 = 1)
collect clear
collect create table_policies

collect: prtest policy_intervention if inlist(d_treat, 1, 2), by(d_treat)
collect: prtest policy_intervention if inlist(d_treat, 1, 3), by(d_treat)
collect: prtest policy_intervention if inlist(d_treat, 1, 4), by(d_treat)
collect label values result1 p "Policy Intervention"
collect remap result = result1

local i = 2
local f = 1
foreach v of varlist arg_labour arg_againstinn arg_proinn higher_taxes_on ///
    targ redistr education_polic tax_credits_inn {
    collect: prtest `v' if inlist(d_treat, 1, 2), by(d_treat)
    collect: prtest `v' if inlist(d_treat, 1, 3), by(d_treat)
    collect: prtest `v' if inlist(d_treat, 1, 4), by(d_treat)
    collect label values result`i' p "`v'"
    collect remap result = result`i'
    local l = `f' * 3 + 1
    local j = `f' * 3 + 2
    local k = `f' * 3 + 3
    collect remap cmdset[`l' `j' `k'] = cmdset[1 2 3]
    local i = `i' + 1
    local f = `f' + 1
}

collect label values cmdset 1 "optimistic" 2 "balanced" 3 "pessimistic", ///
    modify
collect style cell, nformat(%6.3f)
collect layout (cmdset) (result1[p] result2[p] result3[p] result4[p] ///
    result5[p] result6[p] result7[p] result8[p] result9[p])
collect export "tests_policies.tex", replace tableonly

* T: heterogeneity by prior beliefs (main outcomes)
foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn {
    reg `v' i.d_expectation##i.d_treat i.d_voting $controls
    parmest, frame(d_expectation, replace) idstr(d_expectation) label
    
    local z: variable label `v'
    
    frame change d_expectation
    
    keep if ustrrpos(parm, "d_treat") != 0 | ustrrpos(parm, "d_expectation") != 0
    drop if ustrrpos(parm, "1b") != 0
    
    gen order = _n - 3 if ustrrpos(parm, "d_treat") != 0
    sort order
    sort parm in 4/15
    
    replace estimate = round(estimate, 0.001) if (parm == "2.d_expectation" | ///
        parm == "3.d_expectation" | parm == "4.d_expectation")
    local levels "2 3 4"
    foreach l of local levels {
        sum estimate if parm == "`l'.d_expectation"
        local m_`l' = r(mean)
        sum p if parm == "`l'.d_expectation"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if (parm == "2.d_expectation" | parm == "3.d_expectation" | ///
        parm == "4.d_expectation")
    
    gen id = _N - _n + 1
    
    gen order2 = 0
    replace order2 = 1 if ustrrpos(parm, "d_expectation") == 0
    replace order2 = 2 if ustrrpos(parm, "2.d_expectation") != 0
    replace order2 = 3 if ustrrpos(parm, "3.d_expectation") != 0
    replace order2 = 4 if ustrrpos(parm, "4.d_expectation") != 0
    
    local i = 1
    forvalues l = 3 2 to 1 {
        replace id = id + `i' if order2 == `l'
        local i = `i' + 1
    }
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") rows(1) ///
        position(6) size(vsmall) region(lstyle(foreground)) title("statement seen", ///
        size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ///
        ylabel(2 `""pessimist" "[`m_4']`s_4'""' 6 `""balanced" "[`m_3']`s_3'""' 10 ///
        `""optimist" "[`m_2']`s_2'""' 14 "main effects", labsize(vsmall)) ysize(7) ///
        xsize(6) subtitle("`z'", size(small) box bexpand bcolor(gs13)) saving(`v', ///
        replace) // -.2(0.05).2
*     graph export "./graphs/het_`v'.png", replace width(1000)
    
    frame change default
}

grc1leg2 "policy_intervention" "arg_labour" "arg_againstinn" "arg_proinn", ///
    xcommon ysize(8) xsize(7)

graph export "./graphs/heterogeneity_prior_beliefs.png", replace width(1000)


* T: heterogeneity by voting (main outcomes)
foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn {
    reg `v' ib2.d_voting##i.d_treat i.d_expectation $controls
    parmest, frame(d_voting, replace) idstr(d_voting) label
    
    local z: variable label `v'
    
    frame change d_voting
    
    keep if ustrrpos(parm, "d_treat") != 0 | ustrrpos(parm, "d_voting") != 0
    drop if ustrrpos(parm, "1b") != 0
    drop if ustrrpos(parm, "2b") != 0
    drop if ustrrpos(parm, "5.d_voting") != 0
    
    gen order = _n - 3 if ustrrpos(parm, "d_treat") != 0
    sort order
    sort parm in 4/15
    
    replace estimate = round(estimate, 0.001) if (parm == "1.d_voting" | ///
        parm == "3.d_voting" | parm == "4.d_voting")
    local levels "1 3 4"
    foreach l of local levels {
        sum estimate if parm == "`l'.d_voting"
        local m_`l' = r(mean)
        sum p if parm == "`l'.d_voting"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if (parm == "1.d_voting" | parm == "3.d_voting" | parm == "4.d_voting")
    
    gen id = _N - _n + 1
    
    gen order2 = 0
    replace order2 = 1 if ustrrpos(parm, "d_voting") == 0
    replace order2 = 2 if ustrrpos(parm, "1.d_voting") != 0
    replace order2 = 3 if ustrrpos(parm, "3.d_voting") != 0
    replace order2 = 4 if ustrrpos(parm, "4.d_voting") != 0
    
    local i = 1
    forvalues l = 3 2 to 1 {
        replace id = id + `i' if order2 == `l'
        local i = `i' + 1
    }
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") rows(1) ///
        position(6) size(vsmall)) ytitle(" ") xlabel(, labsize(vsmall)) ///
        ylabel(2 `""far-right" "[`m_4']`s_4'""' 6 `""center-right" "[`m_3']`s_3'""' ///
        10 `""far-left" "[`m_1']`s_1'""' 14 "main effects", labsize(vsmall)) ///
        ysize(7) xsize(6) subtitle("`z'", size(small) box bexpand bcolor(gs13)) ///
        saving(`v', replace) // -.2(0.05).2
*     graph export "./graphs/het_`v'.png", replace width(1000)
    
    frame change default
}

grc1leg2 "policy_intervention" "arg_labour" "arg_againstinn" "arg_proinn", ///
    xcommon ysize(8) xsize(7)

graph export "./graphs/heterogeneity_voting.png", replace width(1000)


* T: heterogeneity by prior beliefs (policies)
foreach v of varlist higher_taxes_on targ redistr education_polic ///
    tax_credits_inn {
    reg `v' i.d_expectation##i.d_treat i.d_voting $controls
    parmest, frame(d_expectation, replace) idstr(d_expectation) label
    
    local z: variable label `v'
    
    frame change d_expectation
    
    keep if ustrrpos(parm, "d_treat") != 0 | ustrrpos(parm, "d_expectation") != 0
    drop if ustrrpos(parm, "1b") != 0
    
    gen order = _n - 3 if ustrrpos(parm, "d_treat") != 0
    sort order
    sort parm in 4/15
    
    replace estimate = round(estimate, 0.001) if (parm == "2.d_expectation" | ///
        parm == "3.d_expectation" | parm == "4.d_expectation")
    local levels "2 3 4"
    foreach l of local levels {
        sum estimate if parm == "`l'.d_expectation"
        local m_`l' = r(mean)
        sum p if parm == "`l'.d_expectation"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if (parm == "2.d_expectation" | parm == "3.d_expectation" | ///
        parm == "4.d_expectation")
    
    gen id = _N - _n + 1
    
    gen order2 = 0
    replace order2 = 1 if ustrrpos(parm, "d_expectation") == 0
    replace order2 = 2 if ustrrpos(parm, "2.d_expectation") != 0
    replace order2 = 3 if ustrrpos(parm, "3.d_expectation") != 0
    replace order2 = 4 if ustrrpos(parm, "4.d_expectation") != 0
    
    local i = 1
    forvalues l = 3 2 to 1 {
        replace id = id + `i' if order2 == `l'
        local i = `i' + 1
    }
    
    gen min95_trunc = min95 if min95 > -0.1
    replace min95_trunc = -0.1 if min95 <= -0.1
    gen max95_trunc = max95 if max95 < 0.1
    replace max95_trunc = 0.1 if max95 >= 0.1
    
    graph twoway (rcap max95_trunc min95_trunc id if ustrrpos(parm, "2.d_treat") ///
        != 0, horizontal lcolor(optimistic)) ///
        (rcap max95_trunc min95_trunc id if ustrrpos(parm, "3.d_treat") != 0, ///
        horizontal lcolor(balanced)) ///
        (rcap max95_trunc min95_trunc id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") rows(1) ///
        position(6) size(vsmall)) ytitle(" ") xlabel(, labsize(vsmall)) ///
        ylabel(2 `""pessimist" "[`m_4']`s_4'""' 6 `""balanced" "[`m_3']`s_3'""' 10 ///
        `""optimist" "[`m_2']`s_2'""' 14 "main effects", labsize(vsmall)) ysize(7) ///
        xsize(6) subtitle("`z'", size(small) box bexpand bcolor(gs13)) saving(`v', ///
        replace) graphregion(margin(0 0 5 0)) // -.2(0.05).2
*     graph export "./graphs/het_`v'.png", replace width(1000)
    
    frame change default
}

grc1leg2 "higher_taxes_on" "targ" "redistr" "education_polic" ///
    "tax_credits_inn", xcommon ysize(8) xsize(7)
graph export "./graphs/heterogeneity_prior_beliefs_policies.png", ///
    replace width(1000)


* T: heterogeneity by voting (policies)
foreach v of varlist higher_taxes_on targ redistr education_polic ///
    tax_credits_inn {
    reg `v' ib2.d_voting##i.d_treat i.d_expectation $controls
    parmest, frame(d_voting, replace) idstr(d_voting) label
    
    local z: variable label `v'
    
    frame change d_voting
    
    keep if ustrrpos(parm, "d_treat") != 0 | ustrrpos(parm, "d_voting") != 0
    drop if ustrrpos(parm, "1b") != 0
    drop if ustrrpos(parm, "2b") != 0
    drop if ustrrpos(parm, "5.d_voting") != 0
    
    gen order = _n - 3 if ustrrpos(parm, "d_treat") != 0
    sort order
    sort parm in 4/15
    
    replace estimate = round(estimate, 0.001) if (parm == "1.d_voting" | ///
        parm == "3.d_voting" | parm == "4.d_voting")
    local levels "1 3 4"
    foreach l of local levels {
        sum estimate if parm == "`l'.d_voting"
        local m_`l' = r(mean)
        sum p if parm == "`l'.d_voting"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if (parm == "1.d_voting" | parm == "3.d_voting" | parm == "4.d_voting")
    
    gen id = _N - _n + 1
    
    gen order2 = 0
    replace order2 = 1 if ustrrpos(parm, "d_voting") == 0
    replace order2 = 2 if ustrrpos(parm, "1.d_voting") != 0
    replace order2 = 3 if ustrrpos(parm, "3.d_voting") != 0
    replace order2 = 4 if ustrrpos(parm, "4.d_voting") != 0
    
    local i = 1
    forvalues l = 3 2 to 1 {
        replace id = id + `i' if order2 == `l'
        local i = `i' + 1
    }
    
*     gen min95_trunc = min95 if min95 > -0.1
*     replace min95_trunc = -0.1 if min95 <= -0.1
*     gen max95_trunc = max95 if max95 < 0.1
*     replace max95_trunc = 0.1 if max95 >= 0.1
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") rows(1) ///
        position(6) size(vsmall)) ytitle(" ") xlabel(, labsize(vsmall)) ///
        ylabel(2 `""far-right" "[`m_4']`s_4'""' 6 `""center-right" "[`m_3']`s_3'""' ///
        10 `""far-left" "[`m_1']`s_1'""' 14 "main effects", labsize(vsmall)) ///
        ysize(7) xsize(6) subtitle("`z'", size(small) box bexpand bcolor(gs13)) ///
        saving(`v', replace) graphregion(margin(0 0 5 0)) // -.2(0.05).2
*     graph export "./graphs/het_`v'.png", replace width(1000)
    
    frame change default
}

grc1leg2 "higher_taxes_on" "targ" "redistr" "education_polic" ///
    "tax_credits_inn", xcommon ysize(8) xsize(7)
graph export "./graphs/heterogeneity_voting_policies.png", ///
    replace width(1000)


* T: heterogeneity by characteristics (main outcomes)
foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn {
    reg `v' i.d_treat $controls
    parmest, frame(baseline, replace) idstr(base) label
    foreach var of varlist female under35 over65 university blue_collar neet ///
        high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech {
        reg `v' i.d_treat##c.`var' $controls
        parmest, frame(`var', replace) idstr(`var') label
    }
    
    local z: variable label `v'
    
    frame change baseline
    xframeappend female under35 over65 university blue_collar neet ///
        high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech
    
    keep if ustrrpos(parm, "d_treat") != 0 | (ustrrpos(parm, "female") != 0 & ///
        idstr == "female") | (ustrrpos(parm, "under35") != 0 & idstr == "under35") | ///
        (ustrrpos(parm, "over65") != 0 & idstr == "over65") | (ustrrpos(parm, ///
        "university") != 0 & idstr == "university") | (ustrrpos(parm, ///
        "blue_collar") != 0 & idstr == "blue_collar") | (ustrrpos(parm, "neet") ///
        != 0 & idstr == "neet") | (ustrrpos(parm, "high_vulnerability_gpt4") != 0 & ///
        idstr == "high_vulnerability_gpt4") | (ustrrpos(parm, "indiv") != 0 & ///
        idstr == "indiv") | (ustrrpos(parm, "equal") != 0 & idstr == "equal") | ///
        (ustrrpos(parm, "risk_averse") != 0 & idstr == "risk_averse") | ///
        (ustrrpos(parm, "negative_tech") != 0 & idstr == "negative_tech") | ///
        (ustrrpos(parm, "ignorant") != 0 & idstr == "ignorant")
    drop if ustrrpos(parm, "1b") != 0
    drop if ustrrpos(parm, "o.") != 0
    drop if label == "RECODE of d_treat (narratives.1.player.treat)" & ///
        idstr != "base"
    
    replace estimate = round(estimate, 0.001) if inlist(parm, "female", ///
        "under35", "over65", "university", "blue_collar", "neet", ///
        "high_vulnerability_gpt4")
    replace estimate = round(estimate, 0.001) if inlist(parm, "negative_tech", ///
        "indiv", "equal", "risk_averse", "ignorant")
    levelsof idstr, local(levels)
    foreach l of local levels {
        sum estimate if parm == "`l'"
        local `l' = r(mean)
        sum p if parm == "`l'"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if inlist(parm, "female", "under35", "over65", "university", ///
        "blue_collar", "neet", "high_vulnerability_gpt4")
    drop if inlist(parm, "negative_tech", "indiv", "equal", "risk_averse", ///
        "ignorant")
    
    gen id = _N - _n + 1
    
    local variables ///
        `""risk_averse" "ignorant" "equal" "indiv" "high_vulnerability_gpt4" "neet" "blue_collar" "university" "over65" "under35" "female" "base""'
    local i = 1
    foreach var of local variables {
        replace id = id + `i' if idstr == "`var'"
        local i = `i' + 1
    }
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        ylabel(2 ///
        `""neg. feelings" "towards tech" "[`negative_tech']`s_negative_tech'""' 6 ///
        `""risk averse" "[`risk_averse']`s_risk_averse'""' 10 ///
        `""low knowledge" "on auto/AI" "[`ignorant']`s_ignorant'""' 14 ///
        `""egalitarians" "[`equal']`s_equal'""' 18 ///
        `""individualists" "[`indiv']`s_indiv'""' 22 ///
        `""exposed to AI" "[`high_vulnerability_gpt4']`s_high_vulnerability_gpt4'""' ///
        26 `""neet" "[`neet']`s_neet'""' 30 ///
        `""blue collars" "[`blue_collar']`s_blue_collar'""' 34 ///
        `""university" "[`university']`s_university'""' 38 ///
        `""over 65" "[`over65']`s_over65'""' 42 ///
        `""under 35" "[`under35']`s_under35'""' 46 ///
        `""female" "[`female']`s_female'""' 50 "baseline", labsize(tiny)) ///
        legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
        rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
        size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
        subtitle("`z'", size(small) box bexpand bcolor(gs13)) saving(`v', replace) ///
        graphregion(margin(0 0 5 0)) // -.2(0.05).2
    frame change default
    
}

grc1leg2 "policy_intervention" "arg_labour" "arg_againstinn" "arg_proinn", ///
    xcommon ysize(10) xsize(7)
graph export "./graphs/heterogeneity_individual.png", replace width(2000)



* T: heterogeneity by characteristics (on policies)
foreach v of varlist higher_taxes_on targ redistr education_polic ///
    tax_credits_inn {
    reg `v' i.d_treat $controls
    parmest, frame(baseline, replace) idstr(base) label
    foreach var of varlist female under35 over65 university blue_collar neet ///
        high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech {
        reg `v' i.d_treat##c.`var' $controls
        parmest, frame(`var', replace) idstr(`var') label
    }
    
    local z: variable label `v'
    
    frame change baseline
    xframeappend female under35 over65 university blue_collar neet ///
        high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech
    
    keep if ustrrpos(parm, "d_treat") != 0 | (ustrrpos(parm, "female") != 0 & ///
        idstr == "female") | (ustrrpos(parm, "under35") != 0 & idstr == "under35") | ///
        (ustrrpos(parm, "over65") != 0 & idstr == "over65") | (ustrrpos(parm, ///
        "university") != 0 & idstr == "university") | (ustrrpos(parm, ///
        "blue_collar") != 0 & idstr == "blue_collar") | (ustrrpos(parm, "neet") ///
        != 0 & idstr == "neet") | (ustrrpos(parm, "high_vulnerability_gpt4") != 0 & ///
        idstr == "high_vulnerability_gpt4") | (ustrrpos(parm, "indiv") != 0 & ///
        idstr == "indiv") | (ustrrpos(parm, "equal") != 0 & idstr == "equal") | ///
        (ustrrpos(parm, "risk_averse") != 0 & idstr == "risk_averse") | ///
        (ustrrpos(parm, "negative_tech") != 0 & idstr == "negative_tech") | ///
        (ustrrpos(parm, "ignorant") != 0 & idstr == "ignorant")
    drop if ustrrpos(parm, "1b") != 0
    drop if ustrrpos(parm, "o.") != 0
    drop if label == "RECODE of d_treat (narratives.1.player.treat)" & ///
        idstr != "base"
    
    replace estimate = round(estimate, 0.001) if inlist(parm, "female", ///
        "under35", "over65", "university", "blue_collar", "neet", ///
        "high_vulnerability_gpt4")
    replace estimate = round(estimate, 0.001) if inlist(parm, "negative_tech", ///
        "indiv", "equal", "risk_averse", "ignorant")
    levelsof idstr, local(levels)
    foreach l of local levels {
        sum estimate if parm == "`l'"
        local `l' = r(mean)
        sum p if parm == "`l'"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if inlist(parm, "female", "under35", "over65", "university", ///
        "blue_collar", "neet", "high_vulnerability_gpt4")
    drop if inlist(parm, "negative_tech", "indiv", "equal", "risk_averse", ///
        "ignorant")
    
    gen id = _N - _n + 1
    
    local variables ///
        `""risk_averse" "ignorant" "equal" "indiv" "high_vulnerability_gpt4" "neet" "blue_collar" "university" "over65" "under35" "female" "base""'
    local i = 1
    foreach var of local variables {
        replace id = id + `i' if idstr == "`var'"
        local i = `i' + 1
    }
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        ylabel(2 ///
        `""neg. feelings" "towards tech" "[`negative_tech']`s_negative_tech'""' 6 ///
        `""risk averse" "[`risk_averse']`s_risk_averse'""' 10 ///
        `""low knowledge" "on auto/AI" "[`ignorant']`s_ignorant'""' 14 ///
        `""egalitarians" "[`equal']`s_equal'""' 18 ///
        `""individualists" "[`indiv']`s_indiv'""' 22 ///
        `""exposed to AI" "[`high_vulnerability_gpt4']`s_high_vulnerability_gpt4'""' ///
        26 `""neet" "[`neet']`s_neet'""' 30 ///
        `""blue collars" "[`blue_collar']`s_blue_collar'""' 34 ///
        `""university" "[`university']`s_university'""' 38 ///
        `""over 65" "[`over65']`s_over65'""' 42 ///
        `""under 35" "[`under35']`s_under35'""' 46 ///
        `""female" "[`female']`s_female'""' 50 "baseline", labsize(tiny)) ///
        legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
        rows(1) position(6)) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
        subtitle("`z'", size(small) box bexpand bcolor(gs13)) saving(`v', replace) ///
        graphregion(margin(0 0 5 0)) // -.2(0.05).2
    frame change default
    
}

grc1leg2 "higher_taxes_on" "targ" "redistr" "education_polic" ///
    "tax_credits_inn", xcommon ysize(11) xsize(9)
graph export "./graphs/heterogeneity_individual_policies.png", ///
    replace width(2000)

 // ╭─────────────────────────╮
 // │ T: main regression
 // ╰─────────────────────────╯

collect clear
local i = 1
foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn higher_taxes_on targ redistr education_polic tax_credits_inn {
    collect e(N) e(r2), tags(coleq["`v'"] ///
        cmdset[`i']): reg `v' i.d_treat $controls
    collect p1 = r(p), tags(coleq["`v'"] cmdset[`i']): test 2.d_treat = 3.d_treat
    collect p2 = r(p), tags(coleq["`v'"] cmdset[`i']): test 2.d_treat = 4.d_treat
    collect p3 = r(p), tags(coleq["`v'"] cmdset[`i']): test 3.d_treat = 4.d_treat
    local i = `i' + 1
}

* collect e(N) e(r2), * tags(coleq["max_policies"] cmdset[6]): reg max_policies * i.d_treat##c.policy_intervention $controls
* collect p1 = r(p), * tags(coleq["max_policies"] cmdset[6]): test 2.d_treat = 3.d_treat
* collect p2 = r(p), * tags(coleq["max_policies"] cmdset[6]): test 2.d_treat = 4.d_treat
* collect p3 = r(p), * tags(coleq["max_policies"] cmdset[6]): test 3.d_treat = 4.d_treat
* collect layout (colname[i.d_treat c.policy_intervention * i.d_treat#c.policy_intervention]#result[_r_b _r_se] result[p1 p2 p3 * r2 N]) (cmdset#coleq)
collect layout (colname[i.d_treat]#result[_r_b _r_se] result[p1 p2 p3 r2 N]) ///
    (cmdset#coleq)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se r2 p1 p2 p3], nformat(%5.3f)
collect style cell result[p1], border(top)
collect style cell result[r2], border(top)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs" p1 "optimistic vs balanced" p2 ///
    "optimistic vs pessimistic" p3 "balanced vs pessimistic", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" 6 "(6)" ///
    7 "(7)" 8 "(8)" 9 "(9)" 10 "(10)"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, country, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "regression_policies.tex", replace tableonly

* robustness with multiple hypotheses testing

frame copy default multiple_hypotheses, replace
frame change multiple_hypotheses

wyoung policy_intervention arg_labour arg_againstinn arg_proinn ///
    higher_taxes_on targ redistr education_polic tax_credits_inn, ///
    cmd(regress OUTCOMEVAR d_treat2 d_treat3 d_treat4 $controls) seed(29081980) ///
    familyp(d_treat2 d_treat3 d_treat4) replace
drop model
egen order = seq(), from(1) to (9)
sort order familyp
save wyoung_simple, replace

frame copy default multiple_hypotheses, replace
frame change multiple_hypotheses

wyoung policy_intervention arg_labour arg_againstinn arg_proinn ///
    higher_taxes_on targ redistr education_polic tax_credits_inn, ///
    cmd(regress OUTCOMEVAR d_treat2 d_treat3 d_treat4 $controls) seed(29081980) ///
    familyp(d_treat2-d_treat3) familypexp replace
drop model
save wyoung_test1, replace


frame copy default multiple_hypotheses, replace
frame change multiple_hypotheses

wyoung policy_intervention arg_labour arg_againstinn arg_proinn ///
    higher_taxes_on targ redistr education_polic tax_credits_inn, ///
    cmd(regress OUTCOMEVAR d_treat2 d_treat3 d_treat4 $controls) seed(29081980) ///
    familyp(d_treat2-d_treat4) familypexp replace
drop model
save wyoung_test2, replace

frame copy default multiple_hypotheses, replace
frame change multiple_hypotheses

wyoung policy_intervention arg_labour arg_againstinn arg_proinn ///
    higher_taxes_on targ redistr education_polic tax_credits_inn, ///
    cmd(regress OUTCOMEVAR d_treat2 d_treat3 d_treat4 $controls) seed(29081980) ///
    familyp(d_treat3-d_treat4) familypexp replace
drop model
save wyoung_test3, replace

use wyoung_simple, clear
append using wyoung_test1 wyoung_test2 wyoung_test3
drop k coef stderr p pbonf psidak
bys outcome (order familyp ): gen id = _n
bys outcome: egen order2 = mean(order)
drop outcome order
reshape wide pwyoung, i(id) j(order2)
label variable pwyoung1 "Policy intervention"
label variable pwyoung2 "Job losses"
label variable pwyoung3 "Other anti-AI"
label variable pwyoung4 "Pro-markets"
label variable pwyoung5 "Break"
label variable pwyoung6 "Constr"
label variable pwyoung7 "Redistr"
label variable pwyoung8 "Education"
label variable pwyoung9 "Tax credits"
replace familyp = "Optimistic" if familyp == "d_treat2"
replace familyp = "Balanced" if familyp == "d_treat3"
replace familyp = "Pessimistic" if familyp == "d_treat4"
replace familyp = "Optimistic vs Balanced" if familyp == "d_treat2-d_treat3"
replace familyp = "Optimistic vs Pessimistic" if familyp == ///
    "d_treat2-d_treat4"
replace familyp = "Balanced vs Pessimistic" if familyp == "d_treat3-d_treat4"
drop id
encode familyp, gen(test)

recode test (3 = 1 "Optimistic") (1 = 2 "Balanced") (6 = 3 "Pessimistic") ///
    (4 = 4 "Optimistic vs Balanced") (5 = 5 "Optimistic vs Pessimistic") ///
    (2 = 6 "Balanced vs Pessimistic"), gen(test2)
drop test familyp
rename test2 test

table (test) (var), ///
    statistic(firstnm pwyoung1 pwyoung2 pwyoung3 pwyoung4 pwyoung5 pwyoung6 ///
    pwyoung7 pwyoung8 pwyoung9) nototals
collect export "multiple_hypotheses.tex", tableonly replace


* T: heterogeneity by voting (main outcomes)
foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn {
    reg `v' i.d_lr_scale##i.d_treat i.d_expectation $controls
    parmest, frame(d_voting, replace) idstr(d_voting) label
    
    local z: variable label `v'
    
    frame change d_voting
    
    keep if ustrrpos(parm, "d_treat") != 0 | ustrrpos(parm, "d_lr_scale") != 0
    drop if ustrrpos(parm, "1b") != 0
    drop if ustrrpos(parm, "0b") != 0
    
    gen order = _n - 3 if ustrrpos(parm, "d_treat") != 0
    sort order
    sort parm in 4/11
    
    replace estimate = round(estimate, 0.001) if (parm == "2.d_lr_scale" | ///
        parm == "1.d_lr_scale")
    local levels "1 2"
    foreach l of local levels {
        sum estimate if parm == "`l'.d_lr_scale"
        local m_`l' = r(mean)
        sum p if parm == "`l'.d_lr_scale"
        local temp = r(mean)
        if `temp' < 0.01 {
            local s_`l' "***"
        }
        else if `temp' < 0.05 {
            local s_`l' "**"
        }
        else if `temp' < 0.1 {
            local s_`l' "*"
        }
        else {
            local s_`l' ""
        }
    }
    drop if (parm == "2.d_lr_scale" | parm == "3.d_lr_scale" | ///
        parm == "1.d_lr_scale")
    
    gen id = _N - _n + 1
    
    gen order2 = 0
    replace order2 = 1 if ustrrpos(parm, "1.d_lr_scale") != 0
    replace order2 = 2 if ustrrpos(parm, "d_lr_scale") == 0
    
    local i = 1
    forvalues l = 1/2 {
        replace id = id + `i' if order2 == `l'
        local i = `i' + 1
    }
    
    graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
        horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
        "3.d_treat") != 0, horizontal lcolor(balanced)) ///
        (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
        horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
        "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
        "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
        "4.d_treat") != 0, color(pessimistic)), xline(0) ///
        legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") rows(1) ///
        position(6) region(lstyle(foreground)) title("statement seen", size(vsmall)) ///
        size(vsmall)) ytitle(" ") xlabel(, labsize(vsmall)) ///
        ylabel(2 `""right" "[`m_2']`s_2'""' 6 `""left" "[`m_1']`s_1'""' 10 ///
        "main effects", labsize(vsmall)) ysize(7) xsize(6) subtitle("`z'", ///
        size(small) box bexpand bcolor(gs13)) saving(`v', replace) // -.2(0.05).2
*     graph export "./graphs/het_`v'.png", replace width(1000)
    
    frame change default
}

grc1leg2 "policy_intervention" "arg_labour" "arg_againstinn" "arg_proinn", ///
    xcommon ysize(8) xsize(7)
graph export "./graphs/heterogeneity_orientation.png", replace width(1000)



* T: figure on main regression

foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn higher_taxes_on targ redistr education_polic tax_credits_inn {
    reg `v' i.d_treat $controls
    parmest, frame(`v', replace) idstr(`v') label
}

frame change policy_intervention
xframeappend arg_labour arg_againstinn arg_proinn higher_taxes_on targ ///
    redistr education_polic tax_credits_inn

keep if ustrrpos(parm, "d_treat") != 0
drop if ustrrpos(parm, "1b") != 0

gen ty = ""
replace ty = "policy_intervention" if idstr == "policy_intervention"
replace ty = "arguments" if inlist(idstr, "arg_labour", "arg_againstinn", ///
    "arg_proinn")
replace ty = "individual_policies" if inlist(idstr, "higher_taxes_on", ///
    "targ", "redistr", "education_polic", "tax_credits_inn")

gen id = _N - _n + 1

local variables ///
    `""tax_credits_inn" "education_polic" "redistr" "targ" "higher_taxes_on" "arg_proinn" "arg_againstinn" "arg_labour" "policy_intervention""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if idstr == "`var'"
    local i = `i' + 1
}
local i = 2
local ty "arguments policy_intervention"
foreach type of local ty {
    replace id = id + `i' if ty == "`type'"
    local i = `i' + 2
}


graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
    horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
    "3.d_treat") != 0, horizontal lcolor(balanced)) ///
    (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
    horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
    "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
    "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
    "4.d_treat") != 0, color(pessimistic)), xline(0) ///
    ylabel(3 "Tax credits" 7 "Education" 11 "Redistribution" 15 ///
    "Constraints on big tech" 19 "Tax robots" 25 "Pro-markets" 29 ///
    "Other anti-AI" 33 "Job losses" 39 "{bf:Policy intervention}", ///
    labsize(vsmall) noticks) ymlabel(35 "{bf:Arguments}" 21 "{bf:Policies}", ///
    noticks nogrid labsize(vsmall)) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
    subtitle("`z'", size(small) box bexpand bcolor(gs13))

graph export "./graphs/regression_policies.png", replace width(2000)


* T: figure on main regression with prior beliefs as additional controls

foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn higher_taxes_on targ redistr education_polic tax_credits_inn {
    reg `v' i.d_treat $controls i.d_expectation
    parmest, frame(`v', replace) idstr(`v') label
}

frame change policy_intervention
xframeappend arg_labour arg_againstinn arg_proinn higher_taxes_on targ ///
    redistr education_polic tax_credits_inn

keep if ustrrpos(parm, "d_treat") != 0
drop if ustrrpos(parm, "1b") != 0

gen ty = ""
replace ty = "policy_intervention" if idstr == "policy_intervention"
replace ty = "arguments" if inlist(idstr, "arg_labour", "arg_againstinn", ///
    "arg_proinn")
replace ty = "individual_policies" if inlist(idstr, "higher_taxes_on", ///
    "targ", "redistr", "education_polic", "tax_credits_inn")

gen id = _N - _n + 1

local variables ///
    `""tax_credits_inn" "education_polic" "redistr" "targ" "higher_taxes_on" "arg_proinn" "arg_againstinn" "arg_labour" "policy_intervention""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if idstr == "`var'"
    local i = `i' + 1
}
local i = 2
local ty "arguments policy_intervention"
foreach type of local ty {
    replace id = id + `i' if ty == "`type'"
    local i = `i' + 2
}


graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
    horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
    "3.d_treat") != 0, horizontal lcolor(balanced)) ///
    (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
    horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
    "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
    "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
    "4.d_treat") != 0, color(pessimistic)), xline(0) ///
    ylabel(3 "Tax credits" 7 "Education" 11 "Redistribution" 15 ///
    "Constraints on big tech" 19 "Tax robots" 25 "Pro-markets" 29 ///
    "Other anti-AI" 33 "Job losses" 39 "{bf:Policy intervention}", ///
    labsize(vsmall) noticks) ymlabel(35 "{bf:Arguments}" 21 "{bf:Policies}", ///
    noticks nogrid labsize(vsmall)) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
    subtitle("`z'", size(small) box bexpand bcolor(gs13))

graph export "./graphs/regression_policies_beliefs.png", replace width(2000)


* T: figure on main regression with alternative weights

foreach v of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn higher_taxes_on targ redistr education_polic tax_credits_inn {
    reg `v' i.d_treat $controls [pw = weight_alt]
    parmest, frame(`v', replace) idstr(`v') label
}

frame change policy_intervention
xframeappend arg_labour arg_againstinn arg_proinn higher_taxes_on targ ///
    redistr education_polic tax_credits_inn

keep if ustrrpos(parm, "d_treat") != 0
drop if ustrrpos(parm, "1b") != 0

gen ty = ""
replace ty = "policy_intervention" if idstr == "policy_intervention"
replace ty = "arguments" if inlist(idstr, "arg_labour", "arg_againstinn", ///
    "arg_proinn")
replace ty = "individual_policies" if inlist(idstr, "higher_taxes_on", ///
    "targ", "redistr", "education_polic", "tax_credits_inn")

gen id = _N - _n + 1

local variables ///
    `""tax_credits_inn" "education_polic" "redistr" "targ" "higher_taxes_on" "arg_proinn" "arg_againstinn" "arg_labour" "policy_intervention""'
local i = 1
foreach var of local variables {
    replace id = id + `i' if idstr == "`var'"
    local i = `i' + 1
}
local i = 2
local ty "arguments policy_intervention"
foreach type of local ty {
    replace id = id + `i' if ty == "`type'"
    local i = `i' + 2
}


graph twoway (rcap max95 min95 id if ustrrpos(parm, "2.d_treat") != 0, ///
    horizontal lcolor(optimistic)) (rcap max95 min95 id if ustrrpos(parm, ///
    "3.d_treat") != 0, horizontal lcolor(balanced)) ///
    (rcap max95 min95 id if ustrrpos(parm, "4.d_treat") != 0, ///
    horizontal lcolor(pessimistic)) (scatter id estimate if ustrrpos(parm, ///
    "2.d_treat") != 0, color(optimistic)) (scatter id estimate if ustrrpos(parm, ///
    "3.d_treat") != 0, color(balanced)) (scatter id estimate if ustrrpos(parm, ///
    "4.d_treat") != 0, color(pessimistic)), xline(0) ///
    ylabel(3 "Tax credits" 7 "Education" 11 "Redistribution" 15 ///
    "Constraints on big tech" 19 "Tax robots" 25 "Pro-markets" 29 ///
    "Other anti-AI" 33 "Job losses" 39 "{bf:Policy intervention}", ///
    labsize(vsmall) noticks) ymlabel(35 "{bf:Arguments}" 21 "{bf:Policies}", ///
    noticks nogrid labsize(vsmall)) ///
    legend(order(4 "optimistic" 5 "balanced" 6 "pessimistic") size(vsmall) ///
    rows(1) position(6) region(lstyle(foreground)) title("statement seen", ///
    size(vsmall))) ytitle(" ") xlabel(, labsize(vsmall)) ysize(10) ///
    subtitle("`z'", size(small) box bexpand bcolor(gs13))

graph export "./graphs/regression_policies_weights.png", replace width(2000)


* T: own job loss

reg job_loss_chance i.d_treat $controls

coefplot (., keep(2.d_treat) mcolor(optimistic) ciopts(recast(rcap) ///
    lcolor(optimistic))) (., keep(3.d_treat) mcolor(balanced) ///
    ciopts(recast(rcap) lcolor(balanced))) (., keep(4.d_treat) ///
    mcolor(pessimistic) ciopts(recast(rcap) lcolor(pessimistic))), xline(0) ///
    legend(off) subtitle("Chances of losing one's own job", size(small) ///
    box bexpand bcolor(gs13))
graph export "./graphs/job_loss_chance.png", replace width(1000)

