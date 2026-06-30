test_that("weighted-sum validates aliases, scaling, runs, and deprecated weights", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = NULL,
      runs = multiscape::set_runs_grid(3)
    ),
    "aliases"
  )
  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", ""),
      runs = multiscape::set_runs_grid(3)
    ),
    "empty"
  )
  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      objective_scaling = NA
    ),
    "objective_scaling"
  )
  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = NULL
    ),
    "runs"
  )
  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      normalize_weights = NA
    ),
    "normalize_weights"
  )

  expect_error(
    multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      weights = c(1, 1)
    ),
    "runs.*weights|weights.*runs|only one"
  )
  expect_error(
    suppressWarnings(multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      weights = c(1, NA)
    )),
    "weights"
  )
  expect_error(
    suppressWarnings(multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      weights = c(1, Inf)
    )),
    "finite"
  )
  expect_error(
    suppressWarnings(multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      weights = c(1, -1)
    )),
    "non-negative"
  )
  expect_error(
    suppressWarnings(multiscape::set_method_weighted_sum(
      p,
      aliases = c("cost", "benefit"),
      weights = c(0, 0)
    )),
    "positive"
  )

  out <- suppressWarnings(multiscape::set_method_weighted_sum(
    p,
    aliases = c("cost", "benefit"),
    weights = c(2, 1),
    normalize_weights = TRUE,
    objective_scaling = TRUE,
    control = multiscape::set_runs_control(stop_on_error = FALSE)
  ))
  expect_s3_class(out, "Problem")
  expect_true(out$data$method$normalize_weights)
  expect_true(out$data$method$objective_scaling)
  expect_false(out$data$method$stop_on_error)
  expect_equal(names(out$data$method$runs$values), c("weight_cost", "weight_benefit"))
})


test_that("epsilon-constraint validates aliases, deprecated interface, and lexicographic settings", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "",
      runs = multiscape::set_runs_grid(3)
    ),
    "primary"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", NA_character_),
      runs = multiscape::set_runs_grid(3)
    ),
    "aliases"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", ""),
      runs = multiscape::set_runs_grid(3)
    ),
    "empty"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", "cost"),
      runs = multiscape::set_runs_grid(3)
    ),
    "duplicates"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("benefit"),
      runs = multiscape::set_runs_grid(3)
    ),
    "primary"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost"),
      runs = multiscape::set_runs_grid(3)
    ),
    "at least two"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      runs = NULL
    ),
    "runs"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      lexicographic = NA
    ),
    "lexicographic"
  )
  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      lexicographic_tol = -1
    ),
    "lexicographic_tol"
  )

  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(3),
      eps = list(benefit = 1)
    ),
    "runs.*deprecated|deprecated.*runs|not both"
  )

  out_manual_old <- suppressWarnings(multiscape::set_method_epsilon_constraint(
    p,
    primary = "cost",
    aliases = c("cost", "benefit"),
    mode = "manual",
    eps = list(benefit = c(2, 4)),
    lexicographic = FALSE,
    lexicographic_tol = 0
  ))
  expect_s3_class(out_manual_old, "Problem")
  expect_equal(out_manual_old$data$method$constrained, "benefit")
  expect_false(out_manual_old$data$method$lexicographic)
  expect_equal(out_manual_old$data$method$runs$values$eps_benefit, c(2, 4))

  out_auto_old <- suppressWarnings(multiscape::set_method_epsilon_constraint(
    p,
    primary = "cost",
    aliases = c("cost", "benefit"),
    mode = "auto",
    n_points = 4,
    include_extremes = FALSE
  ))
  expect_s3_class(out_auto_old, "Problem")
  expect_equal(out_auto_old$data$method$runs$n, 4L)
})


test_that("epsilon grid rejects three-objective automatic designs", {
  p <- make_round4_mo_problem() |>
    multiscape::add_objective_min_loss(alias = "loss")

  expect_error(
    multiscape::set_method_epsilon_constraint(
      p,
      primary = "cost",
      aliases = c("cost", "benefit", "loss"),
      runs = multiscape::set_runs_grid(3)
    ),
    "exactly one constrained objective"
  )

  ok <- multiscape::set_method_epsilon_constraint(
    p,
    primary = "cost",
    aliases = c("cost", "benefit", "loss"),
    runs = multiscape::set_runs_manual(
      data.frame(eps_benefit = c(1, 2), eps_loss = c(0, 1))
    )
  )
  expect_equal(ok$data$method$constrained, c("benefit", "loss"))
})
