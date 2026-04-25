# 02_eda.R
# Exploratory data analysis: time series plots, descriptive statistics,
# correlation matrix, ACF/PACF, and seasonality checks.

library(here)
library(readr)
library(dplyr)
library(ggplot2)
library(patchwork)
library(skimr)
library(tseries)

combined <- read_csv(here("data", "processed", "combined_weekly.csv"))

# ─── Descriptive statistics ──────────────────────────────────────────────────
skim(combined)

# ─── Time series plots ───────────────────────────────────────────────────────
p_sp500 <- ggplot(combined, aes(x = date, y = sp500_return)) +
  geom_line() +
  labs(title = "S&P 500 Weekly Returns", x = NULL, y = "Return")

# TODO: Add plots for each Google Trends series (US & CH)

# ─── Correlation matrix ──────────────────────────────────────────────────────
cor_matrix <- combined |>
  select(-date) |>
  cor(use = "complete.obs")

print(cor_matrix)

# ─── ACF / PACF ──────────────────────────────────────────────────────────────
par(mfrow = c(2, 2))
acf(na.omit(combined$sp500_return),  main = "ACF – S&P 500 Returns")
pacf(na.omit(combined$sp500_return), main = "PACF – S&P 500 Returns")
# TODO: Repeat for Google Trends series

# ─── Stationarity (ADF) ──────────────────────────────────────────────────────
adf_sp500 <- adf.test(na.omit(combined$sp500_return))
print(adf_sp500)
# TODO: Run ADF on all series; difference non-stationary series

# ─── Save plots ──────────────────────────────────────────────────────────────
ggsave(here("images", "sp500_returns.png"), p_sp500, width = 10, height = 4)
