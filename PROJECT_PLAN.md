# Project Plan — CS2 Skin Market Integration Study

**Course:** Time Series Analysis in Finance (TSA01_FS2601) — HSLU Spring 2026
**Team:** Emanuel Lemma & Jakub Holzmann
**Final submission:** 22 May 2026, 12:15 — Ilias or email to denis.bieri@hslu.ch & thomas.ankenbrand@hslu.ch

---

## Research Question

> *"Is the CS2 skin market integrated with traditional and crypto financial markets, and what is the direction and temporal dynamics of any such relationship?"*

---

## Hypotheses

| # | Hypothesis | Outcome |
|---|---|---|
| H1 | CS2 skin index returns are significantly correlated with Bitcoin returns (market integration) | **Rejected** — correlations ≈ 0 |
| H2 | Bitcoin Granger-causes CS2 skin prices, but not vice versa | **Rejected** — no significant Granger causality in either direction; borderline signal (p=0.068) runs CS2→system |
| H3 | CS2 exhibits higher volatility than S&P 500 but similar volatility clustering to Bitcoin | **Partially supported** — CS2 vol > S&P 500 ✅; persistence equal to Bitcoin ✅; but ARCH dynamics differ (CS2 α̂=0.0151 vs Bitcoin α̂=0.1265) |

> Note: IRF (H3 original) dropped from scope. H3 reassigned to GARCH volatility comparison.

---

## R Scripts Pipeline

| # | File | Status | Input → Output |
|---|---|---|---|
| 0 | `src/00_setup.R` | ✅ done | Kaggle API → `data/raw/items/` (22,446 CSVs) |
| 1 | `src/01_data_preprocessing.R` | ✅ done | `data/raw/` → `data/processed/cs2_daily.parquet` (35.3M rows) |
| 2 | `src/02_index_construction.R` | ✅ done | `cs2_daily.parquet` → `cs2_index.parquet` (1,607 items, 3,960 days) + `filter_stats.csv` |
| 3 | `src/03_eda.R` | ✅ done | `cs2_index.parquet` + quantmod → `images/eda/` + `images/index/` + `returns.parquet` |
| 4 | `src/04_garch.R` | ✅ done | `returns.parquet` → GARCH estimates + `images/garch/` (incl. `residual_qq.png`) |
| 5 | `src/05_var_granger.R` | ✅ done | `returns.parquet` → VAR(4) + Granger results + `var_model.rds` + `var_lag_selection.csv` + `var_ljungbox.csv` |
| 6 | `src/06_irf.R` | 🗑️ deleted — IRF removed from scope | — |

### Item counts (verified from R output)
- Raw dataset: **22,446 item variants** across **10,833 base items**
- After wearable + StatTrak/Souvenir filter: 7,348 variants / 1,638 base items
- After liquidity filter: **1,607 base items** (31 dropped, 2%)
- Aligned sample: **2,448 observations** (Gold has 2 fewer trading days)

---

## Key Results

### EDA
- CS2 annualised vol: **114.56%** — exceeds Bitcoin (69.87%)
- Correlations: CS2–BTC = −0.016, CS2–SP500 = 0.000, CS2–Gold = 0.011 → all ≈ 0
- All ADF tests reject unit root at 1%

### GARCH(1,1) — student-t innovations
| Asset | α̂ | β̂ | α̂+β̂ | Uncond. Vol. |
|---|---|---|---|---|
| CS2 | 0.0151 | 0.9839 | 0.9990 | 161.88% |
| S&P 500 | 0.1821 | 0.8158 | 0.9979 | 49.70% |
| Bitcoin | 0.1265 | 0.8725 | 0.9990 | 337.76% |
| Gold | 0.0280 | 0.9642 | 0.9923 | 16.61% |

