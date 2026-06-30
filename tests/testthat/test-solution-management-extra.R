test_that("solution filtering covers feasible, status, nondominated, and top-n paths", {
  s <- make_mock_solutionset()

  feasible <- multiscape::solution_filter(s, feasible_only = TRUE)
  expect_s3_class(feasible, "SolutionSet")
  expect_true(all(feasible$solution$runs$status %in% c("optimal", "time_limit_feasible")))

  optimal <- multiscape::solution_filter(s, status = "optimal")
  expect_equal(nrow(optimal$solution$runs), 1L)

  by_run <- multiscape::solution_filter(s, run_id = 1)
  expect_equal(by_run$solution$runs$run_id, 1L)

  by_solution <- multiscape::solution_filter(s, solution_id = 2)
  expect_equal(by_solution$solution$runs$solution_id, 2L)

  expect_error(multiscape::solution_filter(list()), "SolutionSet")
  expect_error(multiscape::solution_filter(s, run_id = 999), "Unknown run_id")
  expect_error(multiscape::solution_filter(s, solution_id = 999), "Unknown solution_id")
  expect_error(multiscape::solution_filter(s, status = "missing"), "Unknown status")
})


test_that("solution unique and append validate stored solution sets", {
  s <- make_mock_solutionset()

  unique_dec <- multiscape::solution_unique(s, by = "decisions")
  expect_s3_class(unique_dec, "SolutionSet")
  expect_lte(nrow(unique_dec$solution$runs), nrow(s$solution$runs))

  unique_obj <- multiscape::solution_unique(s, by = "objectives")
  expect_s3_class(unique_obj, "SolutionSet")

  expect_error(multiscape::solution_unique(list()), "SolutionSet")
  expect_error(multiscape::solution_unique(s, by = "bad"), "arg")

  expect_error(
    multiscape::solution_append(s, s),
    "Multiple stored solutions point to the same run_id|same run_id"
  )

  expect_error(multiscape::solution_append(list(), s), "SolutionSet")
  expect_error(multiscape::solution_append(s, list()), "SolutionSet")
})
