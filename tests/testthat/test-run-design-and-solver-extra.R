test_that("run design constructors validate edge cases", {
  expect_error(multiscape::set_runs_grid(1), ">= 2")
  expect_error(multiscape::set_runs_grid(NA_integer_), ">= 2")

  grid <- multiscape::set_runs_grid(4.9)
  expect_s3_class(grid, "RunGrid")
  expect_equal(grid$n, 4L)
  expect_true(grid$include_extremes)

  expect_error(multiscape::set_runs_manual(NULL), "data.frame")
  expect_error(multiscape::set_runs_manual(data.frame()), "at least one row|column")
  expect_error(multiscape::set_runs_manual(data.frame(foo = 1)), "weight_<alias>|eps_<alias>")
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = 1, eps_benefit = 2)),
    "cannot mix"
  )
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = "a")),
    "numeric"
  )
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = NA_real_)),
    "missing"
  )
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = Inf)),
    "finite"
  )
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = -1)),
    "non-negative"
  )
  expect_error(
    multiscape::set_runs_manual(data.frame(weight_cost = 0, weight_benefit = 0)),
    "positive total"
  )

  manual <- multiscape::set_runs_manual(
    data.frame(
      weight_cost = c(1, 0),
      weight_benefit = c(0, 1)
    )
  )
  expect_s3_class(manual, "RunManual")
  expect_equal(nrow(manual$values), 2L)
})


test_that("run control validates logical scalar inputs", {
  control <- multiscape::set_runs_control(
    stop_on_infeasible = TRUE,
    stop_on_no_solution = TRUE,
    stop_on_error = FALSE
  )
  expect_s3_class(control, "RunsControl")
  expect_true(control$stop_on_infeasible)
  expect_true(control$stop_on_no_solution)
  expect_false(control$stop_on_error)

  expect_error(multiscape::set_runs_control(stop_on_infeasible = NA), "TRUE or FALSE")
  expect_error(multiscape::set_runs_control(stop_on_no_solution = c(TRUE, FALSE)), "TRUE or FALSE")
  expect_error(multiscape::set_runs_control(stop_on_error = "yes"), "TRUE or FALSE")
})


test_that("solver configuration validates logging and preserves incremental parameters", {
  p <- make_round4_problem() |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost")

  expect_error(multiscape::set_solver(p, solver_params = "bad"), "list")
  expect_error(multiscape::set_solver(p, solution_limit = NA), "TRUE or FALSE")
  expect_error(multiscape::set_solver(p, cores = 0), "positive integer")
  expect_error(multiscape::set_solver(p, log_file = ""), "non-empty")
  expect_error(multiscape::set_solver(p, write_log = TRUE), "log_file")

  expect_warning(
    out_warn <- multiscape::set_solver(
      p,
      write_log = FALSE,
      log_file = "solver.log"
    ),
    "write_log = FALSE"
  )
  expect_equal(out_warn$data$solve_args$name_output_file, "solver.log")
  expect_false(out_warn$data$solve_args$output_file)

  out <- multiscape::set_solver(
    p,
    solver = "cbc",
    gap_limit = 0.12345,
    time_limit = 12.3456,
    solution_limit = TRUE,
    solver_params = list(alpha = 1),
    beta = 2,
    verbose = FALSE
  )

  expect_equal(out$data$solve_args$gap_limit, 0.123)
  expect_equal(out$data$solve_args$time_limit, 12.346)
  expect_true(out$data$solve_args$solution_limit)
  expect_equal(out$data$solve_args$solver_params$alpha, 1)
  expect_equal(out$data$solve_args$solver_params$beta, 2)

  out2 <- multiscape::set_solver(
    out,
    solver = "cbc",
    solver_params = list(alpha = 9)
  )
  expect_equal(out2$data$solve_args$solver_params$alpha, 9)
  expect_equal(out2$data$solve_args$solver_params$beta, 2)
})
