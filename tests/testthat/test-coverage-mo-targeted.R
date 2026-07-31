test_that("weighted MO solves action fragmentation with selected action weights", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = TRUE,
    with_boundary = TRUE
  ) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(
      include_pu_cost = FALSE,
      include_action_cost = TRUE,
      alias = "cost"
    ) |>
    multiscape::add_objective_min_fragmentation_action(
      relation_name = "boundary",
      actions = "restoration",
      action_weights = c(conservation = 2, restoration = 3),
      weight_multiplier = 1.5,
      alias = "action_frag"
    ) |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "action_frag"),
      runs = multiscape::set_runs_manual(data.frame(
        weight_cost = c(1, 0.5, 0),
        weight_action_frag = c(0, 0.5, 1)
      ))
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  out <- multiscape::solve(p)
  values <- multiscape::get_objectives(out)

  spec <- p$data$objectives$action_frag
  ir <- getFromNamespace(".pamo_objective_to_ir", "multiscape")(p, spec)
  ir$terms[[1]]$actions <- 2L
  evaluate <- getFromNamespace(
    ".pamo_eval_action_boundary_cut_on_solution",
    "multiscape"
  )
  evaluated <- evaluate(
    p,
    out$solution$solutions[[1]],
    ir$terms[[1]]
  )

  expect_s3_class(out, "SolutionSet")
  expect_equal(nrow(multiscape::get_runs(out)), 3L)
  expect_true(all(c("cost", "action_frag") %in% names(values)))
  expect_true(all(is.finite(values$cost)))
  expect_true(all(is.finite(values$action_frag)))
  expect_equal(evaluated, values$action_frag[1], tolerance = 1e-8)
})


test_that("weighted MO composes all supported atomic objective families", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = TRUE,
    with_profit = TRUE,
    with_boundary = TRUE
  ) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(
      include_pu_cost = TRUE,
      include_action_cost = TRUE,
      alias = "cost"
    ) |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::add_objective_min_loss(alias = "loss") |>
    multiscape::add_objective_max_profit(alias = "profit") |>
    multiscape::add_objective_max_net_profit(alias = "net_profit") |>
    multiscape::add_objective_min_fragmentation_planning_units(
      relation_name = "boundary",
      weight_multiplier = 0.5,
      alias = "pu_frag"
    ) |>
    multiscape::add_objective_min_fragmentation_action(
      relation_name = "boundary",
      action_weights = c(conservation = 1, restoration = 2),
      alias = "action_frag"
    ) |>
    multiscape::add_objective_min_intervention_impact(
      impact_col = "amount",
      alias = "impact"
    )

  aliases <- c(
    "cost", "benefit", "loss", "profit", "net_profit",
    "pu_frag", "action_frag", "impact"
  )

  weights <- as.data.frame(
    stats::setNames(
      as.list(rep(1, length(aliases))),
      paste0("weight_", aliases)
    )
  )

  p <- p |>
    multiscape::set_method_weighted_sum(
      aliases = aliases,
      runs = multiscape::set_runs_manual(weights)
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  out <- multiscape::solve(p)
  values <- multiscape::get_objectives(out)

  expect_s3_class(out, "SolutionSet")
  expect_identical(names(values), c("solution_id", aliases))
  expect_equal(nrow(values), 1L)
  expect_true(all(is.finite(unlist(values[aliases]))))
})

test_that("automatic epsilon grid covers non-lexicographic fragmentation anchors", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = TRUE,
    with_boundary = TRUE
  ) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(
      include_pu_cost = FALSE,
      include_action_cost = TRUE,
      alias = "cost"
    ) |>
    multiscape::add_objective_min_fragmentation_planning_units(
      relation_name = "boundary",
      alias = "pu_frag"
    ) |>
    multiscape::set_method_epsilon_constraint(
      primary = "cost",
      aliases = c("cost", "pu_frag"),
      runs = multiscape::set_runs_grid(n = 3),
      lexicographic = FALSE,
      lexicographic_tol = 0
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  out <- multiscape::solve(p)
  runs <- multiscape::get_runs(out)
  values <- multiscape::get_objectives(out)

  expect_s3_class(out, "SolutionSet")
  expect_equal(nrow(runs), 3L)
  expect_true(all(c("cost", "pu_frag") %in% names(values)))
  expect_true(any(!is.na(runs$solution_id)))
})


