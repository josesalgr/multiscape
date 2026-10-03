make_cardinality_problem <- function(pu = c(10L, 20L, 30L), include_pairs = NULL,
                                     actions = NULL, pu_cost = 7) {
  if (is.null(actions)) actions <- data.frame(id = c("a", "b", "c", "d"))
  create_problem(
    pu = data.frame(id = pu, cost = pu_cost),
    features = data.frame(id = 1L, name = "woodland"),
    dist_features = data.frame(pu = pu, feature = 1L, amount = 100)
  ) |>
    add_actions(actions, cost = 1, include_pairs = include_pairs)
}

cardinality_profit_problem <- function(...) {
  make_cardinality_problem(...) |>
    add_profit(c(a = 8, b = 4, c = 2, d = 1)) |>
    add_objective_max_profit(alias = "profit") |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
}

cardinality_selected_counts <- function(solution, ids, actions = NULL) {
  selected <- get_actions(solution)
  selected <- selected[selected$selected > 0.5, , drop = FALSE]
  if (!is.null(actions)) selected <- selected[selected$action %in% actions, , drop = FALSE]
  tabulate(match(selected$pu, ids), nbins = length(ids))
}

test_that("cardinality stores independent rules with normalized scopes", {
  p <- make_cardinality_problem()
  out <- p |>
    add_constraint_action_cardinality(4, "max", pu = c(20L, 10L, 20L), name = "capacity") |>
    add_constraint_action_cardinality(1, "min", actions = c("b", "a", "b"), pu = 10L)
  specs <- out$data$constraints$action_cardinality
  expect_s3_class(out, "Problem")
  expect_equal(nrow(specs), 2L)
  expect_identical(specs$count, c(4L, 1L))
  expect_identical(specs$pu[[1]], c(10L, 20L))
  expect_null(specs$actions[[1]])
  expect_identical(specs$actions[[2]], c("a", "b"))
  expect_identical(specs$name, c("capacity", "action_cardinality_2"))
  expect_null(p$data$constraints$action_cardinality)
})

test_that("cardinality preserves inputs and invalidates only the copied cache", {
  p <- cardinality_profit_problem() |> compile_model()
  data <- serialize(p$data[setdiff(names(p$data), "model_ptr")], NULL)
  pointer <- p$data$model_ptr
  out <- add_constraint_action_cardinality(p, 2, "max", pu = 10L)
  expect_null(out$data$model_ptr)
  expect_null(out$data$model_list)
  expect_true(out$data$meta$model_dirty)
  expect_false(p$data$meta$model_dirty)
  expect_identical(p$data$model_ptr, pointer)
  expect_identical(serialize(p$data[setdiff(names(p$data), "model_ptr")], NULL), data)
  for (field in c("pu", "actions", "dist_actions", "dist_profit", "objectives", "method")) {
    expect_identical(out$data[[field]], p$data[[field]], info = field)
  }
})

test_that("count is an integer scalar and sense is explicitly required", {
  p <- make_cardinality_problem()
  expect_error(add_constraint_action_cardinality(p, sense = "max"), "count.*provided")
  for (bad in list(NULL, numeric(), c(1, 2), NA_real_, Inf, -Inf, -1, 1.5,
                   .Machine$integer.max + 1, TRUE, "2", factor("2"), matrix(2))) {
    expect_error(add_constraint_action_cardinality(p, bad, "max"), "non-negative integer")
  }
  expect_error(add_constraint_action_cardinality(p, 1), "sense.*explicitly")
  expect_error(add_constraint_action_cardinality(p, 1, NULL), "sense.*explicitly")
  for (bad in list(NA_character_, "other", c("min", "max"), 1)) {
    expect_error(add_constraint_action_cardinality(p, 1, bad))
  }
  expect_identical(add_constraint_action_cardinality(p, 0, "equal")$data$constraints$action_cardinality$count, 0L)
})

test_that("the constructor validates problem prerequisites and rule names", {
  p <- make_cardinality_problem()
  for (bad in list(NULL, list(data = p$data), data.frame(id = 1))) {
    expect_error(add_constraint_action_cardinality(bad, 1, "max"), "Problem object")
  }
  no_actions <- create_problem(
    pu = data.frame(id = 1L, cost = 1), features = data.frame(id = 1L),
    dist_features = data.frame(pu = 1L, feature = 1L, amount = 1)
  )
  expect_error(add_constraint_action_cardinality(no_actions, 1, "max"), "Run add_actions")
  for (bad in list(NA_character_, "", " ", 1, c("a", "b"), character())) {
    expect_error(add_constraint_action_cardinality(p, 1, "max", name = bad), "name")
  }
})

