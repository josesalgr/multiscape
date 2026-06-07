test_that("run_grid creates a validated automatic design", {
  x <- multiscape::run_grid(
    n = 5,
    include_extremes = FALSE
  )

  expect_s3_class(x, "RunGrid")
  expect_s3_class(x, "RunDesign")
  expect_identical(x$type, "grid")
  expect_identical(x$n, 5L)
  expect_false(x$include_extremes)
})


test_that("run_grid validates its arguments", {
  expect_error(
    multiscape::run_grid(1),
    "integer >= 2"
  )

  expect_error(
    multiscape::run_grid(NA),
    "integer >= 2"
  )

  expect_error(
    multiscape::run_grid(3, include_extremes = NA),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::run_grid(3, include_extremes = 1),
    "TRUE or FALSE"
  )
})


test_that("run_manual preserves the supplied run table", {
  values <- data.frame(
    weight_cost = c(1, 0.5, 0),
    weight_benefit = c(0, 0.5, 1)
  )

  x <- multiscape::run_manual(values)

  expect_s3_class(x, "RunManual")
  expect_s3_class(x, "RunDesign")
  expect_identical(x$type, "manual")
  expect_identical(x$values, values)
})


test_that("run_manual rejects invalid inputs", {
  expect_error(
    multiscape::run_manual(NULL),
    "data.frame"
  )

  expect_error(
    multiscape::run_manual(list()),
    "data.frame"
  )

  expect_error(
    multiscape::run_manual(data.frame()),
    "at least one row"
  )
})


test_that("mo_control exposes stable defaults", {
  x <- multiscape::mo_control()

  expect_s3_class(x, "MOControl")
  expect_false(x$stop_on_infeasible)
  expect_false(x$stop_on_no_solution)
  expect_true(x$stop_on_error)
  expect_equal(x$slack_upper_bound, 1e6)
})


test_that("mo_control validates each setting", {
  expect_error(
    multiscape::mo_control(stop_on_infeasible = NA),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::mo_control(stop_on_no_solution = 1),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::mo_control(stop_on_error = c(TRUE, FALSE)),
    "TRUE or FALSE"
  )

  expect_error(
    multiscape::mo_control(slack_upper_bound = 0),
    "positive"
  )

  expect_error(
    multiscape::mo_control(slack_upper_bound = Inf),
    "finite"
  )
})


test_that("internal control resolver accepts NULL and validates controls", {
  x <- multiscape:::.pamo_check_mo_control(NULL)

  expect_s3_class(x, "MOControl")

  custom <- multiscape::mo_control(
    stop_on_infeasible = TRUE,
    slack_upper_bound = 100
  )

  expect_identical(
    multiscape:::.pamo_check_mo_control(custom),
    custom
  )

  expect_error(
    multiscape:::.pamo_check_mo_control(list()),
    "mo_control"
  )
})
