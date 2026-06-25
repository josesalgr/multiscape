test_that("add_benefits and add_losses store wrapper-specific tables", {
  p <- make_round4_problem(with_actions = TRUE)

  benefits <- data.frame(
    pu = c(1, 2),
    action = c("restoration", "restoration"),
    feature = c("sp1", "sp2"),
    delta = c(2, 3),
    stringsAsFactors = FALSE
  )
  b <- multiscape::add_benefits(p, benefits = benefits, effect_type = "delta")
  expect_true(is.data.frame(b$data$dist_benefit))
  expect_false("loss" %in% names(b$data$dist_benefit))
  expect_true(all(b$data$dist_effects$benefit > 0))

  losses <- data.frame(
    pu = c(1, 2),
    action = c("conservation", "conservation"),
    feature = c("sp1", "sp2"),
    delta = c(-1, -2),
    stringsAsFactors = FALSE
  )
  l <- multiscape::add_losses(p, losses = losses, effect_type = "delta")
  expect_true(is.data.frame(l$data$dist_loss))
  expect_false("benefit" %in% names(l$data$dist_loss))
  expect_true(all(l$data$dist_effects$loss > 0))
  expect_identical(l$data$losses_meta$stored_as, "loss")
})


test_that("add_effects covers signed, after, effect, legacy benefit, and invalid paths", {
  expect_error(multiscape::add_effects(NULL), "x is NULL")

  p_bad_amount <- make_round4_problem(with_actions = TRUE)
  p_bad_amount$data$dist_features$amount[1] <- NA_real_
  expect_error(
    multiscape::add_effects(p_bad_amount, effects = NULL),
    "dist_features\\$amount"
  )

  p <- make_round4_problem(with_actions = TRUE)

  e_after <- data.frame(
    pu = 1,
    action = "restoration",
    feature = "sp1",
    after = 10,
    stringsAsFactors = FALSE
  )
  out_after <- multiscape::add_effects(p, effects = e_after, effect_type = "after")
  expect_equal(out_after$data$dist_effects$amount_after, 10)

  expect_error(
    multiscape::add_effects(p, effects = e_after, effect_type = "delta"),
    "Column 'after'"
  )

  e_delta <- transform(e_after[, c("pu", "action", "feature")], delta = -2)
  out_delta <- multiscape::add_effects(p, effects = e_delta, effect_type = "delta")
  expect_true(any(out_delta$data$dist_effects$loss > 0))

  expect_error(
    multiscape::add_effects(p, effects = e_delta, effect_type = "after"),
    "Column 'delta'"
  )

  e_effect <- transform(e_after[, c("pu", "action", "feature")], effect = 2)
  out_effect <- multiscape::add_effects(p, effects = e_effect, effect_type = "delta")
  expect_true(is.data.frame(out_effect$data$dist_effects))

  e_negative_benefit <- transform(
    e_after[, c("pu", "action", "feature")],
    benefit = -1
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = e_negative_benefit,
      effect_type = "delta"
    ),
    "non-negative"
  )

  e_ambiguous <- transform(e_after[, c("pu", "action", "feature")], delta = 1, effect = 1)
  expect_error(multiscape::add_effects(p, effects = e_ambiguous), "Ambiguous")

  e_split_bad <- transform(e_after[, c("pu", "action", "feature")], benefit = 1, loss = 1)
  expect_error(multiscape::add_effects(p, effects = e_split_bad), "cannot have both")

  e_negative_after <- transform(e_after[, c("pu", "action", "feature")], delta = -999)
  expect_error(multiscape::add_effects(p, effects = e_negative_after), "negative")

  expect_warning(
    out_empty <- multiscape::add_effects(
      p,
      effects = transform(e_after[, c("pu", "action", "feature")], delta = 1),
      effect_type = "delta",
      component = "loss"
    ),
    "No effect rows remain"
  )
  expect_equal(nrow(out_empty$data$dist_effects), 0L)
})


