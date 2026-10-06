#' @title Configure solver settings
#'
#' @description
#' Store solver configuration inside a \code{Problem} object so that
#' \code{\link{solve}} can later run using the stored backend and runtime
#' options.
#'
#' This function does not build or solve the optimization model. It only updates
#' the solver configuration stored in \code{x$data$solve_args}.
#'
#' @details
#' \strong{Purpose}
#'
#' The \code{multiscape} workflow separates problem specification from solver
#' configuration. Problem data, actions, effects, targets, objectives, and
#' methods are stored in the \code{Problem} object, and solver settings are
#' stored separately in \code{x$data$solve_args}.
#'
#' This function allows solver options to be configured once and reused later
#' through \code{\link{solve}(x)} without repeating the same arguments each time.
#'
#' \strong{Stored fields}
#'
#' The solver configuration is stored in \code{x$data$solve_args}. Typical
#' entries include:
#' \itemize{
#'   \item \code{solver},
#'   \item \code{gap_limit},
#'   \item \code{time_limit},
#'   \item \code{solution_limit},
#'   \item \code{cores},
#'   \item \code{verbose},
#'   \item \code{write_log},
#'   \item \code{log_file},
#'   \item \code{solver_params}.
#' }
#'
#' \strong{Single configuration}
#'
#' Solver settings can be configured only once per problem, including through
#' backend wrappers. A second call raises an error, even if the arguments are
#' identical. Supply all settings together. Arguments left as \code{NULL} use
#' solver defaults. Reading defaults does not count as explicit configuration.
#' To compare configurations, derive each alternative from the same problem
#' before the first solver call.
#'
#' \strong{Gap limit}
#'
#' The argument \code{gap_limit} is interpreted as a relative optimality gap for
#' mixed-integer optimization. It must lie in \eqn{[0,1]}.
#'
#' If the solver stops with incumbent value \eqn{z^{\mathrm{inc}}} and best
#' bound \eqn{z^{\mathrm{bd}}}, then the exact stopping rule depends on the
#' solver backend, but conceptually \code{gap_limit} controls the maximum
#' accepted relative difference between the incumbent and the bound.
#'
#' \strong{Time limit}
#'
#' The argument \code{time_limit} is interpreted as a maximum wall-clock time in
#' seconds allowed for the solver.
#'
#' \strong{Solution limit}
#'
#' The argument \code{solution_limit} is stored as a logical flag. Its exact
#' meaning depends on the backend-specific solving layer, but conceptually it
#' requests early termination after finding a feasible solution according to the
#' behaviour supported by the chosen solver.
#'
#' \strong{Cores}
#'
#' The argument \code{cores} specifies the maximum number of solver threads.
#' It is supported by Gurobi. Rcplex, rcbc, and Rsymphony do not reliably
#' expose thread control through the interfaces used here; multiscape therefore
#' warns and ignores \code{cores} for CPLEX, CBC, and SYMPHONY. If
#' the requested number exceeds the number of detected logical processors, it
#' is capped to the detected maximum with a warning.
#'
#' \strong{Verbose output and log files}
#'
#' The arguments \code{verbose}, \code{write_log}, and \code{log_file}
#' control how solver logging is handled. These options are stored and later
#' interpreted by the solving layer for the selected backend. Solver log files
#' are currently available only with Gurobi. A parameter that is not available
#' through the selected R solver interface is reported with a warning and is
#' not stored as if it had been applied.
#'
#' \strong{Backend capabilities}
#'
#' Common parameters are translated only when the selected backend supports
#' them:
#' \itemize{
#'   \item Gurobi supports \code{cores}, \code{solution_limit}, and
#'   \code{write_log}.
#'   \item CBC supports \code{solution_limit}. Thread control and CBC log
#'   files are not exposed reliably through the current rcbc integration.
#'   \item CPLEX through Rcplex does not expose \code{cores},
#'   \code{solution_limit}, or solver log files.
#'   \item SYMPHONY through Rsymphony supports \code{solution_limit}, but does
#'   not expose \code{cores} or solver log files.
#' }
#'
#' \strong{Solver-specific parameters}
#'
#' Additional backend-specific parameters can be passed in two ways:
#' \itemize{
#'   \item through the named list \code{solver_params},
#'   \item through additional named arguments in \code{...}.
#' }
#'
#' These two sources are merged within the single configuration call.
#'
#' This is particularly useful for backend-specific controls such as node
#' selection, emphasis parameters, tolerances, or heuristics.
#'
#' \strong{Supported backends}
#'
#' The \code{solver} argument selects the backend to be used later by
#' \code{\link{solve}}. Supported values are:
#' \itemize{
#'   \item \code{"auto"}: let the solving layer choose an available backend,
#'   \item \code{"gurobi"},
#'   \item \code{"cplex"},
#'   \item \code{"cbc"},
#'   \item \code{"symphony"}.
#' }
#'
#' This function only stores the requested backend. Availability of the backend
#' is checked later when solving.
#'
#' @param x A \code{Problem} object.
#' @param solver Character string indicating the solver backend to use. Must be
#'   one of \code{"auto"}, \code{"gurobi"}, \code{"cplex"},
#'   \code{"cbc"}, or \code{"symphony"}.
#' @param gap_limit Optional numeric value in \eqn{[0,1]} giving the relative
#'   optimality gap for mixed-integer optimization. If \code{NULL}, the
#'   previously stored value is kept unchanged.
#' @param time_limit Optional non-negative numeric value giving the maximum
#'   solving time in seconds. If \code{NULL}, the previously stored value is
#'   kept unchanged.
#' @param solution_limit Optional logical flag requesting early termination
#'   after a feasible solution is found. Supported by Gurobi, CBC, and
#'   SYMPHONY, but not by CPLEX through Rcplex. If \code{NULL}, the previously
#'   stored value is kept unchanged.
#' @param cores Optional positive integer giving the maximum number of solver
#'   threads. Currently supported by Gurobi. If \code{NULL}, the previously
#'   stored value is kept unchanged.
#' @param verbose Optional logical flag indicating whether the solver should
#'   print log output. If \code{NULL}, the previously stored value is kept
#'   unchanged.
#' @param log_file Optional character string giving the complete path or file
#'   name of the solver log. Currently supported by Gurobi. If \code{NULL}, the
#'   previously stored value is kept unchanged.
#' @param write_log Optional logical flag indicating whether solver output
#'   should be written to a file. Currently supported by Gurobi. If
#'   \code{NULL}, the previously stored value is kept unchanged.
#' @param solver_params Named list of solver-specific parameters. These are
#'   merged with previously stored parameters. Rcplex parameters are validated
#'   against its supported control names; Rsymphony does not currently receive
#'   arbitrary solver-specific parameters.
#' @param ... Additional named solver-specific parameters. These are merged into
#'   \code{solver_params}. For example, \code{MIPFocus = 1} for Gurobi.
#'
#' @return An updated \code{Problem} object with modified solver settings stored
#'   in \code{x$data$solve_args}.
#'
#' @seealso
#' \code{\link{solve}},
#' \code{\link{set_solver_gurobi}},
#' \code{\link{set_solver_cplex}},
#' \code{\link{set_solver_cbc}},
#' \code{\link{set_solver_symphony}}
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' x <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' )
#'
#' x1 <- set_solver(
#'   x,
#'   solver = "cbc",
#'   gap_limit = 0.01,
#'   time_limit = 300,
#'   cores = 2,
#'   verbose = TRUE
#' )
#'
#' x1$data$solve_args
#'
#' # Define an alternative from the common unconfigured problem
#' x2 <- set_solver(
#'   x,
#'   gap_limit = 0.05,
#'   solver_params = list(randomSeed = 123)
#' )
#'
#' x2$data$solve_args
#'
#' @export
set_solver <- function(
    x,
    solver = NULL,
    gap_limit = NULL,
    time_limit = NULL,
    solution_limit = NULL,
    cores = NULL,
    verbose = NULL,
    log_file = NULL,
    write_log = NULL,
    solver_params = list(),
    ...
) {
  if (!inherits(x, "Problem")) {
    stop(
      "`x` must be a Problem object.",
      call. = FALSE
    )
  }

  .pa_assert_unconfigured(x, "solve_args", "Solver configuration", "set_solver()")
  if (exists(".pa_clone_data", mode = "function")) {
    x <- .pa_clone_data(x)
  }

  solver_choices <- c("auto", "gurobi", "cplex", "cbc", "symphony")
  stored_solver <- x$data$solve_args$solver %||% NULL

  if (is.null(solver)) {
    solver <- stored_solver %||% "auto"
  } else {
    solver <- match.arg(solver, solver_choices)
  }

  # -----------------------------------------------------------------------
  # Solver-specific parameters
  # -----------------------------------------------------------------------

  if (is.null(solver_params)) {
    solver_params <- list()
  }

  if (!is.list(solver_params)) {
    stop(
      "`solver_params` must be a list.",
      call. = FALSE
    )
  }

  dots <- list(...)

  if (length(dots) > 0L) {
    solver_params <- utils::modifyList(
      solver_params,
      dots
    )
  }

  # -----------------------------------------------------------------------
  # Validate common solver arguments
  # -----------------------------------------------------------------------

  if (!is.null(gap_limit)) {
    if (
      !is.numeric(gap_limit) ||
      length(gap_limit) != 1L ||
      is.na(gap_limit) ||
      !is.finite(gap_limit) ||
      gap_limit < 0 ||
      gap_limit > 1
    ) {
      stop(
        "`gap_limit` must be a single finite number between 0 and 1.",
        call. = FALSE
      )
    }

    gap_limit <- as.numeric(gap_limit)
  }

  if (!is.null(time_limit)) {
    if (
      !is.numeric(time_limit) ||
      length(time_limit) != 1L ||
      is.na(time_limit) ||
      !is.finite(time_limit) ||
      time_limit < 0
    ) {
      stop(
        "`time_limit` must be a single non-negative finite number.",
        call. = FALSE
      )
    }

    time_limit <- round(
      as.numeric(time_limit),
      digits = 3
    )
  }

  if (!is.null(solution_limit)) {
    if (
      !is.logical(solution_limit) ||
      length(solution_limit) != 1L ||
      is.na(solution_limit)
    ) {
      stop(
        "`solution_limit` must be TRUE or FALSE.",
        call. = FALSE
      )
    }

    solution_limit <- isTRUE(solution_limit)
  }

  if (!is.null(cores)) {
    if (
      !is.numeric(cores) ||
      length(cores) != 1L ||
      is.na(cores) ||
      !is.finite(cores) ||
      cores < 1 ||
      cores != floor(cores)
    ) {
      stop(
        "`cores` must be a single positive integer.",
        call. = FALSE
      )
    }

    cores <- as.integer(cores)

    max_cores <- parallel::detectCores(
      logical = TRUE
    )

    if (
      length(max_cores) == 1L &&
      !is.na(max_cores) &&
      is.finite(max_cores) &&
      max_cores >= 1L &&
      cores > max_cores
    ) {
      warning(
        paste0(
          "`cores` is larger than the number of detected logical cores; ",
          "using ",
          max_cores,
          " cores instead."
        ),
        call. = FALSE,
        immediate. = TRUE
      )

      cores <- as.integer(max_cores)
    }
  }

  if (!is.null(verbose)) {
    if (
      !is.logical(verbose) ||
      length(verbose) != 1L ||
      is.na(verbose)
    ) {
      stop(
        "`verbose` must be TRUE or FALSE.",
        call. = FALSE
      )
    }

    verbose <- isTRUE(verbose)
  }

  if (!is.null(write_log)) {
    if (
      !is.logical(write_log) ||
      length(write_log) != 1L ||
      is.na(write_log)
    ) {
      stop(
        "`write_log` must be TRUE or FALSE.",
        call. = FALSE
      )
    }

    write_log <- isTRUE(write_log)
  }

  if (!is.null(log_file)) {
    if (
      !is.character(log_file) ||
      length(log_file) != 1L ||
      is.na(log_file) ||
      !nzchar(log_file)
    ) {
      stop(
        "`log_file` must be a single non-empty character string.",
        call. = FALSE
      )
    }

    log_file <- as.character(log_file)
  }

  # A file name is required only by a backend that can actually write a log.
  # Unsupported logging requests are handled by the capability check below.
  if (
    identical(write_log, TRUE) &&
    is.null(log_file) &&
    identical(solver, "gurobi") &&
    is.null(x$data$solve_args$name_output_file)
  ) {
    stop(
      "`log_file` must be supplied when `write_log = TRUE`.",
      call. = FALSE
    )
  }

  if (
    identical(write_log, FALSE) &&
    !is.null(log_file)
  ) {
    warning(
      "`log_file` was supplied but `write_log = FALSE`; the file name will be stored but logging is disabled.",
      call. = FALSE,
      immediate. = TRUE
    )
  }

  # -----------------------------------------------------------------------
  # Update stored solver configuration
  # -----------------------------------------------------------------------

  if (
    is.null(x$data$solve_args) ||
    !is.list(x$data$solve_args)
  ) {
    x$data$solve_args <- list()
  }

  # First and only explicit configuration; NULL values leave solver defaults.
  out <- list()

  out$solver <- solver

  if (!is.null(gap_limit)) {
    out$gap_limit <- gap_limit
  }

  if (!is.null(time_limit)) {
    out$time_limit <- time_limit
  }

  if (!is.null(solution_limit)) {
    out$solution_limit <- solution_limit
  }

  if (!is.null(cores)) {
    out$cores <- cores
  }

  if (!is.null(verbose)) {
    out$verbose <- verbose
  }

  if (!is.null(write_log)) {
    out$output_file <- write_log
  }

  if (!is.null(log_file)) {
    out$name_output_file <- log_file
  }

  out$solver_params <- solver_params

  # Report settings that cannot be transmitted by the selected R interface.
  unavailable <- character(0)

  if (identical(solver, "cplex")) {
    if (!is.null(out$cores)) unavailable <- c(unavailable, "cores")
    if (isTRUE(out$solution_limit)) {
      unavailable <- c(unavailable, "solution_limit")
    }
    if (isTRUE(out$output_file) ||
        (!is.null(out$name_output_file) && !identical(out$output_file, FALSE))) {
      unavailable <- c(unavailable, "write_log/log_file")
    }

    rcplex_parameters <- c(
      "trace", "method", "preind", "aggind", "itlim", "epagap", "epgap",
      "tilim", "disjcuts", "mipemphasis", "cliques", "nodesel", "probe",
      "varsel", "flowcovers", "solnpoolagap", "solnpoolgap",
      "solnpoolintensity", "maxcalls", "round"
    )
    unknown <- setdiff(names(out$solver_params), rcplex_parameters)
    if (length(unknown) > 0L) {
      unavailable <- c(unavailable, paste0("solver_params$", unknown))
      out$solver_params[unknown] <- NULL
    }

    out$cores <- NULL
    out$solution_limit <- FALSE
    out$output_file <- FALSE
    out$name_output_file <- NULL
  }

  if (identical(solver, "symphony")) {
    if (!is.null(out$cores)) unavailable <- c(unavailable, "cores")
    if (isTRUE(out$output_file) ||
        (!is.null(out$name_output_file) && !identical(out$output_file, FALSE))) {
      unavailable <- c(unavailable, "write_log/log_file")
    }
    if (length(out$solver_params) > 0L) {
      unavailable <- c(unavailable, "solver_params")
    }

    out$cores <- NULL
    out$output_file <- FALSE
    out$name_output_file <- NULL
    out$solver_params <- list()
  }

  if (identical(solver, "cbc")) {
    if (!is.null(out$cores)) {
      unavailable <- c(
        unavailable,
        "cores (thread control is not available through rcbc)"
      )
      out$cores <- NULL
    }
    if (isTRUE(out$output_file) ||
        (!is.null(out$name_output_file) && !identical(out$output_file, FALSE))) {
      unavailable <- c(unavailable, "write_log/log_file")
      out$output_file <- FALSE
      out$name_output_file <- NULL
    }
  }

  unavailable <- unique(unavailable)
  if (length(unavailable) > 0L) {
    warning(
      paste0(
        "Parameter(s) not available for solver '", solver,
        "' through its current R interface: ",
        paste(unavailable, collapse = ", "),
        ". The unsupported setting(s) will be ignored."
      ),
      call. = FALSE,
      immediate. = TRUE
    )
  }

  x$data$solve_args <- out

  x
}

