make_action_sets_problem <- function(actions = NULL, include_pairs = NULL) {
  if (is.null(actions)) {
    actions <- data.frame(id = c("restore", "control", "fence"))
  }
  create_problem(
    pu = data.frame(id = c(10L, 20L, 30L), cost = 0),
    features = data.frame(id = 1L, name = "woodland"),
    dist_features = data.frame(
      pu = c(10L, 20L, 30L), feature = 1L, amount = 100
    )
  ) |>
    add_actions(actions, include_pairs = include_pairs, cost = 1)
}

action_sets_memberships <- function() {
  data.frame(
    set = c("restore_control", "restore_control", "restore_fence", "restore_fence"),
    action = c("restore", "control", "restore", "fence")
  )
}

test_that("lists and long tables register equivalent overlapping sets", {
  p <- make_action_sets_problem()
  listed <- add_action_sets(p, list(
    restore_control = c("restore", "control"),
    restore_fence = c("restore", "fence")
  ))
  tabulated <- add_action_sets(p, action_sets_memberships()[c(4, 2, 3, 1), ])
  expect_s3_class(listed, "Problem")
  expect_identical(get_action_sets(listed), get_action_sets(tabulated))
  expect_named(get_action_sets(listed), c("set", "action"))
  expect_equal(sum(get_action_sets(listed)$action == "restore"), 2L)
  expect_equal(nrow(get_action_sets(listed)), 4L)
})

test_that("input factors, numeric action ids, and tibbles normalize consistently", {
  p <- make_action_sets_problem()
  tab <- action_sets_memberships()
  tab$set <- factor(tab$set)
  tab$action <- factor(tab$action)
  expect_identical(
    get_action_sets(add_action_sets(p, tab)),
    get_action_sets(add_action_sets(p, action_sets_memberships()))
  )
  tab$unused <- seq_len(nrow(tab))
  expect_identical(
    get_action_sets(add_action_sets(p, dplyr::as_tibble(tab))),
    get_action_sets(add_action_sets(p, action_sets_memberships()))
  )
  numeric_p <- make_action_sets_problem(data.frame(id = c(10L, 20L, 30L)))
  from_list <- add_action_sets(numeric_p, list(pair = c(10L, 20L)))
  from_table <- add_action_sets(numeric_p, data.frame(set = "pair", action = c(20, 10)))
  expect_identical(get_action_sets(from_list), get_action_sets(from_table))
  expect_identical(get_action_sets(from_list)$action, c("10", "20"))
  from_factors <- add_action_sets(p, list(pair = factor(c("restore", "control"))))
  expect_identical(get_action_sets(from_factors)$action, c("control", "restore"))
  unicode <- add_action_sets(p, stats::setNames(
    list(c("restore", "control")), "restauraci\u00f3n_control"
  ))
  expect_identical(unique(get_action_sets(unicode)$set), "restauraci\u00f3n_control")
})

test_that("larger and identically composed sets retain their own identifiers", {
  p <- make_action_sets_problem() |>
    add_action_sets(list(
      all_three = c("restore", "control", "fence"),
      pair_a = c("restore", "control"),
      pair_b = c("control", "restore")
    ))
  expect_equal(as.integer(table(get_action_sets(p)$set)), c(3L, 2L, 2L))
})

test_that("registration adds new sets across calls without changing existing definitions", {
  p <- make_action_sets_problem()
  first <- add_action_sets(p, list(restore_control = c("restore", "control")))
  second <- add_action_sets(first, data.frame(
    set = "control_fence", action = c("control", "fence")
  ))
  expect_equal(nrow(get_action_sets(first)), 2L)
  expect_equal(nrow(get_action_sets(second)), 4L)
  expect_identical(get_action_sets(p), multiscape:::.pa_empty_action_sets())
  retained <- get_action_sets(second)[get_action_sets(second)$set == "restore_control", ]
  rownames(retained) <- NULL
  expect_identical(retained, get_action_sets(first))
})

