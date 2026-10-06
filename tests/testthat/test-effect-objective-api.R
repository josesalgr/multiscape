test_that("effect objectives use the same signed coefficients with opposite senses", {
  p <- create_problem(data.frame(id=1, cost=0), data.frame(id=1),
    data.frame(pu=1, feature=1, amount=100)) |>
    add_actions(data.frame(id=c("a", "b")), cost=1) |>
    add_effects(data.frame(action=c("a", "b"), feature=1, effect=c(30,-20))) |>
    add_constraint_action_cardinality(1, "equal")
  hi <- compile_model(add_objective_max_effect(p))
  lo <- compile_model(add_objective_min_effect(p))
  expect_equal(hi$data$model_list$obj, lo$data$model_list$obj)
  expect_equal(hi$data$model_list$modelsense, "max")
  expect_equal(lo$data$model_list$modelsense, "min")
  expect_equal(hi$data$model_list$obj[hi$data$model_list$x_offset + hi$data$dist_actions_model$internal_row], c(30,-20))
  ir <- .pamo_objective_to_ir(p, list(objective_id="min_effect", objective_args=list()))
  expect_equal(ir$sense, "min")
})

test_that("legacy wrappers warn and preserve their distinct criteria", {
  p <- create_problem(data.frame(id=1, cost=0), data.frame(id=1),
    data.frame(pu=1, feature=1, amount=100)) |>
    add_actions(data.frame(id="a"), cost=1) |>
    add_effects(data.frame(action="a", feature=1, effect=-20))
  withr::local_options(lifecycle_verbosity="warning")
  expect_warning(old <- add_objective_max_benefit(p), class="lifecycle_warning_deprecated")
  expect_equal(old$data$model_args, add_objective_max_effect(p)$data$model_args)
  expect_warning(loss <- add_objective_min_loss(p), class="lifecycle_warning_deprecated")
  expect_equal(loss$data$model_args$objective_id, "min_loss")
})

effect_api_fixture <- function(joint = FALSE) {
  p <- create_problem(data.frame(id=1, cost=0), data.frame(id=1),
    data.frame(pu=1, feature=1, amount=100)) |>
    add_actions(data.frame(id=c("a", "b")), cost=1) |>
    add_constraint_action_cardinality(if (joint) 2 else 1, "equal")
  e <- data.frame(action=c("a", "b"), feature=1, effect=c(30,-20))
  if (joint) {
    p <- add_action_sets(p, list(ab=c("a","b")))
    e <- rbind(e, data.frame(action="ab", feature=1, effect=-7))
  }
  add_effects(p, e)
}

test_that("minimum signed effects optimize decreases in single and MO methods", {
  skip_if_no_cbc()
  p <- effect_api_fixture() |> add_objective_min_effect(alias="effect") |>
    add_objective_min_cost(alias="cost") |> set_solver_cbc(gap_limit=0)
  methods <- list(
    effect_api_fixture() |> add_objective_min_effect(alias="effect") |> set_solver_cbc(gap_limit=0),
    set_method_weighted_sum(p, aliases=c("effect","cost"),
      normalize_weights=FALSE, objective_scaling=FALSE,
      runs=set_runs_manual(data.frame(weight_effect=1,weight_cost=0))),
    set_method_epsilon_constraint(p, primary="effect", aliases=c("effect","cost"),
      runs=set_runs_grid(n=2)),
    set_method_augmecon(p, primary="effect", aliases=c("effect","cost"),
      runs=set_runs_grid(n=2)))
  for (q in methods) {
    s <- solve(q)
    expect_true(all(abs(get_objectives(s)$effect + 20) < 1e-7))
  }
})

test_that("joint total effects retain their sign and scoped objectives exclude interactions", {
  p <- effect_api_fixture(TRUE)
  hi <- compile_model(add_objective_max_effect(p))
  lo <- compile_model(add_objective_min_effect(p))
  expect_equal(hi$data$model_list$obj, lo$data$model_list$obj)
  if (requireNamespace("rcbc", quietly=TRUE)) {
    for (fun in list(add_objective_max_effect,add_objective_min_effect)) {
      s <- solve(set_solver_cbc(fun(p,alias="effect"),gap_limit=0))
      expect_equal(get_objectives(s)$effect,-7)
      s <- solve(set_solver_cbc(fun(p,actions="a",alias="effect"),gap_limit=0))
      expect_equal(get_objectives(s)$effect,30)
    }
  }
})
