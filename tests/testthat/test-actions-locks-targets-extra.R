test_that("locked planning units accept ids, logical vectors, and raw columns", {
  p <- make_round4_problem()
  p$data$pu_data_raw$lock_char <- c("yes", "no", "true", NA)
  p$data$pu_data_raw$out_num <- c(0, 1, 0, 0)

  by_ids <- multiscape::add_constraint_locked_planning_units(
    p,
    locked_in = c(1, 3),
    locked_out = 4
  )
  expect_equal(by_ids$data$pu$locked_in, c(TRUE, FALSE, TRUE, FALSE))
  expect_equal(by_ids$data$pu$locked_out, c(FALSE, FALSE, FALSE, TRUE))

  by_logical <- multiscape::add_constraint_locked_planning_units(
    p,
    locked_in = c(FALSE, TRUE, FALSE, FALSE),
    locked_out = c(FALSE, FALSE, TRUE, FALSE)
  )
  expect_equal(which(by_logical$data$pu$locked_in), 2L)
  expect_equal(which(by_logical$data$pu$locked_out), 3L)

  by_columns <- multiscape::add_constraint_locked_planning_units(
    p,
    locked_in = "lock_char",
    locked_out = "out_num"
  )
  expect_equal(by_columns$data$pu$locked_in, c(TRUE, FALSE, TRUE, FALSE))
  expect_equal(by_columns$data$pu$locked_out, c(FALSE, TRUE, FALSE, FALSE))
})


test_that("locked planning units reject conflicts and malformed specs", {
  p <- make_round4_problem()

  expect_error(
    multiscape::add_constraint_locked_planning_units(p, locked_in = c(TRUE, FALSE), locked_out = NULL),
    "length"
  )
  expect_error(
    multiscape::add_constraint_locked_planning_units(p, locked_in = 999),
    "not present"
  )
  expect_error(
    multiscape::add_constraint_locked_planning_units(p, locked_in = c("not_an_id", "also_bad")),
    "must be NULL"
  )
  expect_error(
    multiscape::add_constraint_locked_planning_units(p, locked_in = 1, locked_out = 1),
    "both locked_in and locked_out"
  )
  expect_error(
    multiscape::add_constraint_locked_planning_units(p, locked_in = "missing_column"),
    "not found"
  )
})


test_that("target constraints parse labels, features, actions, and append rows", {
  p <- make_round4_problem(with_actions = TRUE)

  abs_one <- multiscape::add_constraint_targets_absolute(
    p,
    targets = data.frame(feature = "sp1", target = 2),
    actions = "conservation",
    label = "abs_sp1"
  )
  expect_equal(nrow(abs_one$data$targets), 1L)
  expect_equal(abs_one$data$targets$feature, 1)
  expect_equal(abs_one$data$targets$target_unit, "absolute")
  expect_equal(abs_one$data$targets$target_value, 2)
  expect_equal(abs_one$data$targets$actions, "conservation")
  expect_equal(abs_one$data$targets$label, "abs_sp1")
  expect_equal(abs_one$data$targets$feature_name, "sp1")

  rel_one <- multiscape::add_constraint_targets_relative(
    abs_one,
    targets = c(sp2 = 0.5),
    label = "rel_sp2"
  )
  # A scalar relative target is expanded to all features. The named vector is
  # accepted, but the current implementation still applies the scalar value
  # across all features.
  expect_equal(nrow(rel_one$data$targets), 3L)
  rel_rows <- rel_one$data$targets[rel_one$data$targets$label == "rel_sp2", ]
  expect_equal(nrow(rel_rows), 2L)

  sp2 <- rel_rows[rel_rows$feature == 2, ]
  expect_equal(nrow(sp2), 1L)
  expect_equal(sp2$target_unit, "relative_baseline")
  expect_equal(sp2$target_raw, 0.5)
  expect_equal(sp2$basis_total, 6)
  expect_equal(sp2$target_value, 3)
  expect_equal(sp2$label, "rel_sp2")

  expect_true(isTRUE(rel_one$data$meta$model_dirty))
})


test_that("target constraints reject invalid relative values and unknown features", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_constraint_targets_relative(p, targets = 1.1),
    "between 0 and 1"
  )
  expect_error(
    multiscape::add_constraint_targets_relative(p, targets = -0.1),
    "between 0 and 1"
  )
  expect_error(
    multiscape::add_constraint_targets_absolute(
      p,
      targets = data.frame(feature = "unknown", target = 1)
    ),
    "Unmatched|Unknown|feature"
  )
})


test_that("add_actions validates ids and pair filtering semantics", {
  p <- make_round4_problem()

  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = c("a", "a")),
      cost = 1
    ),
    "Duplicated|duplicate"
  )

  expect_error(
    multiscape::add_actions(
      p,
      actions = data.frame(id = "a"),
      include_pairs = data.frame(pu = 999, action = "a"),
      cost = 1
    ),
    "planning-unit|pu|not present"
  )

  out <- multiscape::add_actions(
    p,
    actions = data.frame(id = c("a", "b"), action_set = c("set1", "set2")),
    include_pairs = data.frame(pu = c(1, 2, 3), action = c("a", "a", "b")),
    exclude_pairs = data.frame(pu = 2, action = "a"),
    cost = c(a = 5, b = 7)
  )

  expect_equal(nrow(out$data$actions), 2L)
  expect_equal(nrow(out$data$dist_actions), 2L)
  expect_false(any(out$data$dist_actions$pu == 2 & out$data$dist_actions$action == "a"))
  expect_equal(out$data$dist_actions$cost[out$data$dist_actions$action == "a"], 5)
  expect_equal(out$data$dist_actions$cost[out$data$dist_actions$action == "b"], 7)
})
