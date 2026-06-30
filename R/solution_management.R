#' Filter solutions in a solution set
#'
#' @description
#' Return a reduced \code{\link{solutionset-class}} object containing only the
#' runs or solutions that match the requested filters.
#'
#' This function is intended to curate \code{SolutionSet} objects before
#' downstream analysis, plotting, frontier analysis, or post-hoc evaluation.
#' It filters all relevant components of the object consistently, including the
#' run table, design table, stored run-level solutions, and available summary
#' tables.
#'
#' @details
#' A \code{SolutionSet} distinguishes between runs and stored solutions.
#'
#' \itemize{
#'   \item \code{run_id} identifies a run or attempted solve. Runs may be
#'   feasible, optimal, infeasible, failed, or otherwise incomplete.
#'   \item \code{solution_id} identifies a stored solution. Runs that did not
#'   produce a solution have \code{solution_id = NA}.
#' }
#'
#' Therefore, filtering by \code{run_id} and filtering by \code{solution_id}
#' are not always equivalent. For example, an infeasible run may have a
#' \code{run_id} but no \code{solution_id}.
#'
#' The function filters:
#' \itemize{
#'   \item \code{x$solution$runs}, using the selected \code{run_id}s;
#'   \item \code{x$solution$design}, when it contains a \code{run_id} column;
#'   \item \code{x$solution$solutions}, using the selected \code{solution_id}s;
#'   \item all tables in \code{x$summary} that contain a \code{run_id} column.
#' }
#'
#' The function does not renumber \code{run_id} or \code{solution_id}. This
#' preserves traceability to the original run design.
#'
#' If more than one filter is supplied, filters are combined using logical
#' \emph{and}. For example, setting both \code{status = "optimal"} and
#' \code{solution_id = c("s1", "s3")} keeps only optimal runs whose
#' \code{solution_id} is either \code{"s1"} or \code{"s3"}.
#'
#' If \code{nondominated = TRUE}, the function further keeps only non-dominated
#' solutions among the runs retained by the previous filters. Dominance is
#' evaluated in objective space using the objective values stored in the run
#' table. Objective senses are obtained from the objective specifications stored in
#' the original problem.
#'
#' Non-dominated filtering requires the \pkg{moocore} package.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param run_id Optional integer vector of run ids to keep.
#'
#' @param solution_id Optional character vector of solution ids to keep. Runs
#'   without a stored solution are never matched by this filter.
#'
#' @param status Optional character vector of run statuses to keep. Matching is
#'   case-insensitive.
#'
#' @param feasible_only Logical. If \code{TRUE}, keep only runs whose status is
#'   interpreted as having produced a usable solution. The current accepted
#'   statuses are \code{"optimal"}, \code{"feasible"}, \code{"suboptimal"},
#'   \code{"time_limit"}, and \code{"gap_limit"}.
#'
#' @param nondominated Logical. If \code{TRUE}, keep only non-dominated
#'   solutions among the runs retained by the other filters. This uses
#'   \pkg{moocore} internally.
#'
#' @param objectives Optional character vector of objective names to use when
#'   \code{nondominated = TRUE}. If \code{NULL}, all available objective-value
#'   columns are used.
#'
#' @return A filtered \code{\link{solutionset-class}} object.
#'
#' @examples
#' pu <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' features <- data.frame(
#'   id = 1:2,
#'   name = c("sp1", "sp2")
#' )
#'
#' dist_features <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' actions <- data.frame(
#'   id = c("conservation", "restoration")
#' )
#'
#' effects <- data.frame(
#'   action = rep(actions$id, each = 2),
#'   feature = rep(features$id, times = 2),
#'   multiplier = c(
#'     1.0, 1.0,
#'     1.5, 1.5
#'   )
#' )
#'
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     actions = actions,
#'     cost = c(
#'       conservation = 1,
#'       restoration = 2
#'     )
#'   ) |>
#'   add_effects(
#'     effects = effects,
#'     effect_type = "after"
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(
#'       n = 5
#'     ),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'   runs <- get_runs(solutions)
#'
#'   # Keep only runs with a usable solver status
#'   feasible_solutions <- solution_filter(
#'     solutions,
#'     feasible_only = TRUE
#'   )
#'
#'   # Keep selected runs
#'   selected_runs <- solution_filter(
#'     solutions,
#'     run_id = runs$run_id[1:2]
#'   )
#'
#'   # Keep one stored solution
#'   solution_ids <- runs$solution_id[
#'     !is.na(runs$solution_id)
#'   ]
#'
#'   if (length(solution_ids) > 0L) {
#'     selected_solution <- solution_filter(
#'       solutions,
#'       solution_id = solution_ids[1]
#'     )
#'   }
#'
#'   # Keep only optimal runs
#'   if ("optimal" %in% tolower(runs$status)) {
#'     optimal_solutions <- solution_filter(
#'       solutions,
#'       status = "optimal"
#'     )
#'   }
#'
#'   # Keep only non-dominated solutions
#'   if (requireNamespace("moocore", quietly = TRUE)) {
#'     nondominated_solutions <- solution_filter(
#'       solutions,
#'       feasible_only = TRUE,
#'       nondominated = TRUE
#'     )
#'
#'     # Evaluate dominance using selected objectives
#'     nondominated_subset <- solution_filter(
#'       solutions,
#'       feasible_only = TRUE,
#'       nondominated = TRUE,
#'       objectives = c("cost", "benefit")
#'     )
#'   }
#' }
#'
#' @seealso
#' \code{\link{solutionset-class}},
#' \code{\link{solve}},
#' \code{\link{get_runs}},
#' \code{\link{get_objectives}},
#' \code{\link{get_planning_units}},
#' \code{\link{get_actions}}
#'
#' @include internal.R
#' @export
solution_filter <- function(x,
                            run_id = NULL,
                            solution_id = NULL,
                            status = NULL,
                            feasible_only = FALSE,
                            nondominated = FALSE,
                            objectives = NULL) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop("No run table found in x$solution$runs.", call. = FALSE)
  }

  if (!("run_id" %in% names(runs))) {
    stop("Run table must contain a 'run_id' column.", call. = FALSE)
  }

  if (!("solution_id" %in% names(runs))) {
    runs$solution_id <- NA_integer_
  } else {
    runs$solution_id <- suppressWarnings(as.integer(runs$solution_id))
  }

  keep <- rep(TRUE, nrow(runs))

  # --------------------------------------------------------------------------
  # run_id filter
  # --------------------------------------------------------------------------
  if (!is.null(run_id)) {
    run_id <- as.integer(run_id)

    if (anyNA(run_id) || any(!is.finite(run_id)) || any(run_id < 1L)) {
      stop("`run_id` must contain positive integers.", call. = FALSE)
    }

    missing_run <- setdiff(run_id, runs$run_id)

    if (length(missing_run) > 0L) {
      stop(
        "Unknown run_id value(s): ",
        paste(missing_run, collapse = ", "),
        ". Available run ids are: ",
        paste(runs$run_id, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    keep <- keep & runs$run_id %in% run_id
  }

  # --------------------------------------------------------------------------
  # solution_id filter
  # --------------------------------------------------------------------------
  if (!is.null(solution_id)) {
    solution_id <- suppressWarnings(as.integer(solution_id))
    solution_id <- solution_id[
      !is.na(solution_id) &
        is.finite(solution_id) &
        solution_id >= 1L
    ]

    if (length(solution_id) == 0L) {
      stop(
        "`solution_id` must contain at least one positive integer.",
        call. = FALSE
      )
    }

    available_solution_ids <- runs$solution_id
    available_solution_ids <- available_solution_ids[
      !is.na(available_solution_ids) &
        is.finite(available_solution_ids) &
        available_solution_ids >= 1L
    ]

    missing_solution <- setdiff(solution_id, available_solution_ids)

    if (length(missing_solution) > 0L) {
      stop(
        "Unknown solution_id value(s): ",
        paste(missing_solution, collapse = ", "),
        ". Available solution ids are: ",
        if (length(available_solution_ids) > 0L) {
          paste(unique(available_solution_ids), collapse = ", ")
        } else {
          "none"
        },
        ".",
        call. = FALSE
      )
    }

    keep <- keep & runs$solution_id %in% solution_id
  }

  # --------------------------------------------------------------------------
  # status filter
  # --------------------------------------------------------------------------
  if (!is.null(status)) {
    if (!("status" %in% names(runs))) {
      stop("Cannot filter by status because the run table has no 'status' column.", call. = FALSE)
    }

    status <- as.character(status)
    status <- status[!is.na(status) & nzchar(status)]

    if (length(status) == 0L) {
      stop("`status` must contain at least one non-empty value.", call. = FALSE)
    }

    available_status <- unique(as.character(runs$status))
    available_status_lower <- tolower(available_status)

    missing_status <- setdiff(tolower(status), available_status_lower)

    if (length(missing_status) > 0L) {
      stop(
        "Unknown status value(s): ",
        paste(status[tolower(status) %in% missing_status], collapse = ", "),
        ". Available statuses are: ",
        paste(available_status, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    keep <- keep & tolower(as.character(runs$status)) %in% tolower(status)
  }

  # --------------------------------------------------------------------------
  # feasible_only filter
  # --------------------------------------------------------------------------
  if (isTRUE(feasible_only)) {
    if (!("status" %in% names(runs))) {
      stop("Cannot use feasible_only because the run table has no 'status' column.", call. = FALSE)
    }

    feasible_status <- .pa_feasible_status_values()

    keep <- keep & tolower(as.character(runs$status)) %in% feasible_status
  }

  if (!any(keep)) {
    stop("No runs or solutions matched the requested filters.", call. = FALSE)
  }

  keep_run_ids <- runs$run_id[keep]

  out <- .pa_filter_solution_set(x, run_ids = keep_run_ids)

  # --------------------------------------------------------------------------
  # Non-dominated filtering
  # --------------------------------------------------------------------------
  if (isTRUE(nondominated)) {
    if (!requireNamespace("moocore", quietly = TRUE)) {
      stop(
        "Filtering non-dominated solutions requires the 'moocore' package. ",
        "Install it with install.packages('moocore').",
        call. = FALSE
      )
    }

    obj <- .pa_get_objective_matrix(
      out,
      objectives = objectives,
      minimize = TRUE,
      drop_na = TRUE
    )

    nd <- moocore::is_nondominated(obj$matrix)

    if (!is.logical(nd) || length(nd) != nrow(obj$matrix)) {
      stop(
        "moocore::is_nondominated() did not return a valid logical vector.",
        call. = FALSE
      )
    }

    keep_solution_ids <- suppressWarnings(as.integer(obj$solution_id[nd]))
    keep_solution_ids <- keep_solution_ids[
      !is.na(keep_solution_ids) &
        is.finite(keep_solution_ids) &
        keep_solution_ids >= 1L
    ]

    if (length(keep_solution_ids) == 0L) {
      stop(
        "No stored non-dominated solutions were identified.",
        call. = FALSE
      )
    }

    keep_runs <- out$solution$runs %||% NULL

    if (is.null(keep_runs) || !inherits(keep_runs, "data.frame")) {
      stop("No run table found after filtering.", call. = FALSE)
    }

    keep_run_ids <- keep_runs$run_id[
      keep_runs$solution_id %in% keep_solution_ids
    ]

    out <- .pa_filter_solution_set(out, run_ids = keep_run_ids)
  }

  out
}


#' Feasible or usable solve statuses
#'
#' @noRd
.pa_feasible_status_values <- function() {
  c(
    "optimal",
    "feasible",
    "suboptimal",
    "time_limit",
    "gap_limit"
  )
}



#' Filter internal components of a SolutionSet by run ids
#'
#' @noRd
.pa_filter_solution_set <- function(x, run_ids) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object.", call. = FALSE)
  }

  # IMPORTANT:
  # SolutionSet objects are pproto objects and can behave like reference
  # objects. Clone before modifying internal fields so that filtering does not
  # mutate the original object.
  x <- .pa_clone_solution_set(x)

  run_ids <- as.integer(run_ids)
  run_ids <- unique(run_ids[is.finite(run_ids) & !is.na(run_ids)])

  if (length(run_ids) == 0L) {
    stop("`run_ids` must contain at least one valid run id.", call. = FALSE)
  }

  # --------------------------------------------------------------------------
  # runs table
  # --------------------------------------------------------------------------
  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop("No run table found in x$solution$runs.", call. = FALSE)
  }

  if (!("run_id" %in% names(runs))) {
    stop("Run table must contain a 'run_id' column.", call. = FALSE)
  }

  if (!("solution_id" %in% names(runs))) {
    runs$solution_id <- NA_integer_
  } else {
    runs$solution_id <- suppressWarnings(as.integer(runs$solution_id))
  }

  runs <- runs[runs$run_id %in% run_ids, , drop = FALSE]
  rownames(runs) <- NULL

  keep_solution_ids <- runs$solution_id
  keep_solution_ids <- keep_solution_ids[
    !is.na(keep_solution_ids) & keep_solution_ids >= 1L
  ]

  x$solution$runs <- runs

  # --------------------------------------------------------------------------
  # design table
  # --------------------------------------------------------------------------
  design <- x$solution$design %||% NULL

  if (!is.null(design) && inherits(design, "data.frame") &&
      "run_id" %in% names(design)) {
    design <- design[design$run_id %in% run_ids, , drop = FALSE]
    rownames(design) <- NULL
    x$solution$design <- design
  }

  # --------------------------------------------------------------------------
  # stored run-level solutions
  # --------------------------------------------------------------------------
  sols <- x$solution$solutions %||% NULL

  if (!is.null(sols) && is.list(sols)) {
    if (length(keep_solution_ids) == 0L) {
      x$solution$solutions <- list()
    } else {
      sol_names <- names(sols)

      if (!is.null(sol_names) && all(nzchar(sol_names))) {
        sol_names_int <- suppressWarnings(as.integer(sol_names))

        x$solution$solutions <- sols[
          !is.na(sol_names_int) &
            sol_names_int %in% keep_solution_ids
        ]
      } else {
        # Fallback for old objects without named stored solutions.
        keep <- vapply(sols, function(sol_i) {
          sid <- suppressWarnings(as.integer(sol_i$meta$solution_id %||% NA_integer_))[1]

          !is.na(sid) &&
            is.finite(sid) &&
            sid >= 1L &&
            sid %in% keep_solution_ids
        }, logical(1))

        x$solution$solutions <- sols[keep]
      }
    }
  }

  # --------------------------------------------------------------------------
  # summary tables
  # --------------------------------------------------------------------------
  if (!is.null(x$summary) && is.list(x$summary)) {
    for (nm in names(x$summary)) {
      tab <- x$summary[[nm]]

      if (inherits(tab, "data.frame") && "run_id" %in% names(tab)) {
        tab <- tab[tab$run_id %in% run_ids, , drop = FALSE]
        rownames(tab) <- NULL
        x$summary[[nm]] <- tab
      }
    }
  }

  x
}


#' Clone a SolutionSet object before modifying it
#'
#' @description
#' Internal helper used by solution-management functions to avoid mutating the
#' original SolutionSet object. This is important because SolutionSet objects
#' are pproto objects and therefore can behave like reference objects.
#'
#' @noRd
.pa_clone_solution_set <- function(x) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object.", call. = FALSE)
  }

  pproto(
    NULL,
    SolutionSet,
    problem = x$problem %||% NULL,
    solution = .pa_deep_copy_list(x$solution %||% list()),
    summary = .pa_deep_copy_list(x$summary %||% list()),
    diagnostics = .pa_deep_copy_list(x$diagnostics %||% list()),
    method = .pa_deep_copy_list(x$method %||% list()),
    meta = .pa_deep_copy_list(x$meta %||% list()),
    name = x$name %||% "solset"
  )
}


