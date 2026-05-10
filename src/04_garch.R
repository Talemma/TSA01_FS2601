# 04_garch.R
# Fits GARCH(1,1) models to CS2, S&P 500, Bitcoin, and Gold log returns.
# Compares volatility persistence and unconditional volatility across assets (H3).
#
# Requires: data/processed/returns.parquet (produced by 03_eda.R)
# Outputs:  images/garch/conditional_volatility.png

library(data.table)
library(arrow)
library(here)
library(rugarch)
library(ggplot2)

dir.create(here("images", "garch"), showWarnings = FALSE, recursive = TRUE)

# ── Load aligned returns ───────────────────────────────────────────────────────

ret <- as.data.table(read_parquet(here("data", "processed", "returns.parquet")))

ASSETS <- c(
  "CS2"     = "r_cs2",
  "S&P 500" = "r_sp500",
  "Bitcoin" = "r_btc",
  "Gold"    = "r_gold"
)

# ── GARCH(1,1) specification — student-t innovations ─────────────────────────
# Student-t handles the fat tails observed in all four return series.

spec <- ugarchspec(
  variance.model     = list(model = "sGARCH", garchOrder = c(1, 1)),
  mean.model         = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std"
)

# ── Fit and extract results ───────────────────────────────────────────────────

fits   <- list()
params <- list()

for (label in names(ASSETS)) {
  col  <- ASSETS[[label]]
  x    <- na.omit(ret[[col]])
  fit  <- ugarchfit(spec = spec, data = x, solver = "hybrid")
  fits[[label]] <- fit

  cf <- coef(fit)
  omega <- cf["omega"]
  alpha <- cf["alpha1"]
  beta  <- cf["beta1"]
  pers  <- alpha + beta
  uncond_vol_ann <- sqrt(omega / (1 - pers)) * sqrt(252) * 100

  params[[label]] <- data.table(
    asset         = label,
    omega         = omega,
    alpha         = alpha,
    beta          = beta,
    persistence   = pers,
    uncond_vol_ann = uncond_vol_ann
  )

  message(sprintf("\n── GARCH(1,1): %s ─────────────────────────────────────────", label))
  message(sprintf("  omega  = %.6f", omega))
  message(sprintf("  alpha  = %.4f", alpha))
  message(sprintf("  beta   = %.4f", beta))
  message(sprintf("  alpha + beta (persistence) = %.4f", pers))
  message(sprintf("  Unconditional vol (ann.)   = %.2f%%", uncond_vol_ann))
}

results <- rbindlist(params)
message("\n── Summary Table ─────────────────────────────────────────────────────────")
print(results[, .(asset, alpha = round(alpha, 4), beta = round(beta, 4),
                  persistence = round(persistence, 4),
                  uncond_vol_ann = round(uncond_vol_ann, 2))])

# ── Conditional volatility plot ───────────────────────────────────────────────

vol_list <- lapply(names(fits), function(label) {
  data.table(
    date  = ret$date[!is.na(ret[[ASSETS[[label]]]])],
    asset = label,
    sigma = as.numeric(sigma(fits[[label]])) * sqrt(252) * 100
  )
})

vol_dt <- rbindlist(vol_list)
vol_dt[, asset := factor(asset, levels = c("CS2", "S&P 500", "Bitcoin", "Gold"))]

p_vol <- ggplot(vol_dt, aes(x = date, y = sigma)) +
  geom_line(linewidth = 0.4, colour = "steelblue") +
  facet_wrap(~asset, ncol = 1, scales = "free_y") +
  labs(title  = "GARCH(1,1) Conditional Volatility (Annualised, %)",
       x = NULL, y = "Conditional Volatility (%)") +
  theme_minimal(base_size = 11)

ggsave(here("images", "garch", "conditional_volatility.png"),
       p_vol, width = 10, height = 9, dpi = 150)

message("\nPlot saved to images/garch/conditional_volatility.png")

# ── Standardised residuals Q-Q plots ─────────────────────────────────────────

png(here("images", "garch", "residual_qq.png"),
    width = 1200, height = 800, res = 150)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
for (label in names(fits)) {
  std_resid <- as.numeric(residuals(fits[[label]], standardize = TRUE))
  qqnorm(std_resid, main = paste("Std. Residuals Q-Q —", label),
         cex.main = 0.85, pch = 16, cex = 0.4, col = "steelblue")
  qqline(std_resid, col = "red", lwd = 1.5)
}
dev.off()

message("Plot saved to images/garch/residual_qq.png")
