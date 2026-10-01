# Historical effects interfaces: retained to protect backward compatibility.
# Other test files use semantic inputs. Explicit warning checks are below.

test_that("[legacy] historical tables warn and match semantic replacements", {
  p <- reference_problem()
  keys <- data.frame(pu = 1, action = "restore", feature = 1)
  cases <- list(
    list(data = transform(keys, delta = 30), args = list(), effect = 30),
    list(data = transform(keys, after = 130), args = list(effect_type = "after"), effect = 30),
    list(data = data.frame(action = "restore", feature = 1, multiplier = 0.3),
         args = list(), effect = 30),
    list(data = data.frame(action = "restore", feature = 1, multiplier = 1.3),
         args = list(effect_type = "after"), effect = 30),
    list(data = transform(keys, benefit = 30), args = list(), effect = 30),
    list(data = transform(keys, loss = 20), args = list(), effect = -20),
    list(data = transform(keys, effect = 130), args = list(effect_type = "after"), effect = 30),
    list(data = transform(keys, effect = 30), args = list(component = "any"), effect = 30),
    list(data = transform(keys, effect = 30), args = list(effect_aggregation = "sum"), effect = 30)
  )
  for (case in cases) {
    lifecycle::expect_deprecated(
      old <- do.call(add_effects, c(list(x = p, effects = case$data), case$args))
    )
    modern <- add_effects(p, transform(keys, effect = case$effect))
    expect_equal(old$data$dist_effects, modern$data$dist_effects)
  }
  lifecycle::expect_deprecated(add_benefits(p, transform(keys, delta = 30)))
  lifecycle::expect_deprecated(add_losses(p, transform(keys, delta = -20)))
})

test_that("[legacy] raster arguments warn and preserve single-feature coefficients", {
  p <- reference_problem()
  z <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 1)
  terra::values(z) <- 1:2
  p$data$pu_raster_id <- z
  r <- z
  terra::values(r) <- c(30, 0)
  lifecycle::expect_deprecated(old <- add_effects(
    p, list(restore = r), effect_type = "delta", effect_aggregation = "sum"
  ))
  modern <- add_effects(p, list(restore = r), raster_type = "effect", raster_aggregation = "sum")
  expect_equal(old$data$dist_effects, modern$data$dist_effects)
})

# From test-actions-effects.R
test_that("[legacy] add_effects validates unknown entities and conflicting components", {
  withr::local_options(lifecycle_verbosity = "quiet")
  x <- make_round3_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_effects(
      x,
      effects = data.frame(
        action = "unknown",
        feature = 1,
        multiplier = 1
      ),
      effect_type = "after"
    )
  )

  expect_error(
    multiscape::add_effects(
      x,
      effects = data.frame(
        action = "conservation",
        feature = "unknown",
        multiplier = 1
      ),
      effect_type = "after"
    )
  )

  expect_error(
    multiscape::add_effects(
      x,
      effects = data.frame(
        pu = 1,
        action = "conservation",
        feature = 1,
        benefit = 1,
        loss = 1
      )
    ),
    "both positive"
  )
})

# From test-actions-effects.R
test_that("[legacy] add_benefits and add_losses create component-specific effects", {
  withr::local_options(lifecycle_verbosity = "quiet")
  x <- make_round3_action_problem(with_effects = FALSE)

  benefits <- multiscape::add_benefits(
    x,
    benefits = data.frame(
      pu = 1L,
      action = "restoration",
      feature = 1L,
      delta = 2
    ),
    effect_type = "delta"
  )

  expect_true(all(benefits$data$dist_effects$loss == 0))
  expect_true(any(benefits$data$dist_effects$benefit > 0))
  expect_s3_class(benefits$data$dist_benefit, "data.frame")

  losses <- multiscape::add_losses(
    x,
    losses = data.frame(
      pu = 1L,
      action = "conservation",
      feature = 2L,
      delta = -1
    ),
    effect_type = "delta"
  )

  expect_true(all(losses$data$dist_effects$benefit == 0))
  expect_true(any(losses$data$dist_effects$loss > 0))
  expect_s3_class(losses$data$dist_loss, "data.frame")
})

