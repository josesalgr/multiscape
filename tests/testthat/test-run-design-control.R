test_that("set_runs_grid creates a validated automatic design", {
  x <- multiscape::set_runs_grid(
    n = 5
  )

  expect_s3_class(x, "RunGrid")
  expect_s3_class(x, "RunDesign")
  expect_identical(x$type, "grid")
  expect_identical(x$n, 5L)
})


test_that("set_runs_grid validates its arguments", {
  expect_error(
    multiscape::set_runs_grid(1),
    "integer >= 2"
  )

  expect_error(
    multiscape::set_runs_grid(NA),
    "integer >= 2"
  )
})


test_that("set_runs_manual preserves the supplied run table", {
  values <- data.frame(
    weight_cost = c(1, 0.5, 0),
    weight_benefit = c(0, 0.5, 1)
  )

  x <- multiscape::set_runs_manual(values)

  expect_s3_class(x, "RunManual")
  expect_s3_class(x, "RunDesign")
  expect_identical(x$type, "manual")
  expect_identical(x$values, values)
})


test_that("set_runs_manual rejects invalid inputs", {
  expect_error(
    multiscape::set_runs_manual(NULL),
    "data.frame"
  )

  expect_error(
    multiscape::set_runs_manual(list()),
    "data.frame"
  )

  expect_error(
    multiscape::set_runs_manual(data.frame()),
    "at least one row"
  )
})


test_that("set_runs_control exposes stable defaults", {
  x <- multiscape::set_runs_control()

  expect_s3_class(x, "MOControl")
  expect_false(x$stop_on_infeasible)
  expect_false(x$stop_on_no_solution)
  expect_true(x$stop_on_error)
})


test_that("set_runs_control validates each setting", {
  expect_error(
    multiscape::set_runs_control(stop_on_infeasible = NA),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::set_runs_control(stop_on_no_solution = 1),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::set_runs_control(stop_on_error = c(TRUE, FALSE)),
    "TRUE or FALSE"
  )
})


test_that("set_runs_control creates and validates MOControl objects", {
  x <- multiscape::set_runs_control()

  expect_s3_class(x, "MOControl")

  custom <- multiscape::set_runs_control(
    stop_on_infeasible = TRUE
  )

  expect_s3_class(custom, "MOControl")
  expect_true(custom$stop_on_infeasible)

  expect_error(
    multiscape::set_runs_control(slack_upper_bound = -1),
    "slack_upper_bound"
  )
})
