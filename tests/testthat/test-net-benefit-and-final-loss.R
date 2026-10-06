net_effect_problem <- function(effects, actions = c("a", "b"), features = "habitat",
                               pu = 10L, sets = NULL, concurrent = TRUE) {
  dist <- expand.grid(pu = pu, feature = seq_along(features))
  dist$amount <- 100
  p <- create_problem(data.frame(id = pu, cost = 0),
    data.frame(id = seq_along(features), name = features), dist) |>
    add_actions(data.frame(id = actions), cost = 1)
  if (!is.null(sets)) p <- add_action_sets(p, sets)
  if (concurrent) p <- add_constraint_action_cardinality(p, length(actions), "max")
  add_effects(p, effects)
}

net_lock_allocation <- function(p, selected) {
  pairs <- p$data$dist_actions[, c("pu", "action")]
  keep <- pairs$action %in% selected
  add_constraint_locked_actions(p,
    locked_in = if (any(keep)) pairs[keep, , drop = FALSE] else NULL,
    locked_out = if (any(!keep)) pairs[!keep, , drop = FALSE] else NULL)
}

test_that("benefit uses signed coefficients without changing canonical reporting data", {
  effects <- data.frame(action = c("a", "a", "b", "b"),
    feature = c("habitat", "water", "habitat", "water"), effect = c(100, -90, 20, 0))
  base <- net_effect_problem(effects, features = c("habitat", "water"), concurrent = FALSE)
  p <- base |> add_objective_max_benefit(alias = "benefit") |> compile_model()
  ml <- p$data$model_list
  expect_equal(ml$obj[ml$x_offset + p$data$dist_actions_model$internal_row], c(10, 20))
  expect_identical(p$data$dist_effects, base$data$dist_effects)
  expect_equal(base$data$dist_effects$benefit, pmax(base$data$dist_effects$effect, 0))
  expect_null(base$data$model_ptr)
  skip_if_no_cbc()
  s <- solve(set_solver_cbc(p, gap_limit = 0))
  expect_equal(get_objectives(s)$benefit, 20)
  expect_equal(sum(get_features(s)$selected_net), 20)
  expect_identical(as.character(get_actions(s)$action[get_actions(s)$selected > .5]), "b")
})

test_that("all-negative, zero, and cancelling benefit objectives are valid", {
  skip_if_no_cbc()
  for (values in list(c(-10, -20), c(0, 0))) {
    base <- net_effect_problem(data.frame(action = c("a", "b"), feature = "habitat", effect = values),
      concurrent = FALSE)
    p <- base |> add_constraint_action_cardinality(1, "equal") |>
      add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0)
    expect_equal(get_objectives(solve(p))$benefit, max(values))
    p <- base |> add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0)
    expect_equal(get_objectives(solve(p))$benefit, 0)
  }
  p <- net_effect_problem(data.frame(action = "a", feature = c("habitat", "water"), effect = c(10, -10)),
    actions = "a", features = c("habitat", "water"), concurrent = FALSE) |>
    add_constraint_locked_actions(locked_in = list(a = 10L)) |>
    add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0)
  expect_equal(get_objectives(solve(p))$benefit, 0)
})

test_that("effect, outcome, relative-change and legacy inputs preserve signed benefit", {
  base <- create_problem(data.frame(id = 10L, cost = 0), data.frame(id = 1L, name = "habitat"),
    data.frame(pu = 10L, feature = 1L, amount = 100)) |>
    add_actions(data.frame(id = c("a", "b")), cost = 1)
  tables <- list(
    data.frame(action = c("a", "b"), feature = "habitat", effect = c(20, -10)),
    data.frame(action = c("a", "b"), feature = "habitat", outcome = c(120, 90)),
    data.frame(action = c("a", "b"), feature = "habitat", relative_change = c(.2, -.1)))
  for (table in tables) {
    p <- add_effects(base, table) |> add_objective_max_benefit() |> compile_model()
    expect_equal(p$data$model_list$obj[p$data$model_list$x_offset + 1:2], c(20, -10))
  }
  p <- suppressWarnings(add_effects(base,
    data.frame(pu = 10L, action = c("a", "b"), feature = "habitat", delta = c(20, -10)), effect_type = "delta")) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(p$data$model_list$obj[p$data$model_list$x_offset + 1:2], c(20, -10))
})

