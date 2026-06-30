test_that("add_profit supports all documented input forms", {
  p <- make_round2_action_problem(with_effects = FALSE)

  zero <- multiscape::add_profit(p, NULL)
  expect_s3_class(zero, "Problem")
  expect_s3_class(zero$data$dist_profit, "data.frame")
  expect_equal(nrow(zero$data$dist_profit), 0L)

  scalar <- multiscape::add_profit(p, 5)
  expect_true(all(scalar$data$dist_profit$profit == 5))
  expect_equal(nrow(scalar$data$dist_profit), 8L)

  named <- multiscape::add_profit(
    p,
    c(conservation = 2, restoration = -1)
  )
  expect_setequal(unique(named$data$dist_profit$profit), c(2, -1))

  action_table <- multiscape::add_profit(
    p,
    data.frame(
      action = c("conservation", "restoration"),
      profit = c(3, 0)
    )
  )
  expect_equal(nrow(action_table$data$dist_profit), 4L)
  expect_true(all(action_table$data$dist_profit$action == "conservation"))

  pair_table <- multiscape::add_profit(
    p,
    data.frame(
      pu = c(1, 3),
      action = c("restoration", "conservation"),
      profit = c(10, -2)
    )
  )
  expect_equal(nrow(pair_table$data$dist_profit), 2L)
  expect_setequal(pair_table$data$dist_profit$profit, c(10, -2))
  expect_true(
    all(c("internal_pu", "internal_action") %in%
          names(pair_table$data$dist_profit))
  )
})


test_that("add_profit validates malformed specifications", {
  p <- make_round2_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_profit(p, c(unknown = 1)),
    "unknown action"
  )

  expect_error(
    multiscape::add_profit(
      p,
      data.frame(action = c("conservation", "conservation"), profit = 1:2)
    ),
    "unique action"
  )

  expect_error(
    multiscape::add_profit(
      p,
      data.frame(
        pu = c(1, 1),
        action = c("conservation", "conservation"),
        profit = c(1, 2)
      )
    ),
    "duplicate"
  )

  expect_error(
    multiscape::add_profit(
      p,
      data.frame(action = "unknown", profit = 1)
    ),
    "unknown action"
  )

  expect_error(
    multiscape::add_profit(p, Inf),
    "finite"
  )
})


test_that("max profit compiles and selects profitable decisions", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = FALSE,
    with_profit = TRUE
  ) |>
    multiscape::add_objective_max_profit(alias = "profit") |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  compiled <- multiscape::compile_model(p)
  expect_s3_class(compiled, "Problem")

  s <- multiscape::solve(p)
  expect_s3_class(s, "SolutionSet")

  selected <- multiscape::get_actions(s)
  expect_gt(nrow(selected), 0L)

  sol_selected <- selected[selected$selected == 1L, , drop = FALSE]
  expect_true(all(sol_selected$action == "restoration"))
})


test_that("max net profit compiles and solves", {
  skip_if_no_cbc()

  p <- make_round2_action_problem(
    with_effects = FALSE,
    with_profit = TRUE
  ) |>
    multiscape::add_objective_max_net_profit(
      include_pu_cost = TRUE,
      include_action_cost = TRUE,
      alias = "net_profit"
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  compiled <- multiscape::compile_model(p)
  expect_s3_class(compiled, "Problem")

  s <- multiscape::solve(p)
  expect_s3_class(s, "SolutionSet")
})


test_that("loss and intervention impact objectives compile", {
  p_loss <- make_round2_action_problem(with_effects = TRUE) |>
    multiscape::add_objective_min_loss(alias = "loss")

  expect_s3_class(multiscape::compile_model(p_loss), "Problem")

  p_impact <- make_round2_action_problem(with_effects = TRUE) |>
    multiscape::add_objective_min_intervention_impact(
      impact_col = "amount",
      alias = "impact"
    )

  expect_s3_class(multiscape::compile_model(p_impact), "Problem")
})


test_that("action fragmentation objective compiles", {
  p <- make_round2_action_problem(
    with_effects = FALSE,
    with_boundary = TRUE
  ) |>
    multiscape::add_objective_min_fragmentation_action(
      relation_name = "boundary",
      actions = "restoration",
      alias = "action_frag"
    )

  expect_s3_class(multiscape::compile_model(p), "Problem")
})


test_that("add_profit supports partial named vectors and preserves the input", {
  p <- make_round3_action_problem(with_effects = FALSE)
  original <- p$data$dist_profit

  out <- multiscape::add_profit(
    p,
    c(restoration = 5)
  )

  expect_true(all(out$data$dist_profit$action == "restoration"))
  expect_true(all(out$data$dist_profit$profit == 5))
  expect_identical(p$data$dist_profit, original)
})


test_that("add_profit validates named vector values and names", {
  p <- make_round3_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_profit(
      p,
      c(conservation = Inf)
    )
  )

  expect_error(
    multiscape::add_profit(
      p,
      stats::setNames(1, "")
    )
  )

  duplicated <- c(1, 2)
  names(duplicated) <- c("conservation", "conservation")

  expect_error(
    multiscape::add_profit(p, duplicated)
  )
})


test_that("add_profit rejects unknown planning units and infeasible pairs", {
  p <- make_round3_action_problem(with_effects = FALSE)

  expect_error(
    multiscape::add_profit(
      p,
      data.frame(
        pu = 999,
        action = "conservation",
        profit = 1
      )
    ),
    "unknown pu"
  )

  restricted <- multiscape::add_actions(
    make_round3_tabular_problem(),
    actions = data.frame(id = c("conservation", "restoration")),
    include_pairs = data.frame(
      pu = c(1, 2),
      action = c("conservation", "restoration")
    ),
    cost = 1
  )

  expect_error(
    multiscape::add_profit(
      restricted,
      data.frame(
        pu = 1,
        action = "restoration",
        profit = 10
      )
    ),
    "not feasible"
  )
})
