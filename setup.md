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