# From test-add-effects-components-and-names.R
test_that("[legacy] add_effects accepts feature names and component filters", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round4_problem(with_actions = TRUE)

  effects <- data.frame(
    pu = c(1, 2),
    action = c("conservation", "restoration"),
    feature = c("sp1", "sp2"),
    delta = c(2, -3)
  )

  benefit_only <- multiscape::add_effects(
    p,
    effects = effects,
    effect_type = "delta",
    component = "benefit"
  )
  expect_equal(nrow(benefit_only$data$dist_effects), 1L)
  expect_true(all(benefit_only$data$dist_effects$benefit > 0))
  expect_equal(benefit_only$data$dist_effects$feature, 1L)

  loss_only <- multiscape::add_effects(
    p,
    effects = effects,
    effect_type = "delta",
    component = "loss"
  )
  expect_equal(nrow(loss_only$data$dist_effects), 1L)
  expect_true(all(loss_only$data$dist_effects$loss > 0))
  expect_equal(loss_only$data$dist_effects$feature, 2L)
})

# From test-add_effects.R
test_that("[legacy] after column requires effect_type = 'after'", {
  withr::local_options(lifecycle_verbosity = "quiet")
  pu <- data.frame(id = 1, cost = 1)
  features <- data.frame(id = 1, name = "carbon")
  dist_features <- data.frame(pu = 1, feature = 1, amount = 100)

  p <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features
  )

  p <- add_actions(
    p,
    actions = data.frame(id = "harvest")
  )

  eff <- data.frame(
    pu = 1,
    action = "harvest",
    feature = 1,
    after = 30
  )

  expect_error(
    add_effects(
      p,
      effects = eff,
      effect_type = "delta"
    ),
    "Column 'after' was provided"
  )
})

# From test-add_effects.R
test_that("[legacy] add_benefits and add_losses use benefit and loss columns", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round4_problem(with_actions = TRUE)

  b <- multiscape::add_benefits(
    p,
    benefits = data.frame(
      pu = 1L,
      action = "restoration",
      feature = 1L,
      benefit = 2
    )
  )

  l <- multiscape::add_losses(
    p,
    losses = data.frame(
      pu = 1L,
      action = "restoration",
      feature = 1L,
      loss = 0.5
    )
  )

  expect_s3_class(b, "Problem")
  expect_s3_class(l, "Problem")
})

# From test-coverage-effects-more.R
test_that("[legacy] add_effects rejects malformed explicit numeric values", {
  withr::local_options(lifecycle_verbosity = "quiet")
  make_p <- function() make_round3_action_problem(with_effects = FALSE)
  common <- data.frame(pu = 1, action = "conservation", feature = 1)

  expect_error(
    multiscape::add_effects(make_p(), transform(common, delta = NA_real_)),
    "missing values"
  )
  expect_error(
    multiscape::add_effects(make_p(), transform(common, delta = Inf)),
    "finite values"
  )
  expect_error(
    multiscape::add_effects(make_p(), transform(common, delta = "bad")),
    "must be numeric"
  )
  expect_error(
    multiscape::add_effects(
      make_p(), transform(common, benefit = "bad", loss = 0)
    ),
    "must be numeric"
  )
  expect_error(
    multiscape::add_effects(
      make_p(), transform(common, benefit = -1, loss = 0)
    ),
    "non-negative"
  )
  expect_error(
    multiscape::add_effects(make_p(), transform(common, unrelated = 1)),
    "must include 'delta'"
  )
})

# From test-coverage-effects-more.R
test_that("[legacy] component wrappers filter signed effects consistently", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round3_action_problem(with_effects = FALSE)
  signed <- data.frame(
    pu = c(1, 2), action = c("conservation", "restoration"),
    feature = c(1, 2), effect = c(2, -1)
  )
  benefits <- multiscape::add_benefits(p, signed, effect_type = "delta")
  expect_true(all(benefits$data$dist_effects$benefit > 0))

  losses <- multiscape::add_losses(
    make_round3_action_problem(FALSE), signed, effect_type = "delta"
  )
  expect_true(all(losses$data$dist_effects$loss > 0))
})

