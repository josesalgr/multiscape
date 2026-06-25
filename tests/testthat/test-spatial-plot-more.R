test_that("spatial plot helpers cover multi-solution and dispatcher branches", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("ggplot2")

  # Add simple polygon geometry to the mock SolutionSet problem.
  make_square <- function(x0, y0) {
    sf::st_polygon(list(matrix(
      c(
        x0, y0,
        x0 + 1, y0,
        x0 + 1, y0 + 1,
        x0, y0 + 1,
        x0, y0
      ),
      ncol = 2,
      byrow = TRUE
    )))
  }

  s <- make_mock_solutionset()
  s$problem$data$pu_sf <- sf::st_sf(
    id = 1:4,
    geometry = sf::st_sfc(
      make_square(0, 0),
      make_square(1, 0),
      make_square(0, 1),
      make_square(1, 1)
    )
  )

  expect_error(
    p_pu <- multiscape::plot_spatial_planning_units(
      s,
      solutions = c(1, 2),
      show_base = FALSE,
      draw_borders = TRUE
    ),
    NA
  )
  expect_s3_class(p_pu, "ggplot")

  expect_error(
    p_dispatch <- multiscape:::plot_spatial(
      s,
      what = "pu",
      solutions = 1,
      show_base = FALSE
    ),
    NA
  )
  expect_s3_class(p_dispatch, "ggplot")

  expect_error(
    p_actions_multi <- multiscape::plot_spatial_actions(
      s,
      solutions = c(1, 2),
      layout = "single",
      show_base = FALSE,
      use_viridis = FALSE
    ),
    NA
  )
  expect_s3_class(p_actions_multi, "ggplot")

  expect_error(
    multiscape::plot_spatial_actions(
      s,
      solutions = c(1, 2),
      layout = "facet"
    ),
    "multiple runs|Faceting"
  )

  expect_warning(
    p_actions_facet <- multiscape::plot_spatial_actions(
      s,
      solutions = 1,
      layout = "facet",
      max_facets = 1,
      show_base = FALSE,
      use_viridis = FALSE
    ),
    "Showing only the first"
  )
  expect_s3_class(p_actions_facet, "ggplot")

  expect_error(
    p_features_multi <- multiscape::plot_spatial_features(
      s,
      solutions = c(1, 2),
      features = "sp1",
      value = "baseline",
      layout = "single",
      use_viridis = FALSE
    ),
    NA
  )
  expect_s3_class(p_features_multi, "ggplot")

  expect_error(
    multiscape::plot_spatial_features(
      s,
      solutions = c(1, 2),
      value = "baseline"
    ),
    "exactly one feature"
  )

  expect_error(
    p_feature_dispatch <- multiscape:::plot_spatial(
      s,
      what = "features",
      solutions = 1,
      features = "sp2",
      value = "benefit",
      layout = "single",
      use_viridis = FALSE
    ),
    NA
  )
  expect_s3_class(p_feature_dispatch, "ggplot")
})