#' Deep-copy lists and data frames used inside SolutionSet objects
#'
#' @noRd
.pa_deep_copy_list <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }

  if (inherits(x, "data.frame")) {
    return(as.data.frame(x, stringsAsFactors = FALSE))
  }

  if (is.list(x)) {
    out <- lapply(x, .pa_deep_copy_list)
    names(out) <- names(x)
    return(out)
  }

  x
}


#' Append solutions from another solution set
#'
#' @description
#' Append the runs and stored solutions from one
#' \code{\link{solutionset-class}} object to another.
#'
#' This function combines two \code{SolutionSet} objects generated from the
#' same planning problem. It is intended for combining results obtained with
#' different \pkg{multiscape} solving workflows, such as weighted-sum,
#' epsilon-constraint, or AUGMECON methods, while keeping a single coherent
#' result object for downstream extraction, plotting, and analysis.
#'
#' @details
#' \code{solution_append()} is a solution-set management function. It does not
#' modify the original input objects. Instead, it returns a new
#' \code{SolutionSet} containing the runs and solutions from both inputs.
#'
#' Both input objects must be generated from the same planning problem. This is
#' checked conservatively before appending. In particular, the two objects must
#' have compatible:
#' \itemize{
#'   \item planning units;
#'   \item features and feature distributions;
#'   \item actions, feasible action pairs, and effects;
#'   \item profit data, when present;
#'   \item targets;
#'   \item locks and constraints;
#'   \item spatial relations;
#'   \item objective specifications.
#' }
#'
#' Differences in method settings, run design, solver settings, solver status,
#' runtime, gaps, and other solve diagnostics are allowed.
#'
#' The appended runs and solutions are assigned new \code{run_id} and
#' \code{solution_id} values to keep identifiers unique in the combined object.
#' Identifiers are not required to match between the two inputs.
#'
#' This function is not intended to combine results from different planning
#' problems, scenarios, target sets, or objective definitions. Such workflows
#' should be handled by a future comparison/binding function rather than by
#' \code{solution_append()}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param y A second \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}} and generated from the same planning problem as
#'   \code{x}.
#'
#' @return A new \code{\link{solutionset-class}} object containing the runs and
#'   stored solutions from both input objects.
#'
#' @examples
#' pu <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' features <- data.frame(
#'   id = 1:2,
#'   name = c("sp1", "sp2")
#' )
#'
#' dist_features <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' actions <- data.frame(
#'   id = c("conservation", "restoration")
#' )
#'
#' effects <- data.frame(
#'   action = rep(actions$id, each = 2),
#'   feature = rep(features$id, times = 2),
#'   multiplier = c(
#'     1.0, 1.0,
#'     1.5, 1.5
#'   )
#' )
#'
#' make_problem <- function() {
#'   create_problem(
#'     pu = pu,
#'     features = features,
#'     dist_features = dist_features,
#'     cost = "cost"
#'   ) |>
#'     add_actions(
#'       actions = actions,
#'       cost = c(
#'         conservation = 1,
#'         restoration = 2
#'       )
#'     ) |>
#'     add_effects(
#'       effects = effects,
#'       effect_type = "after"
#'     ) |>
#'     add_constraint_targets_relative(0.05) |>
#'     add_objective_min_cost(alias = "cost") |>
#'     add_objective_max_benefit(alias = "benefit")
#' }
#'
#' weighted_problem <- make_problem() |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(
#'       n = 4
#'     ),
#'     normalize_weights = TRUE
#'   )
#'
#' epsilon_problem <- make_problem() |>
#'   set_method_epsilon_constraint(
#'     primary = "cost",
#'     runs = set_runs_grid(
#'       n = 4
#'     )
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   weighted_problem <- set_solver_cbc(
#'     weighted_problem,
#'     verbose = FALSE
#'   )
#'
#'   epsilon_problem <- set_solver_cbc(
#'     epsilon_problem,
#'     verbose = FALSE
#'   )
#'
#'   weighted_solutions <- solve(weighted_problem)
#'   epsilon_solutions <- solve(epsilon_problem)
#'
#'   combined_solutions <- solution_append(
#'     weighted_solutions,
#'     epsilon_solutions
#'   )
#'
#'   # Inspect the combined run history
#'   get_runs(combined_solutions)
#'
#'   # Inspect objective values from both methods
#'   get_objectives(
#'     combined_solutions,
#'     format = "wide"
#'   )
#'
#'   # The original objects remain unchanged
#'   get_runs(weighted_solutions)
#'   get_runs(epsilon_solutions)
#' }
#'
#' @seealso
#' \code{\link{solution_filter}},
#' \code{\link{solutionset-class}},
#' \code{\link{get_runs}},
#' \code{\link{get_objectives}},
#' \code{\link{plot_tradeoff}}
#'
#' @export
solution_append <- function(x, y) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  if (!inherits(y, "SolutionSet")) {
    stop(
      "y must be a SolutionSet object returned by solve(). ",
      "Appending external selection tables will be supported in a later version.",
      call. = FALSE
    )
  }

  .pa_check_solution_append_compatible(x, y)

  x <- .pa_clone_solution_set(x)
  y <- .pa_clone_solution_set(y)

  x <- .pa_finalize_solution_ids(x)
  y <- .pa_finalize_solution_ids(y)

  .pa_solution_append_solutionset(x = x, y = y)
}