### VAR(4) / Granger causality (BIC lag selection)
| Cause | F | p | Result |
|---|---|---|---|
| Bitcoin → system | 1.453 | 0.134 | Not significant |
| S&P 500 → system | 1.275 | 0.226 | Not significant |
| Gold → system | 1.353 | 0.181 | Not significant |
| CS2 → system | 1.663 | 0.068 | Borderline, not significant at 5% |

---

## Report (LaTeX in `latex/`)

| Item | Status |
|---|---|
| Document structure | ✅ done |
| Title page | ✅ done — Emanuel Lemma & Jakub Holzmann |
| Abstract | ✅ done |
| Table of Contents | ✅ done |
| List of Figures | ✅ done (auto-generated) |
| List of Tables | ✅ done (auto-generated) |
| List of Abbreviations + Glossary | ✅ done — `chapters/07_abbreviations.tex` (12 abbr. + 9 glossary terms) |
| 1. Introduction | ✅ done |
| 2. Literature Review | ✅ done |
| 3. Methodology | ✅ done |
| 4. Results & Discussion | ✅ done |
| 5. Conclusion | ✅ done |
| 6. Appendix | ✅ done — EDA plots, filter funnel, GARCH diagnostics, VAR diagnostics, full R code (scripts 01–05) |
| Declaration of Authorship | ✅ done — `chapters/08_declaration.tex` |
| `references.bib` | ✅ done — 12 entries |

### Branch & build status
- Branch: `appendix-and-frontmatter` — pushed to remote, **not yet merged to main**
- Latest commit: `945211e`
- Compiled PDF: **29 pages**, zero errors
- All numerical errors and interpretations reviewed and fixed (multi-agent audit)

### Page Budget (5 pages main body)

| Section | Target |
|---|---|
| 1. Introduction | ~0.5 pages |
| 2. Literature Review | ~0.75 pages |
| 3. Methodology | ~0.8 pages |
| 4. Results & Discussion | ~2.0 pages |
| 5. Conclusion | ~0.5 pages |

> Title page, ToC, bibliography, and appendix do not count toward the 5-page limit.

---

## Presentation (4–5 slides, 5 minutes)

**Status: ❌ not started**

| Slide | Content |
|---|---|
| 1 | Research question + motivation |
| 2 | Data & index construction (CS2 value-weighted index, 1,607 items) |
| 3 | Methodology (EDA → GARCH → VAR/Granger) |
| 4 | Key results (H1–H3 outcomes, GARCH table, Granger table) |
| 5 | Conclusion + limitations + future work |

---

## Deliverables Checklist

- [ ] Paper (PDF, 5 pages) — content complete on `appendix-and-frontmatter`; merge to main when Jakub has reviewed
- [ ] Presentation (slides) — not started
- [x] R scripts — all 5 scripts done and committed
- [ ] Team agreement
- **Submit:** before **22 May 2026, 12:15**

---

## Data Files

| File | Status | Description |
|---|---|---|
| `data/raw/items/` | ✅ | 22,446 item CSVs from Steam Marketplace |
| `data/raw/name_conversion_table.csv` | ✅ | URL-encoded → decoded item names |
| `data/raw/cs_skins_only.csv` | ✅ | Jakub's rarity mapping file |
| `data/processed/cs2_daily.parquet` | ✅ | 35.3M rows, all items, daily VWAP, enriched |
| `data/processed/cs2_index.parquet` | ✅ | Daily value-weighted CS2 index (3,960 days, 1,607 base items) |
| `data/processed/returns.parquet` | ✅ | Aligned log returns for CS2, S&P 500, BTC, Gold (2,448 obs) |
| `data/processed/filter_stats.csv` | ✅ | Item counts at each filter stage (used in appendix) |
| `data/processed/var_model.rds` | ✅ | Fitted VAR(4) object |
| `data/processed/var_lag_selection.csv` | ✅ | BIC/AIC/HQ/FPE lag criteria (used in appendix) |
| `data/processed/var_ljungbox.csv` | ✅ | Ljung-Box residual test results (used in appendix) |
