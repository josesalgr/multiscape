test_that("SolutionSet accessors work without calling a solver", {
  s <- make_mock_solutionset()

  runs <- multiscape::get_runs(s)
  expect_equal(nrow(runs), 2L)
  expect_false(any(grepl("^value_", names(runs))))
  expect_false("message" %in% names(runs))

  obj_wide <- multiscape::get_objectives(s, format = "wide")
  expect_equal(nrow(obj_wide), 2L)
  expect_true(all(c("solution_id", "cost", "benefit") %in% names(obj_wide)))

  obj_long <- multiscape::get_objectives(s, format = "long")
  expect_equal(nrow(obj_long), 4L)
  expect_setequal(obj_long$objective, c("cost", "benefit"))

  expect_equal(nrow(multiscape::get_planning_units(s)), 8L)
  expect_equal(nrow(multiscape::get_planning_units(s, solution = 1)), 4L)
  expect_equal(nrow(multiscape::get_actions(s, solution = 2)), 4L)
  expect_equal(nrow(multiscape::get_features(s, solution = 1)), 2L)
  expect_equal(nrow(multiscape::get_targets(s, solution = 2)), 2L)

  expect_equal(multiscape:::get_solution_vector(s, solution = 1), c(1, 0, 0, 1))
  expect_error(multiscape::get_planning_units(s, solution = 99), "No rows")
})

test_that("accessors report clear errors for malformed SolutionSet objects", {
  malformed <- multiscape:::pproto(
    NULL,
    multiscape:::SolutionSet,
    solution = list(runs = data.frame(status = "optimal")),
    summary = list()
  )

  expect_error(multiscape::get_runs(malformed), "run_id")
  expect_error(multiscape::get_planning_units(malformed), "planning-unit summary")
  expect_error(
    multiscape:::get_solution_vector(malformed, solution = 1),
    "No stored solutions"
  )
})
