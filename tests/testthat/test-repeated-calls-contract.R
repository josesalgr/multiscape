contract_base <- function() {
  create_problem(
    pu = data.frame(id = 1:3, cost = 1, area = 10, alternate_area = 5),
    features = data.frame(id = 1:2, name = c("woodland", "water")),
    dist_features = data.frame(pu = rep(1:3, each = 2), feature = 1:2, amount = 100)
  )
}

contract_actions <- function() {
  add_actions(contract_base(), data.frame(id = c("a", "b", "c")), cost = 1)
}

contract_mo <- function() {
  contract_actions() |>
    add_profit(c(a = 5, b = 3, c = 1)) |>
    add_objective_min_cost(alias = "cost") |>
    add_objective_max_profit(alias = "profit")
}

test_that("action catalogs cannot be replaced, expanded, or reordered", {
  p <- contract_actions()
  original <- serialize(p$data, NULL)
  for (ids in list(c("a", "b", "c"), c("aa", "a", "b", "c"), c("c", "b", "a"))) {
    expect_error(add_actions(p, data.frame(id = ids)), "Action catalog already defined")
  }
  expect_identical(serialize(p$data, NULL), original)
  expect_null(contract_base()$data$actions)
})

test_that("effects are single-assignment including explicit zeros and empty filtered results", {
  base <- contract_actions()
  p <- add_effects(base, data.frame(action = "b", feature = 1, effect = 20))
  original <- serialize(p$data, NULL)
  for (effect in c(0, 20, -10)) {
    expect_error(add_effects(p, data.frame(action = "a", feature = 1, effect = effect)),
                 "Effects already defined")
  }
  expect_error(add_benefits(p, NULL), "Effects already defined")
  expect_error(add_losses(p, NULL), "Effects already defined")
  expect_identical(serialize(p$data, NULL), original)
  zero <- add_effects(base, NULL)
  expect_error(add_effects(zero, NULL), "Effects already defined")
  expect_null(base$data$dist_effects)
  alternative <- add_effects(base, data.frame(action = "a", feature = 1, effect = 10))
  expect_equal(alternative$data$dist_effects$effect, rep(10, 3))
})

test_that("legacy wrappers share the canonical effects assignment", {
  base <- contract_actions()
  benefit <- suppressWarnings(add_benefits(base, data.frame(pu = 1, action = "a", feature = 1, benefit = 2)))
  loss <- suppressWarnings(add_losses(base, data.frame(pu = 1, action = "a", feature = 1, loss = 2)))
  for (p in list(benefit, loss)) {
    expect_error(add_effects(p, NULL), "Effects already defined")
    expect_error(add_benefits(p, NULL), "Effects already defined")
    expect_error(add_losses(p, NULL), "Effects already defined")
  }
  # Even a legacy mirror without the canonical field cannot bypass the guard.
  legacy <- multiscape:::.pa_clone_data(benefit)
  legacy$data$dist_effects <- NULL
  expect_error(add_effects(legacy, NULL), "Effects already defined")
})

test_that("profit is single-assignment even when its sparse table is empty", {
  base <- contract_actions()
  for (value in list(NULL, 0, c(a = 5))) {
    p <- add_profit(base, value)
    original <- serialize(p$data, NULL)
    expect_error(add_profit(p, 7), "Profit already defined")
    expect_error(add_profit(p, value), "Profit already defined")
    expect_identical(serialize(p$data, NULL), original)
  }
  expect_null(base$data$dist_profit)
})

test_that("solver defaults allow a first call and every solver wrapper rejects a second", {
  base <- contract_base()
  multiscape:::.pa_get_solve_args(base)
  expect_null(base$data$solve_args)
  p <- set_solver(base)
  original <- serialize(p$data, NULL)
  for (setter in list(set_solver, set_solver_cbc, set_solver_gurobi,
                      set_solver_cplex, set_solver_symphony)) {
    expect_error(setter(p), "Solver configuration already defined")
  }
  expect_identical(serialize(p$data, NULL), original)
  expect_equal(set_solver_cbc(base, gap_limit = 0.001)$data$solve_args$gap_limit, 0.001)
  expect_equal(set_solver_gurobi(base)$data$solve_args$solver, "gurobi")
})

