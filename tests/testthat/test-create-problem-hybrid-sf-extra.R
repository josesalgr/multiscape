make_cp6_hybrid_inputs <- function() {
  testthat::skip_if_not_installed("sf")

  g <- sf::st_sfc(
    sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(1, 0, 2, 0, 2, 1, 1, 1, 1, 0), ncol = 2, byrow = TRUE)))
  )

  pu <- sf::st_sf(
    id = 1:2,
    cost = c(10, 20),
    alt_cost = c(11, 22),
    owner = c("a", "b"),
    geometry = g
  )

  features <- data.frame(
    id = 1:2,
    name = c("sp1", "sp2"),
    stringsAsFactors = FALSE
  )

  dist_features <- data.frame(
    pu = c(1, 1, 2),
    feature = c("sp1", "sp2", "sp1"),
    amount = c(1, 2, 3),
    stringsAsFactors = FALSE
  )

  list(pu = pu, features = features, dist_features = dist_features)
}


test_that("hybrid sf create_problem succeeds with name-based and id-based features", {
  testthat::skip_if_not_installed("sf")

  d <- make_cp6_hybrid_inputs()

  p <- multiscape::create_problem(
    pu = d$pu,
    features = d$features,
    dist_features = d$dist_features,
    cost = "alt_cost"
  )

  expect_s3_class(p, "Problem")
  expect_equal(p$data$pu$cost, c(11, 22))
  expect_true(all(c("pu_sf", "pu_coords", "pu_data_raw") %in% names(p$data)))
  expect_equal(p$data$dist_features$feature, c(1L, 2L, 1L))
  expect_equal(p$data$pu_data_raw$owner, c("a", "b"))

  dist_ids <- d$dist_features
  dist_ids$feature <- c(1, 2, 1)
  p_ids <- multiscape::create_problem(d$pu, d$features, dist_ids, cost = "cost")
  expect_equal(p_ids$data$dist_features$feature, c(1L, 2L, 1L))
})


test_that("hybrid sf create_problem covers id, cost, and feature validation branches", {
  testthat::skip_if_not_installed("sf")

  d <- make_cp6_hybrid_inputs()

  pu_no_id <- d$pu[, setdiff(names(d$pu), "id")]
  expect_warning(
    p_auto <- multiscape::create_problem(pu_no_id, d$features, d$dist_features, cost = "cost"),
    "no 'id' column|Creating sequential ids"
  )
  expect_s3_class(p_auto, "Problem")

  expect_error(
    multiscape::create_problem(d$pu, d$features, d$dist_features, cost = "cost", pu_id_col = "missing"),
    "missing the id column"
  )

  pu_no_cost <- d$pu[, setdiff(names(d$pu), c("cost", "alt_cost"))]
  expect_error(
    multiscape::create_problem(pu_no_cost, d$features, d$dist_features),
    "must provide `cost`|column name"
  )

  expect_error(
    multiscape::create_problem(d$pu, d$features, d$dist_features, cost = "bad_cost"),
    "cost.*column"
  )

  pu_bad_cost <- d$pu
  pu_bad_cost$cost[1] <- Inf
  expect_error(
    multiscape::create_problem(pu_bad_cost, d$features, d$dist_features),
    "non-finite"
  )

  features_no_id <- d$features[, "name", drop = FALSE]
  expect_error(
    multiscape::create_problem(d$pu, features_no_id, d$dist_features, cost = "cost"),
    "id"
  )

  features_empty_name <- d$features
  features_empty_name$name[1] <- ""
  expect_error(
    multiscape::create_problem(d$pu, features_empty_name, d$dist_features, cost = "cost"),
    "NA or empty"
  )

  features_dup_name <- d$features
  features_dup_name$name[2] <- features_dup_name$name[1]
  expect_error(
    multiscape::create_problem(d$pu, features_dup_name, d$dist_features, cost = "cost"),
    "unique|Duplicated"
  )
})


test_that("hybrid sf create_problem covers dist_features validation branches", {
  testthat::skip_if_not_installed("sf")

  d <- make_cp6_hybrid_inputs()

  expect_error(
    multiscape::create_problem(d$pu, d$features, d$dist_features[, c("pu", "feature")], cost = "cost"),
    "Missing|amount"
  )

  features_no_name <- d$features[, "id", drop = FALSE]
  dist_named <- d$dist_features
  dist_named$feature <- c("sp1", "sp2", "sp1")
  expect_error(
    multiscape::create_problem(d$pu, features_no_name, dist_named, cost = "cost"),
    "no `name` column|could not be matched"
  )

  dist_bad_name <- d$dist_features
  dist_bad_name$feature[1] <- "missing_species"
  expect_error(
    multiscape::create_problem(d$pu, d$features, dist_bad_name, cost = "cost"),
    "Unmatched|valid feature"
  )

  dist_bad_pu <- d$dist_features
  dist_bad_pu$pu[1] <- 99
  expect_error(
    multiscape::create_problem(d$pu, d$features, dist_bad_pu, cost = "cost"),
    "not present in `pu`"
  )

  dist_bad_feature_id <- d$dist_features
  dist_bad_feature_id$feature <- c(1, 99, 1)
  expect_error(
    multiscape::create_problem(d$pu, d$features, dist_bad_feature_id, cost = "cost"),
    "Unmatched|not present in `features`|valid feature"
  )
})