#' @title Configure Gurobi solver settings
#'
#' @description
#' Convenience wrapper around \code{\link{set_solver}} that stores
#' \code{solver = "gurobi"} in the problem object.
#'
#' This function does not solve the model. It only updates the stored solver
#' configuration.
#' A solver can be configured only once per problem. Calling this wrapper after
#' any solver setter raises an error. Derive alternatives from the same problem
#' before its first solver configuration.
#'
#' @inheritParams set_solver
#'
#' @return An updated \code{Problem} object with Gurobi solver settings stored
#'   in \code{x$data$solve_args}.
#'
#' @seealso
#' \code{\link{set_solver}},
#' \code{\link{solve}}
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' x <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_gurobi(
#'   x,
#'   gap_limit = 0.01,
#'   time_limit = 600,
#'   cores = 2,
#'   MIPFocus = 1
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_gurobi <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                              solution_limit = NULL, cores = NULL, verbose = NULL,
                              log_file = NULL, write_log = NULL) {
  set_solver(
    x,
    solver = "gurobi",
    gap_limit = gap_limit,
    time_limit = time_limit,
    solution_limit = solution_limit,
    cores = cores,
    verbose = verbose,
    log_file = log_file,
    write_log = write_log,
    solver_params = solver_params,
    ...
  )
}

