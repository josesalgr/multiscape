make_relation_problem <- function(pu = c(10L, 20L), actions = NULL, include_pairs = NULL) {
  if (is.null(actions)) actions <- data.frame(id = c("d", "b", "a", "c"))
  create_problem(
    pu = data.frame(id = pu, cost = 0),
    features = data.frame(id = 1L, name = "woodland"),
    dist_features = data.frame(pu = pu, feature = 1L, amount = 100)
  ) |>
    add_actions(actions, include_pairs = include_pairs, cost = 1)
}

relation_profit_problem <- function(pu = 10L, profit = c(a = 10, b = 4, c = 3, d = 2),
                                    include_pairs = NULL, capacity = 4L) {
  p <- make_relation_problem(pu = pu, include_pairs = include_pairs)
  if (!is.null(capacity)) p <- add_constraint_action_cardinality(p, capacity, "max")
  p |> add_profit(profit) |> add_objective_max_profit(alias = "profit") |>
    set_solver_cbc(gap_limit = 0, verbose = FALSE)
}

relation_selected <- function(solution, pu = 10L) {
  da <- get_actions(solution)
  sort(as.character(da$action[da$pu == pu & da$selected > 0.5]), method = "radix")
}

relation_feasible_vectors <- function(p) {
  compiled <- compile_model(p)
  da <- compiled$data$dist_actions_model
  ml <- compiled$data$model_list
  allocations <- as.matrix(expand.grid(rep(list(0:1), nrow(da))))
  feasible <- logical(nrow(allocations))
  for (k in seq_len(nrow(allocations))) {
    vector <- numeric(length(ml$obj))
    vector[ml$x_offset + da$internal_row] <- allocations[k, ]
    vector[ml$w_offset + compiled$data$pu$internal_id] <- as.integer(vapply(
      compiled$data$pu$id,
      function(id) any(allocations[k, da$pu == id] > 0), logical(1)
    ))
    lhs <- as.numeric(ml$A %*% vector)
    feasible[k] <- all(ifelse(ml$sense == "<=", lhs <= ml$rhs + 1e-9,
                              ifelse(ml$sense == ">=", lhs >= ml$rhs - 1e-9,
                                     abs(lhs - ml$rhs) <= 1e-9)))
  }
  colnames(allocations) <- paste(da$pu, da$action, sep = ":")
  list(feasible = feasible, allocations = allocations, compiled = compiled)
}

test_that("all relation families store canonical external IDs and independent rules", {
  p <- make_relation_problem()
  out <- p |>
    add_constraint_action_requires(c("b", "a", "b"), c("d", "c"),
                                   pu = c(20, 10, 20), name = "dependency") |>
    add_constraint_action_excludes(c("d", "c"), pu = 10, name = "exclusive") |>
    add_constraint_action_together(c("c", "b"), pu = 20, name = "joint")
  specs <- out$data$constraints$action_relations
  expect_identical(specs$type, c("requires", "excludes", "together"))
  expect_identical(specs$sense, c("all", NA_character_, NA_character_))
  expect_identical(specs$actions[[1]], c("a", "b"))
  expect_identical(specs$requires[[1]], c("c", "d"))
  expect_null(specs$requires[[2]])
  expect_identical(specs$pu[[1]], c(10L, 20L))
  expect_identical(specs$name, c("dependency", "exclusive", "joint"))
  expect_null(p$data$constraints$action_relations)
  expect_identical(out$data$dist_actions, p$data$dist_actions)
})

test_that("relations require a valid problem, registered actions, and explicit groups", {
  p <- make_relation_problem()
  expect_error(add_constraint_action_requires(NULL, "a", "b"), "Problem")
  empty <- create_problem(data.frame(id = 1, cost = 0), data.frame(id = 1),
                          data.frame(pu = 1, feature = 1, amount = 100))
  expect_error(add_constraint_action_together(empty, c("a", "b")), "add_actions")
  expect_error(add_constraint_action_requires(p), "actions.*provided")
  expect_error(add_constraint_action_requires(p, "a"), "requires.*provided")
  expect_error(add_constraint_action_excludes(p), "actions.*provided")
  expect_error(add_constraint_action_together(p), "actions.*provided")
  expect_error(add_constraint_action_requires(p, "a", "b", sense = "other"), "arg")
})

