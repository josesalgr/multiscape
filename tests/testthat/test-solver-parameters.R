test_that("solver defaults are quiet and do not request a log file", {
  p <- make_round4_problem()
  args <- multiscape:::.pa_get_solve_args(p)

  expect_false(args$verbose)
  expect_false(args$output_file)
  expect_null(args$name_output_file)
  expect_null(args$cores)
})


test_that("set_solver defines all settings together and preserves small gap values", {
  p <- make_round4_problem()

  configured <- multiscape::set_solver_gurobi(
    p,
    gap_limit = 0.0001,
    cores = 2,
    verbose = TRUE,
    time_limit = 30
  )
  expect_error(multiscape::set_solver(configured, time_limit = 30), "already defined")

  expect_identical(configured$data$solve_args$solver, "gurobi")
  expect_equal(configured$data$solve_args$gap_limit, 0.0001)
  expect_identical(configured$data$solve_args$cores, 2L)
  expect_true(configured$data$solve_args$verbose)
  expect_equal(configured$data$solve_args$time_limit, 30)
})


test_that("unsupported common settings are reported with public names", {
  p <- make_round4_problem()

  expect_warning(
    configured <- multiscape::set_solver_cplex(
      p,
      cores = 8,
      solution_limit = TRUE,
      write_log = TRUE,
      log_file = "cplex.log"
    ),
    "cores, solution_limit, write_log/log_file"
  )

  expect_null(configured$data$solve_args$cores)
  expect_false(configured$data$solve_args$solution_limit)
  expect_false(configured$data$solve_args$output_file)
  expect_null(configured$data$solve_args$name_output_file)
})


test_that("unknown Rcplex controls are reported before solving", {
  p <- make_round4_problem()

  expect_warning(
    configured <- multiscape::set_solver_cplex(p, threads = 8),
    "solver_params\\$threads"
  )
  expect_null(configured$data$solve_args$solver_params$threads)
})


test_that("Gurobi log_file is a complete file name", {
  p <- make_round4_problem()
  configured <- multiscape::set_solver_gurobi(
    p,
    write_log = TRUE,
    log_file = "solver.log"
  )

  expect_true(configured$data$solve_args$output_file)
  expect_identical(configured$data$solve_args$name_output_file, "solver.log")
})


test_that("capability guard protects problem objects created by older versions", {
  expect_warning(
    caps <- multiscape:::.pa_apply_solver_capabilities(
      solver = "cplex",
      cores = 8L,
      solution_limit = TRUE,
      output_file = TRUE,
      name_output_file = "old.log",
      solver_params = list(threads = 8),
      warn = TRUE
    ),
    "cores, solution_limit, write_log/log_file, solver_params\\$threads"
  )

  expect_null(caps$cores)
  expect_false(caps$solution_limit)
  expect_false(caps$output_file)
  expect_null(caps$name_output_file)
  expect_length(caps$solver_params, 0L)
})


test_that("CBC solution_limit is available and cores are reported", {
  p <- make_round4_problem()
  expect_warning(
    configured <- multiscape::set_solver_cbc(
      p,
      cores = 2,
      solution_limit = TRUE
    ),
    "thread control is not available through rcbc"
  )

  expect_true(configured$data$solve_args$solution_limit)
  expect_null(configured$data$solve_args$cores)
  expect_warning(
    caps <- multiscape:::.pa_apply_solver_capabilities(
      solver = "cbc",
      cores = 2L,
      solution_limit = TRUE,
      output_file = FALSE,
      name_output_file = NULL,
      solver_params = list(),
      warn = TRUE
    ),
    "thread control is not available through rcbc"
  )
  expect_null(caps$cores)
})


test_that("Gurobi does not create a log unless requested", {
  skip_if_not_installed("gurobi")
  skip_if_not(isTRUE(multiscape:::available_to_solve("gurobi")))

  p <- make_round4_problem() |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_objective_min_cost(alias = "cost")

  old <- setwd(tempdir())
  on.exit(setwd(old), add = TRUE)
  unlink(c("output_log.txt", "exact_name.log"))

  invisible(multiscape::solve(
    multiscape::set_solver_gurobi(p, gap_limit = 0, verbose = FALSE)
  ))
  expect_false(file.exists("output_log.txt"))

  invisible(multiscape::solve(
    multiscape::set_solver_gurobi(
      p,
      gap_limit = 0,
      verbose = FALSE,
      write_log = TRUE,
      log_file = "exact_name.log"
    )
  ))
  expect_true(file.exists("exact_name.log"))
  expect_false(file.exists("exact_name.log_log.txt"))
})
