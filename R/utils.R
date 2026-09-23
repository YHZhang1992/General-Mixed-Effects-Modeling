load_model_config <- function(path) {
  environment <- new.env(parent = baseenv())
  sys.source(path, envir = environment)
  if (!exists("config", envir = environment, inherits = FALSE)) stop("Configuration must define 'config'.", call. = FALSE)
  config <- get("config", envir = environment, inherits = FALSE)
  required <- c("analysis_id", "outcome_type", "formula", "outcome", "group", "observation_id", "reml", "singular_tolerance", "classification_threshold")
  missing <- setdiff(required, names(config))
  if (length(missing)) stop(sprintf("Configuration is missing: %s", paste(missing, collapse = ", ")), call. = FALSE)
  if (!(config$outcome_type %in% c("gaussian", "binomial"))) stop("outcome_type must be gaussian or binomial.", call. = FALSE)
  config
}

capture_conditions <- function(expression) {
  warnings <- character()
  value <- tryCatch(
    withCallingHandlers(
      expression,
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) structure(list(message = conditionMessage(condition)), class = "captured_error")
  )
  list(value = value, warnings = unique(warnings))
}

is_captured_error <- function(value) inherits(value, "captured_error")

collapse_messages <- function(messages) {
  messages <- unique(messages[nzchar(messages)])
  if (length(messages)) paste(messages, collapse = " | ") else ""
}

write_table <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

sha256_file <- function(path) {
  command <- Sys.which("sha256sum")
  if (nzchar(command)) return(strsplit(system2(command, shQuote(path), stdout = TRUE), "[[:space:]]+")[[1]][1])
  unname(tools::md5sum(path))
}

utc_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)

binary_auc <- function(observed, probability) {
  positives <- probability[observed == 1]
  negatives <- probability[observed == 0]
  if (!length(positives) || !length(negatives)) return(NA_real_)
  comparisons <- outer(positives, negatives, "-")
  (sum(comparisons > 0) + 0.5 * sum(comparisons == 0)) / length(comparisons)
}
