test_that("add_effects with effect separates benefit and loss correctly", {
  toy <- toy_equivalent_basic()

  effects_change <- data.frame(
    pu = c(1, 2, 3, 4),
    action = c("conservation", "conservation", "conservation", "conservation"),
    feature = c(1, 1, 2, 2),
    effect = c(5, -2, 0, -7)
  )

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = effects_change)

  de <- p$data$dist_effects

  expect_true(all(c("benefit", "loss") %in% names(de)))

  row1 <- de[de$pu == 1 & de$feature == 1, ]
  row2 <- de[de$pu == 2 & de$feature == 1, ]
  row4 <- de[de$pu == 4 & de$feature == 2, ]

  expect_equal(row1$benefit, 5)
  expect_equal(row1$loss, 0)

  expect_equal(row2$benefit, 0)
  expect_equal(row2$loss, 2)

  expect_equal(row4$benefit, 0)
  expect_equal(row4$loss, 7)
})

test_that("add_effects with outcome computes signed effects from reference amounts", {
  toy <- toy_equivalent_basic()

  effects_outcome <- data.frame(
    pu = c(1, 2),
    action = c("conservation", "conservation"),
    feature = c(1, 2),
    outcome = c(10, 1)
  )

  # baseline: pu1-feature1 = 8 ; pu2-feature2 = 2
  # expected effects: +2 and -1

  p <- multiscape::create_problem(
    pu = toy$pu,
    features = toy$features,
    dist_features = toy$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(actions = toy$actions, cost = 0) |>
    multiscape::add_effects(effects = effects_outcome)

  de <- p$data$dist_effects

  r1 <- de[de$pu == 1 & de$feature == 1, ]
  r2 <- de[de$pu == 2 & de$feature == 2, ]

  expect_equal(r1$benefit, 2)
  expect_equal(r1$loss, 0)

  expect_equal(r2$benefit, 0)
  expect_equal(r2$loss, 1)
})

test_that("relative changes reproduce action outcomes", {
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
    action = "harvest",
    feature = 1,
    relative_change = -0.7
  )

  p2 <- add_effects(
    p,
    effects = eff
  )

  expect_equal(nrow(p2$data$dist_effects), 1)
  expect_equal(p2$data$dist_effects$benefit, 0)
  expect_equal(p2$data$dist_effects$loss, 70)
})

test_that("relative changes reproduce signed effects", {
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
    actions = data.frame(id = "restoration")
  )

  eff <- data.frame(
    action = "restoration",
    feature = 1,
    relative_change = 0.3
  )

  p2 <- add_effects(
    p,
    effects = eff
  )

  expect_equal(nrow(p2$data$dist_effects), 1)
  expect_equal(p2$data$dist_effects$benefit, 30)
  expect_equal(p2$data$dist_effects$loss, 0)
})


test_that("explicit action outcomes are converted to losses", {
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
    outcome = 30
  )

  p2 <- add_effects(
    p,
    effects = eff
  )

  expect_equal(p2$data$dist_effects$benefit, 0)
  expect_equal(p2$data$dist_effects$loss, 70)
})


test_that("relative changes store amount_after for neutral conservation actions", {
  pu <- data.frame(id = 1, cost = 1)

  features <- data.frame(id = 1, name = "carbon")

  dist_features <- data.frame(
    pu = 1,
    feature = 1,
    amount = 100
  )

  p <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features
  )

  p <- add_actions(
    p,
    actions = data.frame(id = "conservation")
  )

  eff <- data.frame(
    action = "conservation",
    feature = 1,
    relative_change = 0
  )

  p2 <- add_effects(
    p,
    effects = eff
  )

  expect_equal(nrow(p2$data$dist_effects), 1)
  expect_equal(p2$data$dist_effects$amount_after, 100)
  expect_equal(p2$data$dist_effects$benefit, 0)
  expect_equal(p2$data$dist_effects$loss, 0)
})


test_that("relative changes store amount_after for neutral conservation actions", {
  pu <- data.frame(id = 1, cost = 1)

  features <- data.frame(id = 1, name = "carbon")

  dist_features <- data.frame(
    pu = 1,
    feature = 1,
    amount = 100
  )

  p <- create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features
  )

  p <- add_actions(
    p,
    actions = data.frame(id = "conservation")
  )

  eff <- data.frame(
    action = "conservation",
    feature = 1,
    relative_change = 0
  )

  p2 <- add_effects(
    p,
    effects = eff
  )

  expect_equal(nrow(p2$data$dist_effects), 1)
  expect_equal(p2$data$dist_effects$amount_after, 100)
  expect_equal(p2$data$dist_effects$benefit, 0)
  expect_equal(p2$data$dist_effects$loss, 0)
})


test_that("add_effects accepts relative changes by action and feature", {
  d <- make_round4_base_data()
  p <- make_round4_problem(with_actions = TRUE)

  effects <- data.frame(
    action = rep(d$actions$id, each = 2),
    feature = rep(d$features$id, times = 2),
    relative_change = c(
      0, 0,
      0.5, 0.5
    )
  )

  out <- multiscape::add_effects(
    p,
    effects = effects
  )

  expect_s3_class(out, "Problem")
})


test_that("add_effects accepts explicit pu-action-feature effect rows", {
  p <- make_round4_problem(with_actions = TRUE)

  effects <- data.frame(
    pu = c(1L, 2L),
    action = c("restoration", "restoration"),
    feature = c(1L, 2L),
    effect = c(1, -0.5)
  )

  out <- multiscape::add_effects(
    p,
    effects = effects
  )

  expect_s3_class(out, "Problem")
})


test_that("add_effects rejects duplicate keys", {
  p <- make_round4_problem(with_actions = TRUE)

  duplicated <- data.frame(
    action = c("restoration", "restoration"),
    feature = c(1L, 1L),
    relative_change = c(0.5, 0.5)
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = duplicated
    ),
    "duplicated combination"
  )
})


test_that("add_effects rejects non-finite values", {
  p <- make_round4_problem(with_actions = TRUE)

  non_finite <- data.frame(
    action = "restoration",
    feature = 1L,
    relative_change = Inf
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = non_finite
    ),
    "finite"
  )
})


test_that("add_effects rejects unknown actions, features, and planning units", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        action = "unknown",
        feature = 1L,
        relative_change = 0.5
      )
    )
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        action = "restoration",
        feature = 999L,
        relative_change = 0.5
      )
    )
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = 999L,
        action = "restoration",
        feature = 1L,
        effect = 1
      )
    )
  )
})