test_that("manual AUGMECON handles multiple heterogeneous secondary objectives", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = TRUE,
    with_boundary = TRUE
  ) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(
      include_pu_cost = FALSE,
      include_action_cost = TRUE,
      alias = "cost"
    ) |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::add_objective_min_fragmentation_action(
      relation_name = "boundary",
      alias = "action_frag"
    ) |>
    multiscape::set_method_augmecon(
      primary = "cost",
      aliases = c("cost", "benefit", "action_frag"),
      runs = multiscape::set_runs_manual(data.frame(
        eps_benefit = c(0, 1),
        eps_action_frag = c(100, 100)
      )),
      augmentation = 1e-3,
      slack_upper_bound = 1e4
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  out <- multiscape::solve(p)
  runs <- multiscape::get_runs(out)
  values <- multiscape::get_objectives(out)

  expect_s3_class(out, "SolutionSet")
  expect_equal(nrow(runs), 2L)
  expect_true(all(c(
    "cost", "benefit", "action_frag"
  ) %in% names(values)))
  expect_true(any(!is.na(runs$solution_id)))
})

test_that("manual run design validates names, types, and epsilon values", {
  no_columns <- data.frame(row.names = 1L)
  expect_error(
    multiscape::set_runs_manual(no_columns),
    "at least one run-design column"
  )

  empty_name <- data.frame(value = 1)
  names(empty_name) <- ""
  expect_error(
    multiscape::set_runs_manual(empty_name),
    "non-empty names"
  )

  duplicated_names <- data.frame(weight_cost = 1, weight_benefit = 0)
  names(duplicated_names) <- c("weight_cost", "weight_cost")
  expect_error(
    multiscape::set_runs_manual(duplicated_names),
    "Duplicated run-design"
  )

  expect_error(
    multiscape::set_runs_manual(data.frame(
      weight_cost = 1,
      scenario = 1
    )),
    "Unknown run-design"
  )

  eps <- multiscape::set_runs_manual(data.frame(
    eps_cost = c(-1, 0, 2.5),
    eps_loss = c(3, 2, 1)
  ))
  expect_s3_class(eps, "RunManual")
  expect_identical(
    names(eps$values),
    c("eps_cost", "eps_loss")
  )
})


test_that("legacy epsilon converter creates Cartesian designs and validates aliases", {
  convert <- getFromNamespace(".pamo_eps_to_manual_df", "multiscape")

  out <- convert(
    eps = list(cost = c(1, 2), loss = c(10, 20, 30)),
    constrained = c("cost", "loss")
  )

  expect_identical(names(out), c("eps_cost", "eps_loss"))
  expect_equal(nrow(out), 6L)
  expect_equal(
    out,
    expand.grid(
      eps_cost = c(1, 2),
      eps_loss = c(10, 20, 30),
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
  )

  named_vector <- convert(
    eps = c(cost = 4, loss = 5),
    constrained = c("loss", "cost")
  )
  expect_identical(names(named_vector), c("eps_loss", "eps_cost"))
  expect_equal(named_vector$eps_loss, 5)
  expect_equal(named_vector$eps_cost, 4)

  expect_error(convert(1:2, "cost"), "named numeric vector")
  expect_error(convert(list(cost = 1), c("cost", "loss")), "Missing: loss")
  expect_error(convert(list(cost = 1, extra = 2), "cost"), "not constrained")
  expect_error(convert(list(cost = numeric()), "cost"), "empty vectors")
  expect_error(convert(list(cost = Inf), "cost"), "non-finite")
})


test_that("legacy AUGMECON grid converter validates and orders its design", {
  convert <- getFromNamespace(
    ".pamo_augmecon_grid_to_manual_df",
    "multiscape"
  )

  out <- convert(
    grid = list(loss = c(10, 20), cost = c(1, 2, 3)),
    secondary = c("cost", "loss")
  )

  expect_identical(names(out), c("eps_cost", "eps_loss"))
  expect_equal(nrow(out), 6L)
  expect_equal(out$eps_cost, rep(c(1, 2, 3), 2))
  expect_equal(out$eps_loss, rep(c(10, 20), each = 3))

  expect_error(convert(NULL, "cost"), "non-empty named list")
  expect_error(convert(list(1), "cost"), "fully named")

  duplicated <- list(1, 2)
  names(duplicated) <- c("cost", "cost")
  expect_error(convert(duplicated, "cost"), "duplicates")

  expect_error(
    convert(list(cost = 1), c("cost", "loss")),
    "missing secondary"
  )
  expect_error(
    convert(list(cost = 1, other = 2), "cost"),
    "unknown secondary"
  )
  expect_error(
    convert(list(cost = "bad"), "cost"),
    "finite numeric vector"
  )
  expect_error(
    convert(list(cost = NA_real_), "cost"),
    "finite numeric vector"
  )
})
