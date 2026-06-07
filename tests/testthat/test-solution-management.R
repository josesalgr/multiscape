test_that("solution_filter returns an independent filtered SolutionSet", {
  x <- solve_explicit_mo_problem(n = 5)
  original_runs <- multiscape::get_runs(x)

  solved <- original_runs[
    !is.na(original_runs$solution_id) &
      nzchar(original_runs$solution_id),
    ,
    drop = FALSE
  ]

  expect_gte(nrow(solved), 2L)

  out <- multiscape::solution_filter(
    x,
    run_id = solved$run_id[1:2]
  )

  expect_s3_class(out, "SolutionSet")
  expect_equal(
    multiscape::get_runs(out)$run_id,
    solved$run_id[1:2]
  )

  # Filtering must not mutate the original pproto object.
  expect_identical(
    multiscape::get_runs(x),
    original_runs
  )
})


test_that("solution_filter supports solution and status filters", {
  x <- solve_explicit_mo_problem(n = 4)
  runs <- multiscape::get_runs(x)

  solved <- runs[
    !is.na(runs$solution_id) &
      nzchar(runs$solution_id),
    ,
    drop = FALSE
  ]

  by_solution <- multiscape::solution_filter(
    x,
    solution_id = solved$solution_id[1]
  )

  expect_equal(
    multiscape::get_runs(by_solution)$solution_id,
    solved$solution_id[1]
  )

  if ("optimal" %in% tolower(runs$status)) {
    by_status <- multiscape::solution_filter(
      x,
      status = "OPTIMAL"
    )

    expect_true(
      all(tolower(multiscape::get_runs(by_status)$status) == "optimal")
    )
  }

  expect_error(
    multiscape::solution_filter(x, run_id = 99999L),
    "Unknown run_id"
  )
})


test_that("solution_unique never increases the number of stored solutions", {
  x <- solve_explicit_mo_problem(n = 7)

  n_original <- sum(
    !is.na(multiscape::get_runs(x)$solution_id)
  )

  by_decisions <- multiscape::solution_unique(
    x,
    by = "decisions"
  )

  by_objectives <- multiscape::solution_unique(
    x,
    by = "objectives"
  )

  expect_lte(
    sum(!is.na(multiscape::get_runs(by_decisions)$solution_id)),
    n_original
  )

  expect_lte(
    sum(!is.na(multiscape::get_runs(by_objectives)$solution_id)),
    n_original
  )

  expect_s3_class(by_decisions, "SolutionSet")
  expect_s3_class(by_objectives, "SolutionSet")
})


test_that("solution_append combines compatible results without mutation", {
  x <- solve_explicit_mo_problem(n = 3)
  y <- solve_explicit_mo_problem(n = 4)

  x_runs <- multiscape::get_runs(x)
  y_runs <- multiscape::get_runs(y)

  out <- multiscape::solution_append(x, y)
  out_runs <- multiscape::get_runs(out)

  expect_s3_class(out, "SolutionSet")
  expect_equal(
    nrow(out_runs),
    nrow(x_runs) + nrow(y_runs)
  )
  expect_identical(anyDuplicated(out_runs$run_id), 0L)
  expect_identical(
    anyDuplicated(
      out_runs$solution_id[
        !is.na(out_runs$solution_id)
      ]
    ),
    0L
  )

  expect_identical(multiscape::get_runs(x), x_runs)
  expect_identical(multiscape::get_runs(y), y_runs)
})
