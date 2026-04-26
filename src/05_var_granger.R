# 05_var_granger.R
# Fits a VAR(p) model on CS2, S&P 500, Bitcoin, and Gold log returns.
# Selects lag order via AIC/BIC and runs Granger causality tests (H1, H2).
#
# Requires: data/processed/returns.parquet (produced by 03_eda.R)
# Outputs:  data/processed/var_model.rds

library(data.table)
library(arrow)
library(here)
library(vars)

# ── Load aligned returns ──────────────────────────────────────────────────────

ret      <- as.data.table(read_parquet(here("data", "processed", "returns.parquet")))
var_data <- na.omit(ret[, .(r_cs2, r_sp500, r_btc, r_gold)])

message(sprintf("VAR dataset: %d observations, %d variables", nrow(var_data), ncol(var_data)))

# ── Lag selection ───────────────────────────────���─────────────────────────────

lag_select <- VARselect(var_data, lag.max = 10, type = "const")

message("\n-- Lag Selection ----------------------------------------------------------------")
print(lag_select$selection)

p_aic <- lag_select$selection["AIC(n)"]
p_bic <- lag_select$selection["SC(n)"]
message(sprintf("\nAIC suggests p = %d | BIC suggests p = %d", p_aic, p_bic))

p <- p_bic
message(sprintf("Using p = %d (BIC)", p))

# ── Fit VAR(p) ─────────────────────────────────────────────────────���──────────

var_model <- VAR(var_data, p = p, type = "const")

message("\n-- VAR Model Summary ------------------------------------------------------------")
summary(var_model)

# ── Granger causality tests ──────────────────────────���────────────────────────
# causality(model, cause = X) tests whether X Granger-causes all other variables.
# We run each direction of interest separately.

message("\n-- Granger Causality Tests ------------------------------------------------------")

tests <- list(
  "Bitcoin  -> CS2"     = list(cause = "r_btc",   effect = "r_cs2"),
  "CS2      -> Bitcoin" = list(cause = "r_cs2",   effect = "r_btc"),
  "S&P 500  -> CS2"     = list(cause = "r_sp500",  effect = "r_cs2"),
  "CS2      -> S&P 500" = list(cause = "r_cs2",   effect = "r_sp500"),
  "Gold     -> CS2"     = list(cause = "r_gold",   effect = "r_cs2"),
  "CS2      -> Gold"    = list(cause = "r_cs2",   effect = "r_gold")
)

granger_results <- rbindlist(lapply(names(tests), function(name) {
  t     <- tests[[name]]
  res   <- causality(var_model, cause = t$cause)
  pval  <- res$Granger$p.value
  fstat <- res$Granger$statistic

  message(sprintf("  %-25s  F = %6.3f  p = %.4f  %s",
                  name, fstat, pval,
                  ifelse(pval < 0.05, "* significant", "")))

  data.table(direction = name, F_stat = round(fstat, 3), p_value = round(pval, 4))
}))

message("\n-- Summary Table ----------------------------------------------------------------")
print(granger_results)

# ── Save model ─────────────────────────────────────────────────���──────────────

saveRDS(var_model, here("data", "processed", "var_model.rds"))
message("\nSaved: data/processed/var_model.rds")
