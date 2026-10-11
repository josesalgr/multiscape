# Loss-only regressions intentionally retain the historical criterion.
# Assert its deprecation explicitly instead of treating it as an ordinary API.
expect_legacy_min_loss <- function(...) {
  withr::local_options(lifecycle_verbosity = "warning")
  testthat::expect_warning(
    objective <- multiscape::add_objective_min_loss(...),
    class = "lifecycle_warning_deprecated"
  )
  objective
}
