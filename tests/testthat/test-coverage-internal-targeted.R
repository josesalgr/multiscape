test_that("split-effect validation normalizes missing values and rejects ambiguity", {
  validate <- getFromNamespace(".validate_split_effects", "multiscape")

  clean <- validate(data.frame(
    pu = 1:3,
    action = "a",
    feature = 1:3,
    benefit = c(NA, 2, 0),
    loss = c(1, NA, 0)
  ))
  expect_equal(clean$benefit, c(0, 2, 0))
  expect_equal(clean$loss, c(1, 0, 0))

  expect_error(validate(data.frame(benefit = 1)), "requires 'benefit' and 'loss'")
  expect_error(
    validate(data.frame(benefit = -1, loss = 0), context = "custom"),
    "custom.*non-negative"
  )
  expect_error(
    validate(data.frame(
      pu = 7, action = "restore", feature = 2,
      benefit = 1, loss = 2
    )),
    "cannot have both.*pu=7.*restore"
  )
})


test_that("relation validation canonicalizes and aggregates duplicate edges", {
  validate <- getFromNamespace(".pa_validate_relation", "multiscape")
  rel <- data.frame(
    internal_pu1 = c(2, 1, 2, 3),
    internal_pu2 = c(1, 2, 3, 2),
    weight = c(1, 3, 2, 4),
    source = letters[1:4]
  )

  expected <- c(sum = 4, max = 3, min = 1, mean = 2)
  for (method in names(expected)) {
    out <- validate(rel, n_pu = 3, dup_agg = method)
    expect_equal(nrow(out), 2L)
    expect_equal(out$weight[out$internal_pu1 == 1], expected[[method]])
    expect_true("source" %in% names(out))
    expect_true(all(out$internal_pu1 <= out$internal_pu2))
  }

  expect_error(validate(data.frame(x = 1), 2), "missing columns")
  expect_error(
    validate(transform(rel[1, ], internal_pu1 = NA), 3),
    "has NA"
  )
  expect_error(
    validate(transform(rel[1, ], internal_pu1 = 0), 3),
    "internal_pu1 out of range"
  )
  expect_error(
    validate(transform(rel[1, ], internal_pu2 = 4), 3),
    "internal_pu2 out of range"
  )
  expect_error(
    validate(data.frame(internal_pu1 = 1, internal_pu2 = 1, weight = 1), 3),
    "Self-edges"
  )
  expect_error(
    validate(data.frame(internal_pu1 = 1, internal_pu2 = 2, weight = -1), 3),
    "finite and >= 0"
  )

  self <- validate(
    data.frame(internal_pu1 = 1, internal_pu2 = 1, weight = 2),
    n_pu = 2,
    allow_self = TRUE
  )
  expect_equal(self$weight, 2)
})


test_that("objective matrix handles senses, missing ids, and malformed inputs", {
  objective_matrix <- getFromNamespace(".pa_get_objective_matrix", "multiscape")
  s <- make_mock_solutionset()

  out <- objective_matrix(s, objectives = c("cost", "benefit"))
  expect_equal(unname(out$matrix[, "cost"]), c(2, 4))
  expect_equal(unname(out$matrix[, "benefit"]), c(-5, -9))
  expect_identical(unname(out$sense), c("min", "max"))

  raw <- objective_matrix(
    s,
    objectives = c("benefit", "cost"),
    minimize = FALSE,
    drop_na = FALSE
  )
  expect_equal(unname(raw$matrix[, "benefit"]), c(5, 9))

  missing_ids <- make_mock_solutionset()
  missing_ids$solution$runs$solution_id <- c(NA_character_, "")
  fallback <- objective_matrix(missing_ids)
  expect_identical(rownames(fallback$matrix), c("run_1", "run_2"))

  expect_error(objective_matrix(list()), "SolutionSet")
  expect_error(objective_matrix(s, objectives = character()), "at least one")
  expect_error(objective_matrix(s, objectives = "unknown"), "Unknown objective")
  expect_error(objective_matrix(s, objectives = "cost"), "At least two")

  incomplete <- make_mock_solutionset()
  incomplete$solution$runs$value_cost[1] <- NA_real_
  incomplete$solution$runs$value_benefit[2] <- NA_real_
  expect_error(objective_matrix(incomplete), "No complete objective rows")
})


test_that("model currency helper distinguishes complete and dirty snapshots", {
  current <- getFromNamespace(".pa_model_is_current", "multiscape")
  p <- make_round3_tabular_problem()

  expect_false(current(p))

  p$data$model_ptr <- new.env(parent = emptyenv())
  p$data$model_list <- list(ncol = 1L)
  p$data$meta$model_dirty <- FALSE
  expect_true(current(p))

  p$data$meta$model_dirty <- TRUE
  expect_false(current(p))
  p$data$meta$model_dirty <- FALSE
  p$data$model_list <- NULL
  expect_false(current(p))
})
