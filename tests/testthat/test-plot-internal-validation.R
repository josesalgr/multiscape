test_that("spatial plot solution resolver validates run and solution mappings", {
  s <- make_mock_solutionset()

  expect_equal(multiscape:::.pa_plot_spatial_resolve_solutions(s), 1L)
  expect_equal(multiscape:::.pa_plot_spatial_resolve_solutions(s, solutions = c(2, 2)), 2L)

  expect_error(
    multiscape:::.pa_plot_spatial_resolve_solutions(s, solutions = 0),
    "positive integer"
  )
  expect_error(
    multiscape:::.pa_plot_spatial_resolve_solutions(s, solutions = 99),
    "No stored solution"
  )
  expect_error(
    multiscape:::.pa_plot_spatial_resolve_solutions(s, solutions = 1, runs = 1),
    "either `solutions` or deprecated `runs`"
  )
})

test_that("spatial plot geometry helper reports missing geometry clearly", {
  s <- make_mock_solutionset()

  expect_error(
    multiscape:::.pa_plot_spatial_get_geometry(s),
    "No planning-unit geometry"
  )

  malformed <- s
  malformed$problem <- NULL
  expect_error(
    multiscape:::.pa_plot_spatial_get_geometry(malformed),
    "valid associated Problem"
  )
})

test_that("plot_tradeoff validates malformed inputs and missing objective columns", {
  skip_if_not_installed("ggplot2")

  expect_error(multiscape::plot_tradeoff(data.frame()), "SolutionSet")

  s <- make_mock_solutionset()
  s$solution$runs$value_cost <- NULL
  s$solution$runs$value_benefit <- NULL

  expect_error(multiscape::plot_tradeoff(s), "objective")
})
