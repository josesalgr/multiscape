#' Define an automatic multi-objective run grid
#'
#' @description
#' Create an automatic run-design specification for generating multiple
#' optimization runs in a multi-objective workflow.
#'
#' `run_grid()` provides a common interface for controlling the resolution of
#' weighted-sum, epsilon-constraint, and AUGMECON run designs. The returned
#' object does not contain the final run table. Instead, it stores the requested
#' grid settings, which are resolved later by the corresponding
#' `set_method_*()` function using the registered objectives and their
#' optimization senses.
#'
#' @details
#' Multi-objective methods generally require several optimization runs to
#' explore different regions of objective space. `run_grid()` asks
#' `multiscape` to generate those runs automatically.
#'
#' The interpretation of the grid depends on the selected method:
#'
#' \itemize{
#'   \item In \code{\link{set_method_weighted_sum}}, the grid defines
#'   combinations of objective weights. The generated weights are normalized
#'   according to the method settings and represent alternative preferences
#'   among the registered objectives.
#'
#'   \item In \code{\link{set_method_epsilon_constraint}}, the grid defines
#'   epsilon levels for the constrained objectives. The primary objective is
#'   optimized directly, while the remaining objectives are progressively
#'   restricted across the generated runs.
#'
#'   \item In \code{\link{set_method_augmecon}}, the grid similarly defines
#'   epsilon levels for the secondary objectives, which are then used in the
#'   augmented epsilon-constraint formulation.
#' }
#'
#' The argument \code{n} controls the resolution of the automatically generated
#' design. It should not always be interpreted as the final number of runs.
#' For example, when several secondary objectives are present, epsilon levels
#' may be combined across objectives and generate more runs than the value
#' supplied to \code{n}. Likewise, the number of valid weighted combinations
#' depends on the number of objectives and on how the weight grid is
#' constructed.
#'
#' If \code{include_extremes = TRUE}, the generated design includes settings
#' corresponding to the objective-space extremes whenever they are meaningful
#' for the selected method. For weighted-sum methods, this includes weight
#' combinations that place all weight on a single objective. For
#' epsilon-based methods, it includes the boundary levels of the automatically
#' derived objective ranges.
#'
#' Including extremes is generally recommended because it helps recover the
#' best observed value of each objective and provides reference points for
#' subsequent frontier analyses. However, users may set
#' \code{include_extremes = FALSE} when only interior trade-off solutions are
#' required or when extreme solutions have already been obtained separately.
#'
#' The resolved design is stored in the resulting
#' \code{\link{solutionset-class}} object and can be inspected after solving
#' through \code{\link{get_runs}} or the internal run-design table.
#'
#' Use \code{\link{run_manual}} instead when exact weights or epsilon levels
#' must be supplied explicitly.
#'
#' @param n Integer. Resolution of the automatically generated run design.
#'   Must be at least \code{2}. The final number of optimization runs may differ
#'   from \code{n}, depending on the selected method and the number of
#'   objectives.
#'
#' @param include_extremes Logical. Whether objective-space extreme settings
#'   should be included in the generated design. Defaults to \code{TRUE}.
#'
#' @return An object of class \code{RunGrid} and \code{RunDesign}. The object
#'   stores the requested grid resolution and extreme-point setting and is
#'   intended to be supplied to the \code{runs} argument of a multi-objective
#'   method function.
#'
#' @examples
#' # Create an automatic run-grid specification
#' grid <- run_grid(
#'   n = 5,
#'   include_extremes = TRUE
#' )
#'
#' grid
#'
#' # Use the automatic grid in a weighted-sum workflow
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
#'     runs = run_grid(
#'       n = 5,
#'       include_extremes = TRUE
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
#'   # Inspect the resolved run design and objective values
#'   get_runs(solutions)
#'   get_objectives(
#'     solutions,
#'     format = "wide"
#'   )
#' }
#'
#'
#' @seealso
#' \code{\link{run_manual}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{get_runs}}
#'
#' @export
run_grid <- function(n, include_extremes = TRUE) {
  n <- as.integer(n)[1]

  if (!is.finite(n) || is.na(n) || n < 2L) {
    stop("`n` must be an integer >= 2.", call. = FALSE)
  }

  if (
    !is.logical(include_extremes) ||
    length(include_extremes) != 1L ||
    is.na(include_extremes)
  ) {
    stop(
      "`include_extremes` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  structure(
    list(
      type = "grid",
      n = n,
      include_extremes = isTRUE(include_extremes)
    ),
    class = c("RunGrid", "RunDesign")
  )
}


#' Define a manual multi-objective run design
#'
#' @description
#' Create an explicit run-design specification in which each row defines one
#' multi-objective optimization run.
#'
#' \code{run_manual()} is used when exact objective weights or epsilon levels
#' should be supplied by the user instead of being generated automatically with
#' \code{\link{run_grid}}.
#'
#' @details
#' The input must be a non-empty \code{data.frame} with one row per requested
#' optimization run.
#'
#' Weighted-sum columns must follow the convention:
#'
#' \preformatted{
#' weight_<alias>
#' }
#'
#' Epsilon-constraint and AUGMECON columns must follow the convention:
#'
#' \preformatted{
#' eps_<alias>
#' }
#'
#' A manual design must contain at least one column beginning with
#' \code{weight_} or \code{eps_}. Mixing both column families in the same
#' design is not allowed.
#'
#' All run-design columns must be numeric, finite, and free of missing values.
#' Weight columns must contain non-negative values, and each weighted-sum row
#' must assign a strictly positive total weight.
#'
#' This function performs method-independent structural validation.
#' Method-specific validation is performed later by the corresponding
#' \code{set_method_*()} function. This includes checking:
#'
#' \itemize{
#'   \item that all required objective aliases are represented;
#'   \item that no unknown objective columns are supplied;
#'   \item that epsilon columns correspond only to secondary objectives;
#'   \item and that the supplied design is compatible with the selected method.
#' }
#'
#' Therefore, an object may be structurally valid for \code{run_manual()} but
#' rejected later by \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}}, or
#' \code{\link{set_method_augmecon}}.
#'
#' @param x A non-empty \code{data.frame} with one row per optimization run.
#'   Run-design columns must be named using the \code{weight_<alias>} or
#'   \code{eps_<alias>} convention.
#'
#' @return An object of class \code{RunManual} and \code{RunDesign} containing
#'   the validated run table.
#'
#' @examples
#' weighted_runs <- run_manual(
#'   data.frame(
#'     weight_cost = c(1.0, 0.5, 0.0),
#'     weight_benefit = c(0.0, 0.5, 1.0)
#'   )
#' )
#'
#' epsilon_runs <- run_manual(
#'   data.frame(
#'     eps_benefit = c(2, 4, 6, 8)
#'   )
#' )
#'
#' weighted_runs
#' epsilon_runs
#'
#' @seealso
#' \code{\link{run_grid}},
#' \code{\link{set_method_weighted_sum}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}}
#'
#' @export
run_manual <- function(x) {
  if (is.null(x) || !inherits(x, "data.frame")) {
    stop(
      "`x` must be a data.frame.",
      call. = FALSE
    )
  }

  if (nrow(x) == 0L) {
    stop(
      "`x` must contain at least one row.",
      call. = FALSE
    )
  }

  if (ncol(x) == 0L) {
    stop(
      "`x` must contain at least one run-design column.",
      call. = FALSE
    )
  }

  column_names <- names(x)

  if (
    is.null(column_names) ||
    anyNA(column_names) ||
    any(!nzchar(column_names))
  ) {
    stop(
      "All columns in `x` must have non-empty names.",
      call. = FALSE
    )
  }

  if (anyDuplicated(column_names) > 0L) {
    duplicated_names <- unique(
      column_names[duplicated(column_names)]
    )

    stop(
      "Duplicated run-design column name(s): ",
      paste(duplicated_names, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  weight_columns <- grep(
    "^weight_.+",
    column_names,
    value = TRUE
  )

  epsilon_columns <- grep(
    "^eps_.+",
    column_names,
    value = TRUE
  )

  if (
    length(weight_columns) == 0L &&
    length(epsilon_columns) == 0L
  ) {
    stop(
      paste0(
        "`x` must contain at least one column named ",
        "`weight_<alias>` or `eps_<alias>`."
      ),
      call. = FALSE
    )
  }

  if (
    length(weight_columns) > 0L &&
    length(epsilon_columns) > 0L
  ) {
    stop(
      paste0(
        "A manual run design cannot mix `weight_*` and `eps_*` ",
        "columns."
      ),
      call. = FALSE
    )
  }

  design_columns <- c(
    weight_columns,
    epsilon_columns
  )

  additional_columns <- setdiff(
    column_names,
    design_columns
  )

  if (length(additional_columns) > 0L) {
    stop(
      "Unknown run-design column(s): ",
      paste(additional_columns, collapse = ", "),
      ". Columns must follow the `weight_<alias>` or `eps_<alias>` convention.",
      call. = FALSE
    )
  }

  non_numeric <- design_columns[
    !vapply(
      x[design_columns],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric) > 0L) {
    stop(
      "Run-design column(s) must be numeric: ",
      paste(non_numeric, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  values <- as.matrix(
    x[, design_columns, drop = FALSE]
  )

  storage.mode(values) <- "double"

  if (anyNA(values)) {
    stop(
      "Run-design columns must not contain missing values.",
      call. = FALSE
    )
  }

  if (any(!is.finite(values))) {
    stop(
      "Run-design columns must contain only finite values.",
      call. = FALSE
    )
  }

  if (length(weight_columns) > 0L) {
    weight_values <- values[
      ,
      weight_columns,
      drop = FALSE
    ]

    if (any(weight_values < 0)) {
      stop(
        "Manual weights must be non-negative.",
        call. = FALSE
      )
    }

    if (any(rowSums(weight_values) <= 0)) {
      stop(
        paste0(
          "Each manual weighted-sum run must assign a ",
          "strictly positive total weight."
        ),
        call. = FALSE
      )
    }
  }

  structure(
    list(
      type = "manual",
      values = as.data.frame(
        x,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    ),
    class = c("RunManual", "RunDesign")
  )
}
