# 05_irf.R
# Computes Impulse Response Functions (IRF) from the fitted VAR model.
# Compares US vs CH responses (H4) and analyses asymmetry between
# positive and negative shocks (H3).

library(here)
library(vars)
library(ggplot2)
library(dplyr)

var_model <- readRDS(here("data", "processed", "var_model.rds"))

# ─── IRF ─────────────────────────────────────────────────────────────────────
# Response of search volume to a shock in S&P 500 returns
irf_result <- irf(
  var_model,
  impulse  = "sp500_return",
  response = NULL,       # TODO: specify search volume variable names
  n.ahead  = 20,
  boot     = TRUE,
  ci       = 0.95
)

plot(irf_result)

# ─── US vs CH comparison (H4) ────────────────────────────────────────────────
# TODO: Extract IRF values for US and CH series and plot side-by-side

# ─── Asymmetry analysis (H3) ─────────────────────────────────────────────────
# TODO: Split returns into positive and negative shocks, refit VAR on each
# subset, compute IRFs, and compare magnitudes

# ─── Save plots ──────────────────────────────────────────────────────────────
# ggsave(here("images", "irf_us_ch.png"), ..., width = 10, height = 5)