test_that("PU and action scopes reject incomplete and invalid identifiers", {
  p <- make_cardinality_problem()
  for (bad in list(integer(), c(10, NA), Inf, TRUE, list(10), matrix(10), " ")) {
    expect_error(add_constraint_action_cardinality(p, 1, "max", pu = bad), "pu")
  }
  expect_error(add_constraint_action_cardinality(p, 1, "max", pu = c(10L, 99L)), "Unknown PU.*99")
  expect_error(add_constraint_action_cardinality(p, 1, "max", pu = 10.5), "Unknown PU")
  for (bad in list(character(), c("a", NA), Inf, TRUE, list("a"), matrix("a"), " ")) {
    expect_error(add_constraint_action_cardinality(p, 1, "max", actions = bad), "actions")
  }
  expect_error(add_constraint_action_cardinality(p, 1, "max", actions = c("a", "missing")), "Unknown action.*missing")
  out <- add_constraint_action_cardinality(p, 1, "max", pu = factor(c("20", "10")), actions = factor(c("b", "a")))
  expect_identical(out$data$constraints$action_cardinality$pu[[1]], c(10L, 20L))
  expect_identical(out$data$constraints$action_cardinality$actions[[1]], c("a", "b"))
  numeric_actions <- make_cardinality_problem(actions = data.frame(id = c(5L, 9L)))
  expect_identical(
    add_constraint_action_cardinality(numeric_actions, 1, "max", actions = 9L)$data$constraints$action_cardinality$actions[[1]],
    "9"
  )
})

test_that("legacy classification labels expand to individual actions", {
  p <- make_cardinality_problem(actions = data.frame(
    id = c("a", "b", "c", "d"), action_set = c("habitat", "habitat", "other", "other")
  ))
  out <- add_constraint_action_cardinality(p, 1, "max", actions = "habitat")
  expect_identical(out$data$constraints$action_cardinality$actions[[1]], c("a", "b"))
  sets <- add_action_sets(p, list(pair = c("a", "b")))
  expect_error(add_constraint_action_cardinality(sets, 1, "max", actions = "pair"), "individual members")
})

test_that("duplicate scopes and names are rejected without overwriting", {
  p <- make_cardinality_problem() |>
    add_constraint_action_cardinality(2, "max", pu = c(10L, 20L), actions = c("a", "b"), name = "capacity")
  original <- serialize(p$data, NULL)
  expect_error(add_constraint_action_cardinality(p, 1, "max", pu = c(20L, 10L, 10L), actions = c("b", "a")), "already exists")
  expect_error(add_constraint_action_cardinality(p, 1, "min", pu = 30L, name = "capacity"), "name already registered")
  out <- add_constraint_action_cardinality(p, 1, "min", pu = c(10L, 20L), actions = c("a", "b"))
  expect_equal(nrow(out$data$constraints$action_cardinality), 2L)
  expect_identical(serialize(p$data, NULL), original)
  # Generated names avoid explicitly supplied names.
  named <- make_cardinality_problem() |>
    add_constraint_action_cardinality(1, "min", name = "action_cardinality_2") |>
    add_constraint_action_cardinality(2, "max")
  expect_identical(named$data$constraints$action_cardinality$name, c("action_cardinality_2", "action_cardinality_3"))
})

test_that("without cardinality the default remains one action per unit", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem()
  expect_identical(cardinality_selected_counts(solve(p), c(10L, 20L, 30L)), c(1L, 1L, 1L))
  expect_equal(get_objectives(solve(p))$profit, 24)
  # Adding the old default explicitly changes no optimal decisions.
  explicit <- add_constraint_action_cardinality(p, 1, "max")
  expect_equal(get_actions(solve(explicit)), get_actions(solve(p)))
})

test_that("different capacities replace the implicit maximum only in covered units", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(4, "max", pu = 10L) |>
    add_constraint_action_cardinality(2, "max", pu = 20L)
  s <- solve(p)
  expect_identical(cardinality_selected_counts(s, c(10L, 20L, 30L)), c(4L, 2L, 1L))
  expect_equal(get_objectives(s)$profit, 35)
  compiled <- compile_model(p)
  expect_equal(compiled$data$model_registry$cons$action_max_per_pu$n_constraints_added, 1L)
})

test_that("a total upper bound covering every PU does not reintroduce the default", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |> add_constraint_action_cardinality(2, "max")
  compiled <- compile_model(p)
  expect_null(compiled$data$model_registry$cons$action_max_per_pu)
  expect_identical(cardinality_selected_counts(solve(p), c(10L, 20L, 30L)), c(2L, 2L, 2L))
  expect_equal(compiled$data$model_registry$cons$action_cardinality[[1]]$n_constraints_added, 3L)
})

