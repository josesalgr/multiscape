test_that("add_effects validates duplicated keys and unknown feature names", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = c(1, 1),
        action = c("conservation", "conservation"),
        feature = c("sp1", "sp1"),
        effect = c(1, 2)
      )
    ),
    "duplicated"
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = 1,
        action = "conservation",
        feature = "unknown",
        effect = 1
      )
    ),
    "Unknown feature name"
  )

  expect_error(
    multiscape::add_effects(
      p,
      effects = data.frame(
        pu = 1,
        action = "conservation",
        feature = "sp1",
        effect = NA_real_
      )
    ),
    "missing"
  )
})
