test_that("plot_tradeoff covers color, labels, all-pairs, and validation branches", {
  testthat::skip_if_not_installed("ggplot2")

  s <- make_mock_solutionset()

  p1 <- multiscape::plot_tradeoff(s, color_by = "status", connect = TRUE, label_runs = TRUE)
  expect_s3_class(p1, "ggplot")

  p2 <- multiscape::plot_tradeoff(s, objectives = c("cost", "benefit"), color_by = "cost")
  expect_s3_class(p2, "ggplot")

  expect_error(multiscape::plot_tradeoff(make_round4_problem()), "SolutionSet")

  s_one <- s
  s_one$solution$runs$value_benefit <- NULL
  expect_error(multiscape::plot_tradeoff(s_one), "At least two objective")

  expect_error(multiscape::plot_tradeoff(s, objectives = "cost"), "At least two")
  expect_error(
    multiscape::plot_tradeoff(s, objectives = c("cost", "missing"))
  )
  expect_error(
    multiscape::plot_tradeoff(s, color_by = "missing"),
    "At least two objective value columns|color_by|missing"
  )

  s_many <- s
  s_many$solution$runs$value_a <- c(1, 2)
  s_many$solution$runs$value_b <- c(2, 3)
  s_many$solution$runs$value_c <- c(3, 4)

  p_many <- multiscape::plot_tradeoff(
    s_many,
    objectives = c("cost", "a", "b", "c"),
    all_pairs = TRUE,
    color_by = "runtime"
  )
  expect_s3_class(p_many, "ggplot")
})
