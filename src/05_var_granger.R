# 04_var_granger.R
# Fits a VAR model on S&P 500 returns, GARCH volatility, and Google Trends
# search volume (US & CH). Selects lag order via AIC/BIC and runs
# Granger causality tests to address H1.

library(here)
library(readr)
library(vars)
library(dplyr)

combined <- read_csv(here("data", "processed", "combined_garch.csv"))

# ─── Prepare VAR dataset ─────────────────────────────────────────────────────
# TODO: Select and rename the relevant columns; ensure all series are stationary
var_data <- combined |>
  select(
    sp500_return,
    garch_volatility,
    # us_anxiety,        # uncomment and adjust column names as needed
    # ch_anxiety
  ) |>
  na.omit()

# ─── Lag selection ───────────────────────────────────────────────────────────
lag_select <- VARselect(var_data, lag.max = 12, type = "const")
print(lag_select$selection)   # AIC, BIC, HQ, FPE

optimal_lag <- lag_select$selection["AIC(n)"]

# ─── Fit VAR ─────────────────────────────────────────────────────────────────
var_model <- VAR(var_data, p = optimal_lag, type = "const")
summary(var_model)

# ─── Granger causality (H1) ──────────────────────────────────────────────────
# Does S&P 500 Granger-cause search volume?
granger_sp500_to_search <- causality(var_model, cause = "sp500_return")
print(granger_sp500_to_search$Granger)

# Does search volume Granger-cause S&P 500?
# TODO: Repeat causality() with cause = search volume variable

# ─── Save model ──────────────────────────────────────────────────────────────
saveRDS(var_model, here("data", "processed", "var_model.rds"))
message("Saved: data/processed/var_model.rds")