test_that("identifier and name validation is strict for every relation family", {
  p <- make_relation_problem()
  setters <- list(
    function(ids) add_constraint_action_requires(p, ids, "d"),
    function(ids) add_constraint_action_excludes(p, ids),
    function(ids) add_constraint_action_together(p, ids)
  )
  for (bad in list(NULL, character(), logical(), TRUE, NA_character_, " ",
                   c("a", NA), Inf, matrix("a"), list("a"), as.Date("2020-01-01"))) {
    for (setter in setters) expect_error(setter(bad), "identifiers")
    expect_error(add_constraint_action_requires(p, "a", bad), "identifiers")
  }
  for (bad in list("", " ", NA_character_, c("x", "y"), 1)) {
    expect_error(add_constraint_action_requires(p, "a", "b", name = bad), "name")
    expect_error(add_constraint_action_excludes(p, c("a", "b"), name = bad), "name")
    expect_error(add_constraint_action_together(p, c("a", "b"), name = bad), "name")
  }
  for (bad in list(character(), NA_integer_, TRUE, Inf, c(10, 99))) {
    expect_error(add_constraint_action_requires(p, "a", "b", pu = bad), "PU|identifiers")
  }
  expect_error(add_constraint_action_requires(p, c("a", "unknown"), "b"), "Unknown action")
  expect_error(add_constraint_action_requires(p, "a", c("b", "unknown")), "Unknown action")
  expect_error(add_constraint_action_excludes(p, c("a", "unknown")), "Unknown action")
  expect_error(add_constraint_action_together(p, c("a", "unknown")), "Unknown action")
})

test_that("factor and numeric IDs are accepted but display names and registered sets are not", {
  p <- make_relation_problem(actions = data.frame(id = 1:4, name = c("A", "B", "C", "D")))
  out <- add_constraint_action_requires(p, factor(c(2, 1)), 3, pu = factor("20"))
  expect_identical(out$data$constraints$action_relations$actions[[1]], c("1", "2"))
  expect_identical(out$data$constraints$action_relations$requires[[1]], "3")
  expect_identical(out$data$constraints$action_relations$pu[[1]], 20L)
  expect_error(add_constraint_action_together(p, c("A", "B")), "Unknown action")
  sets <- add_action_sets(p, list(pair = c("1", "2")))
  expect_error(add_constraint_action_requires(sets, "pair", "3"), "individual members")
  expect_error(add_constraint_action_requires(sets, "3", "pair"), "individual members")
  expect_error(add_constraint_action_together(sets, "pair"), "individual members")
})

test_that("legacy action classifications resolve to the same atomic group identity", {
  p <- make_relation_problem(actions = data.frame(
    id = c("a", "b", "c", "d"), action_set = c("habitat", "habitat", "other", "other")
  ))
  out <- add_constraint_action_requires(p, "habitat", "other", sense = "any")
  expect_identical(out$data$constraints$action_relations$actions[[1]], c("a", "b"))
  expect_identical(out$data$constraints$action_relations$requires[[1]], c("c", "d"))
  expect_error(add_constraint_action_requires(out, c("b", "a"), c("d", "c"), sense = "any"),
               "already exists")
  expect_error(add_constraint_action_requires(p, "a", "habitat"), "disjoint")
})

test_that("groups reject degenerate and self-dependent specifications", {
  p <- make_relation_problem()
  expect_error(add_constraint_action_excludes(p, "a"), "at least two")
  expect_error(add_constraint_action_together(p, c("a", "a")), "at least two")
  expect_error(add_constraint_action_requires(p, "a", "a"), "disjoint")
  expect_error(add_constraint_action_requires(p, c("a", "b"), c("b", "c"), sense = "any"), "disjoint")
  out <- add_constraint_action_requires(p, "a", "b", sense = "any")
  expect_identical(out$data$constraints$action_relations$sense, "all")
  expect_error(add_constraint_action_requires(out, "a", "b", sense = "all"), "already exists")
})

