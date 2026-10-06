numerical_mo_problem <- function(cost = rep(100, 3), include_pu_cost = TRUE) {
  create_problem(data.frame(id = 1:3, cost = cost, area = 1),
    data.frame(id = 1, name = "habitat"),
    data.frame(pu = 1:3, feature = 1, amount = 1)) |>
    add_actions(data.frame(id = "restore"), cost = 0) |>
    add_effects(data.frame(pu = 1:3, action = "restore", feature = "habitat",
      effect = c(1, 1 + 2e-7, 100))) |>
    add_constraint_area(1, "equal", tolerance = 0) |>
    add_objective_min_cost(alias = "cost", include_pu_cost = include_pu_cost) |>
    add_objective_max_benefit(alias = "benefit")
}

test_that("MO epsilon bounds distinguish genuine differences below the old solver tolerance", {
  skip_if_no_cbc()
  p <- numerical_mo_problem(c(1, 100, 200)) |>
    set_method_epsilon_constraint(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 1 + 2e-7)))
  for (solver in c("cbc", "gurobi")) {
    if (!isTRUE(multiscape:::available_to_solve(solver))) next
    s <- solve(set_solver(p, solver = solver, gap_limit = 0))
    expect_equal(get_objectives(s)$cost, 100)
    expect_equal(get_objectives(s)$benefit, 1 + 2e-7, tolerance = 1e-12)
    expect_true(get_objectives(s)$benefit >= 1 + 2e-7)
    diagnostics <- s$solution$solutions[[1]]$diagnostics
    expect_true(all(diagnostics$epsilon_checks$valid))
    expect_lte(max(diagnostics$epsilon_checks$violation), 1e-9)
  }
})

test_that("AUGMECON resolves small secondary improvements at equal monetary cost", {
  skip_if_no_cbc()
  p <- numerical_mo_problem(c(100, 100, 200)) |>
    set_method_augmecon(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 1)), augmentation = 1e-3)
  for (solver in c("cbc", "gurobi")) {
    if (!isTRUE(multiscape:::available_to_solve(solver))) next
    s <- solve(set_solver(p, solver = solver, gap_limit = 0))
    expect_equal(get_objectives(s)$cost, 100)
    expect_equal(get_objectives(s)$benefit, 1 + 2e-7, tolerance = 1e-12)
    selected <- get_actions(s)
    expect_equal(selected$pu[selected$selected > .5], 2)
    # Solver rescaling must not change returned objective units.
    one <- s$solution$solutions[[1]]
    expect_lt(abs(one$solution$objective - 100), 1e-6)
    expect_equal(one$diagnostics$augmentation_refinement$primary, 100)
    expect_true(one$diagnostics$augmentation_refinement$solver_args$warm_start)
    expect_lte(one$diagnostics$augmentation_refinement$refined_objective,
      one$diagnostics$augmentation_refinement$original_objective + 1e-10)
  }
})

test_that("alias values describe binary decisions rather than integrality noise", {
  skip_if_no_cbc()
  p <- numerical_mo_problem() |>
    set_method_weighted_sum(aliases = c("cost", "benefit"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = 0, weight_benefit = 1))) |>
    set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  z <- s$solution$solutions[[1]]
  expected <- get_objectives(s)$benefit
  binary <- s$problem$data$model_list$vtype == "B"
  z$solution$vector[binary & z$solution$vector > .5] <- 1 - 1e-8
  expect_equal(multiscape:::.pamo_eval_alias_on_solution(s$problem, z, "benefit"),
    expected, tolerance = 1e-12)
  expect_equal(multiscape:::.pamo_eval_alias_on_solution(s$problem, z, "cost"), 100)
})

test_that("scaling preserves signed criteria and leaves zero objectives valid", {
  expect_equal(multiscape:::.pa_positive_objective_scale(c(0, 0)), 1)
  v <- c(-2e-7, 10, 0)
  scale <- multiscape:::.pa_positive_objective_scale(v)
  expect_gt(scale, 0)
  candidates <- rbind(c(1, 0, 0), c(0, 1, 0), c(1, 1, 1))
  expect_identical(order(as.numeric(candidates %*% v)),
    order(as.numeric(candidates %*% (v * scale))))
  expect_true(all(is.finite(v * scale)))
})

