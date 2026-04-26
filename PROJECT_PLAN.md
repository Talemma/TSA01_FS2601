# Project Plan — CS2 Skin Market Integration Study

**Course:** Time Series Analysis in Finance (TSA01_FS2601) — HSLU Spring 2026
**Team:** Emanuel Lemma & Jakub
**Final submission:** 22 May 2026, 12:15 — Ilias or email to denis.bieri@hslu.ch & thomas.ankenbrand@hslu.ch

---

## Research Question

> *"Is the CS2 skin market integrated with traditional and crypto financial markets, and what is the direction and temporal dynamics of any such relationship?"*

---

## Hypotheses

| # | Hypothesis |
|---|---|
| H1 | CS2 skin index returns are significantly correlated with Bitcoin returns (market integration) |
| H2 | Bitcoin Granger-causes CS2 skin prices, but not vice versa |
| H3 | The CS2 market responds to Bitcoin shocks with a lag of several periods |
| H4 | CS2 shows higher volatility than S&P 500 but similar clustering patterns to Bitcoin |

---

## R Scripts Pipeline

| # | File | Status | Input → Output |
|---|---|---|---|
| 0 | `src/00_setup.R` | ✅ done | Kaggle API → `data/raw/items/` (22,495 CSVs) |
| 1 | `src/01_data_preprocessing.R` | ✅ done | `data/raw/` → `data/processed/cs2_daily.parquet` (35.3M rows) |
| 2 | `src/02_index_construction.R` | ⏳ next | `cs2_daily.parquet` → `data/processed/cs2_index.parquet` |
| 3 | `src/03_eda.R` | ❌ pending | `cs2_index.parquet` + quantmod → plots + stats in `images/` |
| 4 | `src/04_garch.R` | ❌ pending | `cs2_index.parquet` → GARCH results + plots |
| 5 | `src/05_var_granger.R` | ❌ pending | `cs2_index.parquet` → VAR/Granger results |
| 6 | `src/06_irf.R` | ❌ pending | VAR model → IRF plots |

### Script Details

#### `02_index_construction.R`
1. Load `cs2_daily.parquet`
2. Filter to wearables only (`item_category` ∈ `weapon_skin`, `knife`, `glove`)
3. Liquidity filter: drop any item sold fewer than 2 times in any calendar month
4. Compute daily value-weighted index level: `sum(price × trading_value) / sum(trading_value)` per day
5. Save `data/processed/cs2_index.parquet` — one row per day

#### `03_eda.R`
- Load CS2 index + fetch BTC, S&P 500, Gold via `quantmod`
- Align to same date range, compute log returns
- Produce: time series plots, descriptive stats table, correlation matrix, ACF/PACF, ADF tests
- Save all figures to `images/`

#### `04_garch.R`
- Fit GARCH(1,1) on CS2, BTC, S&P 500 returns
- Compare volatility persistence (α+β) and unconditional volatility across assets (H4)
- Plot conditional volatility overlay

#### `05_var_granger.R`
- VAR(p) on CS2, BTC, S&P 500 returns; lag selection via AIC/BIC
- Granger causality tests: BTC→CS2, CS2→BTC, S&P 500→CS2 (H1, H2)
- Save results table

#### `06_irf.R`
- Orthogonalised IRF from VAR model
- Response of CS2 to 1-SD shock in BTC and S&P 500 (H3)
- Save IRF plot

---

## Report (LaTeX in `latex/`)

| Item | Status |
|---|---|
| Document structure + subsections | ✅ done |
| Title page | ✅ done (Jakub's last name missing) |
| Abstract (~150 words) | ❌ write after results |
| 1. Introduction | ❌ write |
| 2. Literature Review | ❌ write + sources needed |
| 3. Methodology | ❌ write |
| 4. Results & Discussion | ❌ write after scripts done |
| 5. Conclusion | ❌ write after results |
| 6. Appendix | ❌ fill after scripts done |
| `references.bib` | ❌ find and add sources |

### Page Budget (5 pages total)

| Section | Target |
|---|---|
| 1. Introduction | ~0.5 pages |
| 2. Literature Review | ~0.75 pages |
| 3. Methodology | ~1.25 pages |
| 4. Results & Discussion | ~2.0 pages |
| 5. Conclusion | ~0.5 pages |

> Figures count toward the 5 pages — max 3–4 figures in the main body, rest in appendix.

### Sources Needed

| Topic | Reference | Status |
|---|---|---|
| Index construction methodology | MSCI Inc. (2024); SIX Swiss Exchange AG (2024) | ✅ in references.bib |
| Virtual goods economics | Castronova (2001); Hamari & Lehdonvirta (2010) | ✅ Hamari in references.bib; Castronova still needed |
| CS skin market | Dobrynskaya & Strelnikov (2025); Guede-Fernández et al. (2025); Zhou (2024) | ✅ in references.bib |
| Bitcoin as speculative asset | Baur et al. (2018); Bouri et al. (2017) | ✅ in references.bib |
| Alternative assets & integration | Akin et al. (2024) — British Actuarial Journal | ✅ in references.bib |
| Granger causality | Granger (1969) — *Econometrica* | ✅ in references.bib |
| GARCH | Bollerslev (1986) — *Journal of Econometrics* | ✅ in references.bib |
| VAR methodology | Sims (1980) — *Econometrica* | ✅ in references.bib |

---

## Presentation (4–5 slides, 5 minutes)

| Slide | Content |
|---|---|
| 1 | Research question + motivation |
| 2 | Hypotheses H1–H4 |
| 3 | Data & methodology (CS2 index + pipeline) |
| 4 | Key results (GARCH, Granger, IRF) |
| 5 | Conclusion + limitations |

---

## Deliverables Checklist

- [ ] Paper (PDF, 5 pages)
- [ ] Presentation (slides or R script)
- [ ] R scripts + processed data files
- [ ] Team agreement
- [ ] Submit before **22 May 2026, 12:15**

---

## Data Files

| File | Status | Description |
|---|---|---|
| `data/raw/items/` | ✅ | 22,495 item CSVs from Steam Marketplace |
| `data/raw/name_conversion_table.csv` | ✅ | URL-encoded → decoded item names |
| `data/processed/cs2_daily.parquet` | ✅ | 35.3M rows, all items, daily VWAP, enriched |
| `data/processed/cs2_index.parquet` | ❌ | Daily CS2 index level (output of script 02) |
