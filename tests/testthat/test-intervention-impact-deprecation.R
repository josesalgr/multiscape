impact_transition_problem <- function(fixed_effort = TRUE) {
  p <- create_problem(
    data.frame(id = 1:4, cost = c(1, 3, 2, 4), area = 1),
    data.frame(id = 1:2, name = c("carbon", "water")),
    data.frame(pu = rep(1:4, 2), feature = rep(1:2, each = 4),
      amount = c(.1, .3, .6, .9, .8, .2, .4, .7))) |>
    add_actions(data.frame(id = "restore"),
      cost = data.frame(pu = 1:4, action = "restore", cost = c(1, 3, 2, 4)))
  if (fixed_effort) p <- add_constraint_area(p, 2, "equal", tolerance = 0, actions = "restore")
  p
}

test_that("intervention impact warns with lifecycle and preserves the legacy definition", {
  p <- impact_transition_problem()
  lifecycle::expect_deprecated(old <- add_objective_min_intervention_impact(
    p, features = "carbon", actions = "restore", alias = "impact"))
  expect_identical(old$data$objectives$impact$objective_id, "min_intervention_impact")
  expect_identical(old$data$objectives$impact$sense, "min")
  expect_equal(old$data$objectives$impact$objective_args,
    list(impact_col = "amount", features = 1L, actions = "restore"))
  expect_length(p$data$objectives, 0)
  expect_null(old$data$dist_effects)
  withr::local_options(lifecycle_verbosity = "warning")
  expect_warning(add_objective_min_intervention_impact(p),
    "removed in a future version.*add_effects.*add_objective_max_benefit.*original behavior")
})

test_that("legacy validation and repeated-call errors survive deprecation", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- impact_transition_problem()
  expect_error(add_objective_min_intervention_impact(p, impact_col = "missing"), "not found")
  expect_error(add_objective_min_intervention_impact(p, features = "missing"), "did not match|Unknown|unknown")
  expect_error(add_objective_min_intervention_impact(p, actions = "missing"), "did not match|Unknown|unknown")
  old <- add_objective_min_intervention_impact(p, alias = "impact")
  expect_error(add_objective_min_intervention_impact(old, alias = "impact"), "already|registered|Duplicate")
  one <- add_objective_min_intervention_impact(p)
  expect_error(add_objective_min_intervention_impact(one), "already|single objective")
})

test_that("fixed-effort deficits match legacy values for every allocation", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  base <- impact_transition_problem()
  modern <- add_effects(base, data.frame(action = "restore", feature = 1:2, outcome = c(1, 2)))
  for (selected in combn(1:4, 2, simplify = FALSE)) {
    locks <- list(restore = selected)
    old <- base |>
      add_constraint_locked_actions(locked_in = locks) |>
      add_objective_min_intervention_impact(features = "carbon", alias = "impact") |>
      set_solver_cbc(gap_limit = 0) |> solve()
    new <- modern |>
      add_constraint_locked_actions(locked_in = locks) |>
      add_objective_max_benefit(features = "carbon", alias = "benefit") |>
      set_solver_cbc(gap_limit = 0) |> solve()
    expect_equal(get_objectives(new)$benefit, 2 - get_objectives(old)$impact)
    expect_equal(get_features(new)$selected_net[get_features(new)$feature == 1],
      get_objectives(new)$benefit)
    expect_equal(get_actions(new)$selected, get_actions(old)$selected)
  }
})

test_that("fixed-effort migration preserves trade-offs in all three MO methods", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  base <- impact_transition_problem() |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE)
  old <- base |>
    add_objective_min_intervention_impact(features = "carbon", actions = "restore", alias = "impact") |>
    set_solver_cbc(gap_limit = 0)
  new <- base |>
    add_effects(data.frame(action = "restore", feature = "carbon", outcome = 1)) |>
    add_objective_max_benefit(features = "carbon", actions = "restore", alias = "benefit") |>
    set_solver_cbc(gap_limit = 0)
  methods_old <- list(
    set_method_weighted_sum(old, aliases = c("cost", "impact"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = c(1, 0), weight_impact = c(0, 1)))),
    set_method_epsilon_constraint(old, primary = "cost", aliases = c("cost", "impact"),
      runs = set_runs_manual(data.frame(eps_impact = c(.4, 1.5)))),
    set_method_augmecon(old, primary = "cost", aliases = c("cost", "impact"),
      runs = set_runs_manual(data.frame(eps_impact = c(.4, 1.5)))))
  methods_new <- list(
    set_method_weighted_sum(new, aliases = c("cost", "benefit"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = c(1, 0), weight_benefit = c(0, 1)))),
    set_method_epsilon_constraint(new, primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 2 - c(.4, 1.5)))),
    set_method_augmecon(new, primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 2 - c(.4, 1.5)))))
  for (i in seq_along(methods_old)) {
    a <- solve(methods_old[[i]])
    b <- solve(methods_new[[i]])
    expect_equal(get_objectives(b)$cost, get_objectives(a)$cost)
    expect_equal(get_objectives(b)$benefit, 2 - get_objectives(a)$impact)
    expect_equal(get_actions(b)$selected, get_actions(a)$selected)
  }
})

test_that("variable effort is not treated as an automatic equivalent replacement", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  base <- impact_transition_problem(fixed_effort = FALSE)
  old <- base |> add_objective_min_intervention_impact(features = "carbon", alias = "impact") |>
    set_solver_cbc(gap_limit = 0) |> solve()
  new <- base |> add_effects(data.frame(action = "restore", feature = "carbon", outcome = 1)) |>
    add_objective_max_benefit(features = "carbon", alias = "benefit") |>
    set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(sum(get_actions(old)$selected), 0)
  expect_equal(sum(get_actions(new)$selected), 4)
})

test_that("the restoration vignette cache contains coherent modern benefit results", {
  cache <- testthat::test_path("..", "..", "vignettes", "data",
    "integrated-ecosystem-services-solutions.rds")
  skip_if_not(file.exists(cache), "Source vignette cache is unavailable")
  s <- readRDS(cache)
  migration <- s$meta$evaluation_migration
  services <- names(migration$ceilings)
  specs <- s$problem$data$objectives[services]
  expect_true(all(vapply(specs, function(sp) sp$objective_id == "max_benefit" && sp$sense == "max", logical(1))))
  expect_false(migration$reoptimized)
  expect_equal(length(s$solution$solutions), migration$verified_decisions)
  for (one in s$solution$solutions) {
    selected <- one$summary$actions
    ids <- selected$pu[selected$action == "restoration" & selected$selected > .5]
    expect_equal(length(ids), migration$restoration_units)
    df <- s$problem$data$dist_features
    amounts <- tapply(df$amount[df$pu %in% ids], df$internal_feature[df$pu %in% ids], sum)
    feature_ids <- vapply(specs, function(sp) sp$objective_args$features, integer(1))
    expected <- migration$restoration_units * migration$ceilings -
      as.numeric(amounts[as.character(feature_ids)])
    expect_equal(one$solution$alias_values[services], expected, tolerance = 1e-8)
    expect_true(all(one$solution$alias_values[services] >= one$method$eps[services] - 1e-6))
    expect_equal(length(one$solution$vector), length(s$problem$data$model_list$obj))
    f <- one$summary$features
    expect_equal(f$selected_net[match(feature_ids, f$feature)], unname(expected), tolerance = 1e-8)
  }
})