test_that("duplicate identities and shared names error without modifying the problem", {
  p <- make_relation_problem() |>
    add_constraint_action_requires("a", c("c", "b"), name = "rule") |>
    add_constraint_action_excludes(c("b", "c"), pu = 10) |>
    add_constraint_action_together(c("a", "b"), pu = 20)
  original <- serialize(p$data, NULL)
  expect_error(add_constraint_action_requires(p, "a", c("b", "c"), name = "different"), "already exists")
  expect_error(add_constraint_action_excludes(p, c("c", "b"), pu = c(10, 10)), "already exists")
  expect_error(add_constraint_action_together(p, c("b", "a"), pu = "20"), "already exists")
  expect_error(add_constraint_action_together(p, c("c", "d"), name = "rule"), "name already registered")
  expect_no_error(add_constraint_action_requires(p, "a", c("b", "c"), sense = "any"))
  expect_no_error(add_constraint_action_requires(p, "a", "b", pu = 10))
  expect_identical(serialize(p$data, NULL), original)
})

test_that("automatic names skip explicit collisions across all relation types", {
  p <- make_relation_problem() |>
    add_constraint_action_excludes(c("a", "b"), name = "action_requires_2") |>
    add_constraint_action_requires("a", "b") |>
    add_constraint_action_together(c("b", "c"))
  expect_identical(p$data$constraints$action_relations$name,
                   c("action_requires_2", "action_requires_3", "action_together_3"))
})

test_that("adding a relation deep-copies data and invalidates only its returned model", {
  p <- relation_profit_problem() |> compile_model()
  pointer <- p$data$model_ptr
  original <- serialize(p$data[setdiff(names(p$data), "model_ptr")], NULL)
  out <- add_constraint_action_excludes(p, c("a", "b"))
  expect_null(out$data$model_ptr)
  expect_null(out$data$model_list)
  expect_true(out$data$meta$model_dirty)
  expect_identical(p$data$model_ptr, pointer)
  expect_identical(serialize(p$data[setdiff(names(p$data), "model_ptr")], NULL), original)
  expect_error(add_constraint_action_requires(p, "a", "a"), "disjoint")
  expect_identical(p$data$model_ptr, pointer)
  expect_identical(serialize(p$data[setdiff(names(p$data), "model_ptr")], NULL), original)
})

test_that("compiled relations match exhaustive independent truth tables", {
  base <- make_relation_problem(pu = 10L) |>
    add_constraint_action_cardinality(4, "max") |> add_profit(1) |> add_objective_max_profit()
  cases <- list(
    all = list(p = add_constraint_action_requires(base, "a", c("b", "c")),
               rule = function(m) !m[, "10:a"] | (m[, "10:b"] & m[, "10:c"])),
    any = list(p = add_constraint_action_requires(base, "a", c("b", "c"), "any"),
               rule = function(m) !m[, "10:a"] | (m[, "10:b"] | m[, "10:c"])),
    multi = list(p = add_constraint_action_requires(base, c("a", "d"), c("b", "c"), "any"),
                 rule = function(m) (!m[, "10:a"] | (m[, "10:b"] | m[, "10:c"])) &
                   (!m[, "10:d"] | (m[, "10:b"] | m[, "10:c"]))),
    excludes = list(p = add_constraint_action_excludes(base, c("a", "b", "c")),
                    rule = function(m) rowSums(m[, c("10:a", "10:b", "10:c")]) <= 1),
    together = list(p = add_constraint_action_together(base, c("a", "b", "c")),
                    rule = function(m) m[, "10:a"] == m[, "10:b"] & m[, "10:b"] == m[, "10:c"])
  )
  for (name in names(cases)) {
    result <- relation_feasible_vectors(cases[[name]]$p)
    expect_identical(result$feasible, as.logical(cases[[name]]$rule(result$allocations)), info = name)
    expect_true(result$feasible[1], info = name) # No relation forces implementation.
    expect_true(any(!result$feasible), info = name)
  }
})

test_that("mixed spatially scoped rules match all 256 allocations", {
  p <- make_relation_problem(pu = c(20L, 10L)) |>
    add_constraint_action_cardinality(4, "max") |>
    add_constraint_action_requires("a", c("b", "c"), "any", pu = 10) |>
    add_constraint_action_together(c("c", "d"), pu = 10) |>
    add_constraint_action_excludes(c("b", "d"), pu = 20) |>
    add_profit(1) |> add_objective_max_profit()
  result <- relation_feasible_vectors(p)
  m <- result$allocations
  expected <- (!m[, "10:a"] | (m[, "10:b"] | m[, "10:c"])) &
    (m[, "10:c"] == m[, "10:d"]) & (m[, "20:b"] + m[, "20:d"] <= 1)
  expect_identical(result$feasible, as.logical(expected))
  expect_true(any(result$feasible))
  expect_true(any(!result$feasible))
  compiled <- result$compiled
  expect_identical(compile_model(compiled)$data$model_list, compiled$data$model_list)
})

