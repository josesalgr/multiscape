joint_base <- function(actions = c("a", "b"), sets = list(ab = c("a", "b")), pu = 10L,
                       reference = 100, features = "habitat", pairs = NULL) {
  df <- expand.grid(pu = pu, feature = seq_along(features))
  df$amount <- reference
  create_problem(data.frame(id = pu, cost = 0),
                 data.frame(id = seq_along(features), name = features), df) |>
    add_actions(data.frame(id = actions), cost = 1, include_pairs = pairs) |>
    add_action_sets(sets) |>
    add_constraint_action_cardinality(length(actions), "max")
}

joint_pair <- function(total = 70, pu = 10L, features = "habitat") {
  p <- joint_base(pu = pu, features = features)
  table <- expand.grid(action = c("a", "b", "ab"), feature = features,
                       stringsAsFactors = FALSE)
  table$effect <- c(30, 20, total)
  add_effects(p, table)
}

# Exercise the signed polynomial through existing internal IR, without adding
# the public net-benefit objective reserved for the next development stage.
joint_signed_objective <- function(p, alias = NULL, actions = NULL, features = NULL) {
  multiscape:::.pa_set_active_and_register_objective(
    p, "maximizeBenefits", "max_benefit",
    list(benefit_col = "effect", actions = actions, features = features), "max", alias = alias)
}

joint_selected <- function(solution, pu = 10L) {
  da <- get_actions(solution)
  sort(as.character(da$action[da$pu == pu & da$selected > 0.5]))
}

joint_methods <- function(p, epsilon) {
  list(
    weighted = set_method_weighted_sum(p, aliases = c("cost", "change"),
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_change = 1)), normalize_weights = FALSE),
    epsilon = set_method_epsilon_constraint(p, primary = "cost", aliases = c("cost", "change"),
      runs = set_runs_manual(data.frame(eps_change = epsilon))),
    augmecon = set_method_augmecon(p, primary = "cost", aliases = c("cost", "change"),
      runs = set_runs_manual(data.frame(eps_change = epsilon)))
  )
}

test_that("total joint inputs and atomic catalogs are preserved separately from corrections", {
  base <- joint_base()
  input <- data.frame(action = c("ab", "b", "a"), feature = "habitat", effect = c(70, 20, 30))
  p <- add_effects(base, input)
  expect_identical(p$data$actions, base$data$actions)
  expect_identical(p$data$dist_actions, base$data$dist_actions)
  expect_identical(p$data$effects_input, input)
  expect_equal(p$data$effects_original$effect[match(input$action, p$data$effects_original$action)], input$effect)
  expect_equal(p$data$joint_effects$effect, 70)
  expect_equal(p$data$effect_terms$effect[match(c("a", "b", "ab"), p$data$effect_terms$action)], c(30, 20, 20))
  expect_setequal(p$data$dist_effects$action, c("a", "b"))
  expect_true(is.na(p$data$joint_effects$internal_action))
  expect_identical(p$data$effects_meta$missing_interactions, "zero")
  expect_null(base$data$effect_terms)
  expect_error(add_effects(p, input), "already defined")
})

test_that("effect, outcome and relative change give identical joint polynomials", {
  base <- joint_base(pu = c(10L, 20L), reference = c(100, 200))
  input <- expand.grid(pu = c(10L, 20L), action = c("a", "b", "ab"), feature = "habitat")
  input$relative_change <- rep(c(.3, .2, .7), each = 2)
  relative <- add_effects(base, input)
  ref <- rep(c(100, 200), 3)
  input$outcome <- ref * (1 + input$relative_change)
  input$relative_change <- NULL
  outcome <- add_effects(base, input)
  input$effect <- input$outcome - ref
  input$outcome <- NULL
  absolute <- add_effects(base, input)
  expect_equal(relative$data$effect_terms, absolute$data$effect_terms)
  expect_equal(outcome$data$effect_terms, absolute$data$effect_terms)
  expect_equal(absolute$data$effect_terms$effect[absolute$data$effect_terms$action == "ab"], c(20, 40))
})

