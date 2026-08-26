# Narratives, AI and Automation — Replication Package

Replication code for **"Why Artificial Intelligence is not a Salient Issue: Politicizing AI Reduces Mobilization Potential"** by G. Battiston, F. Boffa, E. Levi, A. Parmigiani and S. Stillman.

---

## 1. Overview

The project studies citizens' beliefs about artificial intelligence and automation, and how political narratives shape those beliefs, policy demands and willingness to mobilize.

Evidence comes from a pre-registered survey experiment fielded in **Italy, Germany and the United States** (N ≈ 11,400). Respondents are randomly assigned to one of four narrative conditions — *baseline* (no narrative), *optimistic*, *balanced*, *pessimistic* — and then report knowledge about AI and automation, beliefs about labour-market effects, policy preferences, and a behavioural outcome: whether they sign an online petition, and which version of it. A **follow-up wave** re-contacts Italian respondents to measure party attributions, false-consensus beliefs and emotional reactions.

---

## 2. Repository contents

```
narratives_AI_code/
├── 0master.do                        Master script: paths, environment, execution order
├── main_study/
│   ├── 1prepare_dataset.do           Import, harmonise and clean the three country samples
│   ├── 2descriptive_stats.do         Descriptives, randomisation balance, main outcome figures
│   ├── 3policies.do                  Policy preferences: main effects and heterogeneity
│   ├── 4signatures.do                Petition signing: main effects
│   ├── 5hetsignatures.do             Petition signing: heterogeneity
│   ├── 6robustness_cntry.do          Country-by-country replication
│   ├── 7robustness_inattentive.do    Attention-filter robustness
│   ├── summary_table.do              Sample characteristics table
└── follow_up/
    ├── 1prepare_dataset.do           Import and link the follow-up wave
    └── 2descriptive_stats.do         Follow-up figures
```

---

## 3. Software requirements

Analysis was run in **Stata 18**. Stata 17 is the minimum: the `collect` / `table` framework used throughout the table-producing scripts is not available in earlier versions.

| Package | Used for | Install |
|---|---|---|
| `grc1leg2` | Combining graph panels with a shared legend | `net install grc1leg2, from("http://digital.cgdev.org/doc/stata/MO/Misc")` |
| `mplotoffset` | Offset marginal-effects plots | SSC |
| `coefplot` | Coefficient plots | SSC |
| `catplot` | Categorical bar graphs | SSC |
| `labmask` | Value-label handling in graphs | SSC |
| `spmap`, `shp2dta` | Italian regional choropleth maps | SSC |
| `wyoung` | Westfall–Young multiple-hypothesis corrected p-values | SSC |
| `ftest` | Joint F-test for the randomisation balance table | SSC |
| `xframeappend` | Appending across frames | SSC |
| `palettes`, `colrspace` | Custom `optimism` colour scheme | SSC |
| `schemepack` | `white_tableau` scheme used in the maps | SSC |
| `fre` | Frequency tabulations | SSC |

`0master.do` installs all of these automatically when `install_packages` is set to 1. It also generates the four treatment-arm colour styles (`baseline`, `pessimistic`, `balanced`, `optimistic`) via `colorpalette ... stylefiles(...)`; this runs once per machine, and every graph-producing script depends on it.

---

## 4. Data

Raw survey exports are **not** included in this repository. The scripts expect the following structure under the data root:

```
<data root>/
├── main_survey/
│   ├── italy/final-2024-10-31.csv
│   ├── germany/final-2024-10-31.csv
│   ├── us/final-2024-11-06.csv
└── follow-up/
    └── italy/all_apps_wide-2025-01-13_final.csv
```

Each preparation script writes `dataset.dta` into its own working folder; all downstream scripts open that file.

---

## 5. Running the package

Open `0master.do`, set the two paths at the top, and run the file end to end:

```stata
global code "/path/to/narratives_AI_code"
global root "/path/to/data"
```

`$code` points at this repository, `$root` at the folder containing `main_survey/` and `follow-up/`, so the code can be cloned anywhere without touching the data location.

The master script creates the output folders (`graphs/`, `tables/`, `logs/`), installs missing packages, generates the colour styles, opens a log, and runs the numbered scripts in order. Four toggles control which blocks execute:

```stata
global install_packages 1
global build_palette 1
global run_main 1
global run_followup 1
```

On a second run, set `install_packages` and `build_palette` to 0. To re-estimate a single script, set both `run_` toggles to 0 and call it directly — `dataset.dta` persists, so preparation need not be repeated.

Approximate runtime on a modern laptop: preparation ≈ 5 minutes, full pipeline ≈ 10 minutes.

---

## 6. Scripts and exhibits

Exhibit numbers are marked `[TBC]` pending cross-reference with the manuscript.

### `main_study/1prepare_dataset.do`

Imports the three raw country CSVs, harmonises their offset column numbering, appends them, and cleans and recodes all analysis variables: treatment indicators, job-impact perceptions, knowledge items, demographics, cultural-worldview measures, voting variables and the policy battery. Applies a common occupation crosswalk across the three survey languages, links to the follow-up wave via `frlink`, and constructs the survey weights (`weight`, plus `weight_alt` for robustness). Writes `main_survey/dataset.dta`. No exhibits.

### `main_study/2descriptive_stats.do`

Sample descriptives, randomisation balance and the main outcome figures, all on `dataset.dta`.


### `main_study/3policies.do`

Treatment effects on the policy battery, by pooled OLS with the standard control set (`$controls`: age bands, gender, education, occupation, employment, industry, income, country and time-of-response fixed effects). Includes Westfall–Young multiple-hypothesis correction and an extensive set of heterogeneity cuts.


### `main_study/4signatures.do`

The behavioural outcome, modelled with multinomial logit plus `margins` because the signature variable distinguishes not signing from signing each petition version. Two designs: *between-subjects* (`mlogit d_sharing_inn i.d_treat`) and *within-subjects* (`mlogit d_opinion c.post c.post#i.d_treat`).


### `main_study/5hetsignatures.do`

Heterogeneity counterpart to `4signatures.do`, same estimator, one block per respondent characteristic.


### `main_study/6robustness_cntry.do`

Re-runs the core exhibits separately for `US`, `DE` and `IT` to show the pooled results are not driven by one country.


### `main_study/7robustness_inattentive.do`

Same exercise splitting on attentiveness (`inattentive = mistakes <= 2`) and on the separate attention-check item. Suffixes are `inattentive` and `attention_check`, so they do not clash with the country suffixes from script 6.


### `main_study/summary_table.do`

Sample characteristics by country and overall, written manually with `file write` as a complete `table` environment labelled `tab:summary`. Output: `tables/summary_table.tex`. 


### `follow_up/1prepare_dataset.do`

Imports and cleans the follow-up wave and links it back to the main survey, so responses can be analysed conditional on original treatment assignment. Writes `follow-up/dataset.dta`. No exhibits.

### `follow_up/2descriptive_stats.do`

Descriptives graphs on preference falsification, emotional reactions to the narratives.

---

## 7. Output inventory

All figures are written to `graphs/` and all LaTeX tables to `tables/`, within the relevant study folder. Both directories are created by `0master.do`.

| | Figures | Tables |
|---|---|---|
| `main_study/` | 42 | 21 |
| `follow_up/` | 6 | 0 |

---

## 8. Contact

Corresponding author for code queries: [name and email].