test_that("all and any dependencies remain exact with negative-profit companions", {
  skip_if_no_cbc()
  p <- relation_profit_problem(profit = c(a = 10, b = -1, c = -2, d = -100), capacity = 3)
  all <- solve(add_constraint_action_requires(p, "a", c("b", "c")))
  any <- solve(add_constraint_action_requires(p, "a", c("b", "c"), "any"))
  expect_identical(relation_selected(all), c("a", "b", "c"))
  expect_identical(relation_selected(any), c("a", "b"))
  expect_equal(get_objectives(all)$profit, 7)
  expect_equal(get_objectives(any)$profit, 9)
})

test_that("exclusions are pairwise within the group and allow outside actions", {
  skip_if_no_cbc()
  p <- relation_profit_problem(capacity = 4)
  s <- solve(add_constraint_action_excludes(p, c("a", "b", "c")))
  expect_identical(relation_selected(s), c("a", "d"))
  expect_equal(get_objectives(s)$profit, 12)
})

test_that("together permits zero or the full group and accounts for member profits", {
  skip_if_no_cbc()
  p <- relation_profit_problem(profit = c(a = 8, b = -1, c = 6, d = -100), capacity = 2)
  joint <- solve(add_constraint_action_together(p, c("a", "b")))
  expect_identical(relation_selected(joint), c("a", "b"))
  expect_equal(get_objectives(joint)$profit, 7)
  p <- relation_profit_problem(profit = c(a = 8, b = -3, c = 6, d = -100), capacity = 2)
  no_group <- solve(add_constraint_action_together(p, c("a", "b")))
  expect_identical(relation_selected(no_group), "c")
})

test_that("relations do not lift the implicit one-action maximum", {
  skip_if_no_cbc()
  p <- relation_profit_problem(capacity = NULL)
  relations <- list(
    function(x) add_constraint_action_requires(x, "a", "b"),
    function(x) add_constraint_action_together(x, c("a", "b"))
  )
  for (k in seq_along(relations)) {
    s <- solve(relations[[k]](p))
    expect_identical(relation_selected(s), c("b", "c")[k])
    expect_equal(get_objectives(s)$profit, c(4, 3)[k])
  }
})

test_that("missing required pairs are zero and cannot be supplied from another unit", {
  skip_if_no_cbc()
  p <- relation_profit_problem(pu = c(10L, 20L), include_pairs = data.frame(
    pu = c(10L, 10L, 20L), action = c("a", "c", "b")
  ))
  s <- solve(add_constraint_action_requires(p, "a", "b", pu = 10))
  expect_identical(relation_selected(s, 10), "c")
  expect_identical(relation_selected(s, 20), "b")
  expect_equal(get_objectives(s)$profit, 7)
  any <- solve(add_constraint_action_requires(p, "a", c("b", "c"), "any", pu = 10))
  expect_identical(relation_selected(any, 10), c("a", "c"))
})

test_that("missing together members prohibit the remaining members", {
  skip_if_no_cbc()
  p <- relation_profit_problem(include_pairs = data.frame(pu = 10, action = c("a", "c", "d")))
  s <- solve(add_constraint_action_together(p, c("a", "b")))
  expect_identical(relation_selected(s), c("c", "d"))
  p <- relation_profit_problem(include_pairs = data.frame(pu = 10, action = c("a", "b", "d")))
  s <- solve(add_constraint_action_together(p, c("a", "b", "c")))
  expect_identical(relation_selected(s), "d")
})