test_that("zero reference and zero corrections have explicit meanings", {
  p <- suppressWarnings(joint_base(reference = 0))
  relative <- add_effects(p, data.frame(action = "ab", feature = "habitat", relative_change = 1))
  expect_equal(relative$data$joint_effects$effect, 0)
  absolute <- add_effects(p, data.frame(action = "ab", feature = "habitat", effect = 7))
  expect_equal(absolute$data$effect_terms$effect, 7)
  expect_identical(absolute$data$effects_meta$missing_individual_effects, "zero")
  expect_error(add_effects(p, data.frame(action = "ab", feature = "habitat", effect = -1)), "negative")
  zero <- joint_pair(50) |> add_objective_max_benefit() |> compile_model()
  expect_equal(zero$data$joint_effects$effect, 50)
  expect_equal(zero$data$effect_terms$effect[zero$data$effect_terms$action == "ab"], 0)
  expect_equal(nrow(zero$data$joint_variables_model), 0)
})

test_that("three-action decomposition subtracts all supplied proper subsets", {
  p <- joint_base(c("a", "b", "c"), list(ab = c("a", "b"), ac = c("a", "c"),
    bc = c("b", "c"), abc = c("a", "b", "c")))
  totals <- c(a = 30, b = 20, c = 10, ab = 70, ac = 45, bc = 25, abc = 90)
  order <- c(7, 3, 5, 1, 4, 6, 2)
  input <- data.frame(action = names(totals)[order], feature = "habitat", effect = totals[order])
  out <- add_effects(p, input)
  terms <- out$data$effect_terms
  expect_equal(terms$effect[match(names(totals), terms$action)], c(30, 20, 10, 20, 5, -5, 10))
  for (id in names(totals)) {
    members <- if (id %in% p$data$action_sets$set) p$data$action_sets$action[p$data$action_sets$set == id] else id
    included <- vapply(terms$members, function(m) all(m %in% members), logical(1))
    expect_equal(sum(terms$effect[included]), unname(totals[id]), info = id)
  }
  reversed <- add_effects(p, input[nrow(input):1L, ])
  expect_equal(reversed$data$effect_terms, terms)
})

test_that("unspecified interactions are zero without generating all subsets", {
  p <- joint_base(c("a", "b", "c"), list(ab = c("a", "b"), abc = c("a", "b", "c"))) |>
    add_effects(data.frame(action = c("a", "b", "c", "ab", "abc"),
                          feature = "habitat", effect = c(30, 20, 10, 70, 100)))
  expect_equal(nrow(p$data$effect_terms), 5)
  expect_equal(p$data$effect_terms$effect[p$data$effect_terms$action == "abc"], 20)
  expect_identical(p$data$effects_meta$missing_interactions, "zero")
})

test_that("equivalent membership aliases cannot double-count a supplied effect", {
  p <- joint_base(sets = list(ab = c("a", "b"), ba = c("b", "a")))
  expect_error(add_effects(p, data.frame(action = c("ab", "ba"), feature = "habitat", effect = 70)),
               "Duplicated joint-effect membership")
  expect_null(p$data$dist_effects)
  good <- add_effects(joint_base(sets = list(ab = c("a", "b"), ba = c("b", "a")),
    features = c("habitat", "water")), data.frame(action = c("ab", "ba"),
      feature = c("habitat", "water"), effect = c(70, 20))) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(nrow(good$data$joint_variables_model), 1)
  expect_equal(length(unique(good$data$effect_terms_model$column0)), 1)
})

test_that("joint inputs reject legacy filtering, invalid values and unavailable explicit scopes", {
  p <- joint_base()
  input <- data.frame(action = "ab", feature = "habitat", effect = 70)
  expect_error(suppressWarnings(add_effects(p, input, component = "benefit")), "Joint effects require")
  expect_error(suppressWarnings(add_effects(p, input, effect_type = "delta")), "Joint effects require")
  expect_error(add_effects(p, transform(input, effect = Inf)), "finite")
  expect_error(add_effects(p, transform(input, effect = NA_real_)), "missing")
  expect_error(add_effects(p, transform(input, effect = "70")), "numeric")
  expect_error(add_effects(p, rbind(input, input)), "duplicated")
  expect_error(add_effects(p, transform(input, action = "unknown")), "Unknown")
  expect_error(add_effects(p, transform(input, pu = 99)), "available pairs")
  unavailable <- joint_base(pu = c(10L, 20L), pairs = data.frame(pu = c(10, 10, 20), action = c("a", "b", "a")))
  out <- add_effects(unavailable, input)
  expect_equal(out$data$joint_effects$pu, 10)
  expect_error(add_effects(unavailable, transform(input, pu = 20)), "available pairs")
})

