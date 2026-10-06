audit_scoped_cost_problem <- function() {
  create_problem(data.frame(id = 1:2, cost = c(3, 7), area = 1),
    data.frame(id = 1, name = "habitat"),
    data.frame(pu = 1:2, feature = 1, amount = 10)) |>
    add_actions(data.frame(id = c("a", "b")), cost = c(a = 10, b = 1)) |>
    add_effects(data.frame(action = c("a", "b"), feature = "habitat", effect = c(1, 2))) |>
    add_constraint_area(2, "equal", tolerance = 0)
}

test_that("single scoped costs agree with independent costs and MO", {
  skip_if_no_cbc()
  p <- audit_scoped_cost_problem()
  for (scope in list("a", "b", c("a", "b"), NULL)) {
    for (include_pu in c(FALSE, TRUE)) {
      objective <- add_objective_min_cost(p, actions = scope,
        include_pu_cost = include_pu, alias = "cost")
      single <- objective |> set_solver_cbc(gap_limit = 0) |> solve()
      multi <- objective |> add_objective_max_benefit(alias = "benefit") |>
        set_method_weighted_sum(aliases = c("cost", "benefit"), normalize_weights = FALSE,
          runs = set_runs_manual(data.frame(weight_cost = 1, weight_benefit = 0))) |>
        set_solver_cbc(gap_limit = 0) |> solve()
      selected <- get_actions(single)
      selected <- selected[selected$selected > .5, ]
      counted <- if (is.null(scope)) selected else selected[selected$action %in% scope, ]
      expected <- sum(ifelse(counted$action == "a", 10, 1)) + if (include_pu) 10 else 0
      expect_equal(get_objectives(single)$cost, expected)
      expect_equal(get_objectives(single)$cost, get_objectives(multi)$cost)
      expect_equal(get_objectives(single)$cost,
        (if (is.null(scope) || length(scope) == 2) 2 else 0) + if (include_pu) 10 else 0)
    }
  }
})

test_that("cost scope does not renumber decisions or exclude feasible actions", {
  skip_if_no_cbc()
  p <- audit_scoped_cost_problem() |>
    add_constraint_locked_actions(locked_in = list(a = 1, b = 2))
  for (action in c("a", "b")) {
    s <- p |> add_objective_min_cost(actions = action, include_pu_cost = FALSE, alias = "cost") |>
      set_solver_cbc(gap_limit = 0) |> solve()
    expect_equal(get_objectives(s)$cost, if (action == "a") 10 else 1)
    selected <- get_actions(s)
    expect_equal(selected$selected[selected$action == "a" & selected$pu == 1], 1)
    expect_equal(selected$selected[selected$action == "b" & selected$pu == 2], 1)
  }
})

test_that("empty feasible cost scopes and disabled action costs remain valid", {
  skip_if_no_cbc()
  p <- audit_scoped_cost_problem() |>
    add_constraint_locked_actions(locked_out = list(a = 1:2))
  s <- p |> add_objective_min_cost(actions = "a", include_pu_cost = FALSE, alias = "cost") |>
    set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(get_objectives(s)$cost, 0)
  selected <- get_actions(s)
  expect_true(all(selected$action[selected$selected > .5] == "b"))
  global <- p |> add_objective_min_cost(actions = "a", include_action_cost = FALSE, alias = "cost") |>
    set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(get_objectives(global)$cost, 10)
})

test_that("numeric external action ids are not confused with internal cost indices", {
  skip_if_no_cbc()
  p <- create_problem(data.frame(id = 1:2, cost = 0, area = 1),
    data.frame(id = 1, name = "habitat"), data.frame(pu = 1:2, feature = 1, amount = 10)) |>
    add_actions(data.frame(id = c("2", "1"), internal_id = c(1L, 2L)),
      cost = c("2" = 10, "1" = 1)) |>
    add_effects(data.frame(action = c("2", "1"), feature = "habitat", effect = c(1, 2))) |>
    add_constraint_area(2, "equal", tolerance = 0) |>
    add_objective_min_cost(actions = "2", include_pu_cost = FALSE, alias = "cost")
  multi <- p |> add_objective_max_benefit(alias = "benefit") |>
    set_method_weighted_sum(aliases = c("cost", "benefit"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_benefit = 0))) |>
    set_solver_cbc(gap_limit = 0) |> solve()
  selected <- get_actions(multi)
  actual <- 10 * sum(selected$selected[selected$action == "2"])
  expect_equal(get_objectives(multi)$cost, actual)
  expect_equal(actual, 0)
})

test_that("CBC preserves trailing empty rows and columns including their objectives", {
  skip_if_no_cbc()
  mat <- Matrix::sparseMatrix(i = 1L, j = 1L, x = 1, dims = c(2, 3))
  completed <- multiscape:::.pa_cbc_complete_dimensions(mat, c(1, 0), c(1, 0),
    c(0, 0, 0), c(1, 1, 1))
  s <- rcbc::cbc_solve(obj = c(2, 0, -3), mat = completed$mat,
    row_lb = completed$row_lb, row_ub = completed$row_ub,
    col_lb = c(0, 0, 0), col_ub = c(1, 1, 1), is_integer = rep(TRUE, 3),
    cbc_args = list(log = "0"))
  expect_equal(s$objective_value, -1)
  expect_length(s$column_solution, 3)
  expect_equal(s$column_solution[c(1, 3)], c(1, 1))
  empty <- multiscape:::.pa_cbc_complete_dimensions(
    Matrix::sparseMatrix(i = integer(), j = integer(), dims = c(0, 2)),
    numeric(), numeric(), c(0, 0), c(1, 1))
  e <- rcbc::cbc_solve(obj = c(1, -2), mat = empty$mat,
    row_lb = empty$row_lb, row_ub = empty$row_ub, col_lb = c(0, 0), col_ub = c(1, 1),
    is_integer = c(TRUE, TRUE), cbc_args = list(log = "0"))
  expect_equal(e$objective_value, -2)
  expect_length(e$column_solution, 2)
})

test_that("CBC solves deprecated impact with all action decisions locked", {
  skip_if_no_cbc()
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- create_problem(data.frame(id = 1:4, cost = 0, area = 1),
    data.frame(id = 1:2, name = c("carbon", "water")),
    data.frame(pu = rep(1:4, 2), feature = rep(1:2, each = 4),
      amount = c(.1, .3, .6, .9, .8, .2, .4, .7))) |>
    add_actions(data.frame(id = "restore"), cost = 0) |>
    add_constraint_area(2, "equal", tolerance = 0) |>
    add_constraint_locked_actions(locked_in = list(restore = 1:2), locked_out = list(restore = 3:4)) |>
    add_objective_min_intervention_impact(features = "carbon", alias = "impact") |>
    set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_equal(get_objectives(s)$impact, .4)
  expect_equal(sum(get_actions(s)$selected), 2)
  expect_equal(sum(s$summary$pu$selected), 2)
})
