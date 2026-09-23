config <- list(
  analysis_id = "synthetic-mixed-regression-v1",
  outcome_type = "gaussian",
  formula = "outcome ~ time + exposure + covariate + (1 + time | group_id)",
  outcome = "outcome",
  group = "group_id",
  observation_id = "observation_id",
  reml = FALSE,
  singular_tolerance = 1e-4,
  classification_threshold = NA_real_
)
