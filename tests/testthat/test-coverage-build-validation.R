test_that("model compilation explains missing action data by objective family", {
  p <- make_round3_tabular_problem()

  no_actions <- multiscape::add_objective_max_profit(p, alias = "profit")
  expect_error(
    multiscape::compile_model(no_actions),
    "requires dist_profit"
  )

  actions_only <- multiscape::add_actions(
    p,
    actions = data.frame(id = c("a", "b")),
    cost = c(a = 1, b = 2)
  )
  targeted <- multiscape::add_constraint_targets_relative(actions_only, 0.2)
  targeted <- multiscape::add_objective_min_cost(targeted, alias = "cost")
  expect_error(
    multiscape::compile_model(targeted),
    "no action effects were provided"
  )

  benefit <- multiscape::add_objective_max_benefit(actions_only, alias = "benefit")
  expect_error(
    multiscape::compile_model(benefit),
    "requires effects"
  )

  loss <- multiscape::add_objective_min_loss(actions_only, alias = "loss")
  expect_error(
    multiscape::compile_model(loss),
    "requires effects/losses"
  )

  profit <- multiscape::add_objective_max_profit(actions_only, alias = "profit")
  expect_error(
    multiscape::compile_model(profit),
    "requires dist_profit"
  )
})


test_that("model compilation validates objective coefficient columns", {
  p <- make_round3_action_problem(with_effects = TRUE)

  benefit <- multiscape::add_objective_max_benefit(p, alias = "benefit")
  benefit$data$model_args$objective_args$benefit_col <- "missing"
  expect_error(multiscape::compile_model(benefit), "requires column 'missing'")

  loss <- multiscape::add_objective_min_loss(p, alias = "loss")
  loss$data$model_args$objective_args$loss_col <- "missing"
  expect_error(multiscape::compile_model(loss), "requires column 'missing'")

  pp <- multiscape::add_profit(
    p,
    profit = data.frame(
      pu = rep(1:4, each = 2),
      action = rep(c("conservation", "restoration"), 4),
      profit = 1
    )
  )
  profit <- multiscape::add_objective_max_profit(pp, alias = "profit")
  profit$data$model_args$objective_args$profit_col <- "missing"
  expect_error(multiscape::compile_model(profit), "requires column 'missing'")
})


test_that("fragmentation compilation validates relation structure and indices", {
  p <- make_round3_action_problem(with_effects = TRUE)

  base <- multiscape::add_spatial_relations(
    p,
    data.frame(pu1 = 1, pu2 = 2, weight = 1),
    name = "edge"
  )

  missing <- multiscape::add_objective_min_fragmentation_planning_units(
    base, relation_name = "edge", alias = "frag"
  )
  missing$data$spatial_relations$edge <- NULL
  expect_error(multiscape::compile_model(missing), "relation named 'edge'")

  malformed <- multiscape::add_objective_min_fragmentation_planning_units(
    base, relation_name = "edge", alias = "frag"
  )
  malformed$data$spatial_relations$edge <- data.frame(x = 1)
  expect_error(multiscape::compile_model(malformed), "must contain columns")

  empty <- multiscape::add_objective_min_fragmentation_planning_units(
    base, relation_name = "edge", alias = "frag"
  )
  empty$data$spatial_relations$edge <- empty$data$spatial_relations$edge[0, ]
  expect_error(multiscape::compile_model(empty), "empty or not a data.frame")

  bad_na <- multiscape::add_objective_min_fragmentation_planning_units(
    base, relation_name = "edge", alias = "frag"
  )
  bad_na$data$spatial_relations$edge$internal_pu1 <- NA_integer_
  expect_error(multiscape::compile_model(bad_na), "contains NA")

  bad_range <- multiscape::add_objective_min_fragmentation_planning_units(
    base, relation_name = "edge", alias = "frag"
  )
  bad_range$data$spatial_relations$edge$internal_pu2 <- 99L
  expect_error(multiscape::compile_model(bad_range), "out of range")
})


test_that("intervention-impact compilation validates required data", {
  p <- make_round3_action_problem(with_effects = TRUE)
  impact <- multiscape::add_objective_min_intervention_impact(
    p, actions = "restoration", alias = "impact"
  )
  impact$data$model_args$objective_args$impact_col <- "missing"
  expect_error(multiscape::compile_model(impact), "requires column 'missing'")

  no_features <- multiscape::add_objective_min_intervention_impact(
    p, actions = "restoration", alias = "impact"
  )
  no_features$data$dist_features <- no_features$data$dist_features[0, ]
  expect_error(multiscape::compile_model(no_features), "requires dist_features")
})