test_that("epsilon validation rejects material violations and respects explicit relaxations", {
  check <- multiscape:::.pamo_check_secondary_values
  expect_error(check(c(benefit = 1), c(benefit = "max"), list(benefit = 1 + 2e-7)),
    "numerically invalid.*benefit.*epsilon")
  expect_error(check(c(cost = 2), c(cost = "min"), list(cost = 1)), "numerically invalid")
  expect_error(check(c(benefit = NA_real_), c(benefit = "max"), list(benefit = 1)),
    "numerically invalid")
  relaxed <- check(c(benefit = 1), c(benefit = "max"), list(benefit = 1.2),
    list(benefit = .3))
  expect_true(relaxed$valid)
  expect_equal(relaxed$limit, .9)
  roundoff <- check(c(benefit = 7000 - 1e-9), c(benefit = "max"), list(benefit = 7000))
  expect_true(roundoff$valid)
})

test_that("explicit MO solver parameters override precise defaults and are recorded", {
  skip_if_no_cbc()
  p <- numerical_mo_problem() |>
    set_method_epsilon_constraint(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = .5))) |>
    set_solver_cbc(gap_limit = 0, solver_params = list(primalTolerance = "1e-8"))
  s <- solve(p)
  args <- s$solution$solutions[[1]]$diagnostics$solver_args
  expect_identical(args$effective_solver_params$primalTolerance, "1e-8")
  expect_gt(args$objective_scale, 0)
})

test_that("AUGMECON refinement preserves augmented trade-offs and maximization primaries", {
  skip_if_no_cbc()
  base <- numerical_mo_problem(c(100, 100, 200))
  tradeoff <- base |>
    set_method_augmecon(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 1)), augmentation = 1000) |>
    set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(get_objectives(tradeoff)$cost, 200)
  expect_equal(get_objectives(tradeoff)$benefit, 100)
  expect_equal(tradeoff$solution$solutions[[1]]$solution$objective, -800)
  maximum <- base |>
    set_method_augmecon(primary = "benefit", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_cost = 100))) |>
    set_solver_cbc(gap_limit = 0) |> solve()
  expect_equal(get_objectives(maximum)$cost, 100)
  expect_equal(get_objectives(maximum)$benefit, 1 + 2e-7, tolerance = 1e-12)
  expect_equal(maximum$solution$solutions[[1]]$diagnostics$augmentation_refinement$primary,
    1 + 2e-7, tolerance = 1e-12)
})

test_that("AUGMECON refinement handles a constant primary and preserves empty constraints", {
  skip_if_no_cbc()
  base <- numerical_mo_problem(include_pu_cost = FALSE) |>
    set_method_augmecon(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 1))) |>
    set_solver_cbc(gap_limit = 0)
  s <- solve(base)
  expect_equal(get_objectives(s)$cost, 0)
  expect_equal(get_objectives(s)$benefit, 100)
  expect_true(all(s$solution$solutions[[1]]$diagnostics$epsilon_checks$valid))
})

test_that("AUGMECON refinement respects raw solver time limits and partial global statuses", {
  skip_if_no_cbc()
  base <- numerical_mo_problem(c(100, 100, 200)) |>
    set_method_augmecon(primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 1))) |>
    set_solver_cbc(gap_limit = 0, time_limit = 10, solver_params = list(sec = "1"))
  original_solve <- multiscape:::.pa_solve_single_problem
  calls <- list()
  partial <- FALSE
  testthat::local_mocked_bindings(.pa_solve_single_problem = function(x, ...) {
    args <- list(...)
    calls[[length(calls) + 1L]] <<- list(time_limit = args$time_limit,
      sec = x$data$solve_args$solver_params$sec)
    s <- original_solve(x, ...)
    if (length(calls) == 1L) {
      s$diagnostics$runtime <- .75
      if (partial) s$diagnostics$status_code <- 2L
    }
    s
  }, .package = "multiscape")
  spec <- list(type = "augmecon", primary = "cost", eps = list(benefit = 1),
    secondary_ranges = 99, augmentation = 1e-3)
  s <- multiscape:::.pamo_solve_one(base, spec)
  expect_length(calls, 2)
  expect_equal(calls[[2]]$time_limit, .25)
  expect_equal(as.numeric(calls[[2]]$sec), .25)
  expect_equal(s$solution$diagnostics$status_code, 0L)
  partial <- TRUE
  calls <- list()
  limited <- multiscape:::.pamo_solve_one(base, spec)
  expect_length(calls, 1)
  expect_equal(limited$solution$diagnostics$status_code, 2L)
  expect_null(limited$solution$diagnostics$augmentation_refinement)
})