#' @title Configure CBC solver settings
#'
#' @description
#' Convenience wrapper around \code{\link{set_solver}} that stores
#' \code{solver = "cbc"} in the problem object.
#'
#' This function does not solve the model. It only updates the stored solver
#' configuration.
#' A solver can be configured only once per problem. Calling this wrapper after
#' any solver setter raises an error. Derive alternatives from the same problem
#' before its first solver configuration.
#'
#' @inheritParams set_solver
#'
#' @return An updated \code{Problem} object with CBC solver settings stored in
#'   \code{x$data$solve_args}.
#'
#' @seealso
#' \code{\link{set_solver}},
#' \code{\link{solve}}
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' x <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_cbc(
#'   x,
#'   gap_limit = 0.01,
#'   time_limit = 300,
#'   cores = 2,
#'   solution_limit = FALSE
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_cbc <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                           solution_limit = NULL, cores = NULL, verbose = NULL,
                           log_file = NULL, write_log = NULL) {
  set_solver(
    x,
    solver = "cbc",
    gap_limit = gap_limit,
    time_limit = time_limit,
    solution_limit = solution_limit,
    cores = cores,
    verbose = verbose,
    log_file = log_file,
    write_log = write_log,
    solver_params = solver_params,
    ...
  )
}

#' Configure CPLEX solver settings
#'
#' @description
#' Convenience wrapper around \code{\link{set_solver}} that sets
#' \code{solver = "cplex"}.
#' A solver can be configured only once per problem. Calling this wrapper after
#' any solver setter raises an error. Derive alternatives from the same problem
#' before its first solver configuration.
#'
#' @inheritParams set_solver
#'
#' @return
#' An updated \code{Problem} object with CPLEX solver settings.
#'
#' @seealso
#' \code{\link{set_solver}},
#' \code{\link{solve}}
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' x <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_cplex(
#'   x,
#'   gap_limit = 0.001,
#'   time_limit = 1200
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_cplex <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                             solution_limit = NULL, cores = NULL, verbose = NULL,
                             log_file = NULL, write_log = NULL) {
  set_solver(
    x,
    solver = "cplex",
    gap_limit = gap_limit,
    time_limit = time_limit,
    solution_limit = solution_limit,
    cores = cores,
    verbose = verbose,
    log_file = log_file,
    write_log = write_log,
    solver_params = solver_params,
    ...
  )
}

#' @title Configure SYMPHONY solver settings
#'
#' @description
#' Convenience wrapper around \code{\link{set_solver}} that stores
#' \code{solver = "symphony"} in the problem object.
#'
#' This function does not solve the model. It only updates the stored solver
#' configuration.
#' A solver can be configured only once per problem. Calling this wrapper after
#' any solver setter raises an error. Derive alternatives from the same problem
#' before its first solver configuration.
#'
#' @inheritParams set_solver
#'
#' @return An updated \code{Problem} object with SYMPHONY solver settings stored
#'   in \code{x$data$solve_args}.
#'
#' @seealso
#' \code{\link{set_solver}},
#' \code{\link{solve}}
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#'
#' x <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_symphony(
#'   x,
#'   gap_limit = 0.05,
#'   time_limit = 300
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_symphony <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                                solution_limit = NULL, cores = NULL, verbose = NULL,
                                log_file = NULL, write_log = NULL) {
  set_solver(
    x,
    solver = "symphony",
    gap_limit = gap_limit,
    time_limit = time_limit,
    solution_limit = solution_limit,
    cores = cores,
    verbose = verbose,
    log_file = log_file,
    write_log = write_log,
    solver_params = solver_params,
    ...
  )
}
