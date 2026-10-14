make_group_equity_problem <- function(objective = c("mean", "gini"), constrain_mean = FALSE) {
  objective <- match.arg(objective)
  pu <- data.frame(id = 1:4, cost = rep(1, 4), area = rep(1, 4))
  features <- data.frame(id = 1, name = "feature")
  dist_features <- data.frame(pu = 1:4, feature = 1, amount = 1)
  actions <- data.frame(id = "restore", name = "restore")

  p <- multiscape::create_problem(pu, features, dist_features, cost = "cost") |>
    multiscape::add_actions(actions, cost = c(restore = 1)) |>
    multiscape::add_constraint_area(
      area = 1, sense = "min", area_col = "area", actions = "restore"
    ) |>
    multiscape::add_groups(
      groups = data.frame(id = c("a", "b", "zero", "locked")),
      dist_groups = data.frame(
        pu = c(1, 2, 3, 4, 1, 4),
        group = c("a", "a", "b", "b", "zero", "locked"),
        area = 1
      ),
      area_unit = "m2"
    ) |>
    multiscape::add_group_equity(
      dist_group_actions = data.frame(
        pu = 1:4,
        group = c("a", "a", "b", "b"),
        action = "restore",
        area = 1
      ),
      actions = "restore",
      exclude_groups = "locked"
    )

  if (isTRUE(constrain_mean)) {
    p <- multiscape::add_constraint_group_mean(p, mean = 0.2, tolerance = 0.01)
  }
  if (identical(objective, "mean")) {
    multiscape::add_objective_min_group_mean(p, alias = "mean")
  } else {
    multiscape::add_objective_min_group_gini_numerator(p, alias = "gini")
  }
}

test_that("group equity stores an explicit population including zero groups", {
  p <- make_group_equity_problem("mean")
  expect_equal(p$data$group_equity$excluded_groups, "locked")
  expect_true(p$data$group_equity$group_totals$included[
    p$data$group_equity$group_totals$group == "zero"
  ])
  expect_equal(p$data$group_equity$denominator_source, "dist_groups")
  expect_equal(
    p$data$group_equity$group_totals$available_amount,
    c(2, 2, 1, 1)
  )
  expect_false("group_totals" %in% names(formals(multiscape::add_group_equity)))
  expect_equal(p$data$objectives$mean$objective_id, "min_group_mean")
})

test_that("add_groups is the canonical area source and converts units once", {
  toy <- toy_multiaction_semantics()
  p <- multiscape::create_problem(toy$pu, toy$features, toy$dist_features, cost = "cost") |>
    multiscape::add_groups(
      groups = data.frame(id = c("a", "b")),
      dist_groups = data.frame(
        pu = c(1, 1, 2), group = c("a", "a", "b"), area = c(0.5, 0.5, 2)
      ),
      area_unit = "ha"
    )

  expect_equal(p$data$dist_groups$area, c(10000, 20000))
  expect_equal(p$data$dist_groups$amount, p$data$dist_groups$area)
  expect_equal(p$data$groups$id, c("a", "b"))
})

test_that("mean equity creates one share variable per included group", {
  p <- make_group_equity_problem("mean", constrain_mean = TRUE)
  built <- multiscape:::.pa_build_model(p)
  reg <- built$data$model_registry$vars$group_equity
  expect_equal(reg$groups, c("a", "b", "zero"))
  expect_length(reg$share_cols_0based, 3L)
  expect_length(reg$absdiff_cols_0based, 0L)

  model <- multiscape:::.pa_model_from_ptr(
    built$data$model_ptr, built$data$model_args, drop_triplets = TRUE
  )
  expect_equal(model$obj[reg$share_cols_0based + 1L], rep(1 / 3, 3))
})

