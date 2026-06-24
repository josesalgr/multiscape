make_mock_solutionset <- function() {
  p <- make_round4_mo_problem()

  sol1 <- multiscape:::pproto(
    NULL,
    multiscape:::Solution,
    problem = p,
    solution = list(
      objective = 10,
      vector = c(1, 0, 0, 1),
      alias_values = c(cost = 2, benefit = 5)
    ),
    summary = list(),
    diagnostics = list(
      status_code = 0L,
      gap = 0,
      runtime = 0.10,
      solver = "mock",
      cores = 1,
      timelimit = NA
    ),
    method = list(type = "weighted_sum", name = "weighted_sum"),
    meta = list(run_id = 1L)
  )

  sol2 <- multiscape:::pproto(
    NULL,
    multiscape:::Solution,
    problem = p,
    solution = list(
      objective = 20,
      vector = c(0, 1, 1, 0),
      alias_values = c(cost = 4, benefit = 9)
    ),
    summary = list(),
    diagnostics = list(
      status_code = 2L,
      gap = 0.01,
      runtime = 0.20,
      solver = "mock",
      cores = 1,
      timelimit = NA
    ),
    method = list(type = "weighted_sum", name = "weighted_sum"),
    meta = list(run_id = 2L)
  )

  multiscape:::pproto(
    NULL,
    multiscape:::SolutionSet,
    problem = p,
    solution = list(
      design = data.frame(
        run_id = 1:2,
        weight_cost = c(1, 0),
        weight_benefit = c(0, 1)
      ),
      runs = data.frame(
        run_id = 1:2,
        solution_id = 1:2,
        status = c("optimal", "time_limit_feasible"),
        runtime = c(0.10, 0.20),
        gap = c(0, 0.01),
        objective = c(10, 20),
        value_cost = c(2, 4),
        value_benefit = c(5, 9),
        message = c("", ""),
        stringsAsFactors = FALSE
      ),
      solutions = list(`1` = sol1, `2` = sol2)
    ),
    summary = list(
      pu = data.frame(
        solution_id = rep(1:2, each = 4),
        internal_id = rep(1:4, times = 2),
        id = rep(1:4, times = 2),
        selected = c(1, 0, 0, 1, 0, 1, 1, 0)
      ),
      actions = data.frame(
        solution_id = rep(1:2, each = 4),
        internal_pu = rep(1:4, times = 2),
        pu = rep(1:4, times = 2),
        internal_action = rep(c(1, 2), times = 4),
        action = rep(c("conservation", "restoration"), times = 4),
        selected = c(1, 0, 0, 1, 0, 1, 1, 0)
      ),
      features = data.frame(
        solution_id = rep(1:2, each = 2),
        internal_feature = rep(1:2, times = 2),
        feature = rep(1:2, times = 2),
        feature_name = rep(c("sp1", "sp2"), times = 2),
        amount = c(4, 6, 7, 8),
        target = c(1, 1, 1, 1)
      ),
      targets = data.frame(
        solution_id = rep(1:2, each = 2),
        internal_feature = rep(1:2, times = 2),
        feature = rep(1:2, times = 2),
        target = c(1, 1, 1, 1),
        amount = c(4, 6, 7, 8),
        gap = c(3, 5, 6, 7)
      )
    ),
    diagnostics = list(
      n_design = 2L,
      n_runs = 2L,
      n_solutions = 2L
    ),
    method = list(
      name = "weighted_sum",
      type = "weighted_sum",
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(n = 2)
    ),
    meta = list()
  )
}
