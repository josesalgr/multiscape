test_that("Problem print and show methods return invisibly", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(out <- print(p), NA)
  expect_true(isTRUE(out))

  expect_error(out_show <- methods::show(p), NA)
  expect_true(isTRUE(out_show))
})

test_that("Solution helper formatting covers status and numeric edge cases", {
  expect_equal(multiscape:::.pa_solution_status_class("optimal"), "ok")
  expect_equal(multiscape:::.pa_solution_status_class("time_limit_feasible"), "warn")
  expect_equal(multiscape:::.pa_solution_status_class("unknown"), "bad")
  expect_equal(multiscape:::.pa_solution_status_class("other"), "muted")

  expect_equal(multiscape:::.pa_pct_text(0.1234, digits = 1), "12.3%")
  expect_equal(multiscape:::.pa_pct_text(NA_real_), "NA")
  expect_equal(multiscape:::.pa_num_text(12.34567, digits = 2), "12.35")
  expect_equal(multiscape:::.pa_num_text(Inf), "NA")
  expect_equal(multiscape:::.pa_n_of_total_text(2, 5), "2 of 5")
  expect_equal(multiscape:::.pa_n_of_total_text(NULL, NA), "0")
})

test_that("hand-made Solution and SolutionSet print, show, and repr work", {
  s <- make_mock_solutionset()
  sol <- s$solution$solutions[[1]]

  expect_output(out_sol <- sol$print(), NA)
  expect_true(isTRUE(out_sol))
  expect_match(sol$repr(), "<Solution>")

  expect_output(out_set <- print(s), NA)
  expect_true(isTRUE(out_set))
  expect_output(out_show <- methods::show(s), NA)
  expect_true(isTRUE(out_show))
  expect_match(s$repr(), "<SolutionSet>")
})
