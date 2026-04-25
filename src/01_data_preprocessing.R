# 01_data_import.R
# Reads all 22,495 CS2 item CSVs, enriches with metadata parsed from filenames,
# aggregates to daily VWAP, and saves data/processed/cs2_daily.parquet.
#
# Run once. Re-running is safe (overwrites output).
# Required packages: data.table, arrow, here, stringr

library(data.table)
library(arrow)
library(here)
library(stringr)

# ── Constants ─────────────────────────────────────────────────────────────────

ITEMS_DIR  <- here("data", "raw", "items")
NAME_TABLE <- here("data", "raw", "name_conversion_table.csv")
OUT_FILE   <- here("data", "processed", "cs2_daily.parquet")
BATCH_SIZE <- 1000

WEAR_CONDITIONS <- c(
  "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"
)

# ── Name lookup table ─────────────────────────────────────────────────────────

name_tbl     <- fread(NAME_TABLE, encoding = "UTF-8")
setnames(name_tbl, c("encoded", "decoded"))
name_lookup  <- setNames(name_tbl$decoded, name_tbl$encoded)

# ── Filename metadata parser ──────────────────────────────────────────────────

parse_item_name <- function(decoded_name) {
  name <- decoded_name

  is_special  <- startsWith(name, "★")          # ★
  is_stattrak <- grepl("StatTrak™", name, fixed = TRUE)
  is_souvenir <- grepl("Souvenir", name, fixed = TRUE)

  name <- sub("^★\\s*", "", name)
  name <- sub("StatTrak™\\s*", "", name)
  name <- sub("Souvenir\\s*", "", name)
  name <- trimws(name)

  # Extract wear from trailing parentheses
  wear <- NA_character_
  for (w in WEAR_CONDITIONS) {
    pattern <- paste0("\\s*\\(", w, "\\)$")
    if (grepl(pattern, name)) {
      wear <- w
      name <- trimws(sub(pattern, "", name))
      break
    }
  }

  # Split on " | "
  parts     <- strsplit(name, " | ", fixed = TRUE)[[1]]
  weapon    <- trimws(parts[1])
  skin_name <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = " | ")) else NA_character_

  # Classify item category
  item_category <- dplyr::case_when(
    grepl("Graffiti",   weapon, fixed = TRUE)                      ~ "graffiti",
    grepl("Music Kit",  decoded_name, fixed = TRUE)                ~ "music_kit",
    grepl("Capsule",    decoded_name, fixed = TRUE)                ~ "capsule",
    grepl("Case",       weapon, fixed = TRUE)                      ~ "case",
    grepl("Package",    decoded_name, fixed = TRUE)                ~ "case",
    grepl("Sticker",    weapon, fixed = TRUE)                      ~ "sticker",
    is_special & grepl("Gloves|Wraps|Hand", weapon)                ~ "glove",
    is_special                                                     ~ "knife",
    !is.na(wear)                                                   ~ "weapon_skin",
    TRUE                                                           ~ "other"
  )

  base_item <- if (!is.na(skin_name)) paste0(weapon, " | ", skin_name) else weapon

  list(
    weapon        = weapon,
    skin_name     = skin_name,
    wear          = wear,
    base_item     = base_item,
    item_category = item_category,
    is_stattrak   = is_stattrak,
    is_special    = is_special,
    is_souvenir   = is_souvenir
  )
}

# ── Process one file ──────────────────────────────────────────────────────────

process_file <- function(filepath) {
  enc_name <- tools::file_path_sans_ext(basename(filepath))
  dec_name <- name_lookup[enc_name]
  if (is.na(dec_name)) dec_name <- URLdecode(enc_name)

  dt <- tryCatch(
    fread(filepath, showProgress = FALSE, select = 1:4),
    error = function(e) NULL
  )
  if (is.null(dt) || nrow(dt) == 0) return(NULL)

  setnames(dt, c("price", "quantity", "date_str", "unix_ts"))

  # Daily VWAP aggregation (handles hourly data in some files)
  dt[, date := as.Date(as.POSIXct(unix_ts, origin = "1970-01-01", tz = "UTC"))]
  dt <- dt[, .(
    price    = sum(price * quantity) / sum(quantity),
    quantity = as.integer(sum(quantity))
  ), by = date]

  meta <- parse_item_name(dec_name)

  dt[, `:=`(
    item_name     = dec_name,
    item_category = meta$item_category,
    weapon        = meta$weapon,
    skin_name     = meta$skin_name,
    wear          = meta$wear,
    base_item     = meta$base_item,
    is_stattrak   = meta$is_stattrak,
    is_special    = meta$is_special,
    is_souvenir   = meta$is_souvenir
  )]

  dt
}

# ── Main loop (batched) ───────────────────────────────────────────────────────

files    <- list.files(ITEMS_DIR, pattern = "\\.csv$", full.names = TRUE)
n_files  <- length(files)
n_batches <- ceiling(n_files / BATCH_SIZE)

message(sprintf("Processing %d files in %d batches...", n_files, n_batches))

batches <- vector("list", n_batches)

for (b in seq_len(n_batches)) {
  idx   <- ((b - 1) * BATCH_SIZE + 1):min(b * BATCH_SIZE, n_files)
  batch <- lapply(files[idx], process_file)
  batches[[b]] <- rbindlist(Filter(Negate(is.null), batch), fill = TRUE)
  message(sprintf("  Batch %d/%d complete (%d/%d files)", b, n_batches, min(b * BATCH_SIZE, n_files), n_files))
}

cs2 <- rbindlist(batches, fill = TRUE)
cs2[, trading_value := price * quantity]

setcolorder(cs2, c(
  "date", "item_name", "item_category", "weapon", "skin_name", "wear",
  "base_item", "is_stattrak", "is_special", "is_souvenir",
  "price", "quantity", "trading_value"
))
setorder(cs2, item_name, date)

# ── Save ──────────────────────────────────────────────────────────────────────

if (!dir.exists(here("data", "processed"))) dir.create(here("data", "processed"), recursive = TRUE)
write_parquet(cs2, OUT_FILE)

# ── Summary ───────────────────────────────────────────────────────────────────

message("\nDone. Output: ", OUT_FILE)
message(sprintf("  Rows:       %s", format(nrow(cs2), big.mark = ",")))
message(sprintf("  Items:      %s", format(uniqueN(cs2$item_name), big.mark = ",")))
message(sprintf("  Date range: %s to %s", min(cs2$date), max(cs2$date)))
message("\nCategory breakdown:")
print(cs2[, .N, by = item_category][order(-N)])
