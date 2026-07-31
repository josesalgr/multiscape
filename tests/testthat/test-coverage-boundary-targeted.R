test_that("boundary tables canonicalize reversed edges and effective diagonals", {
  p <- make_round3_tabular_problem()
  boundary <- data.frame(
    id1 = c(1, 2, 1, 2, 3, 4),
    id2 = c(2, 1, 1, 2, 3, 4),
    boundary = c(2, 3, 10, 10, 8, 6)
  )

  out <- multiscape::add_spatial_boundary(
    p,
    boundary = boundary,
    include_self = TRUE,
    edge_factor = 0.5,
    weight_multiplier = 2
  )

  rel <- out$data$spatial_relations$boundary
  expect_true(any(rel$internal_pu1 != rel$internal_pu2))
  expect_true(any(rel$internal_pu1 == rel$internal_pu2))
  expect_equal(
    rel$weight[
      rel$internal_pu1 == 1 &
        rel$internal_pu2 == 2
    ],
    6
  )
  expect_true(all(c("pu1", "pu2", "source") %in% names(rel)))
  expect_true(any(rel$source == "boundary_table_diag_effective"))
})


test_that("boundary tables create algebraic self terms without input diagonals", {
  p <- make_round3_tabular_problem()
  boundary <- data.frame(
    pu1 = c(1, 2, 3),
    pu2 = c(2, 3, 4),
    weight = c(1, 2, 3)
  )

  out <- multiscape::add_spatial_boundary(
    p,
    boundary = boundary,
    include_self = TRUE
  )
  rel <- out$data$spatial_relations$boundary

  diag <- rel[rel$internal_pu1 == rel$internal_pu2, ]
  expect_equal(nrow(diag), 4L)
  expect_true(all(diag$weight <= 0))
  expect_true(all(diag$source == "boundary_table_diag_algebraic"))
})


test_that("boundary table validation covers missing and degenerate inputs", {
  p <- make_round3_tabular_problem()

  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 2, x = 1)
    ),
    "Could not find a weight column"
  )
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 2, weight = 1),
      weight_col = "missing"
    ),
    "weight_col not found"
  )
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 99, weight = 1)
    ),
    "ids were not found"
  )
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 1, weight = 1),
      include_self = FALSE
    ),
    "no off-diagonal edges"
  )
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 2, weight = 1),
      edge_factor = -1
    ),
    "edge_factor"
  )
  expect_error(
    multiscape::add_spatial_boundary(
      p,
      boundary = data.frame(pu1 = 1, pu2 = 2, weight = 1),
      weight_multiplier = 0
    ),
    "weight_multiplier"
  )
})
