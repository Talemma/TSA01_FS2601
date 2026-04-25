# 00_setup.R
# Downloads the CS2 skin market dataset from Kaggle into data/raw/.
#
# Requirements:
#   - Kaggle CLI installed: pip install kaggle
#   - API credentials at ~/.kaggle/kaggle.json
#     (Kaggle → Account → API → Create New Token)

DATASET  <- "kieranpoc/counter-strike-market-sale-data"
DEST_DIR <- here::here("data", "raw")

# ── preflight checks ─────────────────────────────────────────────────────────

if (Sys.which("kaggle") == "") {
  stop(
    "Kaggle CLI not found.\n",
    "Install it with:  pip install kaggle\n",
    "Then add credentials to ~/.kaggle/kaggle.json"
  )
}

if (!file.exists(path.expand("~/.kaggle/kaggle.json"))) {
  stop(
    "~/.kaggle/kaggle.json not found.\n",
    "Go to https://www.kaggle.com/settings → API → Create New Token"
  )
}

if (!dir.exists(DEST_DIR)) dir.create(DEST_DIR, recursive = TRUE)

# ── download ──────────────────────────────────────────────────────────────────

already_present <- length(list.files(DEST_DIR, pattern = "\\.csv$",
                                     recursive = TRUE)) > 0

if (already_present) {
  message("Data already present in ", DEST_DIR, " — skipping download.")
} else {
  message("Downloading dataset from Kaggle (this may take a while ~900 MB)…")

  exit_code <- system(paste(
    "kaggle datasets download",
    "--unzip",
    "-p", shQuote(DEST_DIR),
    shQuote(DATASET)
  ))

  if (exit_code != 0) stop("kaggle download failed (exit code ", exit_code, ")")

  message("Done. Files saved to ", DEST_DIR)
}
