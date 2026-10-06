test_that("bounded polygon extraction preserves exact aggregated values", {
  skip_if_not_installed("terra")
  skip_if_not_installed("exactextractr")
  r <- terra::rast(nrows=4,ncols=4,xmin=0,xmax=4,ymin=0,ymax=4,crs="EPSG:3857")
  terra::values(r) <- seq_len(16)
  boxes <- sf::st_as_sf(data.frame(id=1:2,wkt=c(
    "POLYGON ((0 0, 2 0, 2 4, 0 4, 0 0))",
    "POLYGON ((2 0, 4 0, 4 4, 2 4, 2 0))")), wkt="wkt",crs=3857)
  expected <- exactextractr::exact_extract(r,boxes,"sum",progress=FALSE)
  actual <- multiscape:::.pa_fast_extract(r,boxes,"sum")
  expect_equal(as.numeric(actual),expected)
  expect_equal(as.numeric(actual),c(60,76))
})
