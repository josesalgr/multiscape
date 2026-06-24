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
