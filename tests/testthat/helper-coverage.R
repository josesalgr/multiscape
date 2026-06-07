make_round2_action_problem <- function(with_effects = TRUE,
                                       with_profit = FALSE,
                                       with_boundary = FALSE) {
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
    id = c("conservation", "restoration"),
    name = c("conservation", "restoration")
  )

  x <- multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = actions,
      cost = c(conservation = 1, restoration = 2)
    )

  if (isTRUE(with_effects)) {
    effects <- data.frame(
      action = rep(actions$id, each = 2),
      feature = rep(features$id, times = 2),
      multiplier = c(
        1.0, 0.8,
        1.2, 1.8
      )
    )

    x <- multiscape::add_effects(
      x,
      effects = effects,
      effect_type = "after"
    )
  }

  if (isTRUE(with_profit)) {
    profit <- data.frame(
      pu = rep(pu$id, each = 2),
      action = rep(actions$id, times = nrow(pu)),
      profit = c(
        1, 10,
        2, 9,
        3, 8,
        4, 7
      )
    )

    x <- multiscape::add_profit(x, profit)
  }

  if (isTRUE(with_boundary)) {
    boundary <- data.frame(
      pu1 = c(1, 2, 3),
      pu2 = c(2, 3, 4),
      boundary = c(1, 1, 1)
    )

    x <- multiscape::add_spatial_boundary(
      x,
      boundary = boundary,
      weight_col = "boundary",
      include_self = FALSE
    )
  }

  x
}


make_round2_spatial_problem <- function(action_based = FALSE) {
  testthat::skip_if_not_installed("sf")

  geometry <- sf::st_sfc(
    sf::st_polygon(list(matrix(
      c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(1, 0, 2, 0, 2, 1, 1, 1, 1, 0),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(0, 1, 1, 1, 1, 2, 0, 2, 0, 1),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(1, 1, 2, 1, 2, 2, 1, 2, 1, 1),
      ncol = 2,
      byrow = TRUE
    ))),
    crs = 3857
  )

  pu <- sf::st_sf(
    id = 1:4,
    cost = c(1, 2, 3, 4),
    geometry = geometry
  )

  features <- data.frame(
    id = 1:2,
    name = c("sp1", "sp2")
  )

  dist_features <- data.frame(
    pu = rep(1:4, each = 2),
    feature = rep(1:2, times = 4),
    amount = c(5, 1, 4, 2, 2, 4, 1, 5)
  )

  x <- multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  )

  if (isTRUE(action_based)) {
    actions <- data.frame(
      id = c("conservation", "restoration")
    )

    effects <- data.frame(
      action = rep(actions$id, each = 2),
      feature = rep(features$id, times = 2),
      multiplier = c(1, 1, 1.5, 1.5)
    )

    x <- x |>
      multiscape::add_actions(
        actions = actions,
        cost = c(conservation = 1, restoration = 2)
      ) |>
      multiscape::add_effects(
        effects = effects,
        effect_type = "after"
      )
  }

  x
}


make_round3_tabular_problem <- function() {
  pu <- data.frame(
    id = 1:4,
    cost = c(1, 2, 3, 4),
    group = c("a", "a", "b", "b")
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

  multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  )
}


make_round3_action_problem <- function(with_effects = TRUE) {
  x <- make_round3_tabular_problem()

  actions <- data.frame(
    id = c("conservation", "restoration"),
    name = c("Conservation", "Restoration")
  )

  x <- multiscape::add_actions(
    x,
    actions = actions,
    cost = c(
      conservation = 1,
      restoration = 2
    )
  )

  if (isTRUE(with_effects)) {
    effects <- data.frame(
      action = rep(actions$id, each = 2),
      feature = rep(1:2, times = 2),
      multiplier = c(
        1.0, 0.8,
        1.4, 1.8
      )
    )

    x <- multiscape::add_effects(
      x,
      effects = effects,
      effect_type = "after"
    )
  }

  x
}


make_round3_spatial_problem <- function(action_based = FALSE) {
  testthat::skip_if_not_installed("sf")

  geometry <- sf::st_sfc(
    sf::st_polygon(list(matrix(
      c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(1, 0, 2, 0, 2, 1, 1, 1, 1, 0),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(0, 1, 1, 1, 1, 2, 0, 2, 0, 1),
      ncol = 2,
      byrow = TRUE
    ))),
    sf::st_polygon(list(matrix(
      c(1, 1, 2, 1, 2, 2, 1, 2, 1, 1),
      ncol = 2,
      byrow = TRUE
    ))),
    crs = 3857
  )

  pu <- sf::st_sf(
    id = 1:4,
    cost = c(1, 2, 3, 4),
    geometry = geometry
  )

  features <- data.frame(
    id = 1:2,
    name = c("sp1", "sp2")
  )

  dist_features <- data.frame(
    pu = rep(1:4, each = 2),
    feature = rep(1:2, times = 4),
    amount = c(5, 1, 4, 2, 2, 4, 1, 5)
  )

  x <- multiscape::create_problem(
    pu = pu,
    features = features,
    dist_features = dist_features,
    cost = "cost"
  )

  if (isTRUE(action_based)) {
    x <- multiscape::add_actions(
      x,
      actions = data.frame(
        id = c("conservation", "restoration")
      ),
      cost = c(
        conservation = 1,
        restoration = 2
      )
    )

    x <- multiscape::add_effects(
      x,
      effects = data.frame(
        action = rep(c("conservation", "restoration"), each = 2),
        feature = rep(1:2, times = 2),
        multiplier = c(1, 1, 1.5, 1.5)
      ),
      effect_type = "after"
    )
  }

  x
}


solve_round3_multiobjective <- function(n = 4L) {
  skip_if_no_cbc()

  x <- make_round3_action_problem(with_effects = TRUE) |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "benefit"),
      runs = multiscape::run_grid(
        n = n,
        include_extremes = TRUE
      ),
      normalize_weights = TRUE
    ) |>
    multiscape::set_solver_cbc(
      gap_limit = 0,
      verbose = FALSE
    )

  multiscape::solve(x)
}


make_round4_base_data <- function() {
  list(
    pu = data.frame(
      id = 1:4,
      cost = c(1, 2, 3, 4)
    ),
    features = data.frame(
      id = 1:2,
      name = c("sp1", "sp2")
    ),
    dist_features = data.frame(
      pu = c(1, 1, 2, 3, 4),
      feature = c(1, 2, 2, 1, 2),
      amount = c(5, 2, 3, 4, 1)
    ),
    actions = data.frame(
      id = c("conservation", "restoration"),
      name = c("conservation", "restoration")
    )
  )
}


make_round4_problem <- function(with_actions = FALSE) {
  d <- make_round4_base_data()

  x <- multiscape::create_problem(
    pu = d$pu,
    features = d$features,
    dist_features = d$dist_features,
    cost = "cost"
  )

  if (isTRUE(with_actions)) {
    x <- multiscape::add_actions(
      x,
      actions = d$actions,
      cost = c(
        conservation = 1,
        restoration = 2
      )
    )
  }

  x
}


make_round4_mo_problem <- function() {
  d <- make_round4_base_data()

  effects <- data.frame(
    action = rep(d$actions$id, each = 2),
    feature = rep(d$features$id, times = 2),
    multiplier = c(
      1.0, 1.0,
      1.5, 1.5
    )
  )

  multiscape::create_problem(
    pu = d$pu,
    features = d$features,
    dist_features = d$dist_features,
    cost = "cost"
  ) |>
    multiscape::add_actions(
      actions = d$actions,
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
}
