test_that("set_solver validates unsupported solvers and common arguments", {
  p <- make_round4_problem() |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost")

  expect_error(
    multiscape::set_solver(
      p,
      solver = "unknown_solver"
    )
  )

  expect_error(
    multiscape::set_solver_cbc(
      p,
      gap_limit = -1
    )
  )

  expect_error(
    multiscape::set_solver_cbc(
      p,
      time_limit = -1
    )
  )

  expect_error(
    multiscape::set_solver_cbc(
      p,
      verbose = NA
    ),
    "TRUE or FALSE"
  )
})


test_that("set_solver_cbc stores a valid configuration in solve_args", {
  p <- make_round4_problem() |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost")

  out <- multiscape::set_solver_cbc(
    p,
    gap_limit = 0,
    time_limit = 60,
    verbose = FALSE
  )

  expect_s3_class(out, "Problem")
  expect_true(is.list(out$data$solve_args))
  expect_identical(out$data$solve_args$solver, "cbc")
  expect_equal(out$data$solve_args$gap_limit, 0)
  expect_equal(out$data$solve_args$time_limit, 60)
  expect_false(out$data$solve_args$verbose)
})


test_that("solver setters do not mutate the original problem", {
  p <- make_round4_problem() |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost")

  original <- p$data$solve_args

  out <- multiscape::set_solver_cbc(
    p,
    verbose = FALSE
  )

  expect_s3_class(out, "Problem")
  expect_identical(p$data$solve_args, original)
  expect_true(is.list(out$data$solve_args))
})
