make_explicit_mo_problem <- function(
    n = 5L,
    method = c("weighted", "epsilon")
) {
  method <- match.arg(method)

  pu <- data.frame(
    id = 1:4,
    cost = c(1, 2, 3, 4)
  )

  features <- data.frame(
    id = 1:2,
    name = c("sp1", "sp2")
  )

  dist_features <- data.frame(
    pu = c(1, 1, 2, 3, 4),
    feature = c(1, 2, 2, 1, 2),
    amount = c(5, 2, 3, 4, 1)
  )

  actions <- data.frame(
    id = c("conservation", "restoration")
  )

  effects <- data.frame(
    action = rep(actions$id, each = 2),
    feature = rep(features$id, times = 2),
    multiplier = c(
      1.0, 1.0,
      1.5, 1.5
    )
  )

  x <- multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = actions,
      cost = c(
        conservation = 1,
        restoration = 2
      )
    ) |>
    multiscape::add_effects(
      effects = effects,
      effect_type = "after"
    ) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit")

  if (identical(method, "weighted")) {
    x <- multiscape::set_method_weighted_sum(
      x,
      aliases = c("cost", "benefit"),
      runs = multiscape::run_grid(
        n = n,
        include_extremes = TRUE
      ),
      normalize_weights = TRUE
    )
  } else {
    x <- multiscape::set_method_epsilon_constraint(
      x,
      primary = "cost",
      runs = multiscape::run_grid(
        n = n,
        include_extremes = TRUE
      )
    )
  }

  multiscape::set_solver_cbc(
    x,
    gap_limit = 0,
    verbose = FALSE
  )
}


solve_explicit_mo_problem <- function(
    n = 5L,
    method = c("weighted", "epsilon")
) {
  skip_if_no_cbc()

  multiscape::solve(
    make_explicit_mo_problem(
      n = n,
      method = method
    )
  )
}
