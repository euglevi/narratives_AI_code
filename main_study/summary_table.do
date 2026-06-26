set more off
clear
clear frames

cd "/home/eugenio/Dropbox/political_economy_techchange/data/main_survey/"

use dataset, replace

* ==============================================================================
* Summary table: share of observations by country
* Variables: d_gender, age, d_education, d_employment, blue_collar,
*            service_worker, d_voting
* ==============================================================================

* Store country labels for header
local countries `""Germany" "Italy" "US" "Total""'

* Start building the LaTeX table
capture file close ftab
file open ftab using "./tables/summary_table.tex", write replace

file write ftab "\begin{table}[htbp]" _n
file write ftab "\centering" _n
file write ftab "\caption{Sample characteristics by country}" _n
file write ftab "\label{tab:summary}" _n
file write ftab "\begin{tabular}{lcccc}" _n
file write ftab "\toprule" _n
file write ftab " & Germany & Italy & US & Total \\" _n
file write ftab "\midrule" _n

* --- Number of observations ---
file write ftab "\textit{N}"
foreach c in 1 2 3 {
    count if d_cntry == `c'
    local n_`c' = r(N)
    file write ftab " & `n_`c''"
}
count
local n_total = r(N)
file write ftab " & `n_total' \\" _n
file write ftab "\addlinespace" _n

* --- Gender ---
file write ftab "\textbf{Gender} & & & & \\" _n
levelsof d_gender, local(glevels)
foreach g of local glevels {
    local glab : label (d_gender) `g'
    file write ftab "\quad `glab'"
    foreach c in 1 2 3 {
        count if d_gender == `g' & d_cntry == `c'
        local share = string(r(N)/`n_`c'' * 100, "%4.1f")
        file write ftab " & `share'\%"
    }
    count if d_gender == `g'
    local share = string(r(N)/`n_total' * 100, "%4.1f")
    file write ftab " & `share'\% \\" _n
}
file write ftab "\addlinespace" _n

* --- Age ---
file write ftab "\textbf{Age} & & & & \\" _n

* Mean age
file write ftab "\quad Mean"
foreach c in 1 2 3 {
    sum age if d_cntry == `c', meanonly
    local m = string(r(mean), "%4.1f")
    file write ftab " & `m'"
}
sum age, meanonly
local m = string(r(mean), "%4.1f")
file write ftab " & `m' \\" _n

* Std dev
file write ftab "\quad Std. dev."
foreach c in 1 2 3 {
    sum age if d_cntry == `c'
    local s = string(r(sd), "%4.1f")
    file write ftab " & (`s')"
}
sum age
local s = string(r(sd), "%4.1f")
file write ftab " & (`s') \\" _n

* Under 35
file write ftab "\quad Under 35"
foreach c in 1 2 3 {
    count if age <= 35 & d_cntry == `c'
    local share = string(r(N)/`n_`c'' * 100, "%4.1f")
    file write ftab " & `share'\%"
}
count if age <= 35
local share = string(r(N)/`n_total' * 100, "%4.1f")
file write ftab " & `share'\% \\" _n

* Over 65
file write ftab "\quad Over 65"
foreach c in 1 2 3 {
    count if age >= 65 & d_cntry == `c'
    local share = string(r(N)/`n_`c'' * 100, "%4.1f")
    file write ftab " & `share'\%"
}
count if age >= 65
local share = string(r(N)/`n_total' * 100, "%4.1f")
file write ftab " & `share'\% \\" _n
file write ftab "\addlinespace" _n

* --- Education ---
file write ftab "\textbf{Education} & & & & \\" _n
levelsof d_education, local(elevels)
foreach e of local elevels {
    local elab : label (d_education) `e'
    file write ftab "\quad `elab'"
    foreach c in 1 2 3 {
        count if d_education == `e' & d_cntry == `c'
        local share = string(r(N)/`n_`c'' * 100, "%4.1f")
        file write ftab " & `share'\%"
    }
    count if d_education == `e'
    local share = string(r(N)/`n_total' * 100, "%4.1f")
    file write ftab " & `share'\% \\" _n
}
file write ftab "\addlinespace" _n

* --- Employment ---
file write ftab "\textbf{Employment} & & & & \\" _n
levelsof d_employment, local(emplevels)
foreach e of local emplevels {
    local elab : label (d_employment) `e'
    file write ftab "\quad `elab'"
    foreach c in 1 2 3 {
        count if d_employment == `e' & d_cntry == `c'
        local share = string(r(N)/`n_`c'' * 100, "%4.1f")
        file write ftab " & `share'\%"
    }
    count if d_employment == `e'
    local share = string(r(N)/`n_total' * 100, "%4.1f")
    file write ftab " & `share'\% \\" _n
}
file write ftab "\addlinespace" _n

* --- Blue collar ---
file write ftab "\textbf{Blue collar}"
foreach c in 1 2 3 {
    count if blue_collar == 1 & d_cntry == `c'
    local share = string(r(N)/`n_`c'' * 100, "%4.1f")
    file write ftab " & `share'\%"
}
count if blue_collar == 1
local share = string(r(N)/`n_total' * 100, "%4.1f")
file write ftab " & `share'\% \\" _n

* --- Service worker ---
file write ftab "\textbf{Service worker}"
foreach c in 1 2 3 {
    count if service_worker == 1 & d_cntry == `c'
    local share = string(r(N)/`n_`c'' * 100, "%4.1f")
    file write ftab " & `share'\%"
}
count if service_worker == 1
local share = string(r(N)/`n_total' * 100, "%4.1f")
file write ftab " & `share'\% \\" _n
file write ftab "\addlinespace" _n

* --- Voting ---
file write ftab "\textbf{Voting intention} & & & & \\" _n
levelsof d_voting, local(vlevels)
foreach v of local vlevels {
    local vlab : label (d_voting) `v'
    file write ftab "\quad `vlab'"
    foreach c in 1 2 3 {
        count if d_voting == `v' & d_cntry == `c'
        local share = string(r(N)/`n_`c'' * 100, "%4.1f")
        file write ftab " & `share'\%"
    }
    count if d_voting == `v'
    local share = string(r(N)/`n_total' * 100, "%4.1f")
    file write ftab " & `share'\% \\" _n
}

* --- Close table ---
file write ftab "\bottomrule" _n
file write ftab "\end{tabular}" _n
file write ftab "\end{table}" _n
file close ftab

di "Table saved to ./tables/summary_table.tex"
