script_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- sub("^--file=", "", script_argument[1])
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source(file.path(repo_root, "R", "utils.R"))
source(file.path(repo_root, "R", "mixed_models.R"))
source(file.path(repo_root, "R", "workflow.R"))

arguments <- commandArgs(trailingOnly = TRUE)
argument_value <- function(name, default = NULL) {
  index <- match(name, arguments)
  if (is.na(index)) return(default)
  if (index == length(arguments)) stop(sprintf("Missing value after %s", name), call. = FALSE)
  arguments[index + 1]
}

config_path <- argument_value("--config")
input_path <- argument_value("--input")
output_dir <- argument_value("--output", file.path(repo_root, "output"))
if (is.null(config_path) || is.null(input_path)) stop("--config and --input are required.", call. = FALSE)

result <- run_mixed_effects_analysis(input_path, config_path, output_dir)
cat(sprintf("Completed %s model with status: %s\n", result$qc$outcome_type, result$qc$status))
