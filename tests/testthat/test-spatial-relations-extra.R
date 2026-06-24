test_that("manual spatial relations normalize undirected edges and validate inputs", {
  p <- make_round4_problem()

  rel <- data.frame(
    pu1 = c(2, 1, 3),
    pu2 = c(1, 2, 4),
    weight = c(1, 3, 2),
    distance = c(10, 10, 20)
  )
  p2 <- multiscape::add_spatial_relations(p, rel, name = "manual")
  out <- p2$data$spatial_relations$manual
  expect_equal(nrow(out), 2L)
  expect_true(any(out$internal_pu1 == 1L & out$internal_pu2 == 2L & out$weight == 3))
  expect_equal(unique(out$relation_name), "manual")

  directed <- multiscape::add_spatial_relations(p, rel[1:2, ], name = "directed", directed = TRUE)
  expect_equal(nrow(directed$data$spatial_relations$directed), 2L)

  expect_error(multiscape::add_spatial_relations(p, rel, name = ""), "name")
  expect_error(multiscape::add_spatial_relations(p, data.frame(pu1 = 1, pu2 = 99, weight = 1), name = "bad"), "not found")
  expect_error(multiscape::add_spatial_relations(p, data.frame(pu1 = 1, pu2 = 1, weight = 1), name = "self"), "Self-edges")

  self_ok <- multiscape::add_spatial_relations(
    p,
    data.frame(pu1 = 1, pu2 = 1, weight = 1),
    name = "self_ok",
    allow_self = TRUE
  )
  expect_equal(nrow(self_ok$data$spatial_relations$self_ok), 1L)
})


test_that("boundary-table relations cover diagonal, off-diagonal, and validation branches", {
  p <- make_round4_problem()

  b <- data.frame(
    id1 = c(1, 1, 2, 3, 4),
    id2 = c(1, 2, 2, 4, 4),
    boundary = c(10, 3, 8, 5, 6)
  )

  with_self <- multiscape::add_spatial_boundary(
    p,
    boundary = b,
    name = "bd",
    include_self = TRUE,
    edge_factor = 0.5
  )
  expect_true("bd" %in% names(with_self$data$spatial_relations))
  expect_true(any(with_self$data$spatial_relations$bd$internal_pu1 == with_self$data$spatial_relations$bd$internal_pu2))

  no_self <- multiscape::add_spatial_boundary(
    p,
    boundary = b,
    name = "bd2",
    include_self = FALSE
  )
  expect_false(any(no_self$data$spatial_relations$bd2$internal_pu1 == no_self$data$spatial_relations$bd2$internal_pu2))

  expect_error(multiscape::add_spatial_boundary(p, boundary = b, edge_factor = -1), "edge_factor")
  expect_error(multiscape::add_spatial_boundary(p, boundary = b, weight_multiplier = 0), "weight_multiplier")
  expect_error(multiscape::add_spatial_boundary(p, boundary = data.frame(pu1 = 1, pu2 = 2)), "weight column")
  expect_error(multiscape::add_spatial_boundary(p, boundary = data.frame(pu1 = 1, pu2 = 99, boundary = 1)), "not found")
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = c(1, 2), pu2 = c(1, 2), boundary = c(1, 1)),
      include_self = FALSE
    ),
    "no off-diagonal"
  )
})


test_that("coordinate-based spatial relations use stored and supplied coordinates", {
  p <- make_round4_problem()
  p$data$pu$x <- c(0, 1, 0, 2)
  p$data$pu$y <- c(0, 0, 1, 0)

  d1 <- multiscape::add_spatial_distance(p, max_distance = 1.01, name = "near", weight_mode = "constant")
  expect_true("near" %in% names(d1$data$spatial_relations))
  expect_true(all(d1$data$spatial_relations$near$weight == 1))

  d2 <- multiscape::add_spatial_distance(p, max_distance = 1.01, name = "near_inv", weight_mode = "inverse")
  expect_true(all(d2$data$spatial_relations$near_inv$weight > 0))

  expect_error(multiscape::add_spatial_distance(p, max_distance = 0), "max_distance")
  expect_error(multiscape::add_spatial_distance(p, max_distance = 0.1), "No edges")

  coords <- data.frame(id = 1:4, x = c(0, 1, 0, 2), y = c(0, 0, 1, 0))
  k1 <- multiscape::add_spatial_knn(p, coords = coords, k = 1, name = "knn1", weight_mode = "inverse_sq")
  expect_true("knn1" %in% names(k1$data$spatial_relations))
  expect_true(all(k1$data$spatial_relations$knn1$weight > 0))

  expect_error(multiscape::add_spatial_knn(p, coords = coords, k = 0), "k must be")
  expect_error(multiscape::add_spatial_knn(p, coords = coords, k = 4), "number of PUs")
  expect_error(multiscape::add_spatial_knn(p, coords = coords[-1, ], k = 1), "cover all")
})
