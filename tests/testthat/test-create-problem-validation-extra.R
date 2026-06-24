test_that("create_problem tabular mode validates ids, amounts, and duplicate keys", {
  d <- make_round4_base_data()

  expect_error(
    multiscape::create_problem(
      pu = d$pu[, "cost", drop = FALSE],
      features = d$features,
      dist_features = d$dist_features,
      cost = "cost"
    ),
    "id"
  )

  bad_features <- d$features
  bad_features$id[2] <- bad_features$id[1]
  expect_error(
    multiscape::create_problem(d$pu, bad_features, d$dist_features, cost = "cost"),
    "unique|duplic"
  )

  bad_dist <- d$dist_features
  bad_dist$amount[1] <- -1
  expect_error(
    multiscape::create_problem(d$pu, d$features, bad_dist, cost = "cost"),
    "amount|negative|>= 0"
  )

  dup_dist <- rbind(d$dist_features, d$dist_features[1, ])
  expect_error(
    multiscape::create_problem(d$pu, d$features, dup_dist, cost = "cost"),
    "duplic|unique|pu.*feature"
  )

  unknown_pu <- d$dist_features
  unknown_pu$pu[1] <- 99
  expect_error(
    multiscape::create_problem(d$pu, d$features, unknown_pu, cost = "cost"),
    "unknown PU|PU ids"
  )
})


test_that("internal tabular builder handles optional boundary and cost fallbacks", {
  d <- make_round4_base_data()
  pu <- d$pu
  pu$monitoring_cost <- pu$cost + 10
  pu$cost <- NULL

  p <- multiscape:::.pa_create_problem_tabular_impl(
    pu = pu,
    features = d$features,
    dist_features = d$dist_features,
    boundary = data.frame(id1 = c(1, 2), id2 = c(2, 3), boundary = c(5, 6))
  )

  expect_s3_class(p, "Problem")
  expect_true("boundary" %in% names(p$data$spatial_relations))
  expect_s3_class(p$data$spatial_relations$boundary, "data.frame")
  expect_equal(p$data$pu$cost, pu$monitoring_cost)
})