test_that("a minimum applies to each PU and needs an explicit total upper bound", {
  skip_if_no_cbc()
  p <- make_cardinality_problem() |>
    add_constraint_action_cardinality(3, "max", pu = c(10L, 20L)) |>
    add_constraint_action_cardinality(2, "min", pu = c(10L, 20L)) |>
    add_objective_min_cost(include_pu_cost = FALSE) |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
  expect_identical(cardinality_selected_counts(solve(p), c(10L, 20L, 30L)), c(2L, 2L, 0L))
  only_min <- make_cardinality_problem() |>
    add_constraint_action_cardinality(2, "min", pu = 10L) |>
    add_objective_min_cost(include_pu_cost = FALSE) |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
  expect_error(solve(only_min), "status: infeasible")
})

test_that("exact counts are enforced and zero prohibits action selection", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(2, "equal", pu = 10L) |>
    add_constraint_action_cardinality(0, "equal", pu = 20L) |>
    add_constraint_action_cardinality(0, "max", pu = 30L)
  expect_identical(cardinality_selected_counts(solve(p), c(10L, 20L, 30L)), c(2L, 0L, 0L))
})

test_that("subset upper bounds and minima do not lift the total default", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(2, "max", actions = c("a", "b"), pu = 10L)
  expect_identical(cardinality_selected_counts(solve(p), c(10L, 20L, 30L)), c(1L, 1L, 1L))
  # Even listing every current action is explicitly a subset, not actions=NULL.
  all_explicit <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(4, "max", actions = c("a", "b", "c", "d"))
  expect_identical(cardinality_selected_counts(solve(all_explicit), c(10L, 20L, 30L)), c(1L, 1L, 1L))
})

test_that("total and subset rules combine without counting memberships twice", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |>
    add_action_sets(list(ab = c("a", "b"), ac = c("a", "c"))) |>
    add_constraint_action_cardinality(3, "max") |>
    add_constraint_action_cardinality(1, "max", actions = c("a", "b")) |>
    add_constraint_action_cardinality(1, "min", actions = "c", pu = 10L)
  s <- solve(p)
  expect_identical(cardinality_selected_counts(s, c(10L, 20L, 30L)), c(3L, 3L, 3L))
  expect_identical(cardinality_selected_counts(s, c(10L, 20L, 30L), c("a", "b")), c(1L, 1L, 1L))
  expect_equal(get_objectives(s)$profit, 33)
  expect_equal(nrow(get_action_sets(p)), 4L)
})

test_that("overlapping explicit rules are cumulative and independent of order", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem()
  first <- p |>
    add_constraint_action_cardinality(4, "max", pu = c(10L, 20L)) |>
    add_constraint_action_cardinality(2, "max", pu = c(20L, 30L))
  reverse <- p |>
    add_constraint_action_cardinality(2, "max", pu = c(20L, 30L)) |>
    add_constraint_action_cardinality(4, "max", pu = c(10L, 20L))
  expect_identical(cardinality_selected_counts(solve(first), c(10L, 20L, 30L)), c(4L, 2L, 2L))
  expect_equal(get_actions(solve(first)), get_actions(solve(reverse)))
})

test_that("positive lower bounds require enough available actions in every unit", {
  p <- make_cardinality_problem(include_pairs = data.frame(
    pu = c(10L, 10L, 20L), action = c("a", "b", "a")
  ))
  expect_error(add_constraint_action_cardinality(p, 2, "min", pu = c(10L, 20L)), "more actions.*20")
  expect_error(add_constraint_action_cardinality(p, 1, "equal", pu = 30L), "more actions.*30")
  expect_error(add_constraint_action_cardinality(p, 2, "equal", actions = "a", pu = 10L), "more actions.*10")
  out <- add_constraint_action_cardinality(p, 0, "min", pu = 30L)
  expect_equal(nrow(out$data$constraints$action_cardinality), 1L)
  out <- add_constraint_action_cardinality(p, 2, "max", pu = 30L) |>
    add_objective_min_cost()
  expect_warning(compiled <- compile_model(out), "all-zero solution")
  expect_equal(compiled$data$model_registry$cons$action_cardinality[[1]]$n_constraints_added, 0L)
})

test_that("locked-out and invalid-cost pairs are not available for positive counts", {
  p <- make_cardinality_problem()
  p$data$dist_actions$status[p$data$dist_actions$pu == 10L & p$data$dist_actions$action == "a"] <- 3L
  expect_error(add_constraint_action_cardinality(p, 4, "min", pu = 10L), "more actions.*10")
  p$data$dist_actions$cost[p$data$dist_actions$pu == 20L & p$data$dist_actions$action == "d"] <- NA_real_
  expect_error(add_constraint_action_cardinality(p, 4, "equal", pu = 20L), "more actions.*20")
})

