make_coverage_mo_problem <- function() {
  p <- make_round3_action_problem(with_effects = TRUE) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_manual(data.frame(
        weight_cost = 0.5, weight_benefit = 0.5
      ))
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)
  p
}


test_that("weighted payoff ranges are computed from objective anchors", {
  skip_if_no_cbc()
  compute_ranges <- getFromNamespace(
    ".pamo_compute_weighted_ranges", "multiscape"
  )
  p <- make_coverage_mo_problem()
  ranges <- compute_ranges(p, c("cost", "benefit"), verbose = FALSE)
  expect_identical(names(ranges), c("cost", "benefit"))
  expect_true(all(is.finite(ranges) & ranges > 0))
  expect_error(compute_ranges(p, character()), "aliases must be non-empty")
})


test_that("MO objective vector builder reports unsupported subsets and terms", {
  skip_if_no_cbc()
  objvec <- getFromNamespace(".pamo_objvec_from_ir", "multiscape")
  base <- multiscape::compile_model(make_coverage_mo_problem())

  expect_error(
    objvec(base, list(terms = list(list(type = "pu_cost", features = 1)))),
    "Subset by features"
  )
  expect_error(
    objvec(base, list(terms = list(list(
      type = "boundary_cut", relation_name = "missing"
    )))),
    "Missing relation"
  )
  expect_error(
    objvec(base, list(terms = list(list(
      type = "net_profit", features = 1,
      include_pu_cost = TRUE, include_action_cost = FALSE
    )))),
    "Subset by features"
  )
  expect_error(
    objvec(base, list(terms = list(list(
      type = "intervention_impact", features = 1, actions = NULL
    )))),
    "non-empty action subset"
  )
  expect_error(
    objvec(base, list(terms = list(list(type = "custom")))),
    "custom objectives"
  )
  expect_error(
    objvec(base, list(terms = list(list(type = "not-a-term")))),
    "Unknown term type"
  )

  no_actions <- multiscape::compile_model(make_coverage_mo_problem())
  no_actions$data$actions <- NULL
  expect_error(
    objvec(no_actions, list(terms = list(list(
      type = "action_cost", actions = "restoration"
    )))),
    "actions is missing"
  )

  bad_features <- multiscape::compile_model(make_coverage_mo_problem())
  bad_features$data$features$internal_id <- NULL
  expect_error(
    objvec(bad_features, list(terms = list(list(
      type = "benefit", features = "sp1"
    )))),
    "must contain 'id' and 'internal_id'"
  )
})


test_that("canonical alias evaluation validates aliases and objective senses", {
  skip_if_no_cbc()
  evaluate <- getFromNamespace(
    ".pamo_eval_alias_canonical_on_solution", "multiscape"
  )
  p <- make_coverage_mo_problem()
  out <- multiscape::solve(p)
  sol <- out$solution$solutions[[1]]

  expect_true(is.finite(evaluate(p, sol, "cost")))
  expect_true(is.finite(evaluate(p, sol, "benefit")))
  expect_error(evaluate(p, sol, ""), "non-empty")

  bad <- make_coverage_mo_problem()
  bad$data$objectives$cost$sense <- "sideways"
  expect_error(evaluate(bad, sol, "cost"), "invalid sense")
})