#' Append one compatible SolutionSet to another
#'
#' @noRd
.pa_solution_append_solutionset <- function(x, y) {
  xruns <- x$solution$runs %||% NULL
  yruns <- y$solution$runs %||% NULL

  if (is.null(xruns) || !inherits(xruns, "data.frame")) {
    stop("x has no valid run table in x$solution$runs.", call. = FALSE)
  }

  if (is.null(yruns) || !inherits(yruns, "data.frame")) {
    stop("y has no valid run table in y$solution$runs.", call. = FALSE)
  }

  if (!("run_id" %in% names(xruns))) {
    xruns$run_id <- seq_len(nrow(xruns))
  }

  if (!("run_id" %in% names(yruns))) {
    yruns$run_id <- seq_len(nrow(yruns))
  }

  if (!("solution_id" %in% names(xruns))) {
    xruns$solution_id <- NA_integer_
  } else {
    xruns$solution_id <- suppressWarnings(as.integer(xruns$solution_id))
  }

  if (!("solution_id" %in% names(yruns))) {
    yruns$solution_id <- NA_integer_
  } else {
    yruns$solution_id <- suppressWarnings(as.integer(yruns$solution_id))
  }

  xsols <- x$solution$solutions %||% list()
  ysols <- y$solution$solutions %||% list()

  if (!is.list(xsols)) xsols <- list()
  if (!is.list(ysols)) ysols <- list()

  old_y_run_id <- yruns$run_id
  old_y_solution_id <- yruns$solution_id

  # --------------------------------------------------------------------------
  # Reassign run ids for y
  # --------------------------------------------------------------------------
  max_run_id <- if (nrow(xruns) > 0L) {
    suppressWarnings(max(as.integer(xruns$run_id), na.rm = TRUE))
  } else {
    0L
  }

  if (!is.finite(max_run_id)) {
    max_run_id <- 0L
  }

  y_run_map <- data.frame(
    old_run_id = old_y_run_id,
    new_run_id = max_run_id + seq_len(nrow(yruns)),
    stringsAsFactors = FALSE
  )

  yruns$run_id <- y_run_map$new_run_id[match(yruns$run_id, y_run_map$old_run_id)]

  # --------------------------------------------------------------------------
  # Reassign solution ids for y
  # --------------------------------------------------------------------------
  # New convention:
  # - solution_id is numeric.
  # - solution_id matches the new run_id of the stored solution.
  # - runs without stored solutions keep solution_id = NA.

  old_y_solution_id <- suppressWarnings(as.integer(old_y_solution_id))

  has_y_solution <- !is.na(old_y_solution_id) &
    is.finite(old_y_solution_id) &
    old_y_solution_id >= 1L

  if (any(has_y_solution)) {
    y_solution_map <- data.frame(
      old_solution_id = old_y_solution_id[has_y_solution],
      new_solution_id = yruns$run_id[has_y_solution],
      stringsAsFactors = FALSE
    )

    y_solution_map <- y_solution_map[
      !duplicated(y_solution_map$old_solution_id),
      ,
      drop = FALSE
    ]

    yruns$solution_id <- NA_integer_
    yruns$solution_id[has_y_solution] <- yruns$run_id[has_y_solution]

  } else {
    y_solution_map <- data.frame(
      old_solution_id = integer(0),
      new_solution_id = integer(0),
      stringsAsFactors = FALSE
    )

    yruns$solution_id <- NA_integer_
  }

  # --------------------------------------------------------------------------
  # Update y stored solutions
  # --------------------------------------------------------------------------
  if (length(ysols) > 0L && nrow(y_solution_map) > 0L) {
    old_names <- names(ysols)

    if (is.null(old_names) || any(!nzchar(old_names))) {
      old_names <- vapply(seq_along(ysols), function(i) {
        as.character(ysols[[i]]$meta$solution_id %||% NA_integer_)
      }, character(1))
    }

    old_ids <- suppressWarnings(as.integer(old_names))

    keep <- !is.na(old_ids) &
      old_ids %in% y_solution_map$old_solution_id

    ysols <- ysols[keep]
    old_ids <- old_ids[keep]

    new_ids <- y_solution_map$new_solution_id[
      match(old_ids, y_solution_map$old_solution_id)
    ]

    names(ysols) <- as.character(new_ids)

    for (i in seq_along(ysols)) {
      sid_new <- as.integer(new_ids[i])

      rid_old <- ysols[[i]]$meta$run_id %||% NA_integer_
      rid_old <- as.integer(rid_old)[1]

      rid_new <- y_run_map$new_run_id[match(rid_old, y_run_map$old_run_id)]

      ysols[[i]]$meta <- ysols[[i]]$meta %||% list()
      ysols[[i]]$meta$solution_id <- sid_new
      ysols[[i]]$meta$run_id <- rid_new
    }
  } else {
    ysols <- list()
  }

  # --------------------------------------------------------------------------
  # Update y summaries and design using the same id maps
  # --------------------------------------------------------------------------
  y <- .pa_remap_solution_set_tables(
    y = y,
    run_map = y_run_map,
    solution_map = y_solution_map
  )

  y$solution$runs <- yruns
  y$solution$solutions <- ysols

  # --------------------------------------------------------------------------
  # Combine runs
  # --------------------------------------------------------------------------
  x$solution$runs <- .pa_bind_rows_fill(xruns, y$solution$runs)

  # --------------------------------------------------------------------------
  # Combine design tables
  # --------------------------------------------------------------------------
  xdesign <- x$solution$design %||% NULL
  ydesign <- y$solution$design %||% NULL

  if (!is.null(xdesign) || !is.null(ydesign)) {
    x$solution$design <- .pa_bind_rows_fill(
      xdesign %||% data.frame(),
      ydesign %||% data.frame()
    )
  }

  # --------------------------------------------------------------------------
  # Combine stored solutions
  # --------------------------------------------------------------------------
  xsols <- x$solution$solutions %||% list()
  ysols <- y$solution$solutions %||% list()

  if (!is.list(xsols)) xsols <- list()
  if (!is.list(ysols)) ysols <- list()

  x$solution$solutions <- c(xsols, ysols)

  # --------------------------------------------------------------------------
  # Combine summary tables
  # --------------------------------------------------------------------------
  x$summary <- .pa_append_summary_tables(x$summary, y$summary)

  # --------------------------------------------------------------------------
  # Refresh diagnostics
  # --------------------------------------------------------------------------
  x$diagnostics <- x$diagnostics %||% list()

  x$diagnostics$n_design <- if (!is.null(x$solution$design) &&
                                inherits(x$solution$design, "data.frame")) {
    nrow(x$solution$design)
  } else {
    0L
  }

  x$diagnostics$n_runs <- if (!is.null(x$solution$runs) &&
                              inherits(x$solution$runs, "data.frame")) {
    nrow(x$solution$runs)
  } else {
    0L
  }

  x$diagnostics$n_solutions <- length(x$solution$solutions %||% list())

  if (exists(".pa_solutionset_status_summary", mode = "function")) {
    x$diagnostics$status_summary <- .pa_solutionset_status_summary(x$solution$runs)
  }

  if (exists(".pa_solutionset_range_text", mode = "function")) {
    if ("runtime" %in% names(x$solution$runs)) {
      x$diagnostics$runtime_range <- .pa_solutionset_range_text(
        x$solution$runs$runtime,
        digits = 3
      )
    }

    if ("gap" %in% names(x$solution$runs)) {
      x$diagnostics$gap_range <- .pa_solutionset_range_text(
        x$solution$runs$gap,
        digits = 4
      )
    }
  }

  x <- .pa_finalize_solution_ids(x)

  x
}


