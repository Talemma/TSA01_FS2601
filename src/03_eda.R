# 03_eda.R
# Exploratory data analysis: load CS2 index + comparison assets, align series,
# compute log returns, produce plots, descriptive stats, correlation matrix,
# ACF/PACF, and ADF stationarity tests.
#
# Outputs (saved to images/eda/):
#   levels.png       — index level series for all four assets
#   returns.png      — log return series for all four assets
#   correlation.png  — correlation matrix heatmap
#   acf.png          — ACF plots for all four return series

library(data.table)
library(arrow)
library(here)
library(ggplot2)
library(patchwork)
library(quantmod)
library(tseries)

dir.create(here("images", "eda"), showWarnings = FALSE, recursive = TRUE)

DATE_FROM <- "2013-08-01"
DATE_TO   <- "2024-06-15"

# ── Load CS2 index ─────────────────────────────────────────────────────────────

cs2 <- as.data.table(read_parquet(here("data", "processed", "cs2_index.parquet")))
cs2 <- cs2[, .(date, cs2 = index_level)]

# ── Load comparison assets via quantmod ───────────────────────────────────────

getSymbols(c("^GSPC", "BTC-USD", "GC=F"),
           from = DATE_FROM, to = DATE_TO,
           auto.assign = TRUE, warnings = FALSE)

sp500 <- data.table(date = as.Date(index(GSPC)),      sp500 = as.numeric(Ad(GSPC)))
btc   <- data.table(date = as.Date(index(`BTC-USD`)), btc   = as.numeric(Ad(`BTC-USD`)))
gold  <- data.table(date = as.Date(index(`GC=F`)),    gold  = as.numeric(Cl(`GC=F`)))

# ── Merge on common dates (inner join — keeps only days all four assets traded) ─

dt <- Reduce(function(a, b) merge(a, b, by = "date"),
             list(cs2, sp500, btc, gold))
setorder(dt, date)

message(sprintf("Common sample: %s to %s (%d observations)",
                min(dt$date), max(dt$date), nrow(dt)))

# ── Log returns ───────────────────────────────────────────────────────────────

for (col in c("cs2", "sp500", "btc", "gold")) {
  dt[, paste0("r_", col) := c(NA_real_, diff(log(get(col))))]
}

ret <- dt[!is.na(r_cs2)]

# ── Descriptive statistics ────────────────────────────────────────────────────

desc_stats <- function(x) {
  list(
    n        = sum(!is.na(x)),
    mean     = mean(x, na.rm = TRUE),
    sd       = sd(x, na.rm = TRUE),
    min      = min(x, na.rm = TRUE),
    max      = max(x, na.rm = TRUE),
    skewness = mean(((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))^3, na.rm = TRUE),
    kurtosis = mean(((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))^4, na.rm = TRUE) - 3
  )
}

stats <- rbindlist(lapply(
  c(cs2 = "r_cs2", `S&P 500` = "r_sp500", Bitcoin = "r_btc", Gold = "r_gold"),
  function(col) as.data.table(desc_stats(ret[[col]]))
), idcol = "asset")

message("\n── Descriptive Statistics (log returns) ──────────────────────────────────")
print(stats)

# Annualised volatility
message("\nAnnualised volatility (SD * sqrt(252)):")
for (col in c("r_cs2", "r_sp500", "r_btc", "r_gold")) {
  message(sprintf("  %-10s %.2f%%", col, sd(ret[[col]], na.rm = TRUE) * sqrt(252) * 100))
}

# ── Correlation matrix ────────────────────────────────────────────────────────

cor_mat <- cor(ret[, .(r_cs2, r_sp500, r_btc, r_gold)], use = "complete.obs")
rownames(cor_mat) <- colnames(cor_mat) <- c("CS2", "S&P 500", "Bitcoin", "Gold")

message("\n── Correlation Matrix ────────────────────────────────────────────────────")
print(round(cor_mat, 3))

# ── ADF stationarity tests ────────────────────────────────────────────────────

message("\n── ADF Tests (log returns) ───────────────────────────────────────────────")
for (col in c("r_cs2", "r_sp500", "r_btc", "r_gold")) {
  adf <- adf.test(na.omit(ret[[col]]))
  message(sprintf("  %-10s statistic = %6.3f  p-value = %.4f  %s",
                  col, adf$statistic, adf$p.value,
                  ifelse(adf$p.value < 0.05, "✓ stationary", "✗ non-stationary")))
}

# ── Plots ─────────────────────────────────────────────────────────────────────

theme_set(theme_minimal(base_size = 11))

# 1. Index levels (normalised to 100 at start)
levels_long <- melt(
  dt[, .(date,
         CS2     = cs2     / cs2[1]     * 100,
         `S&P 500` = sp500 / sp500[1]   * 100,
         Bitcoin = btc     / btc[1]     * 100,
         Gold    = gold    / gold[1]    * 100)],
  id.vars = "date", variable.name = "Asset", value.name = "value"
)

p_levels <- ggplot(levels_long, aes(x = date, y = value, colour = Asset)) +
  geom_line(linewidth = 0.5) +
  scale_y_log10() +
  labs(title = "Normalised Price Levels (base = 100, log scale)",
       x = NULL, y = "Index (base 100, log scale)", colour = NULL) +
  theme(legend.position = "bottom")

ggsave(here("images", "eda", "levels.png"), p_levels, width = 10, height = 4, dpi = 150)

# 2. Log return series
returns_long <- melt(
  ret[, .(date, CS2 = r_cs2, `S&P 500` = r_sp500, Bitcoin = r_btc, Gold = r_gold)],
  id.vars = "date", variable.name = "Asset", value.name = "return"
)

p_returns <- ggplot(returns_long, aes(x = date, y = return)) +
  geom_line(linewidth = 0.3, colour = "steelblue") +
  facet_wrap(~Asset, ncol = 1, scales = "free_y") +
  labs(title = "Daily Log Returns", x = NULL, y = "Log Return")

ggsave(here("images", "eda", "returns.png"), p_returns, width = 10, height = 8, dpi = 150)

# 3. Correlation heatmap
cor_long <- as.data.table(as.table(cor_mat))
setnames(cor_long, c("Asset1", "Asset2", "correlation"))

p_cor <- ggplot(cor_long, aes(x = Asset1, y = Asset2, fill = correlation)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(correlation, 2)), size = 3.5) +
  scale_fill_gradient2(low = "#d73027", mid = "white", high = "#1a9850",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Correlation Matrix — Log Returns", x = NULL, y = NULL, fill = "r") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(here("images", "eda", "correlation.png"), p_cor, width = 5, height = 4, dpi = 150)

# 4. ACF plots for each return series
png(here("images", "eda", "acf.png"), width = 1200, height = 800, res = 120)
par(mfrow = c(2, 4), mar = c(4, 4, 3, 1))
for (col in c("r_cs2", "r_sp500", "r_btc", "r_gold")) {
  label <- switch(col, r_cs2 = "CS2", r_sp500 = "S&P 500", r_btc = "Bitcoin", r_gold = "Gold")
  acf(na.omit(ret[[col]]),  main = paste("ACF —", label),  lag.max = 30)
  pacf(na.omit(ret[[col]]), main = paste("PACF —", label), lag.max = 30)
}
dev.off()

message("\nAll plots saved to images/eda/")

# ── Save aligned returns for downstream scripts ───────────────────────────────

write_parquet(ret, here("data", "processed", "returns.parquet"))
message("Saved aligned returns: data/processed/returns.parquet")