test_that("registered sets cannot be extended or redefined implicitly", {
  p <- make_action_sets_problem() |>
    add_action_sets(list(pair = c("restore", "control")))
  original <- get_action_sets(p)
  expect_error(add_action_sets(p, list(pair = c("restore", "control"))), "already registered")
  expect_error(add_action_sets(p, list(pair = c("restore", "fence"))), "already registered")
  expect_error(add_action_sets(p, list(pair = c("restore", "control", "fence"))), "already registered")
  expect_identical(get_action_sets(p), original)
})

test_that("registration and inspection do not mutate inputs or problem data", {
  p <- make_action_sets_problem()
  original <- serialize(p$data, NULL)
  tab <- action_sets_memberships()
  input <- tab
  out <- add_action_sets(p, tab)
  expect_identical(serialize(p$data, NULL), original)
  expect_identical(tab, input)
  # Construction invalidates model caches but leaves the planning specification intact.
  for (key in c("pu", "features", "actions", "dist_features", "dist_actions",
                "dist_effects", "constraints", "objectives", "index")) {
    expect_identical(out$data[[key]], p$data[[key]], info = key)
  }
  definitions <- get_action_sets(out)
  definitions$action[1] <- "changed"
  expect_false("changed" %in% get_action_sets(out)$action)
})

test_that("get_action_sets returns a typed empty table before registration", {
  p <- make_action_sets_problem()
  definitions <- get_action_sets(p)
  expect_identical(definitions, data.frame(set = character(), action = character()))
  p$data$actions <- NULL
  expect_identical(get_action_sets(p), definitions)
})

test_that("the public functions validate the problem and action prerequisite", {
  for (bad in list(NULL, list(data = list()), data.frame(id = 1))) {
    expect_error(add_action_sets(bad, list(pair = c("restore", "control"))), "Problem object")
    expect_error(get_action_sets(bad), "Problem object")
  }
  p <- make_action_sets_problem()
  p$data$actions <- NULL
  expect_error(add_action_sets(p, list(pair = c("restore", "control"))), "Run add_actions")
  p$data$actions <- data.frame(id = character())
  expect_error(add_action_sets(p, list(pair = c("restore", "control"))), "Run add_actions")
})

test_that("empty and unsupported set inputs are rejected", {
  p <- make_action_sets_problem()
  expect_error(add_action_sets(p, list()), "non-empty")
  expect_error(add_action_sets(p, data.frame(set = character(), action = character())), "non-empty")
  for (bad in list(NULL, "restore", 1, TRUE, matrix("restore"), new.env())) {
    expect_error(add_action_sets(p, bad), "named list or a data.frame")
  }
  expect_error(add_action_sets(p, list(c("restore", "control"))), "named list")
  expect_error(add_action_sets(p, data.frame(set = "pair")), "columns 'set' and 'action'")
  expect_error(add_action_sets(p, data.frame(action = "restore")), "columns 'set' and 'action'")
  dup_columns <- data.frame(set = "pair", action = c("restore", "control"), extra = 1)
  names(dup_columns)[3] <- "action"
  expect_error(add_action_sets(p, dup_columns), "duplicated column names")
})

test_that("set identifiers must be present, nonempty, and unique in lists", {
  p <- make_action_sets_problem()
  for (bad_name in c(NA_character_, "", " ", "\t")) {
    bad_list <- stats::setNames(list(c("restore", "control")), bad_name)
    expect_error(add_action_sets(p, bad_list), "identifiers")
    bad_table <- data.frame(set = rep(bad_name, 2), action = c("restore", "control"))
    expect_error(add_action_sets(p, bad_table), "identifiers")
  }
  repeated <- stats::setNames(
    list(c("restore", "control"), c("control", "fence")), c("pair", "pair")
  )
  expect_error(add_action_sets(p, repeated), "must be unique")
  expect_error(add_action_sets(p, data.frame(set = 1, action = c("restore", "control"))), "strings")
})