test_that("compiled continuous AND variables match every binary allocation exactly", {
  for (total in c(70, 40, 5)) {
    p <- joint_signed_objective(joint_pair(total)) |> compile_model()
    ml <- p$data$model_list
    group <- p$data$joint_variables_model
    expect_equal(ml$vtype[group$column0 + 1L], "C")
    expect_equal(ml$bounds$lower$val[group$column0 + 1L], 0)
    expect_equal(ml$bounds$upper$val[group$column0 + 1L], 1)
    allocations <- expand.grid(a = 0:1, b = 0:1)
    for (k in seq_len(nrow(allocations))) {
      selected <- as.numeric(allocations[k, ])
      vector <- numeric(length(ml$obj))
      vector[ml$x_offset + p$data$dist_actions_model$internal_row] <- selected
      vector[ml$w_offset + 1L] <- as.integer(any(selected > 0))
      vector[group$column0 + 1L] <- prod(selected)
      check <- function(v) {
        lhs <- as.numeric(ml$A %*% v)
        all(ifelse(ml$sense == "<=", lhs <= ml$rhs + 1e-8,
                   ifelse(ml$sense == ">=", lhs >= ml$rhs - 1e-8, abs(lhs - ml$rhs) < 1e-8)))
      }
      expect_true(check(vector), info = paste(total, k))
      expect_equal(sum(vector * ml$obj), c(0, 30, 20, total)[k])
      vector[group$column0 + 1L] <- .5
      expect_false(check(vector), info = paste(total, k))
    }
  }
})

test_that("auxiliaries are shared across features and removed for unreachable combinations", {
  p <- joint_pair(70, pu = c(10L, 20L), features = c("habitat", "water")) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(nrow(p$data$joint_variables_model), 2)
  expect_equal(p$data$model_registry$vars$joint_effects$n_constraints, 6)
  locked <- joint_pair(70, pu = c(10L, 20L)) |>
    add_constraint_locked_actions(locked_out = list(b = 10L)) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(locked$data$joint_variables_model$pu, 20)
  excluded <- joint_pair() |> add_constraint_action_excludes(c("a", "b")) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(nrow(excluded$data$joint_variables_model), 0)
  limited <- joint_base() |> add_constraint_action_cardinality(1, "max", actions = c("a", "b")) |>
    add_effects(data.frame(action = c("a", "b", "ab"), feature = "habitat", effect = c(30, 20, 70))) |>
    add_objective_max_benefit() |> compile_model()
  expect_equal(nrow(limited$data$joint_variables_model), 0)
})

test_that("negative interactions cannot be evaded in any MO method", {
  skip_if_no_cbc()
  for (total in c(70, 40, 5)) {
    p <- joint_pair(total) |> add_constraint_action_cardinality(1, "min") |>
      add_objective_min_cost(include_pu_cost = FALSE, alias = "cost")
    p <- joint_signed_objective(p, alias = "change") |> set_solver_cbc(gap_limit = 0)
    solutions <- joint_methods(p, if (total >= 40) total - 1 else 29)
    for (method in names(solutions)) {
      s <- solve(solutions[[method]])
      expected <- if (total >= 40) c("a", "b") else "a"
      expected_change <- if (total >= 40) total else 30
      expect_identical(joint_selected(s), expected, info = paste(total, method))
      expect_equal(get_objectives(s)$change, expected_change, info = paste(total, method))
      expect_equal(get_objectives(s)$cost, length(expected), info = paste(total, method))
      f <- get_features(s)
      expect_equal(f$selected_benefit, expected_change)
      expect_equal(f$selected_loss, 0)
      expect_equal(f$selected_amount_after, 100 + expected_change)
    }
  }
})

test_that("public benefit objectives work for positive joint contributions in all methods", {
  skip_if_no_cbc()
  p <- joint_pair() |> add_constraint_action_cardinality(1, "min") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "change") |> set_solver_cbc(gap_limit = 0)
  for (spec in joint_methods(p, 69)) {
    s <- solve(spec)
    expect_equal(get_objectives(s)$change, 70)
    expect_identical(joint_selected(s), c("a", "b"))
  }
})

