mo_locked_cost_problem <- function(include_pu_cost = FALSE, solver = "cbc") {
  p <- create_problem(data.frame(id = 1:4, cost = c(999, 1, 2, 3), area = 1),
    data.frame(id = 1, name = "impact"),
    data.frame(pu = 1:4, feature = 1, amount = c(999, 3, 2, 1))) |>
    add_actions(data.frame(id = "selected"),
      cost = data.frame(pu = 1:4, action = "selected", cost = c(999, 1, 2, 3)),
      action_area = data.frame(pu = 1:4, action = "selected", area = 1)) |>
    add_constraint_locked_actions(locked_out = list(selected = 1)) |>
    add_constraint_area(1, sense = "equal", actions = "selected") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = include_pu_cost) |>
    add_objective_min_intervention_impact(alias = "impact")
  if (solver == "gurobi") {
    set_solver_gurobi(p, gap_limit = 0, time_limit = 30, cores = 2, verbose = FALSE)
  } else {
    set_solver_cbc(p, gap_limit = 0, verbose = FALSE)
  }
}

test_that("cost evaluation uses decoded rows without any solver or model snapshot", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- mo_locked_cost_problem()
  decoded <- list(
    problem = NULL,
    solution = list(vector = c(0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0)),
    summary = list(
      pu = data.frame(id = 1:4, cost = c(999, 1, 2, 3), selected = c(0, 1, 0, 0)),
      actions = data.frame(pu = 2:4, internal_action = 1L, cost = 1:3,
        internal_row = 1:3, selected = c(1, 0, 0))))
  expect_equal(multiscape:::.pamo_eval_alias_on_solution(p, decoded, "cost"), 1)
  p <- mo_locked_cost_problem(include_pu_cost = TRUE)
  expect_equal(multiscape:::.pamo_eval_alias_on_solution(p, decoded, "cost"), 2)
  decoded$summary$actions <- NULL
  expect_error(multiscape:::.pamo_eval_alias_on_solution(p, decoded, "cost"), "Decoded action costs")
})

test_that("weighted cost aliases match selected costs after lock-out filtering", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  for (include_pu in c(FALSE, TRUE)) {
    for (aliases in list(c("cost", "impact"), c("impact", "cost"))) {
      p <- mo_locked_cost_problem(include_pu) |>
        set_method_weighted_sum(aliases = aliases, runs = set_runs_manual(
          data.frame(weight_cost = c(1, 0), weight_impact = c(0, 1))))
      s <- solve(p)
      obj <- get_objectives(s)
      expect_equal(obj$cost, c(1, 3) * (1 + include_pu))
      expect_equal(obj$impact, c(3, 1))
      a <- get_actions(s)
      expect_equal(a$pu[a$selected > .5], c(2L, 4L))
      for (i in seq_len(2)) {
        z <- s$solution$solutions[[i]]
        expected <- sum(z$summary$actions$cost[z$summary$actions$selected > .5])
        if (include_pu) expected <- expected + sum(z$summary$pu$cost[z$summary$pu$selected > .5])
        expect_equal(obj$cost[i], expected)
        expect_equal(multiscape:::.pamo_eval_alias_on_solution(s$problem, z, "cost"), expected)
        expect_equal(z$solution$objective, if (i == 1) expected else 1)
      }
    }
  }
})

test_that("Gurobi reproduces the same lock-out Pareto and decoded costs", {
  skip_if_not(multiscape:::available_to_solve("gurobi"))
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- mo_locked_cost_problem(solver = "gurobi")
  weighted <- p |> set_method_weighted_sum(aliases = c("impact", "cost"),
    runs = set_runs_manual(data.frame(weight_cost = c(1, 0), weight_impact = c(0, 1)))) |> solve()
  expect_equal(get_objectives(weighted)$cost, c(1, 3))
  expect_equal(get_objectives(weighted)$impact, c(3, 1))
  for (warm in c(FALSE, TRUE)) {
    s <- p |> set_method_epsilon_constraint(primary = "impact", aliases = c("impact", "cost"),
      runs = set_runs_grid(n = 3), lexicographic = TRUE, warm_start = warm) |> solve()
    expect_equal(get_objectives(s)$cost, c(1, 2, 3))
    expect_equal(get_objectives(s)$impact, c(3, 2, 1))
    expect_equal(s$getDesign()$eps_cost, c(1, 2, 3))
  }
})

test_that("epsilon bounds and all three known Pareto points survive lock-out", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  for (lexicographic in c(FALSE, TRUE)) {
    for (warm_start in c(FALSE, TRUE)) {
      p <- mo_locked_cost_problem() |>
        set_method_epsilon_constraint(primary = "impact", aliases = c("impact", "cost"),
          runs = set_runs_grid(n = 3), lexicographic = lexicographic, warm_start = warm_start)
      s <- solve(p)
      obj <- get_objectives(s)
      expect_equal(obj$cost, c(1, 2, 3))
      expect_equal(obj$impact, c(3, 2, 1))
      expect_equal(s$getDesign()$eps_cost, c(1, 2, 3))
      a <- get_actions(s)
      expect_equal(a$pu[a$selected > .5], c(2L, 3L, 4L))
    }
  }
})

test_that("scoped costs match exhaustive choices with several filtered actions", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  pairs <- data.frame(pu = rep(1:3, each = 2), action = rep(c("a", "b"), 3),
    cost = c(999, 1, 3, 777, 2, 4))
  feasible <- pairs[!((pairs$pu == 1 & pairs$action == "a") |
    (pairs$pu == 2 & pairs$action == "b")), ]
  for (reverse_rows in c(FALSE, TRUE)) {
    costs <- if (reverse_rows) pairs[nrow(pairs):1, ] else pairs
    base <- create_problem(data.frame(id = 1:3, cost = c(5, 7, 11), area = 1),
      data.frame(id = 1, name = "impact"),
      data.frame(pu = 1:3, feature = 1, amount = c(3, 1, 2))) |>
      add_actions(data.frame(id = c("a", "b")), cost = costs,
        action_area = transform(costs[, c("pu", "action")], area = 1)) |>
      add_constraint_locked_actions(locked_out = list(a = 1, b = 2)) |>
      add_constraint_area(1, sense = "equal", actions = c("a", "b"))
    for (scope in list(NULL, "a", "b", c("a", "b"))) {
      for (include_pu in c(FALSE, TRUE)) {
        objective <- if (is.null(scope)) feasible$cost else ifelse(feasible$action %in% scope, feasible$cost, 0)
        if (include_pu) objective <- objective + c(5, 7, 11)[feasible$pu]
        expected <- min(objective)
        s <- base |>
          add_objective_min_cost(actions = scope, include_pu_cost = include_pu, alias = "cost") |>
          add_objective_min_intervention_impact(alias = "impact") |>
          set_method_weighted_sum(aliases = c("cost", "impact"),
            runs = set_runs_manual(data.frame(weight_cost = 1, weight_impact = 0))) |>
          set_solver_cbc(gap_limit = 0, verbose = FALSE) |> solve()
        expect_equal(get_objectives(s)$cost, expected)
        expect_equal(s$solution$solutions[[1]]$solution$objective, expected)
        a <- get_actions(s)
        chosen <- a[a$selected > .5, ]
        expect_equal(nrow(chosen), 1L)
        expect_true(paste(chosen$pu, chosen$action) %in% paste(feasible$pu, feasible$action))
      }
    }
  }
})
