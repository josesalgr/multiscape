test_that("new SolutionSet accessors expose run and objective identifiers", {
  x <- solve_explicit_mo_problem(n = 3)

  runs <- multiscape::get_runs(x)
  objectives_long <- multiscape::get_objectives(x, format = "long")
  objectives_wide <- multiscape::get_objectives(
    x,
    format = "wide"
  )

  expect_s3_class(x, "SolutionSet")
  expect_s3_class(runs, "data.frame")
  expect_true(all(c("solution_id", "status") %in% names(runs)))

  expect_true(
    all(c("solution_id", "objective", "value") %in%
          names(objectives_long))
  )

  expect_true(
    all(c("solution_id", "cost", "benefit") %in%
          names(objectives_wide))
  )

})


test_that("planning-unit and action accessors retain solution ids", {
  x <- solve_explicit_mo_problem(n = 3)

  pu <- multiscape::get_planning_units(x)
  actions <- multiscape::get_actions(x)

  expect_true(all(c("solution_id", "selected") %in% names(pu)))
  expect_true(
    all(c("solution_id", "pu", "action", "selected") %in%
          names(actions))
  )

  expect_true(all(pu$selected %in% c(0, 1)))
  expect_true(all(actions$selected %in% c(0, 1)))
})