test_that("members are nonempty atomic action ids rather than nested values", {
  p <- make_action_sets_problem()
  for (bad_members in list(c("restore", NA), c("restore", ""), c("restore", " "),
                           c(10, Inf), c(10, NA_real_), c(TRUE, FALSE),
                           matrix(c("restore", "control")),
                           list("restore", "control"))) {
    expect_error(add_action_sets(p, list(pair = bad_members)), "identifiers")
  }
  expect_error(add_action_sets(p, list(pair = "restore")), "at least two")
  expect_error(add_action_sets(p, list(pair = character())), "at least two")
  expect_error(add_action_sets(p, data.frame(set = "pair", action = "restore")), "at least two")
  expect_error(add_action_sets(p, list(pair = c("restore", "restore"))), "duplicated")
  expect_error(add_action_sets(p, data.frame(set = "pair", action = c("restore", "restore"))), "duplicated")
})

test_that("unknown actions, display-name members, and nested sets are rejected", {
  p <- make_action_sets_problem(data.frame(
    id = c("restore", "control", "fence"), name = c("Restoration", "Control", "Fence")
  ))
  expect_error(add_action_sets(p, list(pair = c("restore", "missing"))), "Unknown action.*missing")
  expect_error(add_action_sets(p, list(pair = c("Restoration", "control"))), "Unknown action.*Restoration")
  p <- add_action_sets(p, list(pair = c("restore", "control")))
  expect_error(add_action_sets(p, list(nested = c("pair", "fence"))), "nested sets")
})

test_that("set identifiers cannot collide with ids, display names, or legacy labels", {
  p <- make_action_sets_problem(data.frame(
    id = c("restore", "control", "fence"),
    name = c("Restoration", "Control", "Fence"),
    action_set = c("habitat", "threat", "habitat")
  ))
  for (identifier in c("restore", "Restoration", "habitat")) {
    expect_error(
      add_action_sets(p, stats::setNames(list(c("restore", "control")), identifier)),
      "identifiers conflict"
    )
  }
  out <- add_action_sets(p, list(pair = c("restore", "control")))
  expect_identical(out$data$actions$action_set, p$data$actions$action_set)
  expect_identical(
    multiscape:::.pa_resolve_action_subset(out, "habitat"),
    multiscape:::.pa_resolve_action_subset(p, "habitat")
  )
})

test_that("registration is independent of spatial feasibility and action selection", {
  p <- make_action_sets_problem(include_pairs = data.frame(
    pu = c(10L, 20L, 30L), action = c("restore", "control", "fence")
  ))
  out <- add_action_sets(p, list(pair = c("restore", "control")))
  expect_equal(nrow(get_action_sets(out)), 2L)
  expect_identical(out$data$dist_actions, p$data$dist_actions)
  expect_identical(out$data$constraints, p$data$constraints)
  expect_identical(out$data$dist_actions$status, rep(0L, 3))
  expect_error(add_objective_max_benefit(out, actions = "pair"), "did not match")
  expect_error(
    add_effects(out, data.frame(action = "pair", feature = "woodland", effect = 30)),
    "[Uu]nknown|not found|did not match"
  )
})

test_that("action catalogs cannot be redefined after set registration", {
  p <- make_action_sets_problem() |>
    add_action_sets(list(pair = c("restore", "control")))
  original <- serialize(p$data, NULL)
  expect_error(add_actions(p, data.frame(id = c("fence", "control", "restore")), cost = 2), "already defined")
  expect_error(add_actions(p, data.frame(id = c("restore", "control", "fence", "monitor"))), "already defined")
  expect_error(add_actions(p, data.frame(id = c("restore", "fence"))), "already defined")
  expect_error(add_actions(p, data.frame(id = c("restore", "control", "pair"))), "already defined")
  expect_error(add_actions(p, data.frame(
    id = c("restore", "control"), name = c("pair", "Control")
  )), "already defined")
  expect_error(add_actions(p, data.frame(
    id = c("restore", "control"), action_set = "pair"
  )), "already defined")
  expect_identical(serialize(p$data, NULL), original)
})