#' Check whether two SolutionSet objects can be appended safely
#'
#' @noRd
.pa_check_solution_append_compatible <- function(x, y) {
  if (!inherits(x, "SolutionSet") || !inherits(y, "SolutionSet")) {
    stop("Both x and y must be SolutionSet objects.", call. = FALSE)
  }

  px <- x$problem %||% NULL
  py <- y$problem %||% NULL

  if (!inherits(px, "Problem") || !inherits(py, "Problem")) {
    stop(
      "Both SolutionSet objects must contain a valid Problem object.",
      call. = FALSE
    )
  }

  dx <- px$data
  dy <- py$data

  .pa_compare_problem_table(dx$pu, dy$pu, "planning units", key = "id")
  .pa_compare_problem_table(dx$features, dy$features, "features", key = "id")

  .pa_compare_problem_table(dx$dist_features, dy$dist_features, "feature distributions")
  .pa_compare_problem_table(dx$actions, dy$actions, "actions")
  .pa_compare_problem_table(dx$dist_actions, dy$dist_actions, "feasible action pairs")
  .pa_compare_problem_table(dx$dist_effects, dy$dist_effects, "action effects")
  .pa_compare_problem_table(dx$profit, dy$profit, "profit data")
  .pa_compare_problem_table(dx$targets, dy$targets, "targets")

  .pa_compare_problem_object(dx$locks, dy$locks, "locks")
  .pa_compare_problem_object(dx$constraints, dy$constraints, "constraints")
  .pa_compare_problem_object(dx$area_constraints, dy$area_constraints, "area constraints")
  .pa_compare_problem_object(dx$budget_constraints, dy$budget_constraints, "budget constraints")
  .pa_compare_problem_object(dx$locked_pu, dy$locked_pu, "locked planning units")
  .pa_compare_problem_object(dx$locked_actions, dy$locked_actions, "locked actions")

  .pa_compare_problem_object(dx$spatial, dy$spatial, "spatial metadata")
  .pa_compare_problem_object(dx$relations, dy$relations, "spatial relations")
  .pa_compare_problem_object(dx$boundary, dy$boundary, "boundary relations")
  .pa_compare_problem_object(dx$dist_spatial, dy$dist_spatial, "spatial relation table")

  sx <- get_objective_specs(x)
  sy <- get_objective_specs(y)

  keep <- c("objective", "objective_id", "model_type", "sense")

  sx <- sx[, intersect(keep, names(sx)), drop = FALSE]
  sy <- sy[, intersect(keep, names(sy)), drop = FALSE]

  sx <- sx[order(sx$objective), , drop = FALSE]
  sy <- sy[order(sy$objective), , drop = FALSE]

  rownames(sx) <- NULL
  rownames(sy) <- NULL

  if (!identical(sx, sy)) {
    stop(
      "Cannot append SolutionSet objects with different objective specifications.",
      call. = FALSE
    )
  }

  TRUE
}