test_that("public joint loss objectives retain their minimization sense in all MO methods", {
  skip_if_no_cbc()
  p <- joint_base() |>
    add_effects(data.frame(action = c("a", "b", "ab"), feature = "habitat",
                           effect = c(-10, -20, -40))) |>
    add_constraint_action_cardinality(1, "min") |>
    add_profit(c(a = 10, b = 9)) |>
    add_objective_max_profit(alias = "profit") |>
    add_objective_min_loss(alias = "loss") |>
    set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(p, aliases = c("profit", "loss"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_profit = 1, weight_loss = .1))),
    set_method_epsilon_constraint(p, primary = "profit", aliases = c("profit", "loss"),
      runs = set_runs_manual(data.frame(eps_loss = 40))),
    set_method_augmecon(p, primary = "profit", aliases = c("profit", "loss"),
      runs = set_runs_manual(data.frame(eps_loss = 40)))
  )
  for (spec in methods) {
    solution <- solve(spec)
    expect_identical(joint_selected(solution), c("a", "b"))
    expect_equal(get_objectives(solution)$profit, 19)
    expect_equal(get_objectives(solution)$loss, 40)
    expect_equal(get_features(solution)$selected_loss, 40)
    expect_equal(get_features(solution)$selected_amount_after, 60)
  }
})

test_that("joint auxiliaries coexist with spatial auxiliaries and three MO objectives", {
  skip_if_no_cbc()
  p <- joint_pair(pu = c(10L, 20L)) |>
    add_constraint_action_cardinality(1, "min") |>
    add_spatial_relations(data.frame(pu1 = 10L, pu2 = 20L, weight = 7), name = "edge") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "change") |>
    add_objective_min_fragmentation_action(relation_name = "edge", alias = "frag") |>
    set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(p, aliases = c("cost", "change", "frag"), normalize_weights = FALSE,
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_change = 1, weight_frag = 1))),
    set_method_epsilon_constraint(p, primary = "cost", aliases = c("cost", "change", "frag"),
      runs = set_runs_manual(data.frame(eps_change = 139, eps_frag = 0))),
    set_method_augmecon(p, primary = "cost", aliases = c("cost", "change", "frag"),
      runs = set_runs_manual(data.frame(eps_change = 139, eps_frag = 0)))
  )
  for (spec in methods) {
    solution <- solve(spec)
    expect_equal(get_objectives(solution)$cost, 4)
    expect_equal(get_objectives(solution)$change, 140)
    expect_equal(get_objectives(solution)$frag, 0)
    expect_identical(joint_selected(solution, 10L), c("a", "b"))
    expect_identical(joint_selected(solution, 20L), c("a", "b"))
    expect_equal(get_features(solution)$selected_amount_after, 340)
  }
})

test_that("mixed positive/loss objectives and concurrent targets stay protected until point five", {
  p <- joint_pair(40)
  expect_error(compile_model(add_objective_max_benefit(p)), "final feature aggregation")
  expect_error(compile_model(add_objective_min_loss(p)), "final feature aggregation")
  targets <- p |> add_constraint_targets_absolute(10) |> add_objective_min_cost()
  expect_error(compile_model(targets), "targets require final feature aggregation")
  expect_error(compile_model(joint_signed_objective(p, features = 99)), "Unknown feature")
})

test_that("pure joint losses remain signed and the original problem is unchanged", {
  skip_if_no_cbc()
  base <- joint_base()
  p <- base |> add_effects(data.frame(action = c("a", "b", "ab"), feature = "habitat",
                                     effect = c(-10, -20, -40))) |>
    add_constraint_action_cardinality(2, "min") |> add_objective_min_loss() |>
    set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_equal(get_features(s)$selected_loss, 40)
  expect_equal(get_features(s)$selected_benefit, 0)
  expect_equal(get_features(s)$selected_amount_after, 60)
  expect_null(base$data$effects_original)
  expect_null(base$data$model_ptr)
})

test_that("physical outcomes of inferred combinations cannot be negative", {
  skip_if_no_cbc()
  p <- joint_base(c("a", "b", "c"), list(ab = c("a", "b")), reference = 100) |>
    add_effects(data.frame(action = c("a", "b", "c", "ab"), feature = "habitat",
                           effect = c(-60, -60, 0, -80))) |>
    add_profit(c(a = 10, b = 9, c = 1)) |> add_objective_max_profit() |>
    set_solver_cbc(gap_limit = 0)
  expect_equal(get_features(solve(p))$selected_amount_after, 20)
  # Without the supplied positive pair correction, two individually valid
  # losses could imply a negative joint amount; reject that selection in MILP.
  p <- joint_base(c("a", "b", "c"), list(ac = c("a", "c"))) |>
    add_effects(data.frame(action = c("a", "b", "ac"), feature = "habitat", effect = c(-60, -60, -60))) |>
    add_profit(c(a = 10, b = 9, c = 1)) |> add_objective_max_profit() |> set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_identical(joint_selected(s), c("a", "c"))
  expect_equal(get_features(s)$selected_amount_after, 40)
})