# From test-coverage-effects-targeted.R
test_that("[legacy] add_effects canonicalizes partial split benefit and loss tables", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round2_action_problem(with_effects = FALSE)

  benefit <- multiscape::add_effects(
    p,
    data.frame(
      pu = 1,
      action = "conservation",
      feature = 1,
      benefit = 2,
      loss = 0
    )
  )
  expect_equal(benefit$data$dist_effects$benefit, 2)
  expect_equal(benefit$data$dist_effects$loss, 0)

  loss <- multiscape::add_effects(
    p,
    data.frame(
      pu = 2,
      action = "restoration",
      feature = 2,
      loss = 1,
      benefit = 0
    )
  )
  expect_equal(loss$data$dist_effects$benefit, 0)
  expect_equal(loss$data$dist_effects$loss, 1)

  only_benefits <- multiscape::add_benefits(
    p,
    benefits = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      delta = c(2, -1)
    )
  )
  expect_true(all(only_benefits$data$dist_effects$benefit > 0))
  expect_false("loss" %in% names(only_benefits$data$dist_benefit))

  only_losses <- multiscape::add_losses(
    p,
    losses = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c(1, 2),
      delta = c(2, -1)
    )
  )
  expect_true(all(only_losses$data$dist_effects$loss > 0))
  expect_false("benefit" %in% names(only_losses$data$dist_loss))
})

# From test-coverage-effects-targeted.R
test_that("[legacy] add_effects validates compact and explicit effect specifications", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round2_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = "unknown", multiplier = 1)
    ),
    "Unknown feature name"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = 99, multiplier = 1)
    ),
    "Unknown feature id"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(action = "conservation", feature = 1, multiplier = "x")
    ),
    "must be numeric"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        action = c("conservation", "conservation"),
        feature = c(1, 1),
        multiplier = c(1, 2)
      )
    ),
    "duplicated combination"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1,
        delta = 1, effect = 2
      )
    ),
    "Ambiguous effect specification"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, after = 2
      ),
      effect_type = "delta"
    ),
    "Column 'after'.*effect_type = 'delta'"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, delta = 2
      ),
      effect_type = "after"
    ),
    "Column 'delta'.*effect_type = 'after'"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1,
        benefit = 1, loss = 1
      )
    ),
    "cannot have both"
  )
  expect_error(
    multiscape::add_effects(
      p,
      data.frame(
        pu = 1, action = "conservation", feature = 1, delta = -100
      )
    ),
    "after-action feature amounts are negative"
  )
  expect_error(multiscape::add_effects(p, effects = "bad"), "Unsupported type")
})

