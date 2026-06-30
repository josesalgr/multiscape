test_that("create_problem accepts integer-like character PU ids in hybrid sf mode", {
  skip_if_not_installed("sf")

  pu <- sf::st_sf(
    id = c("1001", "1002"),
    cost = c(1, 2),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(
        0, 0,
        1, 0,
        1, 1,
        0, 1,
        0, 0
      ), ncol = 2, byrow = TRUE))),
      sf::st_polygon(list(matrix(c(
        1, 0,
        2, 0,
        2, 1,
        1, 1,
        1, 0
      ), ncol = 2, byrow = TRUE)))
    )
  )

  features <- data.frame(
    id = c("1", "2"),
    name = c("carbon", "volume")
  )

  dist_features <- data.frame(
    pu = c("1001", "1002"),
    feature = c("1", "2"),
    amount = c(10, 20)
  )

  p <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  )

  expect_s3_class(p, "Problem")
  expect_true(all(c("id", "internal_id") %in% names(p$data$pu)))
  expect_type(p$data$pu$id, "integer")
  expect_type(p$data$features$id, "integer")
})

test_that("create_problem gives clear error for non integer-like PU ids", {
  skip_if_not_installed("sf")

  pu <- sf::st_sf(
    id = c("PU_1", "PU_2"),
    cost = c(1, 2),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(
        0, 0,
        1, 0,
        1, 1,
        0, 1,
        0, 0
      ), ncol = 2, byrow = TRUE))),
      sf::st_polygon(list(matrix(c(
        1, 0,
        2, 0,
        2, 1,
        1, 1,
        1, 0
      ), ncol = 2, byrow = TRUE)))
    )
  )

  features <- data.frame(
    id = 1,
    name = "carbon"
  )

  dist_features <- data.frame(
    pu = c("PU_1", "PU_2"),
    feature = c(1, 1),
    amount = c(10, 20)
  )

  expect_error(
    create_problem(
      pu = pu,
      features = features,
      dist_features = dist_features,
      cost = "cost"
    ),
    "integer-like"
  )
})
