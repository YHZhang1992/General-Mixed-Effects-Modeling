# Adaptation checklist

1. Copy the closest example configuration instead of editing the validated example.
2. Define one complete, unique observation ID and a non-missing grouping ID.
3. State the target outcome, population, fixed effects, random structure, link, and interpretation scale.
4. Check observations per group and outcome variation overall and within groups.
5. Center or scale continuous predictors when it improves interpretation or stability.
6. Keep categorical reference levels explicit in the source data or preprocessing step.
7. Start with a scientifically justified random structure; do not select it solely by whichever model converges.
8. Inspect warnings, convergence, singularity, coefficient magnitude, confidence intervals, and residual diagnostics.
9. Use group-aware resampling or an external dataset for prediction assessment.
10. Record package versions, input/config checksums, and expected output changes.
