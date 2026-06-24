test_that("frontier helpers compute distances and validate bad inputs", {
  mat <- matrix(
    c(
      0, 0,
      1, 0,
      1, 1
    ),
    ncol = 2,
    byrow = TRUE
  )

  expect_equal(
    multiscape:::.pa_frontier_distance(mat, ref = c(0, 0), metric = "euclidean"),
    c(0, 1, sqrt(2))
  )
  expect_equal(
    multiscape:::.pa_frontier_distance(mat, ref = c(0, 0), metric = "manhattan"),
    c(0, 1, 2)
  )
  expect_equal(
    multiscape:::.pa_frontier_distance(mat, ref = c(0, 0), metric = "chebyshev"),
    c(0, 1, 1)
  )

  expect_error(
    multiscape:::.pa_frontier_distance(mat, ref = c(0, 0, 0)),
    "Reference point length"
  )
  expect_error(
    multiscape:::.pa_frontier_distance(matrix(c(1, NA), ncol = 2), ref = c(0, 0)),
    "missing|non-finite"
  )
  expect_error(
    multiscape:::.pa_frontier_distance(mat, ref = c(0, Inf)),
    "Reference point"
  )
})


test_that("frontier normalization and knee scorers cover zero-range and angle cases", {
  z <- matrix(
    c(
      2, 5,
      2, 7,
      2, 9
    ),
    ncol = 2,
    byrow = TRUE
  )

  norm <- multiscape:::.pa_normalize_min_objective_matrix(z)
  expect_equal(norm$matrix[, 1], c(0, 0, 0))
  expect_equal(norm$matrix[, 2], c(0, 0.5, 1))
  expect_equal(norm$ranges, c(0, 4))

  expect_error(
    multiscape:::.pa_normalize_min_objective_matrix(matrix(c(1, NaN), ncol = 1)),
    "missing|non-finite"
  )

  dist_score <- multiscape:::.pa_knee_distance_score_2d(
    matrix(c(0, 1, 0.5, 0.25, 1, 0), ncol = 2, byrow = TRUE)
  )
  expect_length(dist_score, 3L)
  expect_true(all(is.finite(dist_score)))

  angle <- multiscape:::.pa_knee_angle_score_2d(
    matrix(c(0, 1, 0.5, 0.2, 1, 0), ncol = 2, byrow = TRUE)
  )
  expect_named(angle, c("score", "turning_angle", "angle_change"))
  expect_length(angle$score, 3L)
  expect_true(all(angle$score >= 0))

  expect_error(
    multiscape:::.pa_knee_distance_score_2d(matrix(1, nrow = 2, ncol = 3)),
    "exactly two"
  )
  expect_error(
    multiscape:::.pa_knee_angle_score_2d(matrix(1, nrow = 2, ncol = 2)),
    "at least three"
  )
})


test_that("frontier public functions work on hand-made SolutionSets without solving", {
  s <- make_mock_solutionset()

  ext <- multiscape::frontier_extremes(
    s,
    objectives = c("cost", "benefit"),
    ties = "first"
  )
  expect_s3_class(ext, "data.frame")
  expect_equal(nrow(ext), 4L)
  expect_setequal(ext$role, c("best", "worst"))
  expect_true(all(ext$sense %in% c("min", "max")))

  dist <- multiscape::frontier_distances(
    s,
    reference = "nadir",
    metric = "manhattan"
  )
  expect_true("distance_to_nadir" %in% names(dist))
  expect_true("rank_from_nadir" %in% names(dist))
  expect_false("distance_to_ideal" %in% names(dist))
  expect_identical(attr(dist, "reference"), "nadir")
  expect_identical(attr(dist, "metric"), "manhattan")

  knee_distance <- multiscape::frontier_knee(
    s,
    method = "distance",
    nondominated = FALSE,
    return_all = TRUE
  )
  expect_true(all(c("knee_score", "knee_rank", "method") %in% names(knee_distance)))
  expect_equal(unique(knee_distance$method), "distance")

  knee_ideal <- multiscape::frontier_knee(
    s,
    method = "ideal",
    metric = "chebyshev",
    nondominated = FALSE,
    return_all = TRUE
  )
  expect_true("distance_to_ideal" %in% names(knee_ideal))
  expect_equal(unique(knee_ideal$method), "ideal")
  expect_equal(unique(knee_ideal$metric), "chebyshev")
})


test_that("frontier public functions validate malformed SolutionSets", {
  s <- make_mock_solutionset()

  expect_error(
    multiscape::frontier_extremes(s, objectives = "unknown"),
    "Unknown objective"
  )

  expect_error(
    multiscape::frontier_extremes(s, objectives = character(0)),
    "at least one"
  )

  expect_error(
    multiscape::frontier_distances(s, objectives = "cost"),
    "At least two"
  )

  expect_error(
    multiscape::frontier_knee(s, nondominated = NA),
    "nondominated"
  )

  expect_error(
    multiscape::frontier_knee(s, return_all = NA),
    "return_all"
  )

  expect_error(
    multiscape::frontier_knee(s, method = "angle", nondominated = FALSE),
    "at least three"
  )
})