#' Compare two problem tables
#'
#' @noRd
.pa_compare_problem_table <- function(x, y, label, key = NULL) {
  nx <- is.null(x)
  ny <- is.null(y)

  if (nx && ny) {
    return(TRUE)
  }

  if (xor(nx, ny)) {
    stop(
      "Cannot append SolutionSet objects with different ", label, ".",
      call. = FALSE
    )
  }

  if (!inherits(x, "data.frame") || !inherits(y, "data.frame")) {
    return(.pa_compare_problem_object(x, y, label))
  }

  x0 <- .pa_normalize_table_for_compare(x, key = key)
  y0 <- .pa_normalize_table_for_compare(y, key = key)

  if (!identical(x0, y0)) {
    stop(
      "Cannot append SolutionSet objects with different ", label, ".",
      call. = FALSE
    )
  }

  TRUE
}


#' Compare two problem components
#'
#' @noRd
.pa_compare_problem_object <- function(x, y, label) {
  nx <- is.null(x)
  ny <- is.null(y)

  if (nx && ny) {
    return(TRUE)
  }

  if (xor(nx, ny)) {
    stop(
      "Cannot append SolutionSet objects with different ", label, ".",
      call. = FALSE
    )
  }

  x0 <- .pa_normalize_object_for_compare(x)
  y0 <- .pa_normalize_object_for_compare(y)

  if (!identical(x0, y0)) {
    stop(
      "Cannot append SolutionSet objects with different ", label, ".",
      call. = FALSE
    )
  }

  TRUE
}


