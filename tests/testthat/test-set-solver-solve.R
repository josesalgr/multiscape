test_that("set_solver covers incremental updates, wrappers, warnings, and validation", {
  p <- make_round4_problem()

  expect_error(multiscape::set_solver(list()), "Problem")
  expect_error(multiscape::set_solver(p, solver_params = "bad"), "solver_params")
  expect_error(multiscape::set_solver(p, gap_limit = -0.1), "gap_limit")
  expect_error(multiscape::set_solver(p, time_limit = -1), "time_limit")
  expect_error(multiscape::set_solver(p, solution_limit = NA), "solution_limit")
  expect_error(multiscape::set_solver(p, cores = 0), "cores")
  expect_error(multiscape::set_solver(p, verbose = NA), "verbose")
  expect_error(multiscape::set_solver(p, write_log = NA), "write_log")
  expect_error(multiscape::set_solver(p, log_file = ""), "log_file")
  expect_error(multiscape::set_solver(p, write_log = TRUE), "log_file")

  expect_warning(
    p_log <- multiscape::set_solver(p, write_log = FALSE, log_file = "solver.log"),
    "write_log = FALSE"
  )
  expect_identical(p_log$data$solve_args$name_output_file, "solver.log")

  p1 <- multiscape::set_solver(
    p,
    solver = "cbc",
    gap_limit = 0.12345,
    time_limit = 10.9876,
    solution_limit = TRUE,
    cores = 1,
    verbose = TRUE,
    solver_params = list(a = 1),
    b = 2
  )

  expect_identical(p1$data$solve_args$solver, "cbc")
  expect_equal(p1$data$solve_args$gap_limit, 0.123)
  expect_equal(p1$data$solve_args$time_limit, 10.988)
  expect_true(p1$data$solve_args$solution_limit)
  expect_true(p1$data$solve_args$verbose)
  expect_equal(p1$data$solve_args$solver_params$a, 1)
  expect_equal(p1$data$solve_args$solver_params$b, 2)

  p2 <- multiscape::set_solver(p1, solver = "gurobi", solver_params = list(a = 3))
  expect_identical(p2$data$solve_args$solver, "gurobi")
  expect_equal(p2$data$solve_args$gap_limit, 0.123)
  expect_equal(p2$data$solve_args$solver_params$a, 3)
  expect_equal(p2$data$solve_args$solver_params$b, 2)

  expect_identical(multiscape::set_solver_gurobi(p)$data$solve_args$solver, "gurobi")
  expect_identical(multiscape::set_solver_cbc(p)$data$solve_args$solver, "cbc")
  expect_identical(multiscape::set_solver_cplex(p)$data$solve_args$solver, "cplex")
  expect_identical(multiscape::set_solver_symphony(p)$data$solve_args$solver, "symphony")
})


test_that("solve dispatch validates malformed method configurations before solver use", {
  p <- make_round4_mo_problem()

  p_bad <- p
  p_bad$data$method <- list(type = "")
  expect_error(multiscape::solve(p_bad), "missing method name")

  p_bad$data$method <- list(type = "unsupported_method")
  expect_error(multiscape::solve(p_bad), "Unknown|unsupported")

  p_nomethod <- p
  p_nomethod$data$method <- NULL
  expect_error(multiscape::solve(p_nomethod), "Multiple objectives")
})