test_that("failed multi-set registration is atomic", {
  p <- make_action_sets_problem() |>
    add_action_sets(list(pair = c("restore", "control")))
  original <- serialize(p$data, NULL)
  expect_error(add_action_sets(p, list(
    valid = c("control", "fence"), invalid = c("restore", "missing")
  )), "Unknown action")
  expect_identical(serialize(p$data, NULL), original)
})

test_that("sets are visible in problem summaries without inflating action counts", {
  p <- make_action_sets_problem() |>
    add_action_sets(action_sets_memberships())
  text <- paste(capture.output(print(p), type = "message"), collapse = "\n")
  expect_match(text, "action sets:.*2 defined.*4 memberships")
  expect_match(text, "actions:.*3 total")
  expect_match(text, "feasible action pairs:.*9 feasible rows")
})

test_that("registering sets invalidates only the copied model cache and preserves compilation", {
  p <- make_action_sets_problem() |>
    add_effects(data.frame(
      action = c("restore", "control", "fence"), feature = "woodland", effect = c(20, 10, 0)
    )) |>
    add_constraint_budget(budget = 2, sense = "max", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "benefit") |>
    compile_model()
  original_model <- p$data$model_list
  original_pointer <- p$data$model_ptr
  out <- add_action_sets(p, list(pair = c("restore", "control")))
  expect_null(out$data$model_ptr)
  expect_null(out$data$model_list)
  expect_true(out$data$meta$model_dirty)
  expect_identical(p$data$model_ptr, original_pointer)
  expect_identical(p$data$model_list, original_model)
  expect_false(p$data$meta$model_dirty)
  out <- compile_model(out)
  expect_equal(out$data$model_list, original_model)
  expect_equal(nrow(out$data$dist_actions_model), nrow(p$data$dist_actions_model))
})

test_that("action-set definitions do not change optimized decisions or values", {
  skip_if_no_cbc()
  effects <- expand.grid(
    pu = c(10L, 20L, 30L), action = c("restore", "control", "fence"),
    stringsAsFactors = FALSE
  )
  effects$feature <- "woodland"
  effects$effect <- c(5, 20, 40, 4, 10, 15, 0, 0, 0)
  p <- make_action_sets_problem() |>
    add_effects(effects) |>
    add_constraint_budget(budget = 2, sense = "max", include_pu_cost = FALSE) |>
    add_objective_max_benefit(alias = "benefit") |>
    set_solver_cbc(gap_limit = 0, verbose = FALSE)
  without_sets <- solve(p)
  with_sets <- solve(add_action_sets(p, list(pair = c("restore", "control"))))
  expect_equal(get_objectives(with_sets), get_objectives(without_sets))
  expect_equal(get_actions(with_sets), get_actions(without_sets))
})

test_that("set definitions preserve compiled models for all existing MO methods", {
  p <- make_action_sets_problem() |>
    add_effects(data.frame(
      action = c("restore", "control", "fence"), feature = "woodland", effect = c(20, 10, 0)
    )) |>
    add_constraint_budget(budget = 2, sense = "max", include_pu_cost = FALSE) |>
    add_constraint_locked_planning_units(locked_in = 10L) |>
    add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
    add_objective_max_benefit(alias = "benefit")
  methods <- list(
    weighted = function(x) set_method_weighted_sum(x,
      aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(weight_cost = 1, weight_benefit = 1))
    ),
    epsilon = function(x) set_method_epsilon_constraint(x,
      primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 20))
    ),
    augmecon = function(x) set_method_augmecon(x,
      primary = "cost", aliases = c("cost", "benefit"),
      runs = set_runs_manual(data.frame(eps_benefit = 20))
    )
  )
  for (method in names(methods)) {
    base <- methods[[method]](p)
    registered <- add_action_sets(base, list(pair = c("restore", "control")))
    expect_identical(registered$data$method, base$data$method, info = method)
    expect_identical(registered$data$objectives, base$data$objectives, info = method)
    before <- compile_model(base)
    after <- compile_model(registered)
    expect_equal(after$data$model_list, before$data$model_list, info = method)
  }
})