test_that("final loss and signed benefit match every allocation of a three-action polynomial", {
  skip_if_no_cbc()
  totals <- c(a = -10, b = 20, c = -5, ab = 5, ac = -30, bc = 12, abc = -2)
  base <- net_effect_problem(data.frame(action = names(totals), feature = "habitat", effect = totals),
    actions = c("a", "b", "c"), sets = list(ab = c("a", "b"), ac = c("a", "c"),
      bc = c("b", "c"), abc = c("a", "b", "c")))
  allocations <- expand.grid(a = 0:1, b = 0:1, c = 0:1)
  for (k in seq_len(nrow(allocations))) {
    selected <- names(allocations)[as.logical(allocations[k, ])]
    expected <- if (!length(selected)) 0 else unname(totals[paste(selected, collapse = "")])
    p <- net_lock_allocation(base, selected)
    benefit <- p |> add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0) |> solve()
    loss <- p |> add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0) |> solve()
    expect_equal(get_objectives(benefit)$benefit, expected, info = paste(selected, collapse = "+"))
    expect_equal(get_objectives(loss)$loss, max(-expected, 0))
    for (s in list(benefit, loss)) {
      f <- get_features(s)
      expect_equal(f$selected_net, expected)
      expect_equal(f$selected_benefit, max(expected, 0))
      expect_equal(f$selected_loss, max(-expected, 0))
      expect_equal(f$selected_amount_after, if (length(selected)) 100 + expected else 0)
    }
  }
})

test_that("negative interactions are not themselves ecological losses", {
  skip_if_no_cbc()
  for (total in c(40, 0, -10)) {
    base <- net_effect_problem(data.frame(action = c("a", "b", "ab"), feature = "habitat",
      effect = c(30, 20, total)), sets = list(ab = c("a", "b"))) |>
      add_constraint_action_cardinality(2, "equal")
    b <- base |> add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0) |> solve()
    l <- base |> add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0) |> solve()
    expect_equal(get_objectives(b)$benefit, total)
    expect_equal(get_objectives(l)$loss, max(-total, 0))
  }
})

test_that("concurrent individual actions are additive and count the reference once", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = c("a", "b"), feature = "habitat", effect = c(30, -20))) |>
    add_constraint_action_cardinality(2, "equal")
  b <- base |> add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0) |> solve()
  l <- base |> add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(get_objectives(b)$benefit, 10)
  expect_equal(get_objectives(l)$loss, 0)
  expect_equal(get_features(l)$selected_baseline, 100)
  expect_equal(get_features(l)$selected_amount_after, 110)
})

test_that("losses are split within PU and feature before summing", {
  skip_if_no_cbc()
  effects <- expand.grid(pu = c(10L, 20L), action = c("a", "b"), feature = c("habitat", "water"))
  effects$effect <- c(30, -20, -10, 10, -20, 30, 10, -10)
  base <- net_effect_problem(effects, features = c("habitat", "water"), pu = c(10L, 20L)) |>
    add_constraint_action_cardinality(2, "equal")
  s <- base |> add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0) |> solve()
  # Net per PU/feature is (20, -10, -10, 20): global net 20, loss 20.
  expect_equal(get_objectives(s)$loss, 20)
  expect_equal(sum(get_features(s)$selected_net), 20)
  expect_equal(sum(get_features(s)$selected_loss), 20)
  expect_equal(sum(get_features(s)$selected_benefit), 40)
})

test_that("loss subsets and overlapping aliases get distinct exact auxiliary expressions", {
  skip_if_no_cbc()
  effects <- data.frame(action = rep(c("a", "b", "ab"), 2), feature = rep(c("habitat", "water"), each = 3),
    effect = c(-10, 20, 5, 20, -30, -40))
  base <- net_effect_problem(effects, features = c("habitat", "water"), sets = list(ab = c("a", "b"))) |>
    add_constraint_action_cardinality(2, "equal") |> add_profit(c(a = 10, b = 9)) |>
    add_objective_max_profit(alias = "profit") |>
    add_objective_max_benefit(alias = "benefit") |>
    add_objective_min_loss(alias = "loss") |>
    add_objective_min_loss(actions = "a", alias = "a_loss") |>
    add_objective_min_loss(features = "habitat", alias = "habitat_loss") |>
    add_objective_min_loss(features = "water", alias = "water_loss") |>
    set_solver_cbc(gap_limit = 0)
  aliases <- c("profit", "benefit", "loss", "a_loss", "habitat_loss", "water_loss")
  weights <- as.data.frame(as.list(stats::setNames(c(1, 0, 0, 0, 0, 0), paste0("weight_", aliases))))
  methods <- list(
    set_method_weighted_sum(base, aliases = aliases, normalize_weights = FALSE,
      runs = set_runs_manual(weights)),
    set_method_epsilon_constraint(base, primary = "profit", aliases = aliases,
      runs = set_runs_manual(data.frame(eps_benefit = -35, eps_loss = 40, eps_a_loss = 10,
        eps_habitat_loss = 0, eps_water_loss = 40))),
    set_method_augmecon(base, primary = "profit", aliases = aliases,
      runs = set_runs_manual(data.frame(eps_benefit = -35, eps_loss = 40, eps_a_loss = 10,
        eps_habitat_loss = 0, eps_water_loss = 40))))
  for (method in methods) {
    s <- solve(method)
    o <- get_objectives(s)
    expect_equal(o$profit, 19)
    expect_equal(o$benefit, -35)
    expect_equal(o$loss, 40)
    expect_equal(o$a_loss, 10)
    expect_equal(o$habitat_loss, 0)
    expect_equal(o$water_loss, 40)
    expect_equal(sum(get_features(s)$selected_loss), o$loss)
  }
})

