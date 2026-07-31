test_that("shipped tabular example data are loadable and consistent", {
  data("sim_pu", package = "multiscape")
  data("sim_features", package = "multiscape")
  data("sim_dist_features", package = "multiscape")

  expect_s3_class(sim_pu, "data.frame")
  expect_s3_class(sim_features, "data.frame")
  expect_s3_class(sim_dist_features, "data.frame")

  expect_true(all(c("id", "cost") %in% names(sim_pu)))
  expect_true("id" %in% names(sim_features))
  expect_true(all(c("pu", "feature", "amount") %in% names(sim_dist_features)))

  expect_true(all(sim_dist_features$pu %in% sim_pu$id))
  expect_true(all(sim_dist_features$feature %in% sim_features$id))
  expect_true(all(is.finite(sim_dist_features$amount)))
})

test_that("load_sim_features_raster returns the packaged SpatRaster", {
  skip_if_not_installed("terra")

  r <- multiscape::load_sim_features_raster()

  expect_s4_class(r, "SpatRaster")
  expect_gt(terra::nlyr(r), 0L)
  expect_gt(terra::ncell(r), 0L)
})

test_that("load_sim_multiaction returns complete and consistent inputs", {

  example_data <- multiscape::load_sim_multiaction()

  expect_named(
    example_data,
    c("planning_units", "features", "dist_features", "actions", "action_costs", "effect_assumptions", "effects")
  )
  expect_s3_class(example_data$planning_units, "sf")
  expect_equal(nrow(example_data$planning_units), 64L)
  expect_equal(nrow(example_data$features), 2L)
  expect_equal(nrow(example_data$actions), 2L)
  expect_true(all(example_data$dist_features$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$dist_features$feature %in% example_data$features$id))
  expect_true(all(example_data$action_costs$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$action_costs$action %in% example_data$actions$id))
  expect_named(example_data$effects, c("pu", "action", "feature", "delta"))
  expect_true(all(example_data$effects$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$effects$action %in% example_data$actions$id))
  expect_true(all(example_data$effects$feature %in% example_data$features$id))
})
