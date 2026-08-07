set more off
clear
clear frames

cd "$root/follow-up/"

use dataset, replace

* policies

kwallis policy_intervention, by(d_treat)
foreach v of varlist universal_incom tax_credits_inn stronger_regula ///
    education_polic breaking_up_tec lower_taxes_on_ higher_taxes_on ///
    minimum_wage_po unemployment_be {
    kwallis `v', by(d_treat)
}


prtest m_policy_intervention if inlist(d_treat, 1, 2), by(d_treat)
prtest m_policy_intervention if inlist(d_treat, 1, 3), by(d_treat)
prtest m_policy_intervention if inlist(d_treat, 1, 4), by(d_treat)
prtest m_policy_intervention if inlist(d_treat, 3, 2), by(d_treat)
prtest m_policy_intervention if inlist(d_treat, 3, 4), by(d_treat)
kwallis m_policy_intervention, by(d_treat)
foreach v of varlist m_universal_incom m_tax_credits_inn m_stronger_regula ///
    m_education_polic m_breaking_up_tec m_lower_taxes_on_ m_higher_taxes_on ///
    m_minimum_wage_po m_unemployment_be {
    kwallis `v', by(d_treat)
}

* political preferences

catcibar l_party_for_worker*, over(d_treat) xlabel(, labsize(small)) ///
    colors(baseline optimistic balanced pessimistic) legend(position(6) rows(1))
graph export "./graphs_tables/party_worker.png", replace width(2000)

catcibar l_party_for_ai*, over(d_treat) xlabel(, labsize(small)) ///
    colors(baseline optimistic balanced pessimistic) legend(position(6) rows(1))
graph export "./graphs_tables/party_ai.png", replace width(2000)

* beliefs

catcibar l_b_most_com*, over(m_d_sharing_inn) ///
    colors(baseline optimistic balanced pessimistic) ///
    legend(order(1 "not support" 2 "optimistic" 3 "balanced" 4 "pessimistic") ///
    rows(1) position(6) size(small) region(lstyle(foreground)) ///
    title("petition signed", size(small)))
graph export "./graphs_tables/falseconsensus.png", width(1000) replace


* emotions

catcibar political_corr happiness anger fear, over(narr_emotion) xlabel(, ///
    labsize(small)) colors(optimistic balanced pessimistic) ///
    legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic") ///
    region(lstyle(foreground)) size(small) title("statement seen", size(small)) ///
    position(6) rows(1))
graph export "./graphs_tables/emotions.png", replace width(2000)

* disaggregated by prior beliefs

catcibar l_b_most_com*, over(m_d_expectation) ///
    colors(baseline optimistic balanced pessimistic) ///
    legend(order(1 "do not know" 2 "optimistic" 3 "balanced" 4 "pessimistic") ///
    size(small))
graph export "./graphs_tables/falseconsensus_by_expectation.png", ///
    replace width(1000)

catcibar political_corr happiness anger fear, over(narr_emotion) ///
    by(m_d_expectation) xlabel(, labsize(small)) ///
    colors(optimistic balanced pessimistic) ///
    legend(order(1 "optimistic" 2 "balanced" 3 "pessimistic"))
graph export "./graphs_tables/emotions_by_expectation.png", ///
    replace width(2000)
