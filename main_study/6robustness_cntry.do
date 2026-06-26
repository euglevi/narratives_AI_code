set more off
clear
clear frames

cd "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/"

use dataset, replace


* T:policy preferences

local countries `""US" "DE" "IT""'

foreach v of local countries {
    cibar policy_intervention if cntry == "`v'", over1(d_treat) ///
        graphopts(ytitle(Share of respondents, size(small)) saving(intervene, ///
        replace) subtitle(Policy intervention, bexpand bcolor(gs13) box) ///
        legend(position(6) rows(1)) fxsize(60)) ///
        barcolor(baseline optimistic balanced pessimistic)
    catcibar arg_labour arg_againstinn arg_proinn if cntry == "`v'", ///
        over(d_treat) ylabel(, labsize(small)) ///
        colors(baseline optimistic balanced pessimistic ) ///
        xlabel(1 "Job losses" 2 "Other anti-AI" 3 "Pro-markets", ///
        labsize(small)) legend(position(6) row(1) ///
        order(1 "baseline" 2 "optimistic" 3 "balanced" 4 "pessimistic") ///
        size(small)) saving(arguments, replace) ytitle(Share of respondents, ///
        size(small)) subtitle(Arguments for/against policy intervention, ///
        bexpand bcolor(gs13) box) fxsize(140)
    catcibar higher_taxes_on targ redistr education_polic ///
        tax_credits_inn if cntry == "`v'", over(d_treat) ylabel(, ///
        labsize(small)) colors(baseline optimistic balanced pessimistic ) ///
        legend(position(6) row(1) ///
        order(1 "baseline" 2 "optimistic" 3 "balanced" 4 "pessimistic") ///
        size(small)) saving(policies, replace) xlabel(, labsize(small)) ///
        ytitle("Share of supported policies" "within the category", ///
        size(small)) subtitle(Policies, bexpand bcolor(gs13) box) fxsize(140) ///
        xlabel(4 "Education" 5 "Tax credits" 3 "Redistribution" 2 ///
        `""Constraints" "on big tech""' 1 "Tax robots")
    grc1leg2 "intervene" "arguments" "policies", lrows(4) position(8) ///
        ring(0) lxoffset(7) lyoffset(5) holes(3) ysize(8) xsize(13)
    
    graph export "./graphs/backlash_`v'.png", replace width(2000)
}


* T: political mobilization

local countries `""US" "DE" "IT""'

foreach v of local countries {
    graph bar d_signature2 d_signature3 d_signature4 if signature2 != 0 & ///
        cntry == "`v'", stack title("Change.org") bar(1, color(optimistic)) ///
        bar(3, color(pessimistic)) bar(2, color(balanced)) blabel(bar, ///
        box margin(small) color(black) position(inside) format(%4.2f) ///
        size(vsmall) gap(0.7)) saving(publ, replace) legend(off) fxsize(60) ///
        plotregion(margin(4 4 5 0)) fysize(70)
    gr_edit title.DragBy 3 0
    graph save publ.gph, replace
    graph bar d_sharing_inn1 d_sharing_inn2 d_sharing_inn3 ///
        d_sharing_inn4 if cntry == "`v'", over(d_treat, label(labsize(small))) ///
        stack title("Survey") bar(1, color(baseline)) bar(2, color(optimistic)) ///
        bar(3, color(balanced)) bar(4, color(pessimistic)) blabel(bar, ///
        box margin(small) color(black) position(inside) format(%4.2f) ///
        size(vsmall) gap(0.7)) saving(priv, replace) ///
        legend(title("signed petition", size(small) position(6)) ///
        order(1 "none" 2 "optimistic" 3 "balanced" 4 "pessimistic") ///
        size(vsmall) rows(1) position(6)) ysize(10) fxsize(140) ///
        b1title("statement seen", size(small)) fysize(100)
    grc1leg2 "publ" "priv", rows(1) legendfrom(priv) ysize(7) xsize(10)
    
    graph export "./graphs/signatures_`v'.png", replace width(2000)
}


* T: other outcomes

local countries `""US" "DE" "IT""'

foreach v of local countries {
    catcibar trust_in_government trust_in_political_p ///
        trust_in_trade_union trust_in_tech_tycoon if cntry == "`v'", ///
        over(d_treat) ylabel(, labsize(tiny)) ///
        colors(baseline optimistic balanced pessimistic ) xlabel(, ///
        labsize(vsmall)) saving(trust, replace) ytitle("Average trust", ///
        size(small))
    
    cibar job_loss_chance if cntry == "`v'", over1(d_treat) ///
        barcolor(baseline optimistic pessimistic balanced) ///
        graphopts(ytitle("% of losing job because of AI/automation", ///
        size(small)) saving(job_loss_sharing, replace))
    
    grc1leg2 "trust" "job_loss_sharing", lrows(1) ysize(7) xsize(15)
    graph export "./graphs/job_loss_trust_`v'.png", replace width(2000)
}