test_that("locked-out and non-finite-cost companions keep their zero semantics", {
  skip_if_no_cbc()
  for (unavailable in c("lock", "cost")) {
    p <- relation_profit_problem()
    if (unavailable == "lock") {
      p <- add_constraint_locked_actions(p, locked_out = list(b = 10))
    } else {
      p$data$dist_actions$cost[p$data$dist_actions$action == "b"] <- Inf
    }
    p <- add_constraint_action_requires(p, "a", "b")
    s <- solve(p)
    expect_identical(relation_selected(s), c("c", "d"), info = unavailable)
    expect_equal(get_objectives(s)$profit, 5, info = unavailable)
  }
})

test_that("fully absent groups and sources add no empty linear rows", {
  p <- relation_profit_problem(pu = c(10L, 20L), include_pairs = data.frame(pu = 20, action = "d")) |>
    add_constraint_action_requires("a", "b", pu = 10, name = "absent_source") |>
    add_constraint_action_excludes(c("a", "b"), name = "absent_group") |>
    add_constraint_action_together(c("a", "b"), name = "absent_together") |>
    compile_model()
  registry <- p$data$model_registry$cons$action_relations
  expect_true(all(vapply(registry, function(r) r$n_constraints_added == 0L, logical(1))))
})

test_that("cycles and conflicting valid relations are resolved by the solver", {
  skip_if_no_cbc()
  p <- relation_profit_problem(capacity = 2) |>
    add_constraint_action_requires("a", "b") |>
    add_constraint_action_requires("b", "a")
  s <- solve(p)
  expect_identical(relation_selected(s), c("a", "b"))
  contradictory <- p |> add_constraint_action_excludes(c("a", "b")) |>
    add_constraint_locked_actions(locked_in = list(a = 10))
  expect_error(solve(contradictory), "status: infeasible")
  missing <- relation_profit_problem(include_pairs = data.frame(pu = 10, action = c("a", "c"))) |>
    add_constraint_action_requires("a", "b") |>
    add_constraint_locked_actions(locked_in = list(a = 10))
  expect_error(solve(missing), "status: infeasible")
})

test_that("relations and budgets constrain action costs while PU costs count once", {
  skip_if_no_cbc()
  p <- make_relation_problem(pu = 10L)
  p$data$pu$cost <- 5
  p <- p |> add_constraint_action_cardinality(2, "max") |>
    add_constraint_action_requires("a", "b") |>
    add_profit(c(a = 10, b = 4, c = 3, d = 2)) |>
    add_constraint_budget(6, "max") |> add_objective_max_profit() |> set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_identical(relation_selected(s), "b")
  # A separate base with budget 7 makes the required two-action pair feasible.
  base <- make_relation_problem(pu = 10L)
  base$data$pu$cost <- 5
  base <- base |> add_constraint_action_cardinality(2, "max") |>
    add_constraint_action_requires("a", "b") |>
    add_profit(c(a = 10, b = 4, c = 3, d = 2)) |>
    add_constraint_budget(7, "max") |> add_objective_max_profit() |> set_solver_cbc(gap_limit = 0)
  expect_identical(relation_selected(solve(base)), c("a", "b"))
})

test_that("all MO methods enforce every relation and preserve objective interpretation", {
  skip_if_no_cbc()
  p <- make_relation_problem(pu = 10L) |>
    add_constraint_action_cardinality(2, "max") |>
    add_constraint_action_cardinality(1, "min") |>
    add_constraint_action_requires("a", "b") |>
    add_constraint_action_excludes(c("a", "c")) |>
    add_constraint_action_together(c("c", "d")) |>
    add_profit(c(a = 8, b = 4, c = 6, d = 1)) |>
    add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
    add_objective_max_profit(alias = "profit") |> set_solver_cbc(gap_limit = 0)
  methods <- list(
    weighted = function(x) set_method_weighted_sum(x, aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_profit = 1)), normalize_weights = FALSE),
    epsilon = function(x) set_method_epsilon_constraint(x, primary = "cost", aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(eps_profit = 10))),
    augmecon = function(x) set_method_augmecon(x, primary = "cost", aliases = c("cost", "profit"),
      runs = set_runs_manual(data.frame(eps_profit = 10)))
  )
  for (name in names(methods)) {
    specification <- methods[[name]](p)
    solution <- solve(specification)
    expect_identical(relation_selected(solution), c("a", "b"), info = name)
    expect_equal(get_objectives(solution)$cost, 2, info = name)
    expect_equal(get_objectives(solution)$profit, 12, info = name)
    expect_match(get_runs(solution)$status, "optimal", info = name)
    expect_identical(specification$data$objectives, p$data$objectives, info = name)
  }
})

