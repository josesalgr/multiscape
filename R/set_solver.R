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
#' \strong{Incremental update semantics}
#'
#' This function updates solver settings incrementally.
#'
#' If an argument is supplied as \code{NULL}, the previously stored value is
#' kept unchanged. Therefore, repeated calls can be used to modify only selected
#' components of the solver configuration.
#'
#' For example, a user may first configure the solver backend and time limit,
#' and later update only the optimality gap or only a backend-specific
#' parameter.
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
#' The argument \code{cores} specifies the number of CPU cores to use. If the
#' requested number exceeds the number of detected cores, it is capped to the
#' detected maximum with a warning.
#'
#' \strong{Verbose output and log files}
#'
#' The arguments \code{verbose}, \code{write_log}, and \code{log_file}
#' control how solver logging is handled. These options are stored and later
#' interpreted by the solving layer for the selected backend.
#'
#' \strong{Solver-specific parameters}
#'
#' Additional backend-specific parameters can be passed in two ways:
#' \itemize{
#'   \item through the named list \code{solver_params},
#'   \item through additional named arguments in \code{...}.
#' }
#'
#' These two sources are merged, and the result is then merged with any
#' previously stored \code{solver_params}. Existing parameters are therefore
#' preserved unless explicitly overwritten.
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
#' @param solution_limit Optional logical flag controlling backend-specific
#'   early stopping after feasible solution discovery. If \code{NULL}, the
#'   previously stored value is kept unchanged.
#' @param cores Optional positive integer giving the number of CPU cores to use.
#'   If \code{NULL}, the previously stored value is kept unchanged.
#' @param verbose Optional logical flag indicating whether the solver should
#'   print log output. If \code{NULL}, the previously stored value is kept
#'   unchanged.
#' @param log_file Optional character string giving the name of the
#'   solver log file. If \code{NULL}, the previously stored value is kept
#'   unchanged.
#' @param write_log Optional logical flag indicating whether solver output
#'   should be written to a file. If \code{NULL}, the previously stored value is
#'   kept unchanged.
#' @param solver_params Named list of solver-specific parameters. These are
#'   merged with previously stored backend-specific parameters rather than
#'   replacing them completely.
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
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
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
#' # Update only selected settings
#' x2 <- set_solver(
#'   x1,
#'   gap_limit = 0.05,
#'   solver_params = list(randomSeed = 123)
#' )
#'
#' x2$data$solve_args
#'
#' @export
set_solver <- function(
    x,
    solver = c("auto", "gurobi", "cplex", "cbc", "symphony"),
    gap_limit = NULL,
    time_limit = NULL,
    solution_limit = NULL,
    cores = NULL,
    verbose = FALSE,
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

  if (exists(".pa_clone_data", mode = "function")) {
    x <- .pa_clone_data(x)
  }

  solver <- match.arg(solver)

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

    gap_limit <- round(
      as.numeric(gap_limit),
      digits = 3
    )
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

  # It is clearer to reject contradictory log settings immediately.
  if (
    identical(write_log, TRUE) &&
    is.null(log_file)
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

  # Begin with the existing configuration so that NULL arguments preserve
  # previously stored values.
  out <- x$data$solve_args

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

  out$solver_params <- utils::modifyList(
    out$solver_params %||% list(),
    solver_params
  )

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
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
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
                              solution_limit = NULL, cores = NULL, verbose = FALSE,
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

#' @title Configure CPLEX solver settings
#'
#' @description
#' Convenience wrapper around \code{\link{set_solver}} that stores
#' \code{solver = "cplex"} in the problem object.
#'
#' This function does not solve the model. It only updates the stored solver
#' configuration.
#'
#' @inheritParams set_solver
#'
#' @return An updated \code{Problem} object with CPLEX solver settings stored in
#'   \code{x$data$solve_args}.
#'
#' @seealso
#' \code{\link{set_solver}},
#' \code{\link{solve}}
#'
#' @examples
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_cbc(
#'   x,
#'   gap_limit = 0.01,
#'   time_limit = 300,
#'   cores = 2
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_cbc <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                           solution_limit = NULL, cores = NULL, verbose = FALSE,
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
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
#'   cost = "cost"
#' )
#'
#' x <- set_solver_cplex(
#'   x,
#'   gap_limit = 0.001,
#'   time_limit = 1200,
#'   cores = 2
#' )
#'
#' x$data$solve_args
#'
#' @export
set_solver_cplex <- function(x, ..., solver_params = list(), gap_limit = NULL, time_limit = NULL,
                             solution_limit = NULL, cores = NULL, verbose = FALSE,
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
#' pu_tbl <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' feat_tbl <- data.frame(
#'   id = 1:2,
#'   name = c("feature_1", "feature_2")
#' )
#'
#' dist_feat_tbl <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
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
                                solution_limit = NULL, cores = NULL, verbose = FALSE,
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
