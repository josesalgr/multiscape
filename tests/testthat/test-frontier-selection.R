test_that("frontier_extremes identifies both bounds for each objective", {
  x <- solve_explicit_mo_problem(n = 5)

  out <- multiscape::frontier_extremes(x)

  expect_s3_class(out, "data.frame")
  expect_setequal(out$objective, c("cost", "benefit"))
  expect_setequal(out$bound, c("min", "max"))
  expect_true(all(out$role %in% c("best", "worst")))
  expect_true(all(!is.na(out$solution_id)))
})


test_that("frontier_distances returns normalized values and references", {
  x <- solve_explicit_mo_problem(n = 5)

  out <- multiscape::frontier_distances(
    x,
    reference = c("ideal", "nadir")
  )

  expect_true(
    all(c(
      "run_id",
      "solution_id",
      "norm_cost",
      "norm_benefit",
      "distance_to_ideal",
      "rank_to_ideal",
      "distance_to_nadir",
      "rank_from_nadir"
    ) %in% names(out))
  )

  expect_true(all(out$norm_cost >= 0 & out$norm_cost <= 1))
  expect_true(all(out$norm_benefit >= 0 & out$norm_benefit <= 1))
  expect_named(attr(out, "ideal"), c("cost", "benefit"))
  expect_named(attr(out, "nadir"), c("cost", "benefit"))
  expect_identical(attr(out, "metric"), "euclidean")
})


test_that("frontier distance metrics are available", {
  x <- solve_explicit_mo_problem(n = 4)

  euclidean <- multiscape::frontier_distances(
    x,
    metric = "euclidean"
  )

  manhattan <- multiscape::frontier_distances(
    x,
    metric = "manhattan"
  )

  chebyshev <- multiscape::frontier_distances(
    x,
    metric = "chebyshev"
  )

  expect_equal(nrow(euclidean), nrow(manhattan))
  expect_equal(nrow(euclidean), nrow(chebyshev))
  expect_true(
    all(manhattan$distance_to_ideal >=
          chebyshev$distance_to_ideal)
  )
})


test_that("selection_frequency reports valid recurrence proportions", {
  x <- solve_explicit_mo_problem(n = 5)

  out <- multiscape::selection_frequency(x)

  expect_s3_class(out, "data.frame")
  expect_true(
    all(c(
      "pu",
      "action",
      "n_selected",
      "n_solutions",
      "frequency"
    ) %in% names(out))
  )

  expect_true(all(out$frequency >= 0 & out$frequency <= 1))
  expect_equal(
    out$frequency,
    out$n_selected / out$n_solutions
  )
  expect_true(all(out$n_solutions > 0L))
})


test_that("selection_similarity returns long and matrix forms", {
  x <- solve_explicit_mo_problem(n = 5)

  long <- multiscape::selection_similarity(
    x,
    metric = "jaccard",
    format = "long"
  )

  mat <- multiscape::selection_similarity(
    x,
    metric = "hamming",
    format = "matrix"
  )

  expect_s3_class(long, "data.frame")
  expect_true(
    all(c(
      "solution_id_1",
      "solution_id_2",
      "similarity",
      "distance"
    ) %in% names(long))
  )

  expect_true(all(long$similarity >= 0 & long$similarity <= 1))
  expect_equal(long$distance, 1 - long$similarity)

  expect_true(is.matrix(mat))
  expect_equal(mat, t(mat))
  expect_equal(unname(diag(mat)), rep(1, nrow(mat)))
  expect_identical(attr(mat, "metric"), "hamming")
})


test_that("non-dominated filtering integrates with moocore", {
  testthat::skip_if_not_installed("moocore")

  x <- solve_explicit_mo_problem(n = 5)

  out <- multiscape::solution_filter(
    x,
    feasible_only = TRUE,
    nondominated = TRUE
  )

  expect_s3_class(out, "SolutionSet")
  expect_gt(
    sum(!is.na(multiscape::get_runs(out)$solution_id)),
    0L
  )
})