test_that("action catalogs cannot be redefined after cardinality registration", {
  p <- make_cardinality_problem() |>
    add_constraint_action_cardinality(1, "min", actions = c("a", "b"), pu = 10L)
  original <- serialize(p$data, NULL)
  expect_error(add_actions(p, data.frame(id = c("d", "c", "b", "a", "e"))), "already defined")
  expect_error(add_actions(p, data.frame(id = c("a", "c", "d"))), "already defined")
  expect_identical(serialize(p$data, NULL), original)
})

test_that("model compilation revalidates rules after feasibility changes", {
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(4, "equal", pu = 10L)
  p$data$dist_actions$status[p$data$dist_actions$pu == 10L & p$data$dist_actions$action == "a"] <- 3L
  expect_error(compile_model(p), "more actions.*10")
  p <- cardinality_profit_problem() |> add_constraint_action_cardinality(1, "min", actions = "a")
  p$data$constraints$action_cardinality$actions[[1]] <- "missing"
  expect_error(compile_model(p), "unknown action")
})

test_that("cost charges a selected planning unit once and each action separately", {
  skip_if_no_cbc()
  p <- make_cardinality_problem() |>
    add_constraint_action_cardinality(2, "equal", pu = 10L) |>
    add_constraint_action_cardinality(0, "max", pu = c(20L, 30L)) |>
    add_objective_min_cost(alias = "cost") |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
  s <- solve(p)
  expect_equal(get_objectives(s)$cost, 9)
  expect_equal(sum(get_planning_units(s)$selected), 1L)
  expect_equal(sum(get_actions(s)$selected), 2L)
  p <- make_cardinality_problem() |>
    add_constraint_action_cardinality(4, "max") |>
    add_profit(c(a = 8, b = 4, c = 2, d = 1)) |>
    add_objective_max_net_profit(alias = "net") |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
  expect_equal(get_objectives(solve(p))$net, 12)
})

test_that("budgets apply to combined action costs and PU costs counted once", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(4, "max", pu = 10L) |>
    add_constraint_action_cardinality(0, "max", pu = c(20L, 30L)) |>
    add_constraint_budget(9, "max")
  s <- solve(p)
  expect_identical(cardinality_selected_counts(s, c(10L, 20L, 30L)), c(2L, 0L, 0L))
  expect_equal(get_objectives(s)$profit, 12)
})

test_that("locked actions count and conflicts with cardinality remain infeasible", {
  skip_if_no_cbc()
  p <- cardinality_profit_problem(pu = 10L)
  p$data$dist_actions$status[p$data$dist_actions$action %in% c("a", "b")] <- 2L
  s <- solve(add_constraint_action_cardinality(p, 2, "max"))
  expect_identical(cardinality_selected_counts(s, 10L), 2L)
  expect_error(solve(add_constraint_action_cardinality(p, 1, "max")), "status: infeasible")
  blocked <- cardinality_profit_problem(pu = 10L) |>
    add_constraint_action_cardinality(2, "equal") |>
    add_constraint_locked_planning_units(locked_out = 10L)
  expect_error(solve(blocked), "status: infeasible")
})

test_that("compiled rows match independently enumerated cardinality feasibility", {
  # Enumerate every allocation of four actions across two units; this checks
  # real column mapping, all row senses, zero bounds, and per-unit scope.
  p <- make_cardinality_problem(pu = c(20L, 10L), pu_cost = 0) |>
    add_constraint_action_cardinality(3, "max", name = "total") |>
    add_constraint_action_cardinality(2, "min", pu = 10L, name = "required") |>
    add_constraint_action_cardinality(1, "equal", actions = c("a", "b"), pu = 20L, name = "choice") |>
    add_constraint_action_cardinality(0, "max", actions = "d", pu = 10L, name = "excluded") |>
    add_objective_min_cost(include_pu_cost = FALSE) |>
    compile_model()
  da <- p$data$dist_actions_model
  ml <- p$data$model_list
  allocations <- as.matrix(expand.grid(rep(list(0:1), nrow(da))))
  actual <- expected <- logical(nrow(allocations))
  for (k in seq_len(nrow(allocations))) {
    decisions <- allocations[k, ]
    counts <- vapply(c(10L, 20L), function(id) sum(decisions[da$pu == id]), numeric(1))
    expected[k] <- all(counts <= 3) && counts[1] >= 2 &&
      sum(decisions[da$pu == 20L & da$action %in% c("a", "b")]) == 1 &&
      sum(decisions[da$pu == 10L & da$action == "d"]) == 0
    vector <- numeric(length(ml$obj))
    vector[ml$x_offset + da$internal_row] <- decisions
    vector[ml$w_offset + p$data$pu$internal_id] <- as.integer(vapply(
      p$data$pu$id, function(id) any(decisions[da$pu == id] > 0), logical(1)
    ))
    lhs <- as.numeric(ml$A %*% vector)
    actual[k] <- all(ifelse(ml$sense == "<=", lhs <= ml$rhs,
                           ifelse(ml$sense == ">=", lhs >= ml$rhs, lhs == ml$rhs)))
  }
  expect_true(any(expected))
  expect_identical(actual, expected)
  row <- p$data$model_registry$cons$action_cardinality$total$rows[["10"]]
  expect_identical(row$name, "total_pu_10")
})