# From test-effects-build-model.R
test_that("[legacy] add_benefits and add_losses store wrapper-specific tables", {
  withr::local_options(lifecycle_verbosity = "quiet")
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

# From test-effects-build-model.R
test_that("[legacy] add_effects covers signed, after, effect, legacy benefit, and invalid paths", {
  withr::local_options(lifecycle_verbosity = "quiet")
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

# From test-effects-reference-api.R
test_that("[legacy] new inputs and legacy inputs feed identical model tables", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- reference_problem()
  b <- data.frame(pu = 1, action = "restore", feature = 1, effect = 30)
  modern <- add_effects(p, b)
  b$delta <- b$effect
  b$effect <- NULL
  lifecycle::expect_deprecated(old <- add_effects(p, b))
  expect_equal(modern$data$dist_effects, old$data$dist_effects)
  modern <- multiscape:::.pa_build_model_prepare_tables(modern)
  old <- multiscape:::.pa_build_model_prepare_tables(old)
  expect_equal(modern$data$dist_effects_model, old$data$dist_effects_model)
  p$data$dist_actions$status <- c(1L, 3L)
  compact <- data.frame(action = "restore", feature = 1, effect = 30)
  expect_equal(add_effects(p, compact)$data$dist_effects$pu, 1L)
  expect_error(add_effects(p, rbind(compact, compact)), "duplicated")
})

# From test-effects-reference-api.R
test_that("[legacy] legacy positional calls preserve coefficients and warn", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- reference_problem()
  b <- data.frame(pu = 1, action = "restore", feature = 1, effect = 130)
  lifecycle::expect_deprecated(q <- add_effects(p, b, "after", "sum", "any"))
  expect_equal(q$data$dist_effects$effect, 30)
  b <- data.frame(action = "restore", feature = 1, multiplier = 0.3)
  lifecycle::expect_deprecated(q <- add_effects(p, b))
  # Legacy compact multipliers expand only over stored (non-zero) references.
  expect_equal(q$data$dist_effects$effect, 30)
})

# From test-effects-reference-api.R
test_that("[legacy] semantic inputs reject ambiguity and invalid values", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- reference_problem()
  b <- data.frame(pu = 1, action = "restore", feature = 1, outcome = 130)
  expect_error(add_effects(p, b, effect_type = "after"), "omit effect_type")
  b$effect <- 30
  expect_error(add_effects(p, b), "exactly one")
  b$effect <- NULL
  b$outcome <- NA_real_
  expect_error(add_effects(p, b), "missing")
  b$outcome <- -1
  expect_error(add_effects(p, b), "negative")
  b$outcome <- Inf
  expect_error(add_effects(p, b), "finite")
  b$outcome <- "130"
  expect_error(add_effects(p, b), "numeric")
  expect_error(add_effects(p, raster_aggregation = "mean", effect_aggregation = "sum"), "only one")
})

# From test-locked-actions-and-effects-extra.R
test_that("[legacy] add_effects validates effect types, components, and malformed effect tables", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = 1, multiplier = 1), effect_type = "bad"),
    "should be one of|effect_type"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = 1, multiplier = 1), component = "bad"),
    "should be one of|component"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(pu = 1, action = "conservation", feature = 1)),
    "multiplier|amount_after|benefit|loss|Elements"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "unknown", feature = 1, multiplier = 1), effect_type = "after"),
    "action"
  )

  expect_error(
    multiscape::add_effects(p, effects = data.frame(action = "conservation", feature = "unknown", multiplier = 1), effect_type = "after"),
    "feature"
  )

  after <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration"),
      feature = c("sp1", "sp2"),
      after = c(2, 5)
    ),
    effect_type = "after"
  )
  expect_true(is.data.frame(after$data$dist_effects))

  benefit <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = 2,
      action = "restoration",
      feature = "sp1",
      benefit = 4
    ),
    component = "benefit"
  )
  expect_true(is.data.frame(benefit$data$dist_effects))

  loss <- multiscape::add_effects(
    p,
    effects = data.frame(
      pu = 1,
      action = "conservation",
      feature = "sp2",
      loss = 1
    ),
    component = "loss"
  )
  expect_true(is.data.frame(loss$data$dist_effects))
})

# From test-solver-effects.R
test_that("[legacy] add_effects covers explicit split benefit and loss valid branches", {
  withr::local_options(lifecycle_verbosity = "quiet")
  p <- make_round4_problem(with_actions = TRUE)

  e_benefit <- data.frame(
    pu = 1L,
    action = "restoration",
    feature = "sp1",
    benefit = 2,
    stringsAsFactors = FALSE
  )

  out_benefit <- multiscape::add_effects(
    p,
    effects = e_benefit,
    component = "benefit"
  )

  expect_true(is.data.frame(out_benefit$data$dist_effects))
  expect_true(all(out_benefit$data$dist_effects$benefit > 0))
  expect_true(all(out_benefit$data$dist_effects$loss == 0))

  e_loss <- data.frame(
    pu = 1L,
    action = "restoration",
    feature = "sp1",
    loss = 1,
    stringsAsFactors = FALSE
  )

  out_loss <- multiscape::add_effects(
    p,
    effects = e_loss,
    component = "loss"
  )

  expect_true(is.data.frame(out_loss$data$dist_effects))
  expect_true(all(out_loss$data$dist_effects$loss > 0))
  expect_true(all(out_loss$data$dist_effects$benefit == 0))
})
