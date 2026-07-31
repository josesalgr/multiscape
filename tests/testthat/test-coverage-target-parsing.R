test_that("target parser supports all documented input representations", {
  parse_targets <- getFromNamespace(".pa_parse_targets", "multiscape")
  p <- make_round3_tabular_problem()

  scalar <- parse_targets(p, 0.5)
  expect_equal(scalar$feature, c(1, 2))
  expect_equal(scalar$target_raw, c(0.5, 0.5))

  selected <- parse_targets(p, 3, features = "sp2")
  expect_equal(selected$feature, 2)
  expect_equal(selected$feature_name, "sp2")
  expect_equal(selected$target_raw, 3)

  tabular <- parse_targets(
    p,
    data.frame(feature = c("sp2", "sp1"), target = c(4, 5))
  )
  expect_equal(tabular$feature, c(1, 2))
  expect_equal(tabular$target_raw, c(5, 4))

  named <- parse_targets(p, c(sp2 = 7, sp1 = 8))
  expect_equal(named$feature, c(1, 2))
  expect_equal(named$target_raw, c(8, 7))

  numeric_names <- parse_targets(p, c(`2` = 9, `1` = 10))
  expect_equal(numeric_names$feature, c(1, 2))
  expect_equal(numeric_names$target_raw, c(10, 9))

  matrix_named <- matrix(c(11, 12), ncol = 1)
  rownames(matrix_named) <- c("sp2", "sp1")
  matrix_out <- parse_targets(p, matrix_named)
  expect_equal(matrix_out$feature, c(1, 2))
  expect_equal(matrix_out$target_raw, c(12, 11))

  matrix_scalar <- parse_targets(p, matrix(13, ncol = 1))
  expect_equal(matrix_scalar$target_raw, c(13, 13))

  matrix_vector <- parse_targets(p, matrix(c(14, 15), ncol = 1))
  expect_equal(matrix_vector$target_raw, c(14, 15))
})


test_that("target parser reports ambiguous and malformed specifications", {
  parse_targets <- getFromNamespace(".pa_parse_targets", "multiscape")
  p <- make_round3_tabular_problem()

  expect_warning(
    out <- parse_targets(
      p,
      data.frame(feature = 1:2, target = c(1, 2)),
      features = 1
    ),
    "Ignoring 'features'"
  )
  expect_equal(nrow(out), 2L)

  expect_error(
    parse_targets(p, data.frame(feature = 1)),
    "must contain columns"
  )
  expect_error(
    parse_targets(p, data.frame(feature = 1, target = NA_real_)),
    "contain NA"
  )
  expect_error(parse_targets(p, matrix(1:4, ncol = 2)), "exactly 1 column")
  expect_error(
    parse_targets(p, matrix(1:3, ncol = 1)),
    "nrow = 1 or nrow = number"
  )
  expect_error(parse_targets(p, NA_real_), "Target is NA")
  expect_error(parse_targets(p, c(1, NA_real_)), "contain NA")
  expect_error(parse_targets(p, 1, features = numeric()), "empty set")
  expect_error(parse_targets(p, 1, features = 99), "Unknown feature id")
  expect_error(parse_targets(p, 1, features = "unknown"), "Unknown feature name")
  expect_error(
    parse_targets(p, c(sp1 = 1, sp1 = 2)),
    "Duplicate targets"
  )
  expect_error(parse_targets(p, list(1, 2)), "Unsupported targets")

  no_features <- make_round3_tabular_problem()
  no_features$data$features <- data.frame()
  expect_error(parse_targets(no_features, 1), "features is missing")

  no_id <- make_round3_tabular_problem()
  no_id$data$features$id <- NULL
  expect_error(parse_targets(no_id, 1), "must contain column 'id'")

  no_names <- make_round3_tabular_problem()
  no_names$data$features$name <- NULL
  expect_error(
    parse_targets(no_names, 1, features = "sp1"),
    "has no 'name' column"
  )
})