test_that("concurrent ecological effects and targets compile with final aggregation", {
  p <- make_cardinality_problem() |>
    add_effects(data.frame(action = c("a", "b", "c", "d"), feature = 1L, effect = 10)) |>
    add_objective_max_benefit()
  expect_s3_class(compile_model(add_constraint_action_cardinality(p, 1, "max")), "Problem")
  expect_no_error(compile_model(add_constraint_action_cardinality(p, 2, "max", pu = 10L)))
  expect_no_error(compile_model(p |> add_constraint_action_cardinality(2, "equal", pu = 10L) |>
                              add_constraint_targets_absolute(150)))
  # Overlapping maxima that still allow only one action remain compatible.
  safe <- p |> add_constraint_action_cardinality(2, "max") |>
    add_constraint_action_cardinality(1, "max", pu = c(10L, 20L)) |>
    add_constraint_action_cardinality(1, "max", pu = 30L)
  expect_s3_class(compile_model(safe), "Problem")
  one_available <- make_cardinality_problem(include_pairs = data.frame(
    pu = c(10L, 20L, 30L), action = "a"
  )) |>
    add_effects(data.frame(action = "a", feature = 1L, effect = 10)) |>
    add_constraint_action_cardinality(4, "max") |>
    add_objective_max_benefit()
  expect_s3_class(compile_model(one_available), "Problem")
  zero_subset <- p |> add_constraint_action_cardinality(4, "max") |>
    add_constraint_action_cardinality(0, "max", actions = c("b", "c", "d"))
  expect_s3_class(compile_model(zero_subset), "Problem")
})

test_that("cardinality is visible in problem printing", {
  p <- make_cardinality_problem() |> add_constraint_action_cardinality(2, "max")
  text <- paste(capture.output(print(p), type = "message"), collapse = "\n")
  expect_match(text, "action cardinality:.*1 registered rules")
})

test_that("large valid maxima do not overflow the auxiliary upper-bound calculation", {
  p <- cardinality_profit_problem() |>
    add_constraint_action_cardinality(4, "max") |>
    add_constraint_action_cardinality(.Machine$integer.max, "max", actions = "a")
  expect_no_warning(compiled <- compile_model(p))
  expect_equal(unname(multiscape:::.pa_action_cardinality_upper_bounds(compiled)), rep(4, 3))
})

test_that("all MO methods enforce cardinality and return consistent objective values", {
  skip_if_no_cbc()
  p <- make_cardinality_problem(pu = 10L, pu_cost = 0) |>
    add_constraint_action_cardinality(2, "max") |>
    add_constraint_action_cardinality(1, "min", actions = c("a", "b")) |>
    add_profit(c(a = 8, b = 4, c = 2, d = 1)) |>
    add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
    add_objective_max_profit(alias = "profit") |>
    set_solver_cbc(verbose = FALSE, gap_limit = 0)
  methods <- list(
    weighted = function(x) set_method_weighted_sum(x, aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_profit = 1)),
      normalize_weights = FALSE),
    epsilon = function(x) set_method_epsilon_constraint(x, primary = "cost", aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(eps_profit = 10))),
    augmecon = function(x) set_method_augmecon(x, primary = "cost", aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(eps_profit = 10)))
  )
  for (method in names(methods)) {
    solved <- solve(methods[[method]](p))
    values <- get_objectives(solved)
    expect_equal(nrow(values), 1L, info = method)
    expect_identical(cardinality_selected_counts(solved, 10L), 2L, info = method)
    expect_equal(values$cost, 2, info = method)
    expect_equal(values$profit, 12, info = method)
    expect_match(get_runs(solved)$status, "optimal", info = method)
  }
})
