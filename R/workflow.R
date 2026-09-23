run_mixed_effects_analysis <- function(input_path, config_path, output_dir) {
  config <- load_model_config(config_path)
  raw <- utils::read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
  result <- fit_mixed_effects_model(raw, config)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write_table(result$coefficients, file.path(output_dir, "fixed_effects.csv"))
  write_table(result$predictions, file.path(output_dir, "fitted_values.csv"))
  write_table(result$metrics, file.path(output_dir, "diagnostic_metrics.csv"))
  write_table(result$qc, file.path(output_dir, "model_qc.csv"))
  attrition <- data.frame(stage = c("input", "complete_model_records"), records = c(nrow(raw), nrow(result$model_data)))
  write_table(attrition, file.path(output_dir, "attrition.csv"))
  manifest <- data.frame(
    analysis_id = config$analysis_id, run_time_utc = utc_now(), r_version = R.version.string,
    input = normalizePath(input_path, mustWork = TRUE), input_checksum = sha256_file(input_path),
    config = normalizePath(config_path, mustWork = TRUE), config_checksum = sha256_file(config_path),
    outcome_type = config$outcome_type, model_status = result$qc$status, stringsAsFactors = FALSE
  )
  write_table(manifest, file.path(output_dir, "run_manifest.csv"))
  invisible(c(result, list(attrition = attrition, manifest = manifest)))
}
