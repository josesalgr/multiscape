test_that("group-area constraints compile for absolute, relative and action subsets", {
  skip_if_no_cbc()
  p <- make_round3_action_problem(with_effects = TRUE)
  p$data$dist_groups <- data.frame(
    internal_pu = 1:4,
    group = c("north", "north", "south", "south"),
    amount = c(2, 3, 4, 5)
  )
  p$data$constraints <- list(group_area = data.frame(
    group = c("north", "south", "north"),
    value = c(0.2, 8, 5),
    relative = c(TRUE, FALSE, FALSE),
    actions = c(NA_character_, "restoration", "conservation"),
    sense = c("min", "max", "equal"),
    name = c("north_relative", "south_restore", "north_equal"),
    stringsAsFactors = FALSE
  ))
  p <- p |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  compiled <- multiscape::compile_model(p)
  expect_s3_class(compiled, "Problem")
  expect_false(isTRUE(compiled$data$meta$model_dirty))

  missing_group <- make_round3_action_problem(with_effects = TRUE)
  missing_group$data$dist_groups <- p$data$dist_groups
  missing_group$data$constraints <- list(group_area = data.frame(
    group = "absent", value = 1, relative = FALSE,
    actions = NA_character_, sense = "min", name = "absent"
  ))
  missing_group <- multiscape::add_constraint_targets_relative(missing_group, 0.05)
  missing_group <- multiscape::add_objective_min_cost(
    missing_group, alias = "cost"
  )
  expect_error(
    multiscape::compile_model(missing_group),
    "No group-distribution rows"
  )
})


test_that("MO alias bounds add linear constraints and validate inputs", {
  skip_if_no_cbc()
  add_bound <- getFromNamespace(
    ".pamo_add_alias_upper_bound_constraint", "multiscape"
  )
  mo <- make_round3_action_problem(with_effects = TRUE) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_manual(data.frame(
        weight_cost = 0.5, weight_benefit = 0.5
      ))
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)
  base <- multiscape::compile_model(mo)

  bounded <- add_bound(
    base_eval = base, x = base, alias = "cost",
    rhs = 100, tol = 0.25, name = "cost_ceiling"
  )
  expect_s3_class(bounded, "Problem")
  expect_error(
    add_bound(base, base, "cost", rhs = Inf),
    "rhs must be finite"
  )
  expect_error(
    add_bound(base, base, "cost", rhs = 1, tol = -1),
    "non-negative"
  )
})


test_that("MO relation preparation orders edges and validates its contract", {
  prepare <- getFromNamespace(".pamo_prepare_relation_model", "multiscape")
  rel <- data.frame(
    internal_pu1 = c(3, 1, 2),
    internal_pu2 = c(4, 2, 3),
    weight = c(3, 1, 2),
    distance = c(30, 10, 20),
    source = "test",
    extra = "drop"
  )
  out <- prepare(rel)
  expect_equal(out$internal_pu1, 1:3)
  expect_identical(out$internal_edge, 1:3)
  expect_false("extra" %in% names(out))
  expect_error(prepare(rel[, -1]), "must contain columns")
  bad_na <- rel
  bad_na$internal_pu1[1] <- NA
  expect_error(prepare(bad_na), "has NA")
  bad_weight <- rel
  bad_weight$weight[1] <- -1
  expect_error(prepare(bad_weight), "negative weights")
  bad_finite <- rel
  bad_finite$weight[1] <- Inf
  expect_error(prepare(bad_finite), "non-finite")
})


test_that("printing a compiled model includes auxiliary model details", {
  skip_if_no_cbc()
  p <- make_round3_action_problem(with_effects = TRUE) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE) |>
    multiscape::compile_model()
  expect_no_error(print(p))
})


test_that("add_actions covers defensive identifiers and cost validation", {
  p <- make_round3_tabular_problem()
  expect_error(
    multiscape::add_actions(
      p, data.frame(id = "a", internal_id = NA_integer_), cost = 1
    ),
    "internal_id contains NA"
  )
  expect_error(
    multiscape::add_actions(
      p, data.frame(id = c("a", "b"), internal_id = c(1L, 1L)), cost = 1
    ),
    "internal_id must be unique"
  )
  expect_error(
    multiscape::add_actions(p, data.frame(id = "a"), cost = "bad"),
    "Unsupported type|numeric"
  )
  expect_error(
    multiscape::add_actions(p, data.frame(id = "a"), cost = NA_real_),
    "finite"
  )
  expect_error(
    multiscape::add_actions(p, data.frame(id = "a"), cost = -1),
    "non-negative"
  )
  expect_error(
    multiscape::add_actions(
      p, data.frame(id = c("a", "b")), cost = c(a = 1, other = 2)
    ),
    "unknown action"
  )
})
