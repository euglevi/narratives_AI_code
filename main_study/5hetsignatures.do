set more off
clear
clear frames

cd "$root/main_survey/"

use dataset, replace

global controls under35 over65 i.d_gender i.d_education i.occupation ///
    i.d_employment ib2.d_industry low_income i.d_cntry i.date i.hour


* T: heterogeneity by individual characteristics

collect clear
mlogit d_sharing_inn i.d_treat $controls

collect create main, replace
collect, tags(outcome["not signing"]): margins, dydx(d_treat) pr(out(1))
collect, tags(outcome["optimistic"]): margins, dydx(d_treat) pr(out(2))
collect, tags(outcome["balanced"]): margins, dydx(d_treat) pr(out(3))
collect, tags(outcome["pessimistic"]): margins, dydx(d_treat) pr(out(4))

foreach var of varlist female under35 over65 university blue_collar neet ///
    high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech {
    
    mlogit d_sharing_inn i.d_treat $controls if `var'
    local N_`var' = e(N)
    
    local z: variable label `var'
    
    collect create `var', replace
    collect, tags(outcome["not signing"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(1)) // + optimistic and balanced
    collect, tags(outcome["optimistic"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(2)) // - balanced and (almost significant) optimistic
    collect, tags(outcome["balanced"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(3)) // nothing
    collect, tags(outcome["pessimistic"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(4)) // - optimistic and (almost significant) balanced
    
}

collect combine full = main female under35 over65 university blue_collar ///
    neet high_vulnerability_gpt4 indiv equal ignorant risk_averse negative_tech
collect layout (collection#(colname[i.d_treat]#result[_r_b _r_se N] )) ///
    (cmdset#outcome)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se], nformat(%5.3f)
collect style cell collection#colname[4.d_treat]#result[_r_se], ///
    border(bottom)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" 6 "(6)" ///
    7 "(7)" 8 "(8)" 9 "(9)"
collect label values collection main "Baseline" female "female" under35 ///
    "under 35" over65 "over 65" university "university" blue_collar ///
    "blue collar" neet "neet" high_vulnerability_gpt4 "exposed to AI" indiv ///
    "individualist" equal "egalitarian" ignorant "low knowledge on auto/AI" ///
    risk_averse "risk averse" negative_tech "neg. feelings towards tech"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, country, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "willingness_het.tex", replace tableonly

* T: heterogeneity on prior beliefs

mlogit d_sharing_inn i.d_treat##i.d_expectation $controls i.d_voting
margins, dydx(d_expectation) pr(out(1))
forvalues i = 2/4 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_expectation = (1(1)4)) pr(out(1))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) subtitle("Not signing", ///
    size(small) box bexpand bcolor(gs13)) saving(not_signing, replace) ///
    title("Prior beliefs") graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 "do not know" 2 `""optimist" "[`exp2']`s_2'""' 3 ///
    `""balanced" "[`exp3']`s_3'""' 4 `""pessimist" "[`exp4']`s_4'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_expectation) pr(out(2))
forvalues i = 2/4 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_expectation = (1(1)4)) pr(out(2))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) ///
    subtitle("Optimistic petition", size(small) box bexpand bcolor(gs13)) ///
    saving(optimistic, replace) title("Prior beliefs") ///
    graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 "do not know" 2 `""optimist" "[`exp2']`s_2'""' 3 ///
    `""balanced" "[`exp3']`s_3'""' 4 `""pessimist" "[`exp4']`s_4'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_expectation) pr(out(3))
forvalues i = 2/4 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_expectation = (1(1)4)) pr(out(3))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) subtitle("Balanced petition", ///
    size(small) box bexpand bcolor(gs13)) saving(balanced, replace) ///
    title("Prior beliefs") graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 "do not know" 2 `""optimist" "[`exp2']`s_2'""' 3 ///
    `""balanced" "[`exp3']`s_3'""' 4 `""pessimist" "[`exp4']`s_4'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_expectation) pr(out(4))
forvalues i = 2/4 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_expectation = (1(1)4)) pr(out(4))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) ///
    legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") ///
    region(lstyle(foreground)) size(vsmall) title("statement seen", ///
    size(vsmall))) subtitle("Pessimistic petition", size(small) ///
    box bexpand bcolor(gs13)) saving(pessimistic, replace) ///
    graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 "do not know" 2 `""optimist" "[`exp2']`s_2'""' 3 ///
    `""balanced" "[`exp3']`s_3'""' 4 `""pessimist" "[`exp4']`s_4'""', ///
    labsize(vsmall)) xtitle(" ") title(" ") ylabel(, labsize(small))

grc1leg2 "not_signing" "optimistic" "balanced" "pessimistic", ///
    xtob1title maintitlefrom(pessimistic) ycommon lrows(1) ysize(7) xsize(10) ///
    saving(prior, replace) legendfrom(pessimistic)
graph export "./graphs/mob_heterogeneity_prior.png", replace width(2000)



* T: heterogeneity on political orientation

recode d_lr_scale (1 = 1 "left") (0 = 2 "center") (2 = 3 "right"), ///
    gen(d_lr_scale_re)
mlogit d_sharing_inn i.d_treat##ib2.d_lr_scale_re $controls i.d_expectation
margins, dydx(d_lr_scale) pr(out(1))
forvalues i = 1/3 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_lr_scale = (1(1)3)) pr(out(1))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) subtitle("Not signing", ///
    size(small) box bexpand bcolor(gs13)) saving(not_signing, replace) ///
    title("Political orientation") graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 `""left" "[`exp1']`s_1'""' 2 "center" 3 `""right" "[`exp3']`s_3'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_lr_scale) pr(out(2))
forvalues i = 1/3 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_lr_scale = (1(1)3)) pr(out(2))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) ///
    subtitle("Optimistic signature", size(small) box bexpand bcolor(gs13)) ///
    saving(optimistic, replace) title("Prior beliefs") ///
    graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 `""left" "[`exp1']`s_1'""' 2 "center" 3 `""right" "[`exp3']`s_3'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_lr_scale) pr(out(3))
forvalues i = 1/3 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_lr_scale = (1(1)3)) pr(out(3))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) subtitle("Balanced signature", ///
    size(small) box bexpand bcolor(gs13)) saving(balanced, replace) ///
    title("Prior beliefs") graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 `""left" "[`exp1']`s_1'""' 2 "center" 3 `""right" "[`exp3']`s_3'""', ///
    labsize(vsmall)) xtitle(" ") ylabel(, labsize(small))