#' Normalize a data frame for stable comparison
#'
#' @noRd
.pa_normalize_table_for_compare <- function(x, key = NULL) {
  if (is.null(x)) {
    return(NULL)
  }

  x <- as.data.frame(x, stringsAsFactors = FALSE)

  drop_cols <- c(
    "internal_id",
    "internal_pu",
    "internal_action",
    "internal_feature",
    "internal_row",
    "created_at"
  )

  x <- x[, setdiff(names(x), drop_cols), drop = FALSE]

  geom_cols <- vapply(x, function(z) inherits(z, "sfc") || inherits(z, "sfg"), logical(1))
  if (any(geom_cols)) {
    x <- x[, !geom_cols, drop = FALSE]
  }

  x <- x[, sort(names(x)), drop = FALSE]

  for (nm in names(x)) {
    if (is.factor(x[[nm]])) {
      x[[nm]] <- as.character(x[[nm]])
    }
  }

  if (!is.null(key) && key %in% names(x)) {
    x <- x[order(x[[key]]), , drop = FALSE]
  } else if (nrow(x) > 0L && ncol(x) > 0L) {
    ord <- do.call(order, x)
    x <- x[ord, , drop = FALSE]
  }

  rownames(x) <- NULL
  x
}


#' Normalize an arbitrary object for stable comparison
#'
#' @noRd
.pa_normalize_object_for_compare <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }

  if (inherits(x, "data.frame")) {
    return(.pa_normalize_table_for_compare(x))
  }

  if (is.list(x)) {
    out <- lapply(x, .pa_normalize_object_for_compare)

    if (!is.null(names(out))) {
      out <- out[sort(names(out))]
    }

    return(out)
  }

  if (is.factor(x)) {
    return(as.character(x))
  }

  x
}


#' Remap run and solution ids in tables stored in a SolutionSet
#'
#' @noRd
.pa_remap_solution_set_tables <- function(y,
                                          run_map,
                                          solution_map) {
  remap_table <- function(tab) {
    if (!inherits(tab, "data.frame")) {
      return(tab)
    }

    if ("run_id" %in% names(tab)) {
      tab$run_id <- run_map$new_run_id[match(tab$run_id, run_map$old_run_id)]
    }

    if ("solution_id" %in% names(tab) && nrow(solution_map) > 0L) {
      sid <- suppressWarnings(as.integer(tab$solution_id))

      tab$solution_id <- solution_map$new_solution_id[
        match(sid, solution_map$old_solution_id)
      ]
    }

    tab
  }

  if (!is.null(y$solution$design) && inherits(y$solution$design, "data.frame")) {
    y$solution$design <- remap_table(y$solution$design)
  }

  if (!is.null(y$solution$runs) && inherits(y$solution$runs, "data.frame")) {
    y$solution$runs <- remap_table(y$solution$runs)
  }

  if (!is.null(y$summary) && is.list(y$summary)) {
    for (nm in names(y$summary)) {
      y$summary[[nm]] <- remap_table(y$summary[[nm]])
    }
  }

  y
}


#' Append summary tables by name
#'
#' @noRd
.pa_append_summary_tables <- function(xsum, ysum) {
  xsum <- xsum %||% list()
  ysum <- ysum %||% list()

  out <- xsum

  all_names <- union(names(xsum), names(ysum))

  for (nm in all_names) {
    xtab <- xsum[[nm]] %||% NULL
    ytab <- ysum[[nm]] %||% NULL

    if (is.null(xtab)) {
      out[[nm]] <- ytab
    } else if (is.null(ytab)) {
      out[[nm]] <- xtab
    } else if (inherits(xtab, "data.frame") && inherits(ytab, "data.frame")) {
      out[[nm]] <- .pa_bind_rows_fill(xtab, ytab)
    } else {
      out[[nm]] <- xtab
    }
  }

  out
}


#' Bind rows of two data frames, filling missing columns with NA
#'
#' @noRd
.pa_bind_rows_fill <- function(x, y) {
  x <- x %||% data.frame()
  y <- y %||% data.frame()

  if (!inherits(x, "data.frame")) {
    x <- as.data.frame(x, stringsAsFactors = FALSE)
  }

  if (!inherits(y, "data.frame")) {
    y <- as.data.frame(y, stringsAsFactors = FALSE)
  }

  all_cols <- union(names(x), names(y))

  for (nm in setdiff(all_cols, names(x))) {
    x[[nm]] <- NA
  }

  for (nm in setdiff(all_cols, names(y))) {
    y[[nm]] <- NA
  }

  x <- x[, all_cols, drop = FALSE]
  y <- y[, all_cols, drop = FALSE]

  out <- rbind(x, y)
  rownames(out) <- NULL

  out
}