test_that("all pairs of MO method setters reject a second method", {
  base <- contract_mo()
  setters <- list(
    function(p) set_method_weighted_sum(p, aliases = c("cost", "profit"),
                                       runs = set_runs_manual(data.frame(weight_cost = 1, weight_profit = 1))),
    function(p) set_method_epsilon_constraint(p, primary = "cost", aliases = c("cost", "profit"),
                                             runs = set_runs_manual(data.frame(eps_profit = c(1, 3)))),
    function(p) set_method_augmecon(p, primary = "cost", aliases = c("cost", "profit"),
                                  runs = set_runs_grid(n = 2))
  )
  for (first in setters) {
    p <- first(base)
    original <- serialize(p$data, NULL)
    for (second in setters) expect_error(second(p), "Multi-objective method already defined")
    expect_identical(serialize(p$data, NULL), original)
  }
  expect_null(base$data$method)
})

test_that("single objectives are fixed while distinct aliased objectives accumulate", {
  base <- contract_actions() |> add_profit(5)
  p <- add_objective_min_cost(base)
  original <- serialize(p$data, NULL)
  expect_error(add_objective_min_cost(p), "single-objective definition already exists")
  expect_error(add_objective_max_profit(p), "single-objective definition already exists")
  aliased <- p |> add_objective_min_cost(alias = "cost") |> add_objective_max_profit(alias = "profit")
  expect_named(aliased$data$objectives, c("cost", "profit"))
  expect_identical(aliased$data$model_args, p$data$model_args)
  expect_error(add_objective_max_profit(aliased), "single-objective definition already exists")
  expect_error(add_objective_max_profit(aliased, alias = "cost"), "already exists")
  expect_identical(serialize(p$data, NULL), original)
  mo <- base |> add_objective_min_cost(alias = "cost") |> add_objective_max_profit(alias = "profit")
  expect_no_error(single <- add_objective_min_cost(mo))
  expect_error(add_objective_min_cost(single), "single-objective definition already exists")
})

test_that("targets accumulate across features and scopes but reject duplicate identities immediately", {
  base <- contract_actions()
  p <- base |>
    add_constraint_targets_absolute(10, features = 1, actions = c("b", "a"), label = "first") |>
    add_constraint_targets_relative(0.1, features = 2, actions = c("a", "b")) |>
    add_constraint_targets_absolute(5, features = 1, actions = "c")
  original <- serialize(p$data, NULL)
  expect_equal(nrow(p$data$targets), 3)
  expect_error(add_constraint_targets_absolute(p, 20, features = 1, actions = c("a", "b"),
                                              label = "different"), "target already exists")
  expect_error(add_constraint_targets_relative(p, 0.2, features = 1, actions = c("b", "a", "b")),
               "target already exists")
  expect_identical(serialize(p$data, NULL), original)
  total <- add_constraint_targets_absolute(base, 10, features = 1)
  expect_error(add_constraint_targets_relative(total, 0.2, features = 1), "target already exists")
  expect_null(base$data$targets)
})

test_that("legacy action labels and IDs identify the same target scope", {
  p <- add_actions(contract_base(), data.frame(id = c("a", "b", "c"),
                                              action_set = c("habitat", "habitat", "other")))
  p <- add_constraint_targets_absolute(p, 10, features = 1, actions = "habitat")
  expect_error(add_constraint_targets_relative(p, 0.2, features = 1, actions = c("a", "b")),
               "target already exists")
})

