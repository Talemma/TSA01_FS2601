# 02_index_construction.R
# Constructs a daily value-weighted CS2 skin price index from cs2_daily.parquet.
#
# Pipeline:
#   1. Filter to wearable categories (weapon_skin, knife, glove)
#   2. Exclude StatTrak and Souvenir variants
#   3. Liquidity filter: drop base_items with < 2 total trades in any calendar month
#   4. Compute daily value-weighted index: sum(trading_value) / sum(quantity)
#   5. Save cs2_index.parquet

library(data.table)
library(arrow)
library(here)

IN_FILE  <- here("data", "processed", "cs2_daily.parquet")
OUT_FILE <- here("data", "processed", "cs2_index.parquet")

WEARABLE_CATS    <- c("weapon_skin", "knife", "glove")
LIQUIDITY_MIN    <- 2L   # minimum trades per calendar month

# ── Load ──────────────────────────────────────────────────────────────────────

cs2 <- as.data.table(read_parquet(IN_FILE))

message(sprintf("Loaded %s rows, %s items",
                format(nrow(cs2), big.mark = ","),
                format(uniqueN(cs2$item_name), big.mark = ",")))

# ── Step 1: Filter to wearables, exclude StatTrak and Souvenir ────────────────

cs2 <- cs2[item_category %in% WEARABLE_CATS & !is_stattrak & !is_souvenir]

message(sprintf("After wearable filter:   %s rows, %s items",
                format(nrow(cs2), big.mark = ","),
                format(uniqueN(cs2$item_name), big.mark = ",")))

# ── Step 2: Liquidity filter ──────────────────────────────────────────────────
# Aggregate quantities per base_item per calendar month.
# Drop any base_item that records fewer than LIQUIDITY_MIN trades in any month.

cs2[, month := format(date, "%Y-%m")]

monthly <- cs2[, .(monthly_qty = sum(quantity)), by = .(base_item, month)]
illiquid <- monthly[monthly_qty < LIQUIDITY_MIN, unique(base_item)]
cs2      <- cs2[!base_item %in% illiquid]
cs2[, month := NULL]

message(sprintf("After liquidity filter:  %s rows, %s base_items",
                format(nrow(cs2), big.mark = ","),
                format(uniqueN(cs2$base_item), big.mark = ",")))

# ── Step 3: Value-weighted index ──────────────────────────────────────────────
# I_t = sum(price_i * qty_i) / sum(qty_i)
#      = sum(trading_value_i) / sum(qty_i)

index <- cs2[, .(
  index_level  = sum(trading_value) / sum(quantity),
  n_items      = uniqueN(base_item),
  total_volume = sum(quantity)
), by = date]

setorder(index, date)

# ── Step 4: Save ──────────────────────────────────────────────────────────────

write_parquet(index, OUT_FILE)

message("\nDone. Output: ", OUT_FILE)
message(sprintf("  Rows:          %s", format(nrow(index), big.mark = ",")))
message(sprintf("  Date range:    %s to %s", min(index$date), max(index$date)))
message(sprintf("  Avg items/day: %.0f", mean(index$n_items)))
