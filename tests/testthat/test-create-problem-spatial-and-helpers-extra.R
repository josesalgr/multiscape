test_that("create_problem internal path helpers and aggregators are robust", {
  tmp_r <- tempfile(fileext = ".tif")
  tmp_v <- tempfile(fileext = ".gpkg")
  file.create(tmp_r)
  file.create(tmp_v)

  expect_true(multiscape:::.pa_is_raster_path(tmp_r))
  expect_true(multiscape:::.pa_is_vector_path(tmp_v))
  expect_false(multiscape:::.pa_is_raster_path("not_existing.tif"))
  expect_false(multiscape:::.pa_is_vector_path("not_existing.gpkg"))
  expect_false(multiscape:::.pa_is_raster_path(c(tmp_r, tmp_r)))
  expect_false(multiscape:::.pa_is_vector_path(NA_character_))

  mean_fun <- multiscape:::.pa_fun_from_name("mean")
  sum_fun <- multiscape:::.pa_fun_from_name("sum")
  expect_equal(mean_fun(c(1, NA, 3)), 2)
  expect_equal(sum_fun(c(1, NA, 3)), 4)
  expect_error(multiscape:::.pa_fun_from_name("median"), "arg")
})


test_that("create_problem tabular mode preserves raw planning-unit data", {
  d <- make_round4_base_data()
  d$pu$owner <- c("a", "a", "b", "b")

  p <- multiscape::create_problem(
    pu = d$pu,
    features = d$features,
    dist_features = d$dist_features,
    cost = "cost"
  )

  expect_s3_class(p, "Problem")
  expect_equal(p$data$pu_data_raw$owner, d$pu$owner)
  expect_true(all(c("pu", "features", "dist_features") %in% names(p$data)))
})


test_that("create_problem spatial dispatch rejects missing cost before terra work", {
  expect_error(
    multiscape::create_problem(
      pu = "not_a_vector_file.gpkg",
      features = "not_a_raster_file.tif"
    ),
    "must provide `cost`"
  )
})


test_that("raster-cell create_problem keeps valid cells and positive feature amounts", {
  testthat::skip_if_not_installed("terra")

  mask <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2)
  terra::values(mask) <- c(1, NA, 1, 1)

  cost <- mask
  terra::values(cost) <- c(10, 20, 0, 30)
  names(cost) <- "cost"

  f1 <- mask
  f2 <- mask
  terra::values(f1) <- c(5, 6, 7, NA)
  terra::values(f2) <- c(0, 1, 2, 3)
  features <- c(f1, f2)
  names(features) <- c("sp1", "sp2")

  p <- multiscape::create_problem(
    pu = mask,
    features = features,
    cost = cost
  )

  expect_s3_class(p, "Problem")
  expect_equal(nrow(p$data$pu), 2L)
  expect_equal(p$data$pu$cost, c(10, 30))
  expect_equal(p$data$features$name, c("sp1", "sp2"))
  expect_true(all(p$data$dist_features$amount > 0))
  expect_equal(nrow(p$data$dist_features), 2L)
  expect_true(all(c("pu_coords", "cell_index", "pu_raster_mask", "cost_raster", "features_raster") %in% names(p$data)))
})


test_that("raster-cell create_problem validates cost layer and aligned geometry", {
  testthat::skip_if_not_installed("terra")

  mask <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2)
  terra::values(mask) <- 1
  features <- c(mask, mask)
  names(features) <- c("sp1", "sp2")

  bad_cost_layers <- c(mask, mask)
  expect_error(
    multiscape::create_problem(mask, features, cost = bad_cost_layers),
    "exactly 1 layer"
  )

  shifted_cost <- terra::rast(nrows = 2, ncols = 2, xmin = 10, xmax = 12, ymin = 0, ymax = 2)
  terra::values(shifted_cost) <- 1
  expect_error(
    multiscape::create_problem(mask, features, cost = shifted_cost),
    "share extent"
  )

  zero_cost <- mask
  terra::values(zero_cost) <- 0
  expect_error(
    multiscape::create_problem(mask, features, cost = zero_cost),
    "No valid cells"
  )
})