test_that("targets use joint outcomes and never repeat the reference", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = c("a", "b", "ab"), feature = "habitat",
    effect = c(30, 20, 40)), sets = list(ab = c("a", "b")))
  for (target in c(139, 140)) {
    p <- base |> add_constraint_targets_absolute(target) |> add_objective_min_cost(alias = "cost") |>
      set_solver_cbc(gap_limit = 0)
    s <- solve(p)
    expect_equal(get_objectives(s)$cost, 2)
    expect_equal(get_features(s)$selected_amount_after, 140)
  }
  p <- base |> add_constraint_action_cardinality(2, "equal") |>
    add_constraint_targets_relative(1) |> add_objective_max_benefit(alias = "benefit") |>
    set_solver_cbc(gap_limit = 0)
  expect_equal(get_objectives(solve(p))$benefit, 40)
  p <- base |> add_constraint_action_cardinality(2, "equal") |>
    add_constraint_targets_absolute(150) |> add_objective_min_cost() |> set_solver_cbc(gap_limit = 0)
  expect_error(solve(p), "infeasible")
})

test_that("action-scoped targets credit the reference only for selected scoped actions", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = c("a", "b", "c"), feature = "habitat", effect = c(30, 20, 0)),
    actions = c("a", "b", "c"))
  p <- base |> add_constraint_targets_absolute(145, actions = c("a", "b")) |>
    add_constraint_targets_absolute(130, actions = "a") |>
    add_objective_min_cost(alias = "cost") |> set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_equal(get_objectives(s)$cost, 2)
  expect_equal(get_features(s)$selected_amount_after, 150)
  expect_equal(get_targets(s)$achieved, c(150, 130))
  p <- base |> add_constraint_locked_actions(locked_in = list(c = 10L)) |>
    add_constraint_action_cardinality(0, "max", actions = c("a", "b")) |>
    add_constraint_targets_absolute(100, actions = c("a", "b")) |>
    add_objective_min_cost() |> set_solver_cbc(gap_limit = 0)
  expect_error(solve(p), "infeasible")
})

test_that("mixed signed effects, targets and ecological objectives work in all MO methods", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = c("a", "b", "ab"), feature = "habitat", effect = c(30, 20, 40)),
    sets = list(ab = c("a", "b"))) |>
    add_constraint_targets_absolute(140) |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "benefit") |>
    add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(base, aliases = c("cost", "benefit", "loss"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_benefit = 1, weight_loss = 1))),
    set_method_epsilon_constraint(base, primary = "cost", aliases = c("cost", "benefit", "loss"),
      runs = set_runs_manual(data.frame(eps_benefit = 40, eps_loss = 0))),
    set_method_augmecon(base, primary = "cost", aliases = c("cost", "benefit", "loss"),
      runs = set_runs_manual(data.frame(eps_benefit = 40, eps_loss = 0))))
  for (method in methods) {
    s <- solve(method)
    expect_equal(get_objectives(s)$benefit, 40)
    expect_equal(get_objectives(s)$loss, 0)
    expect_equal(get_objectives(s)$cost, 2)
    expect_equal(get_features(s)$selected_amount_after, 140)
  }
})

test_that("loss primitive validates all inputs before mutation", {
  p <- net_effect_problem(data.frame(action = c("a", "b"), feature = "habitat", effect = c(10, -5))) |>
    add_objective_max_benefit() |> compile_model()
  before <- multiscape:::rcpp_optimization_problem_as_list(p$data$model_ptr)
  valid <- as.integer(p$data$model_list$x_offset + 0:1)
  for (bad in list(as.integer(c(-1, 1)), as.integer(c(NA, 1)), rep(valid[1], 2), as.integer(c(valid[1], 9999)))) {
    expect_error(multiscape:::rcpp_add_effect_loss_variables(p$data$model_ptr, list(valid, bad),
      list(c(10, -5), c(10, -5))), "Invalid|duplicated")
    expect_identical(multiscape:::rcpp_optimization_problem_as_list(p$data$model_ptr), before)
  }
  expect_error(multiscape:::rcpp_add_effect_loss_variables(p$data$model_ptr, list(valid), list(c(10, Inf))), "finite")
  expect_error(multiscape:::rcpp_add_effect_loss_variables(p$data$model_ptr, list(valid), list(c(10, 5))), "mixed-sign")
  expect_identical(multiscape:::rcpp_optimization_problem_as_list(p$data$model_ptr), before)
})