test_that("build_model helpers cover implicit conservation and defensive table preparation", {
  p <- make_round4_problem()

  expect_true(multiscape:::.pa_needs_implicit_conservation_model(p))
  implicit <- multiscape:::.pa_add_implicit_conservation_model(p)
  expect_false(multiscape:::.pa_needs_implicit_conservation_model(implicit))
  expect_true(isTRUE(implicit$data$meta$implicit_actions))
  expect_true(isTRUE(implicit$data$meta$implicit_effects))
  expect_true(nrow(implicit$data$dist_actions) > 0L)
  expect_true(nrow(implicit$data$dist_effects) > 0L)

  already <- make_round4_problem(with_actions = TRUE)
  unchanged <- multiscape:::.pa_add_implicit_conservation_model(already)
  expect_equal(nrow(unchanged$data$actions), nrow(already$data$actions))

  broken <- p
  broken$data$pu$internal_id <- NULL
  expect_error(multiscape:::.pa_add_implicit_conservation_model(broken), "internal_id")

  x <- make_round4_problem(with_actions = TRUE)
  x$data$dist_actions$status[1] <- 3L
  x$data$dist_actions$cost[2] <- NA_real_
  x$data$dist_actions$internal_pu[3] <- NA_integer_
  x$data$dist_effects <- data.frame(
    pu = c(1, 99),
    action = c("restoration", "restoration"),
    feature = c(1, 1),
    benefit = c(1, 2),
    loss = c(0, 0),
    stringsAsFactors = FALSE
  )
  x$data$dist_profit <- data.frame(
    pu = c(1, 99),
    action = c("restoration", "restoration"),
    profit = c(5, 6),
    stringsAsFactors = FALSE
  )

  prepared <- multiscape:::.pa_build_model_prepare_tables(x)
  expect_true(all(prepared$data$dist_actions_model$status != 3L))
  expect_true(all(is.finite(prepared$data$dist_actions_model$cost)))
  expect_true("internal_row" %in% names(prepared$data$dist_actions_model))
  expect_true(nrow(prepared$data$dist_effects_model) <= nrow(x$data$dist_effects))
  expect_true(is.data.frame(prepared$data$dist_profit_model))

  dup <- make_round4_problem(with_actions = TRUE)
  dup$data$dist_actions <- rbind(dup$data$dist_actions[1, ], dup$data$dist_actions[1, ])
  expect_error(multiscape:::.pa_build_model_prepare_tables(dup), "duplicated")

  out_range <- make_round4_problem(with_actions = TRUE)
  out_range$data$dist_actions$internal_pu[1] <- 999L
  expect_error(multiscape:::.pa_build_model_prepare_tables(out_range), "out of range")
})


test_that("build_model validation helpers catch missing dependencies", {
  p <- make_round4_problem()
  p$data$model_args <- list(model_type = "minimizeCosts")
  p$data$targets <- NULL
  expect_error(
    multiscape:::.pa_build_model_validate_pipeline_state(p, input_format = "new"),
    "requires targets"
  )

  p_legacy <- p
  expect_error(
    multiscape:::.pa_build_model_validate_pipeline_state(p_legacy, input_format = "legacy"),
    NA
  )

  p_no_obj <- p
  p_no_obj$data$model_args <- list(model_type = "")
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_no_obj), "No active objective")

  p_need_actions <- p
  p_need_actions$data$model_args <- list(model_type = "maximizeProfit")
  p_need_actions$data$dist_actions_model <- data.frame()
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_need_actions), "requires actions")

  p_need_effects <- make_round4_problem(with_actions = TRUE)
  p_need_effects$data$targets <- data.frame(feature = 1, target_value = 1)
  p_need_effects$data$model_args <- list(model_type = "minimizeCosts")
  p_need_effects$data$dist_actions_model <- p_need_effects$data$dist_actions
  p_need_effects$data$dist_effects_model <- data.frame()
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_need_effects), "no action effects")
})