* T: regression of policy preferences

local countries `""US" "DE" "IT""'

global controls under35 over65 i.d_gender i.d_education i.occupation ///
    i.d_employment ib2.d_industry low_income i.d_cntry i.date i.hour

collect clear

foreach v of local countries {
    collect create `v', replace
    local i = 1
    foreach v_var of varlist policy_intervention arg_labour ///
        arg_againstinn arg_proinn higher_taxes_on targ redistr ///
        education_polic tax_credits_inn {
        collect e(N) e(r2), tags(coleq["`v_var'"] ///
            cmdset[`i']): reg `v_var' i.d_treat $controls if cntry == "`v'"
        local i = `i' + 1
    }
    
}

collect combine full = US DE IT, style(right)
collect addtags colname[4.d_treat], fortags(result[r2 N])
collect layout (collection#colname[i.d_treat]#result[_r_b _r_se r2 N]) ///
    (cmdset#coleq)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se r2], nformat(%5.3f)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect style cell result[r2], border(top)
collect style cell result[N], border(bottom)
collect label values result N "Obs" p1 "optimistic vs balanced" p2 ///
    "optimistic vs pessimistic" p3 "balanced vs pessimistic", modify
collect label values collection US "United States" DE "Germany" IT "Italy"
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" ///
    6 "(6)" 7 "(7)" 8 "(8)" 9 "(9)" 10 "(10)"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "regression_policies_cntry.tex", replace tableonly

 // ╭───────────────────────────────────────────────╮
 // │ T: between-subjects parametric evidence │
 // ╰───────────────────────────────────────────────╯

local countries `""US" "DE" "IT""'

collect clear 

foreach v of local countries {
    mlogit d_sharing_inn i.d_treat $controls if cntry == "`v'"
    
    collect create `v', replace
    collect, tags(outcome["not signing"] title["signatures"]): margins, ///
        dydx(d_treat) pr(out(1)) // + optimistic and balanced
    collect, tags(outcome["optimistic"] title["signatures"]): margins, ///
        dydx(d_treat) pr(out(2)) // - balanced and (almost significant) optimistic
    collect, tags(outcome["balanced"] title["signatures"]): margins, ///
        dydx(d_treat) pr(out(3)) // nothing
    collect, tags(outcome["pessimistic"] title["signatures"]): margins, ///
        dydx(d_treat) pr(out(4)) // - optimistic and (almost significant) balanced
}

collect combine full = US DE IT, style(right)
collect layout (collection#colname[i.d_treat]#result[_r_b _r_se]) ///
    (title#cmdset#outcome)
collect style showbase off
collect style cell result[_r_se], sformat("(%s)")
collect style cell result[_r_b _r_se], nformat(%5.3f)
collect style cell colname[4.d_treat]#result[_r_se], border(bottom)
collect style header result[_r_b _r_se], level(hide)
collect style cell coleq, halign(center)
collect style cell cmdset, halign(center)
collect label values result N "Obs", modify
collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" ///
    6 "(6)" 7 "(7)" 8 "(8)" 9 "(9)"
collect label values collection US "United States" DE "Germany" IT "Italy"
collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
collect notes ///
    "Multinomial logit regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, date and hour fixed effects."
collect style title, font(, bold)
collect style column, dups(center)

collect preview
collect export "willingness_between_cntry.tex", replace tableonly

 // ╭───────────────────────────────────────────────╮
 // │ T: whitin-subjects parametric evidence │
 // ╰───────────────────────────────────────────────╯

local countries `""US" "DE" "IT""'

foreach v of local countries {
    preserve
    keep if cntry == "`v'"
    
    expand 2, gen(post)
    label variable post "post"
    
    gen d_opinion = .
    replace d_opinion = d_expectation if post == 0
    replace d_opinion = d_sharing_inn if post == 1
    
    label define options 1 "not support" 2 "optimistic" 4 "pessimistic" ///
        3 "balanced"
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
    collect label values cmdset 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)" 5 "(5)" ///
        6 "(6)" 7 "(7)" 8 "(8)" 9 "(9)"
    collect stars _r_p 0.01 "***" 0.05 "**" 0.1 "*", attach(_r_b) shownote
    collect notes ///
        "OLS regressions. Included controls are age-group, gender, education, income employment status, industry, occupation, date and hour fixed effects."
    collect style title, font(, bold)
    collect style column, dups(center)
    
    collect preview
    collect export "willingness_within_`v'.tex", replace tableonly
    restore
}