test_that("planning-unit locks accumulate, preserve omitted arguments, and reject inversion", {
  base <- contract_actions()
  p <- base |> add_constraint_locked_planning_units(locked_in = 1) |>
    add_constraint_locked_planning_units(locked_out = 2) |>
    add_constraint_locked_planning_units(locked_in = 3)
  expect_identical(p$data$pu$locked_in, c(TRUE, FALSE, TRUE))
  expect_identical(p$data$pu$locked_out, c(FALSE, TRUE, FALSE))
  same <- add_constraint_locked_planning_units(p, locked_in = c(1, 3), locked_out = 2)
  expect_identical(same$data$pu, p$data$pu)
  expect_identical(add_constraint_locked_planning_units(p)$data$pu, p$data$pu)
  original <- serialize(p$data, NULL)
  expect_error(add_constraint_locked_planning_units(p, locked_out = 1), "both locked_in and locked_out")
  expect_error(add_constraint_locked_planning_units(p, locked_in = 2), "both locked_in and locked_out")
  expect_identical(serialize(p$data, NULL), original)
  expect_false(any(base$data$pu$locked_in | base$data$pu$locked_out))
})

test_that("action locks accumulate and repeated states are idempotent", {
  base <- contract_actions()
  p <- base |> add_constraint_locked_actions(locked_in = list(a = 1)) |>
    add_constraint_locked_actions(locked_out = list(b = 2))
  original <- serialize(p$data, NULL)
  expect_equal(sum(p$data$dist_actions$status == 2), 1)
  expect_equal(sum(p$data$dist_actions$status == 3), 1)
  expect_identical(add_constraint_locked_actions(p, locked_in = list(a = 1))$data$dist_actions,
                   p$data$dist_actions)
  expect_identical(add_constraint_locked_actions(p, locked_out = list(b = 2))$data$dist_actions,
                   p$data$dist_actions)
  expect_error(add_constraint_locked_actions(p, locked_out = list(a = 1)), "already locked_in")
  expect_error(add_constraint_locked_actions(p, locked_in = list(b = 2)), "already locked_out")
  expect_identical(serialize(p$data, NULL), original)
})

test_that("conflicting PU and action locks are rejected in either call order", {
  base <- contract_actions()
  pu_out <- add_constraint_locked_planning_units(base, locked_out = 1)
  action_in <- add_constraint_locked_actions(base, locked_in = list(a = 1))
  expect_error(add_constraint_locked_actions(pu_out, locked_in = list(a = 1)), "locked_out")
  expect_error(add_constraint_locked_planning_units(action_in, locked_out = 1), "locked_in.*locked_out")
  # Locking a PU in still allows individual actions to be excluded.
  p <- add_constraint_locked_planning_units(base, locked_in = 1)
  expect_no_error(add_constraint_locked_actions(p, locked_out = list(a = 1)))
})

test_that("spatial names accumulate and cannot silently replace edge tables", {
  base <- contract_actions()
  edge <- data.frame(pu1 = 1, pu2 = 2, weight = 1)
  p <- base |> add_spatial_relations(edge, name = "boundary") |>
    add_spatial_relations(transform(edge, pu2 = 3), name = "proximity")
  original <- serialize(p$data, NULL)
  expect_named(p$data$spatial_relations, c("boundary", "proximity"))
  expect_error(add_spatial_relations(p, edge, name = "boundary"), "already exists")
  expect_error(add_spatial_relations(p, transform(edge, weight = 9), name = "boundary"), "already exists")
  expect_error(add_spatial_boundary(p, boundary = edge, name = "boundary"), "already exists")
  expect_identical(serialize(p$data, NULL), original)
})

test_that("budgets distinguish cost components while thresholds and names do not change identity", {
  p <- contract_actions() |>
    add_constraint_budget(100, "max") |>
    add_constraint_budget(50, "max", include_action_cost = FALSE) |>
    add_constraint_budget(20, "max", include_pu_cost = FALSE)
  expect_equal(nrow(p$data$constraints$budget), 3)
  expect_error(add_constraint_budget(p, 90, "max", name = "different"), "already exists")
  expect_error(add_constraint_budget(p, 10, "max", include_pu_cost = FALSE), "already exists")
})

