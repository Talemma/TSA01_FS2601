# Project Setup

## Requirements

- [R](https://cran.r-project.org/) >= 4.5.3
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/TSA01_FS2601.git
cd TSA01_FS2601
```

### 2. Open the project

Open `TSA01_FS2601.Rproj` in RStudio. This ensures the working directory and renv are activated automatically.

### 3. Restore the package library

On first use, install renv if you don't have it, then restore all packages from the lockfile:

```r
install.packages("renv")
renv::restore()
```

This will install every package at the exact version recorded in `renv.lock`. No manual package installation is needed beyond this step.

### 4. Download the data

The raw data (~900 MB) is not included in the repository. Download it from Kaggle using the provided setup script.

**4a. Install the Kaggle CLI** (Python required):

```bash
pip install kaggle
```

**4b. Get your Kaggle API token:**

1. Log in at [kaggle.com](https://www.kaggle.com)
2. Go to **Account → API → Create New Token**
3. Move the downloaded `kaggle.json` to `~/.kaggle/kaggle.json`
4. Restrict permissions (Linux/macOS): `chmod 600 ~/.kaggle/kaggle.json`

**4c. Run the setup script in R:**

```r
source("src/00_setup.R")
```

This downloads and unzips the dataset into `data/raw/`. The script is safe to re-run — it skips the download if the files are already present.

## Project Structure

```
TSA01_FS2601/
├── data/          # Raw and processed data
├── src/           # R scripts
├── docs/          # Documentation
├── images/        # Figures and plots
├── latex/         # LaTeX files
├── renv/          # renv infrastructure (do not edit manually)
├── renv.lock      # Pinned package versions
└── TSA01_FS2601.Rproj
```

## Managing Packages

| Task | Command |
|---|---|
| Install a new package | `renv::install("packagename")` |
| Record changes to the lockfile | `renv::snapshot()` |
| Sync your library to the lockfile | `renv::restore()` |
| Check for drift between library and lockfile | `renv::status()` |

After installing new packages, always run `renv::snapshot()` and commit the updated `renv.lock`.
