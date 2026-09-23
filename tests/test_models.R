script_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- sub("^--file=", "", script_argument[1])
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(repo_root, "R", "utils.R"))
source(file.path(repo_root, "R", "mixed_models.R"))
source(file.path(repo_root, "R", "workflow.R"))
stopifnot(requireNamespace("lme4", quietly = TRUE))

cases <- list(
  list(type = "gaussian", input = "synthetic_regression.csv", config = "regression.R"),
  list(type = "binomial", input = "synthetic_classification.csv", config = "classification.R")
)

for (case in cases) {
  output_dir <- tempfile(paste0("mixed-", case$type, "-"))
  result <- run_mixed_effects_analysis(
    file.path(repo_root, "data", case$input),
    file.path(repo_root, "config", case$config),
    output_dir
  )
  expected <- c("fixed_effects.csv", "fitted_values.csv", "diagnostic_metrics.csv", "model_qc.csv", "attrition.csv", "run_manifest.csv")
  stopifnot(all(file.exists(file.path(output_dir, expected))))
  stopifnot(result$qc$outcome_type == case$type)
  stopifnot(result$qc$status %in% c("pass", "review"))
  stopifnot(nrow(result$coefficients) >= 4L)
  stopifnot(all(is.finite(result$coefficients$estimate)))
  stopifnot(nrow(result$predictions) == result$qc$complete_rows)
}
cat("Gaussian and binomial mixed-effects tests passed.\n")