test_that("Gini numerator creates one absolute-difference variable per pair", {
  p <- make_group_equity_problem("gini")
  built <- multiscape:::.pa_build_model(p)
  reg <- built$data$model_registry$vars$group_equity
  expect_length(reg$share_cols_0based, 3L)
  expect_length(reg$absdiff_cols_0based, choose(3, 2))

  model <- multiscape:::.pa_model_from_ptr(
    built$data$model_ptr, built$data$model_args, drop_triplets = TRUE
  )
  expect_equal(model$obj[reg$absdiff_cols_0based + 1L], rep(1, 3))
})

test_that("a retained Gini bound prepares pair variables for another objective", {
  p <- make_group_equity_problem("mean") |>
    multiscape::add_constraint_group_gini_numerator(
      upper = 0.75, tolerance = 0.01, name = "retained_gini"
    )

  built <- multiscape:::.pa_build_model(p)
  reg <- built$data$model_registry$vars$group_equity
  expect_length(reg$absdiff_cols_0based, choose(3, 2))
  expect_equal(
    built$data$constraints$group_gini_numerator$upper,
    0.76
  )
  expect_true(!is.null(built$data$model_registry$vars$group_equity))
})

test_that("solved group shares yield internally consistent equity metrics", {
  skip_if_no_cbc()
  p <- make_group_equity_problem("mean") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)
  sol <- multiscape::solve(p)
  metrics <- multiscape::get_group_equity_metrics(sol)

  expect_equal(metrics$n_groups, 3L)
  expect_equal(metrics$mean, mean(metrics$groups$share), tolerance = 1e-8)
  expect_equal(
    metrics$mad_from_mean,
    mean(abs(metrics$groups$share - metrics$mean)),
    tolerance = 1e-8
  )
  expect_equal(
    metrics$gini,
    metrics$gini_numerator / (metrics$n_groups^2 * metrics$mean),
    tolerance = 1e-8
  )
})

test_that("mean and Gini numerator work in a shared multi-objective model", {
  skip_if_no_cbc()
  p <- make_group_equity_problem("mean") |>
    multiscape::add_objective_min_group_gini_numerator(alias = "gini") |>
    multiscape::set_method_weighted_sum(
      aliases = c("mean", "gini"),
      runs = multiscape::set_runs_grid(n = 2),
      normalize_weights = TRUE
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  solset <- multiscape::solve(p)
  expect_s3_class(solset, "SolutionSet")
  expect_equal(nrow(multiscape::get_runs(solset)), 2L)
  expect_true(all(c("value_mean", "value_gini") %in% names(solset$solution$runs)))
})

test_that("group equity works with automatic epsilon constraint", {
  skip_if_no_cbc()
  p <- make_group_equity_problem("mean") |>
    multiscape::add_objective_min_group_gini_numerator(alias = "gini") |>
    multiscape::set_method_epsilon_constraint(
      primary = "gini",
      aliases = c("gini", "mean"),
      runs = multiscape::set_runs_grid(n = 2),
      warm_start = FALSE
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  solset <- multiscape::solve(p)
  expect_s3_class(solset, "SolutionSet")
  expect_true(nrow(solset$solution$runs) >= 1L)
  expect_true(all(c("value_mean", "value_gini") %in% names(solset$solution$runs)))
})

test_that("group equity rejects invalid denominators and unknown exclusions", {
  toy <- toy_multiaction_semantics()
  p <- multiscape::create_problem(toy$pu, toy$features, toy$dist_features, cost = "cost") |>
    multiscape::add_actions(toy$actions, cost = c(conservation = 1, restoration = 2))
  ga <- data.frame(pu = 1, group = "a", action = "restoration", area = 1)

  expect_error(
    multiscape::add_group_equity(p, ga),
    "add_groups"
  )

  p <- multiscape::add_groups(
    p,
    groups = data.frame(id = "a"),
    dist_groups = data.frame(pu = 1, group = "a", area = 1)
  )
  expect_error(
    multiscape::add_group_equity(p, ga, exclude_groups = "missing"),
    "Unknown"
  )
})
