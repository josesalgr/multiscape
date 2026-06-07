test_that("create_problem builds the core problem tables correctly", {
  toy <- toy_equivalent_basic()

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  )

  expect_s3_class(p, "Problem")

  expect_true(is.data.frame(p$data$pu))
  expect_true(is.data.frame(p$data$features))
  expect_true(is.data.frame(p$data$dist_features))

  expect_equal(nrow(p$data$pu), 4)
  expect_equal(nrow(p$data$features), 2)
  expect_equal(nrow(p$data$dist_features), 8)

  expect_true(all(c("id", "cost") %in% names(p$data$pu)))
  expect_true("id" %in% names(p$data$features))
  expect_true(all(c("pu", "feature", "amount") %in% names(p$data$dist_features)))

  expect_true("internal_id" %in% names(p$data$pu))
  expect_true("internal_id" %in% names(p$data$features))

  expect_identical(anyDuplicated(p$data$pu$id), 0L)
  expect_identical(anyDuplicated(p$data$features$id), 0L)
})

test_that("create_problem fails if required feature distribution columns are missing", {
  toy <- toy_equivalent_basic()
  bad_dist <- toy$dist_features
  bad_dist$amount <- NULL

  expect_error(
    multiscape::create_problem(
      pu = toy$pu,
      features = toy$features,
      dist_features = bad_dist,
      cost = "cost"
    )
  )
})


test_that("create_problem preserves sf geometry and raw attributes", {
  testthat::skip_if_not_installed("sf")

  x <- make_round3_spatial_problem(action_based = FALSE)

  expect_s3_class(x, "Problem")
  expect_s3_class(x$data$pu_sf, "sf")
  expect_equal(nrow(x$data$pu_sf), nrow(x$data$pu))
  expect_identical(x$data$pu_sf$id, x$data$pu$id)
  expect_true(all(c("id", "cost") %in% names(x$data$pu_sf)))
})


test_that("create_problem rejects duplicated and malformed identifiers", {
  base <- make_round3_tabular_problem()

  pu_dup <- base$data$pu[, c("id", "cost"), drop = FALSE]
  pu_dup$id[2] <- pu_dup$id[1]

  expect_error(
    multiscape::create_problem(
      pu = pu_dup,
      features = base$data$features[, c("id", "name"), drop = FALSE],
      dist_features = base$data$dist_features[, c("pu", "feature", "amount"), drop = FALSE],
      cost = "cost"
    )
  )

  feature_dup <- base$data$features[, c("id", "name"), drop = FALSE]
  feature_dup$id[2] <- feature_dup$id[1]

  expect_error(
    multiscape::create_problem(
      pu = base$data$pu[, c("id", "cost"), drop = FALSE],
      features = feature_dup,
      dist_features = base$data$dist_features[, c("pu", "feature", "amount"), drop = FALSE],
      cost = "cost"
    )
  )
})


test_that("create_problem rejects unknown ids in feature distributions", {
  x <- make_round3_tabular_problem()
  pu <- x$data$pu[, c("id", "cost"), drop = FALSE]
  features <- x$data$features[, c("id", "name"), drop = FALSE]
  dist <- x$data$dist_features[, c("pu", "feature", "amount"), drop = FALSE]

  bad_pu <- dist
  bad_pu$pu[1] <- 999L

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = bad_pu,
      cost = "cost"
    )
  )

  bad_feature <- dist
  bad_feature$feature[1] <- 999L

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = bad_feature,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects non-finite feature amounts", {
  x <- make_round3_tabular_problem()
  pu <- x$data$pu[, c("id", "cost"), drop = FALSE]
  features <- x$data$features[, c("id", "name"), drop = FALSE]
  dist <- x$data$dist_features[, c("pu", "feature", "amount"), drop = FALSE]

  dist$amount[1] <- Inf

  expect_error(
    multiscape::create_problem(
      pu = pu,
      features = features,
      dist_features = dist,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects duplicated planning-unit ids", {
  d <- make_round4_base_data()
  d$pu$id[2] <- d$pu$id[1]

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = d$dist_features,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects duplicated feature ids", {
  d <- make_round4_base_data()
  d$features$id[2] <- d$features$id[1]

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = d$dist_features,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects unknown planning units in distributions", {
  d <- make_round4_base_data()
  d$dist_features$pu[1] <- 999L

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = d$dist_features,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects unknown features in distributions", {
  d <- make_round4_base_data()
  d$dist_features$feature[1] <- 999L

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = d$dist_features,
      cost = "cost"
    )
  )
})


test_that("create_problem rejects missing and non-finite feature amounts", {
  d <- make_round4_base_data()

  bad_na <- d$dist_features
  bad_na$amount[1] <- NA_real_

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = bad_na,
      cost = "cost"
    )
  )

  bad_inf <- d$dist_features
  bad_inf$amount[1] <- Inf

  expect_error(
    multiscape::create_problem(
      pu = d$pu,
      features = d$features,
      dist_features = bad_inf,
      cost = "cost"
    )
  )
})


test_that("create_problem preserves valid input tables", {
  d <- make_round4_base_data()
  pu_before <- d$pu
  features_before <- d$features
  dist_before <- d$dist_features

  x <- multiscape::create_problem(
    pu = d$pu,
    features = d$features,
    dist_features = d$dist_features,
    cost = "cost"
  )

  expect_s3_class(x, "Problem")
  expect_identical(d$pu, pu_before)
  expect_identical(d$features, features_before)
  expect_identical(d$dist_features, dist_before)
})
