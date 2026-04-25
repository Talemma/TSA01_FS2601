# 03_garch.R
# Fits a GARCH(1,1) model to S&P 500 returns and extracts the conditional
# volatility series for use as an additional variable in the VAR model.

library(here)
library(readr)
library(rugarch)
library(dplyr)

combined <- read_csv(here("data", "processed", "combined_weekly.csv"))
returns   <- na.omit(combined$sp500_return)

# ─── GARCH(1,1) specification ────────────────────────────────────────────────
spec <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model     = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "norm"
)

fit <- ugarchfit(spec = spec, data = returns)
print(fit)

# ─── Extract volatility ──────────────────────────────────────────────────────
volatility <- as.numeric(sigma(fit))

combined_garch <- combined |>
  filter(!is.na(sp500_return)) |>
  mutate(garch_volatility = volatility)

# ─── Save ────────────────────────────────────────────────────────────────────
write_csv(combined_garch, here("data", "processed", "combined_garch.csv"))
message("Saved: data/processed/combined_garch.csv")