margins, dydx(d_lr_scale) pr(out(4))
forvalues i = 1/3 {
    local exp`i' = r(b)[1, `i']
    local p_value = r(table)["pvalue", `i']
    if `p_value' < 0.01 {
        local s_`i' "***"
    }
    else if `p_value' < 0.05 {
        local s_`i' "**"
    }
    else if `p_value' < 0.1 {
        local s_`i' "*"
    }
    else {
        local s_`i' ""
    }
    local exp`i': display %5.3f `exp`i''
}
margins, dydx(d_treat) at(d_lr_scale = (1(1)3)) pr(out(4))
mplotoffset, offset(0.10) recast(scatter) yline(0) plot1opts(lc(optimistic) ///
    mc(optimistic)) plot2opts(lc(balanced) mc(balanced)) ///
    plot3opts(lc(pessimistic) mc(pessimistic)) ci1opts(lc(optimistic)) ///
    ci2opts(lc(balanced)) ci3opts(lc(pessimistic)) ///
    legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") ///
    title("statement seen", size(small) position(6)) size(small)) ///
    subtitle("Pessimistic signature", size(small) box bexpand bcolor(gs13)) ///
    saving(pessimistic, replace) graphregion(margin(2 12 2 2)) ytitle(" ") ///
    xlabel(1 `""left" "[`exp1']`s_1'""' 2 "center" 3 `""right" "[`exp3']`s_3'""', ///
    labsize(vsmall)) xtitle(" ") title(" ") ylabel(, labsize(small))

grc1leg2 "not_signing" "optimistic" "balanced" "pessimistic", ///
    xtob1title maintitlefrom(pessimistic) ycommon lrows(1) ysize(7) xsize(10) ///
    saving(orientation, replace) legendfrom(pessimistic)
graph export "./graphs/mob_heterogeneity_orientation.png", ///
    replace width(2000)



* T: heterogeneity by argument/policy variables

collect clear
mlogit d_sharing_inn i.d_treat $controls

collect create main, replace
collect, tags(outcome["not signing"]): margins, dydx(d_treat) pr(out(1))
collect, tags(outcome["optimistic"]): margins, dydx(d_treat) pr(out(2))
collect, tags(outcome["balanced"]): margins, dydx(d_treat) pr(out(3))
collect, tags(outcome["pessimistic"]): margins, dydx(d_treat) pr(out(4))

foreach var of varlist policy_intervention arg_labour arg_againstinn ///
    arg_proinn {
    
    mlogit d_sharing_inn i.d_treat $controls if `var'
    local N_`var' = e(N)
    
    local z: variable label `var'
    
    collect create `var', replace
    collect, tags(outcome["not signing"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(1))
    collect, tags(outcome["optimistic"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(2))
    collect, tags(outcome["balanced"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(3))
    collect, tags(outcome["pessimistic"] title["`z'"]): margins, dydx(d_treat) ///
        pr(out(4))
}

collect combine full = main policy_intervention arg_labour arg_againstinn ///
    arg_proinn
collect layout (collection#(colname[i.d_treat]#result[_r_b _r_se N] )) ///
    (cmdset#outcome)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se], nformat(%5.3f)
collect style cell collection#colname[4.d_treat]#result[_r_se], ///
    border(bottom)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" 6 "(6)" ///
    7 "(7)" 8 "(8)" 9 "(9)"
collect label values collection main "Baseline" policy_intervention ///
    "Policy intervention" arg_labour "Job losses" arg_againstinn "Other anti-AI" ///
    arg_proinn "Pro-markets", modify
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, country, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "willingness_het_policyarg.tex", replace tableonly
