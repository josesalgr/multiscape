test_that("set_solver covers single assignment, logging warnings, and wrapper paths", {
  p <- make_round4_problem()

  expect_error(multiscape::set_solver(p, solver_params = 1), "solver_params")
  expect_error(multiscape::set_solver_gurobi(p, write_log = TRUE), "log_file")

  expect_warning(
    p1 <- multiscape::set_solver(
      p,
      solver = "cbc",
      write_log = FALSE,
      log_file = "solver.log",
      solver_params = list(alpha = 1),
      beta = 2
    ),
    "write_log = FALSE"
  )

  expect_equal(p1$data$solve_args$solver, "cbc")
  expect_false(p1$data$solve_args$output_file)
  expect_equal(p1$data$solve_args$name_output_file, "solver.log")
  expect_equal(p1$data$solve_args$solver_params$alpha, 1)
  expect_equal(p1$data$solve_args$solver_params$beta, 2)

  expect_error(multiscape::set_solver(p1, solver = "gurobi"), "already defined")
  p2 <- multiscape::set_solver(p, solver = "gurobi", solver_params = list(alpha = 3))
  expect_equal(p2$data$solve_args$solver, "gurobi")
  expect_equal(p2$data$solve_args$solver_params$alpha, 3)
  expect_null(p2$data$solve_args$solver_params$beta)

  expect_equal(multiscape::set_solver_cplex(p)$data$solve_args$solver, "cplex")
  expect_equal(multiscape::set_solver_symphony(p)$data$solve_args$solver, "symphony")
})
