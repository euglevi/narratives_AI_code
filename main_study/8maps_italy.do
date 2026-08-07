set more off
clear
clear frames
set scheme white_tableau

cd "$root/main_survey/"

********************************************************************************
* 8maps_italy.do
* Three choropleth maps of Italian regions:
*   ai_job_impact, job_impact_robots, policy_intervention
* Full Italian sample (d_cntry==2), regional means weighted by `weight'.
* Shapefile: ISTAT 2024 generalized region boundaries (italy_shp/).
********************************************************************************

* ---------------------------------------------------------------------------- *
* 1. Convert ISTAT shapefile to .dta (only if not already done).
* ---------------------------------------------------------------------------- *

capture confirm file "italy_shp/italy_regions_db.dta"
if _rc {
    shp2dta using "italy_shp/Reg01012024_g_WGS84.shp", ///
        database("italy_shp/italy_regions_db") ///
        coordinates("italy_shp/italy_regions_coords") ///
        genid(id) replace
}

* ---------------------------------------------------------------------------- *
* 2. Build region-level outcome data: weighted means + unweighted obs count.
* ---------------------------------------------------------------------------- *

use dataset, clear
keep if d_cntry == 2

* Unweighted observation count per region (kept separately so weights only
* enter the means, not the count).
preserve
    contract region, freq(n_obs)
    tempfile counts
    save `counts'
restore

collapse (mean) ai_job_impact job_impact_robots policy_intervention ///
    [aw=weight], by(region)

merge 1:1 region using `counts', nogen

list region n_obs ai_job_impact job_impact_robots policy_intervention, ///
    sep(0) noobs abbreviate(20)

* ---------------------------------------------------------------------------- *
* 3. Merge with shapefile database via region name (ISTAT spelling matches).
* ---------------------------------------------------------------------------- *

preserve
    use "italy_shp/italy_regions_db", clear
    keep id DEN_REG
    rename DEN_REG region
    tempfile shp_names
    save `shp_names'
restore

merge 1:1 region using `shp_names'
assert _merge == 3
drop _merge

sort id
compress
save "italy_shp/region_outcomes.dta", replace

* ---------------------------------------------------------------------------- *
* 4. Plot three maps with spmap (presentation-ready, Italian labels).
*    - Continuous outcomes: sequential reversed Reds (darker = more pessimistic),
*      8 fine-grained classes.
*    - Binary outcome: sequential Blues, 8 fine-grained classes.
* ---------------------------------------------------------------------------- *

* Reversed ColorBrewer Reds (8-class): darkest first, lightest last.
* Lowest class (most negative) gets the darkest red.
local reds_rev `" "103 0 13" "165 15 21" "203 24 29" "239 59 44" "251 106 74" "252 146 114" "252 187 161" "254 224 210" "'

* Legend inside the plot at the 2 o'clock corner (top-right of Italy's bounding
* box is empty space, so the legend doesn't overlap the peninsula).
local frame_opts ndfcolor(gs14) ocolor(white ..) osize(vthin ..) ///
    legend(position(2) ring(0) size(small) symy(*0.9) symx(*0.9))

* Two-line short notes (avoid right-edge clipping).
local note_cont `""Medie regionali ponderate." "Scala: -100 = distrugge lavoro, +100 = lo crea.""'
local note_pol  `""Medie regionali ponderate." "Quota a favore dell'intervento pubblico.""'

* Shared class breaks for the two continuous outcomes (-100/+100 scale).
* Spans the regional-mean range observed in both variables, with the same
* breaks so a single legend describes both maps in the combined panel.
local breaks_cont -35 -28 -21 -14 -7 0 7 14 21

* (a) Impatto percepito dell'IA sul lavoro
spmap ai_job_impact using "italy_shp/italy_regions_coords", id(id) ///
    clmethod(custom) clbreaks(`breaks_cont') ///
    fcolor(`reds_rev') `frame_opts' ///
    title("Impatto percepito dell'IA sul lavoro", size(medlarge)) ///
    note(`note_cont', size(small)) ///
    name(g_ai, replace)
graph export "map_ai_job_impact.png", as(png) width(2400) replace

* (b) Impatto percepito dei robot sul lavoro
spmap job_impact_robots using "italy_shp/italy_regions_coords", id(id) ///
    clmethod(custom) clbreaks(`breaks_cont') ///
    fcolor(`reds_rev') `frame_opts' ///
    title("Impatto percepito dei robot sul lavoro", size(medlarge)) ///
    note(`note_cont', size(small)) ///
    name(g_rob, replace)
graph export "map_job_impact_robots.png", as(png) width(2400) replace

* (c) Sostegno all'intervento pubblico (share 0-1)
spmap policy_intervention using "italy_shp/italy_regions_coords", id(id) ///
    clmethod(custom) clbreaks(0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90) ///
    fcolor(Blues) `frame_opts' ///
    title("Sostegno all'intervento pubblico", size(medlarge)) ///
    note(`note_pol', size(small)) ///
    name(g_pol, replace)
graph export "map_policy_intervention.png", as(png) width(2400) replace

* (a') Variant of the AI map with no legend, for the combined panel
* (since map (b) right next to it carries an identical legend).
spmap ai_job_impact using "italy_shp/italy_regions_coords", id(id) ///
    clmethod(custom) clbreaks(`breaks_cont') ///
    fcolor(`reds_rev') ndfcolor(gs14) ocolor(white ..) osize(vthin ..) ///
    legend(off) ///
    title("Impatto percepito dell'IA sul lavoro", size(medlarge)) ///
    note(`note_cont', size(small)) ///
    name(g_ai_nl, replace) nodraw

* ---------------------------------------------------------------------------- *
* 5. Combined panel figure (16:9 for slides).
* ---------------------------------------------------------------------------- *

graph combine g_ai_nl g_rob g_pol, cols(3) ///
    title("Attitudini verso IA e automazione nelle regioni italiane", size(medium)) ///
    note("Campione italiano (N=3.738). Medie regionali calcolate con pesi campionari.", size(small)) ///
    iscale(*0.95) ///
    name(g_combined, replace) xsize(16) ysize(9)
graph export "maps_italy.png", as(png) width(3600) replace
