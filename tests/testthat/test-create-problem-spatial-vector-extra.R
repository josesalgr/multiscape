make_cp6_rasters <- function(blank_names = FALSE) {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2)
  terra::values(r) <- c(1, 2, 3, 4)

  f1 <- r
  f2 <- r
  terra::values(f1) <- c(1, 0, 2, 3)
  terra::values(f2) <- c(0, 4, 0, 5)
  features <- c(f1, f2)
  if (blank_names) {
    names(features) <- c("", "")
  } else {
    names(features) <- c("sp1", "sp2")
  }

  cost <- r
  terra::values(cost) <- c(10, 20, 30, 40)
  names(cost) <- "cost"

  list(mask = r, features = features, cost = cost)
}

make_cp6_sf_pu <- function(with_id = TRUE, with_cost = TRUE) {
  testthat::skip_if_not_installed("sf")

  g <- sf::st_sfc(
    sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 2, 0, 2, 0, 0), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(1, 0, 2, 0, 2, 2, 1, 2, 1, 0), ncol = 2, byrow = TRUE)))
  )

  x <- data.frame(.row = 1:2)
  if (with_id) x$id <- 1:2
  if (with_cost) x$cost <- c(10, 20)
  x$.row <- NULL
  sf::st_sf(x, geometry = g)
}


test_that("create_problem low-level spatial readers cover raster, vector, and path branches", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")

  rr <- make_cp6_rasters()

  expect_s4_class(multiscape:::.pa_read_rast(rr$cost), "SpatRaster")

  tmp_tif <- tempfile(fileext = ".tif")
  terra::writeRaster(rr$cost, tmp_tif, overwrite = TRUE)
  expect_s4_class(multiscape:::.pa_read_rast(tmp_tif), "SpatRaster")
  expect_null(multiscape:::.pa_read_rast("not_a_raster.csv"))

  pu_sf <- make_cp6_sf_pu()
  expect_s4_class(multiscape:::.pa_read_vect(pu_sf), "SpatVector")

  pu_v <- terra::vect(pu_sf)
  expect_s4_class(multiscape:::.pa_read_vect(pu_v), "SpatVector")

  tmp_gpkg <- tempfile(fileext = ".gpkg")
  terra::writeVector(pu_v, tmp_gpkg, overwrite = TRUE)
  expect_s4_class(multiscape:::.pa_read_vect(tmp_gpkg), "SpatVector")
  expect_null(multiscape:::.pa_read_vect("not_a_vector.csv"))
})


test_that("raster-cell mode covers unnamed feature layers and empty positive amounts", {
  testthat::skip_if_not_installed("terra")

  rr <- make_cp6_rasters(blank_names = TRUE)

  p <- multiscape::create_problem(
    pu = rr$mask,
    features = rr$features,
    cost = rr$cost
  )

  expect_s3_class(p, "Problem")
  expect_equal(p$data$features$name, c("feature.1", "feature.2"))
  expect_true(all(c("cell_index", "pu_coords", "features_raster") %in% names(p$data)))

  zero_features <- rr$features
  terra::values(zero_features) <- 0

  expect_error(
    multiscape:::.pa_create_problem_raster_cells_impl(
      pu = rr$mask,
      features = zero_features,
      cost = rr$cost
    ),
    "nrow\\(dist_features\\)|dist_features|greater than 0"
  )
})


test_that("spatial vector plus raster mode covers cost-column, cost-raster, and NULL delegation", {
  testthat::skip_if_not_installed("terra")
  testthat::skip_if_not_installed("sf")

  rr <- make_cp6_rasters(blank_names = TRUE)
  pu_no_id <- make_cp6_sf_pu(with_id = FALSE, with_cost = TRUE)

  expect_warning(
    p_auto <- multiscape::create_problem(
      pu = pu_no_id,
      features = rr$features,
      cost = "cost"
    ),
    "no 'id' column|Creating sequential ids"
  )
  expect_s3_class(p_auto, "Problem")
  expect_true(all(c("pu_coords", "pu_data_raw", "pu_sf") %in% names(p_auto$data)))
  expect_equal(p_auto$data$features$name, c("feature.1", "feature.2"))
  expect_true(all(p_auto$data$dist_features$amount > 0))

  pu_id <- make_cp6_sf_pu(with_id = TRUE, with_cost = TRUE)

  p_cost_raster <- multiscape::create_problem(
    pu = pu_id,
    features = rr$features,
    cost = rr$cost,
    cost_aggregation = "sum"
  )
  expect_s3_class(p_cost_raster, "Problem")
  expect_true(all(is.finite(p_cost_raster$data$pu$cost)))
  expect_true(all(p_cost_raster$data$pu$cost > 0))

  p_null <- multiscape::create_problem(
    pu = pu_id,
    features = rr$features,
    dist_features = NULL,
    cost = "cost"
  )
  expect_s3_class(p_null, "Problem")

  expect_error(
    multiscape::create_problem(pu_id, rr$features, cost = "cost", pu_id_col = "missing_id"),
    "missing the id column"
  )

  expect_error(
    multiscape::create_problem(pu_id, data.frame(a = 1), cost = "cost"),
    "features.*SpatRaster|tabular mode"
  )

  expect_error(
    multiscape::create_problem(pu_id, rr$features, cost = "not_a_cost_column"),
    "provide `cost`"
  )
})