test_that("automatic payoff, scaling and grids evaluate signed objectives consistently", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = c("a", "b", "ab"), feature = "habitat",
    effect = c(-10, 20, -5)), sets = list(ab = c("a", "b"))) |>
    add_constraint_action_cardinality(1, "min") |> add_profit(c(a = 2, b = 1)) |>
    add_objective_max_profit(alias = "profit") |>
    add_objective_max_benefit(alias = "benefit") |>
    add_objective_min_loss(alias = "loss") |> set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(base, aliases = c("profit", "benefit", "loss"),
      objective_scaling = TRUE, normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_profit = c(1, 10), weight_benefit = 1, weight_loss = 1))),
    set_method_epsilon_constraint(base, primary = "profit", aliases = c("profit", "benefit"),
      runs = set_runs_grid(n = 3), lexicographic = TRUE),
    set_method_epsilon_constraint(base, primary = "profit", aliases = c("profit", "loss"),
      runs = set_runs_grid(n = 3), lexicographic = TRUE),
    set_method_augmecon(base, primary = "profit", aliases = c("profit", "benefit", "loss"),
      runs = set_runs_grid(n = 3), lexicographic = TRUE))
  for (method in methods) {
    s <- solve(method)
    o <- get_objectives(s)
    expect_gt(nrow(o), 0)
    for (j in seq_len(nrow(o))) {
      id <- o$solution_id[j]
      a <- get_actions(s, solution = id)
      selected <- sort(as.character(a$action[a$selected > .5]))
      expected <- switch(paste(selected, collapse = ""), a = -10, b = 20, ab = -5)
      if ("benefit" %in% names(o)) expect_equal(o$benefit[j], expected)
      if ("loss" %in% names(o)) expect_equal(o$loss[j], max(-expected, 0))
      f <- get_features(s, solution = id)
      expect_equal(f$selected_net, expected)
      expect_equal(f$selected_loss, max(-expected, 0))
    }
  }
})

test_that("constant net benefit and zero-loss secondary objectives work in all MO methods", {
  skip_if_no_cbc()
  base <- net_effect_problem(data.frame(action = rep(c("a", "b"), 2),
    feature = rep(c("habitat", "water"), each = 2), effect = c(10, 20, -10, -20)),
    features = c("habitat", "water"), concurrent = FALSE) |>
    add_constraint_action_cardinality(1, "equal") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "benefit") |>
    add_objective_min_loss(features = "habitat", alias = "loss") |>
    set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(base, aliases = c("cost", "benefit", "loss"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_benefit = 1, weight_loss = 1))),
    set_method_epsilon_constraint(base, primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_grid(n = 2), lexicographic = TRUE),
    set_method_epsilon_constraint(base, primary = "cost", aliases = c("cost", "loss"),
      runs = set_runs_grid(n = 2), lexicographic = TRUE),
    set_method_augmecon(base, primary = "cost", aliases = c("cost", "benefit", "loss"),
      runs = set_runs_grid(n = 2), lexicographic = TRUE))
  for (method in methods) {
    s <- solve(method)
    if ("benefit" %in% names(get_objectives(s))) expect_equal(get_objectives(s)$benefit, rep(0, nrow(get_objectives(s))))
    if ("loss" %in% names(get_objectives(s))) expect_equal(get_objectives(s)$loss, rep(0, nrow(get_objectives(s))))
    expect_equal(get_objectives(s)$cost, rep(1, nrow(get_objectives(s))))
  }
  impossible <- set_method_epsilon_constraint(base, primary = "cost", aliases = c("cost", "benefit"),
    runs = set_runs_manual(data.frame(eps_benefit = 1)))
  expect_warning(s <- solve(impossible), "infeasible")
  expect_true(all(get_runs(s)$status %in% c("infeasible", "infeasible_or_unbounded")))
  mixed <- set_method_epsilon_constraint(base, primary = "cost", aliases = c("cost", "benefit"),
    runs = set_runs_manual(data.frame(eps_benefit = c(1, 0, 1))))
  expect_warning(s <- solve(mixed), "infeasible")
  expect_equal(get_runs(s)$status, c("infeasible", "optimal", "infeasible"))
  expect_equal(get_objectives(s)$cost, c(NA_real_, 1, NA_real_))
  expect_equal(get_objectives(s)$benefit, c(NA_real_, 0, NA_real_))
})
