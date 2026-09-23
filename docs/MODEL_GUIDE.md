# Model guide

## Gaussian mixed regression

Use when the conditional outcome is approximately continuous and the residual/random-effect assumptions are defensible. The example includes a random intercept and random time slope. Review residual patterns, random-effect variance, singularity, influential groups, and sensitivity to the random structure.

## Binomial mixed classification

Use for a repeated or clustered 0/1 outcome. The example uses a logit link and group random intercept. Review outcomes within clusters, separation, convergence, singularity, coefficient magnitude, calibration, and uncertainty.

The exported metrics are explicitly labeled **in-sample diagnostic**. They do not establish predictive performance. Prediction claims require group-aware resampling or external validation, plus discrimination and calibration assessment.

## Interpretation

- Gaussian fixed effects are conditional mean differences on the outcome scale.
- Binomial fixed effects are conditional log odds; exponentiated values are conditional odds ratios.
- Random effects describe modeled cluster heterogeneity, not unexplained causal effects.
- A singular model should trigger random-structure review rather than automatic interpretation.