test_that("joint objective scopes include a correction only when all members are in scope", {
  skip_if_no_cbc()
  p <- joint_pair() |> add_objective_max_benefit(actions = "a", alias = "benefit") |> set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_equal(get_objectives(s)$benefit, 30)
  p <- joint_pair(features = c("habitat", "water")) |>
    add_objective_max_benefit(features = "water", alias = "benefit") |> set_solver_cbc(gap_limit = 0)
  expect_equal(get_objectives(solve(p))$benefit, 70)
})

test_that("ten actions and all supplied subsets reproduce an independent polynomial", {
  actions <- letters[1:10]
  sets <- list()
  totals <- stats::setNames(seq_along(actions), actions)
  for (size in 2:10) for (m in combn(actions, size, simplify = FALSE)) {
    id <- paste0("set_", paste(m, collapse = ""))
    sets[[id]] <- m
    # Only three corrections are non-zero despite specifying all 1013 sets.
    totals[id] <- sum(match(m, actions)) +
      4 * all(c("a", "b") %in% m) - 2 * all(c("b", "c") %in% m) +
      7 * all(c("a", "b", "c") %in% m)
  }
  p <- joint_base(actions, sets) |>
    add_effects(data.frame(action = names(totals), feature = "habitat", effect = as.numeric(totals)))
  expect_equal(nrow(p$data$effect_terms), 1023)
  group <- p$data$effect_terms[p$data$effect_terms$kind == "set" & p$data$effect_terms$effect != 0, ]
  expect_equal(nrow(group), 3)
  expect_setequal(group$effect, c(4, -2, 7))
  p <- joint_signed_objective(p) |> compile_model()
  expect_equal(p$data$model_registry$vars$joint_effects$n_variables, 3)
  expect_equal(p$data$model_registry$vars$joint_effects$n_constraints, 10)
  allocations <- as.matrix(expand.grid(rep(list(0:1), 10)))
  terms <- p$data$effect_terms_model
  for (k in seq_len(nrow(allocations))) {
    selected <- actions[allocations[k, ] == 1]
    computed <- sum(terms$effect[vapply(terms$members, function(m) all(m %in% selected), logical(1))])
    expected <- sum(which(allocations[k, ] == 1)) + 4 * all(c("a", "b") %in% selected) -
      2 * all(c("b", "c") %in% selected) + 7 * all(c("a", "b", "c") %in% selected)
    expect_equal(computed, expected)
  }
})

test_that("malformed native groups are rejected atomically", {
  p <- joint_signed_objective(joint_pair()) |> compile_model()
  before <- multiscape:::rcpp_optimization_problem_as_list(p$data$model_ptr)
  columns <- p$data$model_list$x_offset + p$data$dist_actions_model$internal_row - 1L
  for (bad in list(columns[1], c(columns[1], columns[1]), c(NA_integer_, columns[1]), c(-1L, columns[1]))) {
    expect_error(multiscape:::rcpp_add_joint_effect_variables(p$data$model_ptr, list(as.integer(columns), as.integer(bad))),
                 "members|member")
    expect_identical(multiscape:::rcpp_optimization_problem_as_list(p$data$model_ptr), before)
  }
})

