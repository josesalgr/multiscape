test_that("hybrid sf plus tabular mode preserves geometry and resolves feature names", {
  skip_if_not_installed("sf")

  pu <- sf::st_sf(
    code = c(10, 20),
    cost_col = c(3, 4),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE))),
      sf::st_polygon(list(matrix(c(1, 0, 2, 0, 2, 1, 1, 1, 1, 0), ncol = 2, byrow = TRUE)))
    )
  )

  features <- data.frame(
    id = 1:2,
    name = c("carbon", "habitat")
  )

  dist_features <- data.frame(
    pu = c(10, 20),
    feature = c("carbon", "habitat"),
    amount = c(5, 6)
  )

  p <- multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost_col",
    pu_id_col = "code"
  )

  expect_s3_class(p, "Problem")
  expect_s3_class(p$data$pu_sf, "sf")
  expect_equal(p$data$pu$id, c(10L, 20L))
  expect_equal(p$data$pu$cost, c(3, 4))
  expect_equal(p$data$dist_features$feature, c(1L, 2L))
  expect_true(all(c("id", "x", "y") %in% names(p$data$pu_coords)))
})

test_that("hybrid sf plus tabular mode validates id, cost, and feature mapping", {
  skip_if_not_installed("sf")

  pu <- sf::st_sf(
    id = 1:2,
    cost = c(1, 2),
    geometry = sf::st_sfc(
      sf::st_point(c(0, 0)),
      sf::st_point(c(1, 1))
    )
  )
  features <- data.frame(id = 1, name = "sp1")

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = data.frame(pu = 3, feature = "sp1", amount = 1)
    ),
    "not present in `pu`"
  )

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = data.frame(pu = 1, feature = "unknown", amount = 1)
    ),
    "Unmatched values"
  )

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = data.frame(pu = 1, feature = "sp1", amount = 1),
      cost = "missing_cost"
    ),
    "cost"
  )
})
