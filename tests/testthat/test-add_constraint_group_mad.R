make_group_mad_problem <- function(max_mad = 0.25, max_mean = NULL) {
  toy <- toy_multiaction_semantics()

  groups <- data.frame(
    id = c("A", "B"),
    stringsAsFactors = FALSE
  )

  dist_groups <- data.frame(
    pu = 1:5,
    group = c("A", "A", "B", "B", "B"),
    area = rep(10, 5),
    stringsAsFactors = FALSE
  )

  dist_group_actions <- data.frame(
    pu = 1:5,
    group = c("A", "A", "B", "B", "B"),
    action = "restoration",
    area = rep(10, 5),
    stringsAsFactors = FALSE
  )

  multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = toy$actions,
      cost = c(conservation = 1, restoration = 2)
    ) |>
    multiscape::add_groups(
      groups = groups,
      dist_groups = dist_groups
    ) |>
    multiscape::add_constraint_group_mad(
      max_mad = max_mad,
      max_mean = max_mean,
      groups = c("A", "B"),
      actions = "restoration",
      group_areas = c(A = 20, B = 30),
      dist_group_actions = dist_group_actions
    )
}


test_that("add_constraint_group_mad stores a common group specification", {
  p <- make_group_mad_problem(max_mad = 0.15)

  expect_true(is.data.frame(p$data$constraints$group_mad))
  expect_equal(nrow(p$data$constraints$group_mad), 2L)
  expect_equal(p$data$constraints$group_mad$group, c("A", "B"))
  expect_equal(p$data$constraints$group_mad$group_area, c(20, 30))
  expect_equal(unique(p$data$constraints$group_mad$max_mad), 0.15)
  expect_true(all(is.na(p$data$constraints$group_mad$max_mean)))
  expect_equal(unique(p$data$constraints$group_mad$actions), "restoration")

  # The temporary group-area validation constraint must not be retained.
  expect_null(p$data$constraints$group_area)
})


test_that("add_constraint_group_mad validates bounds and denominators", {
  expect_error(make_group_mad_problem(max_mad = -0.01), "max_mad")
  expect_error(make_group_mad_problem(max_mad = 1.01), "max_mad")
  expect_error(make_group_mad_problem(max_mean = -0.01), "max_mean")
  expect_error(make_group_mad_problem(max_mean = 1.01), "max_mean")

  p <- make_group_mad_problem()
  expect_error(
    multiscape::add_constraint_group_mad(
      p,
      max_mad = 0.1,
      groups = c("A", "B"),
      actions = "restoration",
      group_areas = c(A = 20, B = 30)
    ),
    "already exists"
  )
})


test_that("group mean upper bound is stored and compiled", {
  toy <- toy_multiaction_semantics()
  p <- make_group_mad_problem(max_mad = 1, max_mean = 0.4) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(alias = "cost")

  expect_equal(unique(p$data$constraints$group_mad$max_mean), 0.4)
  compiled <- multiscape::compile_model(p)
  expect_equal(
    compiled$data$model_registry$cons$group_mean_upper_bound$rhs,
    0.4
  )
})


test_that("group MAD compilation adds mean, deviations, and linear rows", {
  toy <- toy_multiaction_semantics()

  p <- make_group_mad_problem(max_mad = 0.25) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.2) |>
    multiscape::add_objective_min_cost(alias = "cost")

  compiled <- multiscape::compile_model(p)

  expect_true(is.list(compiled$data$model_registry$vars$group_mad))
  expect_equal(
    compiled$data$model_registry$vars$group_mad$n_added,
    3L
  )
  expect_equal(
    length(compiled$data$model_registry$cons$group_mad_deviations),
    4L
  )
  expect_equal(
    compiled$data$model_registry$cons$group_mad_upper_bound$rhs,
    0.5
  )
  expect_equal(
    compiled$data$model_registry$group_mad$groups,
    c("A", "B")
  )
})


test_that("group MAD is compatible with epsilon-constraint solves", {
  skip_if_not_installed("rcbc")

  toy <- toy_equivalent_basic()
  groups <- data.frame(id = c("A", "B"))
  dist_groups <- data.frame(
    pu = 1:4,
    group = c("A", "A", "B", "B"),
    area = 1
  )
  dist_group_actions <- data.frame(
    pu = 1:4,
    group = c("A", "A", "B", "B"),
    action = "conservation",
    area = 1
  )

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = toy$actions,
      cost = 0
    ) |>
    multiscape::add_groups(
      groups = groups,
      dist_groups = dist_groups
    ) |>
    multiscape::add_constraint_group_mad(
      max_mad = 0.50,
      actions = "conservation",
      group_areas = c(A = 2, B = 2),
      dist_group_actions = dist_group_actions
    ) |>
    multiscape::add_effects(effects = toy$effects) |>
    multiscape::add_constraint_targets_relative(0.5) |>
    multiscape::add_spatial_boundary(
      boundary = toy$boundary,
      include_self = TRUE
    ) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_min_fragmentation_planning_units(
      alias = "frag"
    ) |>
    multiscape::set_solver_cbc(
      gap_limit = 0,
      verbose = FALSE
    ) |>
    multiscape::set_method_epsilon_constraint(
      primary = "cost",
      aliases = c("cost", "frag"),
      runs = multiscape::set_runs_grid(n = 2),
      lexicographic = TRUE
    )

  solution <- multiscape::solve(p)
  expect_s3_class(solution, "SolutionSet")
  expect_gt(nrow(multiscape::get_runs(solution)), 0L)
})
