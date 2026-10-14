epsilon_start_problem <- function(lexicographic = TRUE, runs = set_runs_grid(n = 3),
                                  solver = NULL) {
  p <- create_problem(data.frame(id = 1:4, cost = c(999, 1, 2, 3), area = 1),
    data.frame(id = 1, name = "impact"),
    data.frame(pu = 1:4, feature = 1, amount = c(999, 3, 2, 1))) |>
    add_actions(data.frame(id = "selected"),
      cost = data.frame(pu = 1:4, action = "selected", cost = c(999, 1, 2, 3)),
      action_area = data.frame(pu = 1:4, action = "selected", area = 1)) |>
    add_constraint_locked_actions(locked_out = list(selected = 1)) |>
    add_constraint_area(1, sense = "equal", actions = "selected") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
    add_objective_min_intervention_impact(alias = "impact") |>
    set_method_epsilon_constraint(primary = "impact", aliases = c("impact", "cost"),
      runs = runs, lexicographic = lexicographic)
  if (identical(solver, "cbc")) p <- set_solver_cbc(p, gap_limit = 0, verbose = FALSE)
  if (identical(solver, "gurobi")) p <- set_solver_gurobi(p, gap_limit = 0,
    time_limit = 30, cores = 1, verbose = FALSE)
  p
}

test_that("automatic anchors pass starts using a common objective layout", {
  withr::local_options(lifecycle_verbosity = "quiet")
  calls <- list()
  local_mocked_bindings(
    .pamo_solve_one = function(x, spec) {
      i <- length(calls) + 1L
      calls[[i]] <<- spec
      list(solution = list(solution = list(vector = c(i, i + 10)), stage = i))
    },
    .pamo_eval_alias_on_solution = function(x, solution, alias) {
      if (alias == "cost") 4 - solution$stage else solution$stage
    }, .package = "multiscape")
  for (lexi in c(FALSE, TRUE)) {
    calls <- list()
    p <- epsilon_start_problem(lexi)
    design <- multiscape:::.pamo_compile_epsilon_runs(p, p$data$method,
      gap_limit = .001, time_limit = 15)
    n <- if (lexi) 4L else 2L
    expect_length(calls, n)
    expect_null(calls[[1]]$mip_start)
    for (i in 2:n) expect_equal(calls[[i]]$mip_start, c(i - 1, i + 9))
    for (spec in calls) {
      expect_equal(spec$gap_limit, .001)
      expect_equal(spec$time_limit, 15)
      if (spec$type == "weighted") expect_equal(spec$aliases, c("impact", "cost"))
    }
    expect_equal(attr(design, "initial_mip_start"), c(n, n + 10))
    expect_false("warm_start" %in% names(formals(set_method_epsilon_constraint)))
  }
})

test_that("CBC and Gurobi receive starts at anchors and epsilon transitions", {
  withr::local_options(lifecycle_verbosity = "quiet")
  original_solve <- multiscape:::.pa_solve_single_problem
  calls <- vectors <- list()
  local_mocked_bindings(.pa_solve_single_problem = function(x, ...) {
    i <- length(calls) + 1L
    calls[[i]] <<- list(start = x$data$runtime_updates$start)
    out <- original_solve(x, ...)
    vectors[i] <<- list(out$solution$vector)
    out
  }, .package = "multiscape")
  solvers <- c("cbc", "gurobi")
  available <- vapply(solvers, multiscape:::available_to_solve, logical(1))
  skip_if_not(any(available))
  for (solver in solvers[available]) {
    for (lexi in c(FALSE, TRUE)) {
      calls <- vectors <- list()
      s <- solve(epsilon_start_problem(lexi, solver = solver))
      expect_equal(get_objectives(s)$cost, c(1, 2, 3))
      expect_equal(get_objectives(s)$impact, c(3, 2, 1))
      expect_length(calls, if (lexi) 7L else 5L)
      expect_null(calls[[1]]$start)
      for (i in 2:length(calls)) {
        expect_equal(calls[[i]]$start, vectors[[i - 1]])
        expect_length(calls[[i]]$start, length(vectors[[i]]))
      }
      expect_null(attr(s$getDesign(), "initial_mip_start"))
    }
    calls <- vectors <- list()
    expect_warning(
      s <- solve(epsilon_start_problem(runs = set_runs_manual(
        data.frame(eps_cost = c(1, 0, 3, 2))), solver = solver)),
      "1 of 4 epsilon-constraint runs were infeasible"
    )
    expect_equal(s$getDesign()$eps_cost, c(1, 0, 3, 2))
    expect_length(calls, 4L)
    expect_null(calls[[1]]$start)
    expect_equal(calls[[2]]$start, vectors[[1]])
    expect_equal(calls[[3]]$start, vectors[[1]])
    expect_equal(calls[[4]]$start, vectors[[3]])
    obj <- get_objectives(s)
    expect_equal(obj$cost, c(1, NA_real_, 3, 2))
    expect_equal(obj$impact, c(3, NA_real_, 1, 2))
  }
})

test_that("unusable solutions cannot replace the last warm start", {
  expect_null(multiscape:::.pamo_solution_vector(NULL))
  expect_null(multiscape:::.pamo_solution_vector(list(solution = list(vector = numeric()))))
  expect_null(multiscape:::.pamo_solution_vector(list(solution = list(vector = c(1, NA)))))
  expect_null(multiscape:::.pamo_solution_vector(list(solution = list(vector = c(1, Inf)))))
})

test_that("automatic maximisation bounds run from restrictive to permissive", {
  skip_if_no_cbc()
  p <- create_problem(data.frame(id = 1:3, cost = 1:3, area = 1),
    data.frame(id = 1, name = "habitat"),
    data.frame(pu = 1:3, feature = 1, amount = 1)) |>
    add_actions(data.frame(id = "restore"), cost = 0) |>
    add_effects(data.frame(pu = 1:3, action = "restore", feature = "habitat",
      effect = 1:3)) |>
    add_constraint_area(1, "equal", tolerance = 0) |>
    add_objective_min_cost(alias = "cost") |>
    add_objective_max_effect(alias = "benefit") |>
    set_method_epsilon_constraint(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_grid(n = 3)) |>
    set_solver_cbc(gap_limit = 0, verbose = FALSE)
  s <- solve(p)
  expect_equal(s$getDesign()$eps_benefit, c(3, 2, 1))
  expect_equal(get_objectives(s)$cost, c(3, 2, 1))
  expect_equal(get_objectives(s)$benefit, c(3, 2, 1))
})
