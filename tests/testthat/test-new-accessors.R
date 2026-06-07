test_that("new SolutionSet accessors expose run and objective identifiers", {
  x <- solve_explicit_mo_problem(n = 3)

  runs <- multiscape::get_runs(x)
  objectives_long <- multiscape::get_objectives(x)
  objectives_wide <- multiscape::get_objectives(
    x,
    format = "wide"
  )
  specs <- multiscape::get_objective_specs(x)

  expect_s3_class(x, "SolutionSet")
  expect_s3_class(runs, "data.frame")
  expect_true(all(c("run_id", "solution_id", "status") %in% names(runs)))

  expect_true(
    all(c("run_id", "solution_id", "objective", "value") %in%
          names(objectives_long))
  )

  expect_true(
    all(c("run_id", "solution_id", "cost", "benefit") %in%
          names(objectives_wide))
  )

  expect_setequal(specs$objective, c("cost", "benefit"))
  expect_setequal(specs$sense, c("min", "max"))
})


test_that("get_solution_vector resolves by solution_id and run_id", {
  x <- solve_explicit_mo_problem(n = 3)
  runs <- multiscape::get_runs(x)

  solved <- runs[
    !is.na(runs$solution_id) &
      nzchar(runs$solution_id),
    ,
    drop = FALSE
  ]

  expect_gt(nrow(solved), 0L)

  by_solution <- multiscape::get_solution_vector(
    x,
    solution_id = solved$solution_id[1]
  )

  by_run <- multiscape::get_solution_vector(
    x,
    run = solved$run_id[1]
  )

  expect_type(by_solution, "double")
  expect_equal(by_solution, by_run)
  expect_gt(length(by_solution), 0L)

  expect_error(
    multiscape::get_solution_vector(
      x,
      run = solved$run_id[1],
      solution_id = solved$solution_id[1]
    ),
    "not both"
  )
})


test_that("planning-unit and action accessors retain solution ids", {
  x <- solve_explicit_mo_problem(n = 3)

  pu <- multiscape::get_pu(x)
  actions <- multiscape::get_actions(x)

  expect_true(all(c("run_id", "solution_id", "selected") %in% names(pu)))
  expect_true(
    all(c("run_id", "solution_id", "pu", "action", "selected") %in%
          names(actions))
  )

  expect_true(all(pu$selected %in% c(0, 1)))
  expect_true(all(actions$selected %in% c(0, 1)))
})