#' Keep unique solutions in a solution set
#'
#' @description
#' Return a reduced \code{\link{solutionset-class}} object containing one
#' representative from each group of equivalent solutions.
#'
#' Solutions can be considered equivalent according to either their decision
#' vectors or their objective values.
#'
#' @details
#' \code{solution_unique()} is a solution-set management function. It removes
#' repeated solutions while consistently filtering the run table, design table,
#' stored run-level solutions, and summary tables.
#'
#' Two definitions of uniqueness are supported:
#'
#' \itemize{
#'   \item \code{by = "decisions"} compares the complete stored decision vector
#'   of each solution. Two solutions are considered equivalent when their
#'   decision vectors are identical. This identifies repeated planning-unit or
#'   planning-unit/action configurations, even when they were generated by
#'   different runs or multi-objective parameter combinations.
#'
#'   \item \code{by = "objectives"} compares the selected objective values.
#'   Two solutions are considered equivalent when all compared objective values
#'   are equal within the specified numerical \code{tolerance}. Such solutions
#'   may still have different decision vectors.
#' }
#'
#' Consequently, uniqueness in objective space and uniqueness in decision space
#' are not equivalent. Two spatially different solutions may produce the same
#' objective values, while repeated runs may generate exactly the same decision
#' vector.
#'
#' Only runs with a stored \code{solution_id} can be assessed. Runs without a
#' stored solution, such as infeasible runs, are preserved unchanged. This
#' retains the full run history while removing only duplicated stored
#' solutions.
#'
#' The function does not renumber \code{run_id} or \code{solution_id}. The
#' representative retained from each duplicate group keeps its original
#' identifiers, preserving traceability to the original run design.
#'
#' For \code{by = "objectives"}, numerical equality is assessed using a
#' relative comparison:
#'
#' \deqn{
#' |a-b| \leq \epsilon \max(1, |a|, |b|),
#' }
#'
#' where \eqn{\epsilon} is specified by \code{tolerance}. This avoids treating
#' insignificant floating-point differences as distinct objective points.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param by Character. Definition of uniqueness. One of
#'   \code{"decisions"} or \code{"objectives"}.
#'
#' @param keep Character. Which representative to retain from each group of
#'   equivalent solutions. If \code{"first"}, retain the first solution in the
#'   current run order. If \code{"last"}, retain the last.
#'
#' @param objectives Optional character vector of objective names to compare
#'   when \code{by = "objectives"}. If \code{NULL}, all available objectives
#'   are used. This argument is ignored when \code{by = "decisions"}.
#'
#' @param tolerance Non-negative numeric tolerance used when comparing
#'   objective values. It is only used when \code{by = "objectives"}.
#'
#' @return A new \code{\link{solutionset-class}} object containing one
#'   representative from each group of equivalent stored solutions, together
#'   with any runs that did not produce a stored solution.
#'
#' @examples
#' pu <- data.frame(
#'   id = 1:4,
#'   cost = c(1, 2, 3, 4)
#' )
#'
#' features <- data.frame(
#'   id = 1:2,
#'   name = c("sp1", "sp2")
#' )
#'
#' dist_features <- data.frame(
#'   pu = c(1, 1, 2, 3, 4),
#'   feature = c(1, 2, 2, 1, 2),
#'   amount = c(5, 2, 3, 4, 1)
#' )
#'
#' actions <- data.frame(
#'   id = c("conservation", "restoration")
#' )
#'
#' effects <- data.frame(
#'   action = rep(actions$id, each = 2),
#'   feature = rep(features$id, times = 2),
#'   multiplier = c(
#'     1.0, 1.0,
#'     1.5, 1.5
#'   )
#' )
#'
#' problem <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     actions = actions,
#'     cost = c(
#'       conservation = 1,
#'       restoration = 2
#'     )
#'   ) |>
#'   add_effects(
#'     effects = effects,
#'     effect_type = "after"
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit") |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(
#'       n = 7
#'     ),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(
#'     problem,
#'     verbose = FALSE
#'   )
#'
#'   solutions <- solve(problem)
#'
#'   # Keep one representative for each distinct decision vector
#'   unique_decisions <- solution_unique(
#'     solutions,
#'     by = "decisions"
#'   )
#'
#'   # Keep one representative for each distinct objective point
#'   unique_objectives <- solution_unique(
#'     solutions,
#'     by = "objectives"
#'   )
#'
#'   # Compare only selected objectives
#'   unique_cost_benefit <- solution_unique(
#'     solutions,
#'     by = "objectives",
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   # Keep the last representative of each duplicate group
#'   unique_last <- solution_unique(
#'     solutions,
#'     by = "decisions",
#'     keep = "last"
#'   )
#'
#'   # Compare the number of stored solutions
#'   sum(!is.na(get_runs(solutions)$solution_id))
#'   sum(!is.na(get_runs(unique_decisions)$solution_id))
#'   sum(!is.na(get_runs(unique_objectives)$solution_id))
#'
#'   # Typical cleaning workflow
#'   if (requireNamespace("moocore", quietly = TRUE)) {
#'     clean_solutions <- solutions |>
#'       solution_filter(
#'         feasible_only = TRUE,
#'         nondominated = TRUE
#'       ) |>
#'       solution_unique(
#'         by = "decisions"
#'       )
#'   }
#' }
#'
#' @seealso
#' \code{\link{solution_filter}},
#' \code{\link{solution_append}},
#' \code{\link{get_objectives}},
#'
#' @export
solution_unique <- function(
    x,
    by = c("decisions", "objectives"),
    keep = c("first", "last"),
    objectives = NULL,
    tolerance = sqrt(.Machine$double.eps)
) {
  if (!inherits(x, "SolutionSet")) {
    stop(
      "x must be a SolutionSet object returned by solve().",
      call. = FALSE
    )
  }

  by <- match.arg(by)
  keep <- match.arg(keep)

  if (
    !is.numeric(tolerance) ||
    length(tolerance) != 1L ||
    is.na(tolerance) ||
    !is.finite(tolerance) ||
    tolerance < 0
  ) {
    stop(
      "`tolerance` must be a single non-negative finite number.",
      call. = FALSE
    )
  }

  tolerance <- as.numeric(tolerance)

  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop(
      "No run table found in x$solution$runs.",
      call. = FALSE
    )
  }

  if (!("run_id" %in% names(runs))) {
    stop(
      "Run table must contain a 'run_id' column.",
      call. = FALSE
    )
  }

  if (!("solution_id" %in% names(runs))) {
    stop(
      paste0(
        "Run table must contain a 'solution_id' column. ",
        "Recreate the SolutionSet with the current version of multiscape."
      ),
      call. = FALSE
    )
  }

  runs$solution_id <- suppressWarnings(as.integer(runs$solution_id))

  has_solution <- !is.na(runs$solution_id) &
    is.finite(runs$solution_id) &
    runs$solution_id >= 1L

  stored_runs <- runs[has_solution, , drop = FALSE]
  other_runs <- runs[!has_solution, , drop = FALSE]

  if (nrow(stored_runs) <= 1L) {
    return(.pa_clone_solution_set(x))
  }

  if (identical(keep, "last")) {
    stored_runs <- stored_runs[
      rev(seq_len(nrow(stored_runs))),
      ,
      drop = FALSE
    ]
  }

  if (identical(by, "decisions")) {
    duplicate_group <- .pa_solution_decision_groups(
      x = x,
      solution_ids = stored_runs$solution_id
    )
  } else {
    duplicate_group <- .pa_solution_objective_groups(
      x = x,
      solution_ids = stored_runs$solution_id,
      objectives = objectives,
      tolerance = tolerance
    )
  }

  keep_position <- !duplicated(duplicate_group)

  kept_runs <- stored_runs[keep_position, , drop = FALSE]

  if (identical(keep, "last")) {
    kept_runs <- kept_runs[
      rev(seq_len(nrow(kept_runs))),
      ,
      drop = FALSE
    ]
  }

  keep_run_ids <- c(
    other_runs$run_id,
    kept_runs$run_id
  )

  # Preserve the original run-table order.
  keep_run_ids <- runs$run_id[
    runs$run_id %in% keep_run_ids
  ]

  .pa_filter_solution_set(
    x,
    run_ids = keep_run_ids
  )
}