test_that("registration order and overlapping scopes do not overwrite rules", {
  p <- relation_profit_problem(pu = c(10L, 20L), capacity = 2)
  left <- p |> add_constraint_action_requires("a", "b", name = "dependency") |>
    add_constraint_action_excludes(c("a", "c"), pu = 10, name = "exclusive")
  right <- p |> add_constraint_action_excludes(c("a", "c"), pu = 10, name = "exclusive") |>
    add_constraint_action_requires("a", "b", name = "dependency")
  l <- relation_feasible_vectors(left)
  r <- relation_feasible_vectors(right)
  expect_identical(l$feasible, r$feasible)
  expect_equal(nrow(left$data$constraints$action_relations), 2)
})

test_that("relation registry records actual rows and source scopes", {
  p <- relation_profit_problem(pu = c(10L, 20L)) |>
    add_constraint_action_requires("a", c("b", "c"), pu = 10, name = "dependency") |>
    add_constraint_action_together(c("a", "d"), pu = 20, name = "joint") |>
    compile_model()
  registry <- p$data$model_registry$cons$action_relations
  expect_named(registry, c("dependency", "joint"))
  expect_equal(registry$dependency$n_constraints_added, 2)
  expect_equal(registry$joint$n_constraints_added, 1)
  expect_named(registry$dependency$rows, "10")
  expect_equal(length(registry$dependency$rows[["10"]]), 2)
  expect_identical(registry$dependency$rows[["10"]][[1]]$name, "dependency_pu_10_1")
})

test_that("model compilation validates damaged relation definitions", {
  p <- relation_profit_problem() |> add_constraint_action_requires("a", "b")
  original <- p$data$constraints$action_relations
  mutations <- list(
    function(d) { d$pu <- NULL; d },
    function(d) { d$type <- "other"; d },
    function(d) { d$sense <- "other"; d },
    function(d) { d$actions <- list("unknown"); d },
    function(d) { d$requires <- list("unknown"); d },
    function(d) { d$requires <- list("a"); d },
    function(d) { d$pu <- list(99L); d },
    function(d) { d$name <- ""; d }
  )
  for (mutation in mutations) {
    bad <- multiscape:::.pa_clone_data(p)
    bad$data$constraints$action_relations <- mutation(original)
    expect_error(compile_model(bad), "malformed|invalid|unknown|disjoint|non-empty")
  }
})

test_that("set registration does not imply a relation but members can be used explicitly", {
  p <- relation_profit_problem() |> add_action_sets(list(pair = c("a", "b")))
  expect_null(p$data$constraints$action_relations)
  members <- get_action_sets(p)$action
  out <- add_constraint_action_together(p, members)
  expect_identical(out$data$constraints$action_relations$actions[[1]], c("a", "b"))
  expect_identical(get_action_sets(out), get_action_sets(p))
})

test_that("existing ecological effects and targets retain their one-action workflow", {
  skip_if_no_cbc()
  p <- make_relation_problem(pu = 10L) |>
    add_effects(data.frame(action = c("a", "b", "c", "d"), feature = 1L,
                          effect = c(20, 10, 5, 0))) |>
    add_constraint_targets_absolute(50) |>
    add_constraint_action_requires("a", "b") |>
    add_objective_max_benefit(alias = "benefit") |> set_solver_cbc(gap_limit = 0)
  s <- solve(p)
  expect_identical(relation_selected(s), "b")
  expect_equal(get_objectives(s)$benefit, 10)
  concurrent <- add_constraint_action_cardinality(p, 2, "max")
  expect_error(compile_model(concurrent), "Concurrent actions with ecological effects")
})

test_that("relations are shown only when registered in problem printing", {
  p <- make_relation_problem()
  before <- paste(capture.output(print(p), type = "message"), collapse = "\n")
  expect_false(grepl("action relations", before))
  after <- p |> add_constraint_action_requires("a", "b") |>
    add_constraint_action_excludes(c("c", "d"))
  text <- paste(capture.output(print(after), type = "message"), collapse = "\n")
  expect_match(text, "action relations:.*2 registered rules")
})
