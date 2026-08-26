set more off
clear
clear frames

cd "$root/main_survey/"

use dataset, replace

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

* T: regression of willingness to sign

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