#' Assign duplicate groups from stored decision vectors
#'
#' @noRd
.pa_solution_decision_groups <- function(x, solution_ids) {
  solution_ids <- suppressWarnings(as.integer(solution_ids))

  if (
    anyNA(solution_ids) ||
    any(!is.finite(solution_ids)) ||
    any(solution_ids < 1L)
  ) {
    stop(
      "`solution_ids` must contain positive integers.",
      call. = FALSE
    )
  }

  vectors <- lapply(
    solution_ids,
    function(sid) {
      v <- get_solution_vector(
        x,
        solution = sid
      )

      if (is.null(v)) {
        stop(
          "No decision vector found for solution = '",
          sid,
          "'.",
          call. = FALSE
        )
      }

      v <- as.numeric(v)

      if (anyNA(v) || any(!is.finite(v))) {
        stop(
          "Decision vector for solution_id = '",
          sid,
          "' contains missing or non-finite values.",
          call. = FALSE
        )
      }

      v
    }
  )

  lengths <- vapply(vectors, length, integer(1))

  if (length(unique(lengths)) != 1L) {
    stop(
      paste0(
        "Stored solutions have decision vectors of different lengths and ",
        "cannot be compared."
      ),
      call. = FALSE
    )
  }

  .pa_group_equal_vectors(
    vectors = vectors,
    tolerance = 0
  )
}


#' Assign duplicate groups from objective values
#'
#' @noRd
.pa_solution_objective_groups <- function(
    x,
    solution_ids,
    objectives = NULL,
    tolerance = sqrt(.Machine$double.eps)
) {
  vals <- get_objectives(
    x,
    format = "wide"
  )

  if (!("solution_id" %in% names(vals))) {
    stop(
      "Objective table must contain a 'solution_id' column.",
      call. = FALSE
    )
  }

  available <- setdiff(
    names(vals),
    c("run_id", "solution_id")
  )

  if (length(available) == 0L) {
    stop(
      "No objective columns are available.",
      call. = FALSE
    )
  }

  if (is.null(objectives)) {
    objectives <- available
  } else {
    objectives <- as.character(objectives)
    objectives <- objectives[
      !is.na(objectives) &
        nzchar(objectives)
    ]

    if (length(objectives) == 0L) {
      stop(
        "`objectives` must contain at least one objective name.",
        call. = FALSE
      )
    }

    unknown <- setdiff(objectives, available)

    if (length(unknown) > 0L) {
      stop(
        "Unknown objective(s): ",
        paste(unknown, collapse = ", "),
        ". Available objectives are: ",
        paste(available, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }

  solution_ids <- suppressWarnings(as.integer(solution_ids))
  vals$solution_id <- suppressWarnings(as.integer(vals$solution_id))

  idx <- match(solution_ids, vals$solution_id)

  if (anyNA(idx)) {
    missing_ids <- solution_ids[is.na(idx)]

    stop(
      "Objective values were not found for solution_id value(s): ",
      paste(missing_ids, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  mat <- as.matrix(
    vals[idx, objectives, drop = FALSE]
  )

  storage.mode(mat) <- "double"

  if (anyNA(mat) || any(!is.finite(mat))) {
    stop(
      paste0(
        "Objective values contain missing or non-finite values. ",
        "Filter incomplete solutions before applying ",
        "solution_unique(by = \"objectives\")."
      ),
      call. = FALSE
    )
  }

  vectors <- lapply(
    seq_len(nrow(mat)),
    function(i) mat[i, ]
  )

  .pa_group_equal_vectors(
    vectors = vectors,
    tolerance = tolerance
  )
}


#' Assign group identifiers to equal numeric vectors
#'
#' @noRd
.pa_group_equal_vectors <- function(vectors, tolerance = 0) {
  n <- length(vectors)

  if (n == 0L) {
    return(integer(0))
  }

  groups <- integer(n)
  representatives <- list()
  n_groups <- 0L

  for (i in seq_len(n)) {
    current <- as.numeric(vectors[[i]])
    matched_group <- NA_integer_

    if (n_groups > 0L) {
      for (g in seq_len(n_groups)) {
        representative <- representatives[[g]]

        if (
          .pa_numeric_vectors_equal(
            current,
            representative,
            tolerance = tolerance
          )
        ) {
          matched_group <- g
          break
        }
      }
    }

    if (is.na(matched_group)) {
      n_groups <- n_groups + 1L
      representatives[[n_groups]] <- current
      matched_group <- n_groups
    }

    groups[i] <- matched_group
  }

  groups
}


#' Compare two numeric vectors using relative tolerance
#'
#' @noRd
.pa_numeric_vectors_equal <- function(
    x,
    y,
    tolerance = sqrt(.Machine$double.eps)
) {
  x <- as.numeric(x)
  y <- as.numeric(y)

  if (length(x) != length(y)) {
    return(FALSE)
  }

  if (length(x) == 0L) {
    return(TRUE)
  }

  if (
    anyNA(x) ||
    anyNA(y) ||
    any(!is.finite(x)) ||
    any(!is.finite(y))
  ) {
    return(FALSE)
  }

  scale <- pmax(
    1,
    abs(x),
    abs(y)
  )

  all(
    abs(x - y) <= tolerance * scale
  )
}

