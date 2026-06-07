test_that("add_spatial_relations normalizes undirected duplicate edges", {
  x <- make_round3_tabular_problem()

  relations <- data.frame(
    pu1 = c(1, 2, 1),
    pu2 = c(2, 1, 2),
    weight = c(1, 3, 2)
  )

  out <- multiscape::add_spatial_relations(
    x,
    relations = relations,
    name = "custom",
    directed = FALSE
  )

  rel <- out$data$spatial_relations$custom

  expect_s3_class(rel, "data.frame")
  expect_equal(nrow(rel), 1L)
  expect_equal(rel$weight, 3)
  expect_equal(rel$relation_name, "custom")
})


test_that("add_spatial_relations validates names, ids, and self edges", {
  x <- make_round3_tabular_problem()

  expect_error(
    multiscape::add_spatial_relations(
      x,
      relations = data.frame(pu1 = 1, pu2 = 2, weight = 1),
      name = ""
    )
  )

  expect_error(
    multiscape::add_spatial_relations(
      x,
      relations = data.frame(pu1 = 1, pu2 = 999, weight = 1),
      name = "bad"
    )
  )

  expect_error(
    multiscape::add_spatial_relations(
      x,
      relations = data.frame(pu1 = 1, pu2 = 1, weight = 1),
      name = "self",
      allow_self = FALSE
    ),
    "Self-edges"
  )

  allowed <- multiscape::add_spatial_relations(
    x,
    relations = data.frame(pu1 = 1, pu2 = 1, weight = 2),
    name = "self",
    allow_self = TRUE
  )

  expect_equal(
    allowed$data$spatial_relations$self$internal_pu1,
    allowed$data$spatial_relations$self$internal_pu2
  )
})


test_that("coordinate spatial relations support knn and distance modes", {
  x <- make_round3_tabular_problem()
  coords <- data.frame(
    id = 1:4,
    x = c(0, 1, 0, 1),
    y = c(0, 0, 1, 1)
  )

  knn <- multiscape::add_spatial_knn(
    x,
    coords = coords,
    k = 1,
    name = "knn1"
  )

  expect_gt(nrow(knn$data$spatial_relations$knn1), 0L)

  distance <- multiscape::add_spatial_distance(
    x,
    coords = coords,
    max_distance = 1.01,
    name = "near",
    weight_mode = "inverse"
  )

  expect_gt(nrow(distance$data$spatial_relations$near), 0L)
  expect_true(all(distance$data$spatial_relations$near$weight > 0))

  expect_error(
    multiscape::add_spatial_distance(
      x,
      coords = coords,
      max_distance = 0
    ),
    "positive finite"
  )

  expect_error(
    multiscape::add_spatial_distance(
      x,
      coords = coords,
      max_distance = 0.01
    ),
    "No edges"
  )
})


test_that("rook and queen relations can be derived from geometry", {
  testthat::skip_if_not_installed("sf")

  x <- make_round3_spatial_problem(action_based = FALSE)

  rook <- multiscape::add_spatial_rook(
    x,
    name = "rook"
  )

  queen <- multiscape::add_spatial_queen(
    x,
    name = "queen"
  )

  expect_gt(nrow(rook$data$spatial_relations$rook), 0L)
  expect_gt(nrow(queen$data$spatial_relations$queen), 0L)
  expect_gte(
    nrow(queen$data$spatial_relations$queen),
    nrow(rook$data$spatial_relations$rook)
  )
})
