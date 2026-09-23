config <- list(
  analysis_id = "synthetic-mixed-classification-v1",
  outcome_type = "binomial",
  formula = "outcome ~ time + exposure + covariate + (1 | group_id)",
  outcome = "outcome",
  group = "group_id",
  observation_id = "observation_id",
  reml = FALSE,
  singular_tolerance = 1e-4,
  classification_threshold = 0.5
)
