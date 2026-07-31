test_that("runtime model updates relax rows, replace objectives and weight slacks", {
  apply_updates <- getFromNamespace(
    ".pa_apply_runtime_updates_to_model", "multiscape"
  )
  p <- make_round3_tabular_problem()
  model <- list(
    sense = c(">=", "<=", "==", "?", "<="),
    rhs = 1:5,
    obj = rep(0, 6),
    modelsense = "min"
  )
  expect_identical(apply_updates(model, p), model)

  p$data$model_registry <- list(
    cons = list(group_a = c(2L, 5L), epsilon = list(cost = 3L)),
    vars = list(slack = c(2L, 6L, 99L)),
    obj_templates = list(maximum = list(obj = 6:1, modelsense = "max"))
  )
  p$data$runtime_updates <- list(
    bigM = 100,
    deactivate_rows = c(1L, 4L, 999L),
    deactivate_groups = c("group_a", "absent"),
    epsilon = list(cost = 42, absent = 2),
    obj = 1:6,
    modelsense = "max",
    slack_weight = -0.5
  )
  out <- apply_updates(model, p)
  expect_equal(out$rhs, c(-100, 100, 42, 100, 100))
  expect_equal(out$sense[3:4], c("==", "<="))
  expect_equal(out$obj, c(1, -0.5, 3, 4, 5, -0.5))
  expect_identical(out$modelsense, "max")

  bad_length <- p
  bad_length$data$runtime_updates <- list(obj = 1:2)
  expect_error(apply_updates(model, bad_length), "length mismatch")
  bad_sense <- make_round3_tabular_problem()
  bad_sense$data$runtime_updates <- list(obj = 1:6, modelsense = "sideways")
  expect_error(apply_updates(model, bad_sense), "must be 'min' or 'max'")

  template <- make_round3_tabular_problem()
  template$data$model_registry <- p$data$model_registry
  template$data$runtime_updates <- list(obj = NULL, objective_template = "maximum")
  templated <- apply_updates(model, template)
  expect_equal(templated$obj, 6:1)
  expect_identical(templated$modelsense, "max")

  bad_template <- make_round3_tabular_problem()
  bad_template$data$model_registry <- list(
    obj_templates = list(short = list(obj = 1:2))
  )
  bad_template$data$runtime_updates <- list(obj = NULL, objective_template = "short")
  expect_error(apply_updates(model, bad_template), "template length mismatch")
})


test_that("private area constraint storage validates complete contracts", {
  store <- getFromNamespace(".pa_store_area_constraints", "multiscape")
  p <- make_round3_tabular_problem()
  valid <- data.frame(
    type = "area", sense = "equal", value = 2, tolerance = 0.1,
    unit = "ha", area_col = "area", actions = NA_character_,
    name = "area_all", stringsAsFactors = FALSE
  )
  out <- store(p, valid)
  expect_equal(out$data$constraints$area$name, "area_all")

  mutate_and_fail <- function(column, value, pattern) {
    q <- valid
    q[[column]] <- value
    expect_error(store(make_round3_tabular_problem(), q), pattern)
  }
  expect_error(store(p, valid[, -1]), "Missing required columns")
  mutate_and_fail("type", "other", "type = 'area'")
  mutate_and_fail("sense", "other", "sense")
  mutate_and_fail("value", -1, "finite values")
  mutate_and_fail("tolerance", Inf, "finite values")
  mutate_and_fail("unit", "acre", "unit")
  mutate_and_fail("name", "", "non-empty")

  duplicate <- rbind(valid, valid)
  expect_error(store(make_round3_tabular_problem(), duplicate), "Duplicated")
  malformed_old <- make_round3_tabular_problem()
  malformed_old$data$constraints <- list(area = "bad")
  expect_error(store(malformed_old, valid), "must be a data.frame")
})


test_that("private budget constraint storage validates complete contracts", {
  store <- getFromNamespace(".pa_store_budget_constraints", "multiscape")
  valid <- data.frame(
    type = "budget", sense = "max", value = 10, tolerance = 0,
    actions = NA_character_, include_pu_cost = TRUE,
    include_action_cost = TRUE, name = "budget_all",
    stringsAsFactors = FALSE
  )
  p <- make_round3_tabular_problem()
  out <- store(p, valid)
  expect_equal(out$data$constraints$budget$value, 10)

  mutate_and_fail <- function(column, value, pattern) {
    q <- valid
    q[[column]] <- value
    expect_error(store(make_round3_tabular_problem(), q), pattern)
  }
  expect_error(store(p, valid[, -1]), "Missing required columns")
  mutate_and_fail("type", "other", "type = 'budget'")
  mutate_and_fail("sense", "other", "sense")
  mutate_and_fail("value", -1, "finite values")
  mutate_and_fail("tolerance", Inf, "finite values")
  mutate_and_fail("include_pu_cost", NA, "TRUE/FALSE")
  mutate_and_fail("include_action_cost", NA, "TRUE/FALSE")
  q <- valid
  q$include_pu_cost <- FALSE
  q$include_action_cost <- FALSE
  expect_error(store(make_round3_tabular_problem(), q), "at least one")
  q <- valid
  q$actions <- "restoration"
  expect_error(store(make_round3_tabular_problem(), q), "not action-specific")
  mutate_and_fail("name", "", "non-empty")
  expect_error(
    store(make_round3_tabular_problem(), rbind(valid, valid)),
    "Duplicated"
  )
  malformed_old <- make_round3_tabular_problem()
  malformed_old$data$constraints <- list(budget = "bad")
  expect_error(store(malformed_old, valid), "must be a data.frame")
})


test_that("run compilers cover multiobjective grids and manual epsilon designs", {
  weighted_grid <- getFromNamespace(
    ".pamo_compile_weighted_grid_runs", "multiscape"
  )
  epsilon_manual <- getFromNamespace(
    ".pamo_compile_epsilon_manual_runs", "multiscape"
  )

  line <- weighted_grid(c("a", "b"), n = 5, include_extremes = FALSE)
  expect_equal(nrow(line), 3L)
  expect_true(all(line$weight_a > 0 & line$weight_a < 1))

  simplex <- weighted_grid(
    c("a", "b", "c"), n = 4,
    include_extremes = FALSE, normalize_weights = TRUE
  )
  expect_true(all(abs(rowSums(simplex[-1]) - 1) < 1e-10))
  expect_true(all(apply(simplex[-1], 1, max) < 1))
  expect_error(weighted_grid("a", 3), "at least two")
  expect_error(weighted_grid(c("a", "b"), 1), "integer >= 2")

  eps <- epsilon_manual(
    data.frame(eps_b = c(1, 2), eps_c = c(3, 4)),
    constrained = c("b", "c")
  )
  expect_identical(eps$run_id, 1:2)
  expect_identical(names(eps), c("run_id", "eps_b", "eps_c"))
  expect_error(
    epsilon_manual(data.frame(eps_b = 1), c("b", "c")),
    "missing columns"
  )
  expect_error(
    epsilon_manual(data.frame(eps_b = Inf), "b"),
    "non-finite"
  )
})
