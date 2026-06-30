make_round7_spatial_solutionset <- function() {
  testthat::skip_if_not_installed("sf")

  s <- make_mock_solutionset()

  g <- sf::st_sfc(
    sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(1, 0, 2, 0, 2, 1, 1, 1, 1, 0), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(0, 1, 1, 1, 1, 2, 0, 2, 0, 1), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(1, 1, 2, 1, 2, 2, 1, 2, 1, 1), ncol = 2, byrow = TRUE))),
    crs = 3857
  )

  s$problem$data$pu_sf <- sf::st_sf(id = 1:4, geometry = g)
  s
}


test_that("spatial plotting covers planning-unit dispatch and deprecated wrapper", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")

  s <- make_round7_spatial_solutionset()

  p1 <- multiscape::plot_spatial_planning_units(
    s,
    solutions = c(1, 2),
    draw_borders = TRUE,
    show_base = FALSE
  )
  expect_s3_class(p1, "ggplot")

  p2 <- multiscape:::plot_spatial(
    s,
    what = "pu",
    solutions = 1,
    draw_borders = FALSE,
    show_base = TRUE
  )
  expect_s3_class(p2, "ggplot")

  expect_warning(
    p3 <- multiscape::plot_spatial_pu(s, solutions = 1),
    "deprecated|replaced|plot_spatial_pu",
    fixed = FALSE
  )
  expect_s3_class(p3, "ggplot")
})


test_that("spatial plotting reports empty selections and malformed summaries", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")

  s <- make_round7_spatial_solutionset()

  empty <- s
  empty$summary$pu$selected <- 0L
  expect_error(multiscape::plot_spatial_planning_units(empty, solutions = 1), "No selected")

  malformed <- s
  malformed$summary$pu$selected <- NULL
  expect_error(multiscape::plot_spatial_planning_units(malformed, solutions = 1), "selected")
})


test_that("plot_tradeoff covers four-objective and too-many-objective branches", {
  testthat::skip_if_not_installed("ggplot2")

  s <- make_mock_solutionset()
  s$solution$runs$value_a <- c(1, 2)
  s$solution$runs$value_b <- c(2, 1)
  s$solution$runs$value_c <- c(3, 4)
  s$solution$runs$value_d <- c(4, 3)
  s$solution$runs$value_e <- c(5, 6)

  expect_error(
    multiscape::plot_tradeoff(s, objectives = c("cost", "benefit", "a", "b", "c")),
    "More than four"
  )

  p <- multiscape::plot_tradeoff(
    s,
    objectives = c("cost", "benefit", "a", "b", "c"),
    all_pairs = TRUE,
    color_by = "runtime",
    connect = TRUE,
    label_runs = TRUE
  )
  expect_s3_class(p, "ggplot")

  expect_error(multiscape::plot_tradeoff(s, objectives = c("cost", "unknown")), "Unknown objective")
  expect_error(
    multiscape::plot_tradeoff(
      s,
      objectives = c("cost", "a"),
      color_by = "not_a_column"
    ),
    "color_by|not_a_column"
  )
})