test_that("modern joint raster inputs retain totals and multi-feature alignment", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  r <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 1, crs = "EPSG:3857")
  polygon <- sf::st_polygon(list(matrix(c(0, 0, 2, 0, 2, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)))
  pu <- sf::st_sf(id = 10L, cost = 0, geometry = sf::st_sfc(polygon, crs = 3857))
  features <- data.frame(id = 1:2, name = c("habitat", "water"))
  p <- create_problem(pu, features, data.frame(pu = 10L, feature = 1:2, amount = c(100, 200))) |>
    add_actions(data.frame(id = c("a", "b")), cost = 1) |>
    add_action_sets(list(ab = c("a", "b"))) |> add_constraint_action_cardinality(2, "max")
  rasters <- lapply(list(a = c(10, 20, 20, 40), b = c(5, 15, 10, 30), ab = c(30, 40, 60, 80)), function(values) {
    out <- c(r, r)
    terra::values(out) <- matrix(values, nrow = 2)
    out
  })
  effects <- add_effects(p, rasters, raster_type = "effect")
  expect_equal(effects$data$joint_effects$effect, c(70, 140))
  expect_equal(effects$data$effect_terms$effect[effects$data$effect_terms$action == "ab"], c(20, 40))
  expect_null(effects$data$effects_input)
  for (id in names(rasters)) {
    terra::values(rasters[[id]]) <- terra::values(rasters[[id]]) + matrix(c(50, 50, 100, 100), nrow = 2)
  }
  outcomes <- add_effects(p, rasters, raster_type = "outcome")
  expect_equal(outcomes$data$effect_terms, effects$data$effect_terms)
  compiled <- effects |> add_objective_max_benefit() |> compile_model()
  expect_equal(nrow(compiled$data$joint_variables_model), 1)
})

test_that("automatic payoff and grid methods never overstate negative interactions", {
  skip_if_no_cbc()
  p <- joint_pair(40) |> add_constraint_action_cardinality(1, "min") |>
    add_objective_min_cost(alias = "cost", include_pu_cost = FALSE)
  p <- joint_signed_objective(p, alias = "change") |> set_solver_cbc(gap_limit = 0)
  methods <- list(
    set_method_weighted_sum(p, aliases = c("cost", "change"), runs = set_runs_grid(n = 3)),
    set_method_epsilon_constraint(p, primary = "cost", aliases = c("cost", "change"), runs = set_runs_grid(n = 3)),
    set_method_augmecon(p, primary = "cost", aliases = c("cost", "change"), runs = set_runs_grid(n = 3))
  )
  for (spec in methods) {
    solution <- solve(spec)
    values <- get_objectives(solution)
    expect_equal(max(values$change), 40)
    expect_true(all(values$change <= 40))
    actions <- get_actions(solution)
    for (k in seq_len(nrow(values))) {
      id <- values$solution_id[k]
      selected <- actions$action[actions$solution_id == id & actions$selected > .5]
      expected <- if (all(c("a", "b") %in% selected)) 40 else if ("a" %in% selected) 30 else 20
      expect_equal(values$change[k], expected)
    }
  }
})

test_that("compilation caches, clones and later locks preserve original joint totals", {
  p <- joint_pair() |> add_objective_max_benefit() |> compile_model()
  expect_identical(compile_model(p)$data$model_list, p$data$model_list)
  original <- serialize(p$data$effects_original, NULL)
  pointer <- p$data$model_ptr
  locked <- add_constraint_locked_actions(p, locked_out = list(b = 10))
  expect_null(locked$data$model_ptr)
  expect_identical(p$data$model_ptr, pointer)
  expect_identical(serialize(locked$data$effects_original, NULL), original)
  locked <- compile_model(locked)
  expect_equal(nrow(locked$data$joint_variables_model), 0)
  expect_equal(nrow(p$data$joint_variables_model), 1)
  expect_error(add_effects(p, p$data$effects_input), "already defined")
})

test_that("corrupt stored joint coefficients are rejected before native construction", {
  base <- joint_pair() |> add_objective_max_benefit()
  mutations <- list(
    function(d) { d$effect[1] <- Inf; d },
    function(d) { d$members[[1]] <- "unknown"; d },
    function(d) { d$pu[1] <- 999L; d },
    function(d) { d$member_key[1] <- "wrong"; d }
  )
  for (f in mutations) {
    out <- multiscape:::.pa_clone_data(base)
    out$data$effect_terms <- f(base$data$effect_terms)
    expect_error(compile_model(out), "malformed|invalid")
    expect_null(out$data$model_ptr)
  }
})

test_that("problem summaries expose joint data and the explicit additive assumption", {
  p <- joint_pair()
  withr::local_options(cli.width = 200)
  output <- paste(capture.output(print(p), type = "message"), collapse = " ")
  expect_match(output, "joint effects: *1 supplied rows")
  expect_match(output, "missing interactions assumed zero")
  expect_match(output, "effect data: *3 rows")
})
