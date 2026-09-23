# General Mixed-Effects Modeling

A reusable R workflow for both major mixed-effects use cases:

- **Regression:** Gaussian linear mixed models with configurable random intercepts and slopes.
- **Classification:** Binomial generalized linear mixed models with configurable random effects.

The implementation standardizes validation, fitting, warnings, convergence and singularity checks, fixed-effect tables, fitted values, diagnostic metrics, attrition, and run provenance. It generalizes mixed-model patterns found in the working-folder longitudinal GSVA and clinical workflows without copying study data or study-specific code.

## Quick start

Requirements: Python 3.11+ for contract tests and R 4.3+ with `lme4` for model execution.

```bash
python -m unittest discover -s tests -p "test_*.py" -v
Rscript tests/test_models.R

Rscript scripts/run_model.R \
  --input data/synthetic_regression.csv \
  --config config/regression.R \
  --output output/regression

Rscript scripts/run_model.R \
  --input data/synthetic_classification.csv \
  --config config/classification.R \
  --output output/classification
```

## Outputs

- `fixed_effects.csv` — estimates, standard errors, Wald intervals, p-values, and odds ratios for binomial models.
- `fitted_values.csv` — observed and fitted values with residuals.
- `diagnostic_metrics.csv` — explicitly in-sample diagnostics, not validation claims.
- `model_qc.csv` — group/event counts, convergence, singularity, formula, and warnings.
- `attrition.csv` and `run_manifest.csv` — row accounting and reproducibility metadata.

## Boundaries

The examples demonstrate mechanics on synthetic data. Formula choice, random-effects structure, covariates, estimand, missing-data handling, and validation design require domain review. A converged fit is not automatically scientifically interpretable or predictive.
