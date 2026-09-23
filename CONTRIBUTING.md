# Contributing

Add a synthetic test whenever a formula, outcome family, output column, or QC rule changes. Keep configuration examples explicit and avoid study-specific paths or data.

Before opening a change:

```bash
python -m unittest discover -s tests -p "test_*.py" -v
Rscript tests/test_models.R
```

Document whether reported metrics are in-sample, cross-validated, or externally validated.