test_that("area constraints distinguish measures, not thresholds or display units", {
  p <- contract_base() |>
    add_constraint_area(10, "max", area_col = "area", name = "total_area") |>
    add_constraint_area(10, "max", area_col = "alternate_area", name = "alternate")
  expect_equal(nrow(p$data$constraints$area), 2)
  expect_error(add_constraint_area(p, 20, "max", area_col = "area", name = "different"), "already exists")
  expect_error(add_constraint_area(p, 1, "max", area_col = "area", area_unit = "ha"), "already exists")
})

test_that("failed first configurations leave the base reusable", {
  p <- contract_base()
  expect_error(add_actions(p, data.frame(id = "a"), cost = -1))
  expect_no_error(add_actions(p, data.frame(id = "a"), cost = 1))
  expect_error(set_solver(p, gap_limit = -1))
  expect_no_error(set_solver_cbc(p, gap_limit = 0))
  actions <- contract_actions()
  expect_error(add_effects(actions, data.frame(action = "a", feature = 1, effect = NA_real_)))
  expect_no_error(add_effects(actions, NULL))
  expect_error(add_profit(actions, Inf))
  expect_no_error(add_profit(actions, 1))
})

test_that("constraint names stay unique within each family", {
  p <- contract_actions() |> add_constraint_budget(100, "max", name = "limit")
  expect_error(add_constraint_budget(p, 10, "min", name = "limit"), "name.*already exists")
  area <- contract_base() |> add_constraint_area(20, "max", area_col = "area") |>
    add_constraint_area(20, "max", area_col = "alternate_area")
  expect_identical(area$data$constraints$area$name, c("area_max", "area_max_2"))
  expect_error(add_constraint_area(area, 5, "min", name = "area_max"), "name.*already exists")
})

test_that("an empty filtered effects definition still blocks all subsequent definitions", {
  p <- suppressWarnings(add_benefits(contract_actions(),
                                    data.frame(pu = 1, action = "a", feature = 1, delta = 0)))
  expect_equal(nrow(p$data$dist_effects), 0)
  expect_error(add_effects(p, NULL), "Effects already defined")
  expect_error(add_losses(p, NULL), "Effects already defined")
})

test_that("rejected setters preserve a compiled model and its original coefficients", {
  p <- contract_mo() |> add_constraint_locked_planning_units(locked_in = 1) |> set_solver_cbc() |>
    set_method_weighted_sum(aliases = c("cost", "profit"),
                            runs = set_runs_manual(data.frame(weight_cost = 1, weight_profit = 1))) |>
    compile_model()
  pointer <- p$data$model_ptr
  model <- p$data$model_list
  expect_error(set_solver_gurobi(p), "already defined")
  expect_error(set_method_augmecon(p, primary = "cost"), "already defined")
  expect_error(add_actions(p, data.frame(id = c("aa", "a", "b", "c"))), "already defined")
  expect_identical(p$data$model_ptr, pointer)
  expect_identical(p$data$model_list, model)
})

test_that("independent solver and MO branches solve without altering their common base", {
  skip_if_no_cbc()
  base <- contract_mo() |> add_constraint_budget(2, "max", include_pu_cost = FALSE) |>
    add_constraint_locked_planning_units(locked_in = 1)
  weighted <- base |> set_solver_cbc(gap_limit = 0) |>
    set_method_weighted_sum(aliases = c("cost", "profit"),
                            runs = set_runs_manual(data.frame(weight_cost = 0, weight_profit = 1)))
  epsilon <- base |> set_solver_cbc(gap_limit = 0) |>
    set_method_epsilon_constraint(primary = "cost", aliases = c("cost", "profit"),
                                  runs = set_runs_manual(data.frame(eps_profit = 8)))
  a <- solve(weighted)
  b <- solve(epsilon)
  expect_equal(max(get_objectives(a)$profit), 10)
  expect_true(all(get_objectives(b)$profit >= 8))
  expect_null(base$data$solve_args)
  expect_null(base$data$method)
})
