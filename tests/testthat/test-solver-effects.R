test_that("set_solver covers incremental storage, logging warnings, and wrapper paths", {
  p <- make_round4_problem()

  expect_error(multiscape::set_solver(p, solver_params = 1), "solver_params")
  expect_error(multiscape::set_solver(p, write_log = TRUE), "log_file")

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

  p2 <- multiscape::set_solver(p1, solver = "gurobi", solver_params = list(alpha = 3))
  expect_equal(p2$data$solve_args$solver, "gurobi")
  expect_equal(p2$data$solve_args$solver_params$alpha, 3)
  expect_equal(p2$data$solve_args$solver_params$beta, 2)

  expect_equal(multiscape::set_solver_cplex(p)$data$solve_args$solver, "cplex")
  expect_equal(multiscape::set_solver_symphony(p)$data$solve_args$solver, "symphony")
})


test_that("add_effects covers explicit split benefit and loss valid branches", {
  p <- make_round4_problem(with_actions = TRUE)

  e_benefit <- data.frame(
    pu = 1L,
    action = "restoration",
    feature = "sp1",
    benefit = 2,
    stringsAsFactors = FALSE
  )

  out_benefit <- multiscape::add_effects(
    p,
    effects = e_benefit,
    component = "benefit"
  )

  expect_true(is.data.frame(out_benefit$data$dist_effects))
  expect_true(all(out_benefit$data$dist_effects$benefit > 0))
  expect_true(all(out_benefit$data$dist_effects$loss == 0))

  e_loss <- data.frame(
    pu = 1L,
    action = "restoration",
    feature = "sp1",
    loss = 1,
    stringsAsFactors = FALSE
  )

  out_loss <- multiscape::add_effects(
    p,
    effects = e_loss,
    component = "loss"
  )

  expect_true(is.data.frame(out_loss$data$dist_effects))
  expect_true(all(out_loss$data$dist_effects$loss > 0))
  expect_true(all(out_loss$data$dist_effects$benefit == 0))
})
