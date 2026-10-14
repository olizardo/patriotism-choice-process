#!/usr/bin/env Rscript
# Setup script to initialize renv and install project dependencies

options(repos = c(CRAN = 'https://cloud.r-project.org'))

cat("Initializing renv...\n")
renv::init()

cat("\nInstalling project dependencies...\n")
packages <- c("gssr", "dplyr", "tidyr", "modelsummary")
renv::install(packages)

cat("\nSnapshotting project state to renv.lock...\n")
renv::snapshot()

cat("\n✓ renv setup complete!\n")
cat("  Packages installed: gssr, dplyr, tidyr, modelsummary\n")
cat("  Lock file: renv.lock\n")
cat("\nTo restore this environment in the future, run:\n")
cat("  renv::restore()\n")
