prepare_model_data <- function(data, config) {
  formula <- stats::as.formula(config$formula)
  required <- unique(c(config$observation_id, config$group, all.vars(formula)))
  missing <- setdiff(required, names(data))
  if (length(missing)) stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")), call. = FALSE)
  if (anyNA(data[[config$observation_id]]) || anyDuplicated(data[[config$observation_id]])) {
    stop("Observation IDs must be complete and unique.", call. = FALSE)
  }
  if (anyNA(data[[config$group]])) stop("Grouping IDs cannot be missing.", call. = FALSE)
  model_data <- data[stats::complete.cases(data[required]), required, drop = FALSE]
  if (!nrow(model_data)) stop("No complete model records are available.", call. = FALSE)
  model_data[[config$group]] <- factor(model_data[[config$group]])
  model_data[[config$outcome]] <- suppressWarnings(as.numeric(model_data[[config$outcome]]))
  if (anyNA(model_data[[config$outcome]])) stop("Outcome must be numeric.", call. = FALSE)
  if (config$outcome_type == "binomial" && !all(model_data[[config$outcome]] %in% c(0, 1))) {
    stop("Binomial outcomes must be coded 0/1.", call. = FALSE)
  }
  if (nlevels(model_data[[config$group]]) < 3L) stop("At least three groups are required.", call. = FALSE)
  list(data = model_data, required = required, formula = formula, input_rows = nrow(data))
}

failed_coefficients <- function(config, message) {
  data.frame(
    outcome_type = config$outcome_type, term = "(model fit)", estimate = NA_real_, standard_error = NA_real_,
    confidence_lower = NA_real_, confidence_upper = NA_real_, p_value = NA_real_, transformed_estimate = NA_real_,
    transformed_scale = if (config$outcome_type == "binomial") "odds ratio" else "identity",
    model_status = "failed", warnings = message, formula = config$formula, stringsAsFactors = FALSE
  )
}

fit_mixed_effects_model <- function(data, config) {
  prepared <- prepare_model_data(data, config)
  model_data <- prepared$data
  formula <- prepared$formula
  group_sizes <- table(model_data[[config$group]])
  outcome <- model_data[[config$outcome]]
  events <- if (config$outcome_type == "binomial") sum(outcome == 1) else NA_integer_
  non_events <- if (config$outcome_type == "binomial") sum(outcome == 0) else NA_integer_
  groups_without_both_classes <- if (config$outcome_type == "binomial") {
    sum(vapply(split(outcome, model_data[[config$group]]), function(values) length(unique(values)) < 2L, logical(1)))
  } else NA_integer_

  fit_attempt <- if (config$outcome_type == "gaussian") {
    capture_conditions(lme4::lmer(formula, data = model_data, REML = config$reml, control = lme4::lmerControl(optimizer = "bobyqa")))
  } else {
    capture_conditions(lme4::glmer(formula, data = model_data, family = stats::binomial(), control = lme4::glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))))
  }

  if (is_captured_error(fit_attempt$value)) {
    message <- collapse_messages(c(fit_attempt$warnings, fit_attempt$value$message))
    qc <- data.frame(
      outcome_type = config$outcome_type, status = "failed", input_rows = prepared$input_rows,
      complete_rows = nrow(model_data), groups = length(group_sizes), minimum_group_size = min(group_sizes),
      events = events, non_events = non_events, groups_without_both_classes = groups_without_both_classes,
      singular = NA, convergence = "failed", warnings = message, formula = config$formula,
      stringsAsFactors = FALSE
    )
    return(list(model = NULL, coefficients = failed_coefficients(config, message), predictions = data.frame(), metrics = data.frame(), qc = qc, model_data = model_data))
  }

  fit <- fit_attempt$value
  coefficient_table <- stats::coef(summary(fit))
  estimate <- coefficient_table[, "Estimate"]
  standard_error <- coefficient_table[, "Std. Error"]
  p_value <- if ("Pr(>|z|)" %in% colnames(coefficient_table)) coefficient_table[, "Pr(>|z|)"] else 2 * stats::pnorm(-abs(estimate / standard_error))
  lower <- estimate - 1.96 * standard_error
  upper <- estimate + 1.96 * standard_error
  convergence_messages <- fit@optinfo$conv$lme4$messages
  singular <- lme4::isSingular(fit, tol = config$singular_tolerance)
  messages <- collapse_messages(c(fit_attempt$warnings, convergence_messages))
  status <- if (singular || length(fit_attempt$warnings) || length(convergence_messages)) "review" else "pass"
  coefficients <- data.frame(
    outcome_type = config$outcome_type, term = rownames(coefficient_table), estimate = estimate,
    standard_error = standard_error, confidence_lower = lower, confidence_upper = upper, p_value = p_value,
    transformed_estimate = if (config$outcome_type == "binomial") exp(estimate) else estimate,
    transformed_scale = if (config$outcome_type == "binomial") "odds ratio" else "identity",
    model_status = status, warnings = messages, formula = config$formula,
    stringsAsFactors = FALSE, row.names = NULL
  )

  fitted_value <- if (config$outcome_type == "binomial") stats::predict(fit, type = "response") else stats::predict(fit)
  predictions <- data.frame(
    observation_id = model_data[[config$observation_id]], group_id = as.character(model_data[[config$group]]),
    observed = outcome, fitted = as.numeric(fitted_value), residual = outcome - as.numeric(fitted_value),
    stringsAsFactors = FALSE
  )
  if (config$outcome_type == "gaussian") {
    metrics <- data.frame(
      outcome_type = "gaussian", evaluation = "in-sample diagnostic",
      rmse = sqrt(mean(predictions$residual^2)), mae = mean(abs(predictions$residual)),
      accuracy = NA_real_, brier_score = NA_real_, log_loss = NA_real_, auc = NA_real_
    )
  } else {
    probability <- pmin(pmax(predictions$fitted, 1e-12), 1 - 1e-12)
    threshold <- config$classification_threshold
    metrics <- data.frame(
      outcome_type = "binomial", evaluation = "in-sample diagnostic",
      rmse = NA_real_, mae = NA_real_, accuracy = mean((probability >= threshold) == outcome),
      brier_score = mean((probability - outcome)^2),
      log_loss = -mean(outcome * log(probability) + (1 - outcome) * log(1 - probability)),
      auc = binary_auc(outcome, probability)
    )
  }
  qc <- data.frame(
    outcome_type = config$outcome_type, status = status, input_rows = prepared$input_rows,
    complete_rows = nrow(model_data), groups = length(group_sizes), minimum_group_size = min(group_sizes),
    events = events, non_events = non_events, groups_without_both_classes = groups_without_both_classes,
    singular = singular, convergence = if (length(convergence_messages)) "review" else "completed",
    warnings = messages, formula = config$formula, stringsAsFactors = FALSE
  )
  list(model = fit, coefficients = coefficients, predictions = predictions, metrics = metrics, qc = qc, model_data = model_data)
}
