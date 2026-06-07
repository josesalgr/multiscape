#' @include internalMO.R
#'
#' @title Set the weighted-sum multi-objective method
#'
#' @description
#' Configure a \code{Problem} object to be solved with a weighted-sum
#' multi-objective method.
#'
#' In the weighted-sum method, several registered atomic objectives are combined
#' into a single scalar objective using a weighted linear combination. This
#' function stores that configuration in \code{x$data$method} so that it can be
#' used later by \code{\link{solve}}.
#'
#' @details
#' Use this method when several registered objectives should be combined into a
#' single scalar optimization problem through explicit preference weights.
#'
#' \strong{General idea}
#'
#' Suppose that a set of atomic objectives has already been registered in the
#' problem under aliases \eqn{k \in \mathcal{K}}. Let \eqn{f_k(x)} denote the
#' scalar value of objective \eqn{k}, and let \eqn{w_k} denote its weight.
#'
#' The weighted-sum method combines them into a single scalar objective of the
#' form:
#'
#' \deqn{
#' \sum_{k \in \mathcal{K}} w_k \, f_k(x).
#' }
#'
#' In practice, the exact sign convention used internally depends on the sense
#' of each registered atomic objective, for example whether it is a
#' minimization-type or maximization-type objective. The solving layer is
#' responsible for constructing a solver-ready scalar objective from the stored
#' objective specifications and the requested weights.
#'
#' \strong{Run designs}
#'
#' Weighted-sum runs are specified through the \code{runs} argument. This
#' argument must be created with either \code{\link{run_grid}} or
#' \code{\link{run_manual}}.
#'
#' \code{run_grid(n = ...)} automatically generates a grid of weight
#' combinations. For two objectives, this is a regular sequence of weights along
#' the line between the two objectives. For three or more objectives, the grid
#' is generated over the weight simplex, where all weights are non-negative and
#' sum to one.
#'
#' \code{run_manual()} allows users to provide explicit weight combinations.
#' In manual weighted-sum runs, each row is one optimization run and columns must
#' be named \code{weight_<alias>}. For example, if
#' \code{aliases = c("cost", "benefit")}, the manual run table must contain
#' columns \code{weight_cost} and \code{weight_benefit}.
#'
#' The older \code{weights} argument is deprecated. It is still accepted for
#' backwards compatibility and is internally converted to a one-row
#' \code{run_manual()} design.
#'
#' \strong{Atomic objectives requirement}
#'
#' The weighted-sum method can only be used with atomic objectives that have
#' already been registered under aliases. These aliases are typically created by
#' calling objective setters with an \code{alias} argument, for example:
#' \preformatted{
#' x <- x |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_min_fragmentation(alias = "frag")
#' }
#'
#' Internally, each atomic objective is stored in
#' \code{x$data$objectives[[alias]]} together with its metadata, such as:
#' \itemize{
#'   \item \code{objective_id},
#'   \item \code{model_type},
#'   \item \code{sense},
#'   \item \code{objective_args}.
#' }
#'
#' The \code{aliases} argument passed to this function selects which of those
#' registered atomic objectives are included in the weighted combination.
#'
#' \strong{Weight normalization}
#'
#' If \code{normalize_weights = TRUE}, the weights in each run are rescaled to
#' sum to one:
#'
#' \deqn{
#' \tilde{w}_k = \frac{w_k}{\sum_{j \in \mathcal{K}} w_j}.
#' }
#'
#' This normalization does not change the optimizer's solution in a pure
#' weighted-sum formulation as long as all weights are multiplied by the same
#' positive constant, but it can improve interpretability and numerical
#' conditioning.
#'
#' If \code{normalize_weights = FALSE}, each row of weights must already sum to
#' one.
#'
#' \strong{Objective scaling}
#'
#' If \code{objective_scaling = TRUE}, the solving layer scales the
#' participating objectives before combining them. The purpose of scaling is to
#' reduce distortions caused by objectives being measured on very different
#' numerical ranges.
#'
#' Conceptually, if \eqn{R_k} denotes a scale or range associated with objective
#' \eqn{k}, then a scaled weighted sum may be interpreted as:
#'
#' \deqn{
#' \sum_{k \in \mathcal{K}} w_k \, \frac{f_k(x)}{R_k}.
#' }
#'
#' The exact scaling rule is implemented in the solving layer.
#'
#' \strong{Mixed objective senses}
#'
#' Weighted sums are straightforward when all participating objectives have the
#' same optimization sense. When minimization and maximization objectives are
#' mixed, the solving layer standardizes them internally before building the
#' scalar objective.
#'
#' Users should provide non-negative weights according to the original meaning
#' of each objective. For example, a positive weight on a maximization objective
#' means that higher values of that objective are preferred.
#'
#' \strong{Failure handling}
#'
#' The \code{control} argument controls how failed runs are handled. It must be
#' created with \code{\link{mo_control}}.
#'
#' Weighted-sum runs do not normally introduce additional constraints, so they
#' should not usually create infeasible subproblems by themselves. However, runs
#' may still fail if the underlying model is infeasible, the solver stops before
#' finding a feasible solution, or a numerical/modeling issue occurs. The
#' \code{control} argument determines whether such failures stop the whole
#' solve or are retained in the returned \code{SolutionSet} with missing
#' objective values.
#'
#' \strong{Theoretical limitation}
#'
#' The weighted-sum method typically recovers only \emph{supported} efficient
#' solutions, that is, solutions lying on the convex hull of the Pareto front in
#' objective space. In non-convex multi-objective problems, especially mixed
#' integer problems, some efficient solutions cannot be obtained by any weighted
#' combination. In such cases, methods such as
#' \code{\link{set_method_epsilon_constraint}} or
#' \code{\link{set_method_augmecon}} may be preferable.
#'
#' \strong{Stored configuration}
#'
#' This function stores the method definition in \code{x$data$method} with:
#' \itemize{
#'   \item \code{name = "weighted"},
#'   \item \code{type = "weighted"},
#'   \item \code{aliases},
#'   \item \code{runs},
#'   \item \code{normalize_weights},
#'   \item \code{objective_scaling},
#'   \item \code{control}.
#' }
#'
#' The actual scalarization is performed later by \code{\link{solve}}.
#'
#' @param x A \code{Problem} object.
#' @param aliases Character vector of objective aliases to combine. Each alias
#'   must correspond to a previously registered atomic objective.
#' @param runs A run design created with \code{\link{run_grid}} or
#'   \code{\link{run_manual}}. For weighted-sum methods, automatic grids define
#'   weight combinations, while manual runs must contain columns named
#'   \code{weight_<alias>}.
#' @param weights Deprecated. Numeric vector of weights, with the same length
#'   and order as \code{aliases}. This argument is kept for backwards
#'   compatibility and is internally converted to
#'   \code{runs = run_manual(...)}. New code should use \code{runs} instead.
#' @param normalize_weights Logical. If \code{TRUE}, normalize the weights in
#'   each run to sum to one before solving.
#' @param objective_scaling Logical. If \code{TRUE}, request scaling of the
#'   participating objectives before weighted aggregation in the solving layer.
#' @param control A control object created with \code{\link{mo_control}}. It
#'   controls how infeasible runs, runs without a solution, and unexpected
#'   errors are handled.
#'
#' @return The updated \code{Problem} object with the weighted-sum method
#'   configuration stored in \code{x$data$method}.
#'
#' @examples
#' # Small toy problem
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
#' actions_df <- data.frame(
#'   id = c("conservation", "restoration"),
#'   name = c("conservation", "restoration")
#' )
#'
#' effects_df <- data.frame(
#'   pu = c(1, 2, 3, 4, 1, 2, 3, 4),
#'   action = c("conservation", "conservation", "conservation", "conservation",
#'              "restoration", "restoration", "restoration", "restoration"),
#'   feature = c(1, 1, 1, 1, 2, 2, 2, 2),
#'   benefit = c(2, 1, 0, 1, 3, 0, 1, 2),
#'   loss = c(0, 0, 1, 0, 0, 1, 0, 0)
#' )
#'
#' x <- create_problem(
#'   pu = pu_tbl,
#'   features = feat_tbl,
#'   dist_features = dist_feat_tbl,
#'   cost = "cost"
#' ) |>
#'   add_actions(actions_df, cost = c(conservation = 1, restoration = 2)) |>
#'   add_effects(effects_df) |>
#'   add_objective_min_cost(alias = "cost") |>
#'   add_objective_max_benefit(alias = "benefit")
#'
#' # Automatic weight grid
#' x1 <- set_method_weighted_sum(
#'   x,
#'   aliases = c("cost", "benefit"),
#'   runs = run_grid(n = 5, include_extremes = TRUE),
#'   objective_scaling = TRUE
#' )
#'
#' x1$data$method
#'
#' # Manual weighted runs
#' manual_weights <- data.frame(
#'   weight_cost = c(1.0, 0.75, 0.50, 0.25, 0.0),
#'   weight_benefit = c(0.0, 0.25, 0.50, 0.75, 1.0)
#' )
#'
#' x2 <- set_method_weighted_sum(
#'   x,
#'   aliases = c("cost", "benefit"),
#'   runs = run_manual(manual_weights),
#'   normalize_weights = FALSE,
#'   objective_scaling = TRUE
#' )
#'
#' x2$data$method
#'
#' # Manual runs with automatic weight normalization
#' manual_weights2 <- data.frame(
#'   weight_cost = c(2, 1, 1),
#'   weight_benefit = c(1, 1, 3)
#' )
#'
#' x3 <- set_method_weighted_sum(
#'   x,
#'   aliases = c("cost", "benefit"),
#'   runs = run_manual(manual_weights2),
#'   normalize_weights = TRUE
#' )
#'
#' x3$data$method
#'
#' # Backwards-compatible deprecated usage
#' x4 <- set_method_weighted_sum(
#'   x,
#'   aliases = c("cost", "benefit"),
#'   weights = c(0.4, 0.6),
#'   normalize_weights = FALSE
#' )
#'
#' x4$data$method
#'
#' # Control failure handling
#' x5 <- set_method_weighted_sum(
#'   x,
#'   aliases = c("cost", "benefit"),
#'   runs = run_grid(n = 5),
#'   control = mo_control(
#'     stop_on_infeasible = TRUE,
#'     stop_on_no_solution = TRUE,
#'     stop_on_error = TRUE
#'   )
#' )
#'
#' x5$data$method
#'
#' @seealso
#' \code{\link{run_grid}},
#' \code{\link{run_manual}},
#' \code{\link{mo_control}},
#' \code{\link{set_method_epsilon_constraint}},
#' \code{\link{set_method_augmecon}},
#' \code{\link{solve}}
#'
#' @export
set_method_weighted_sum <- function(x,
                                    aliases,
                                    runs = NULL,
                                    weights = NULL,
                                    normalize_weights = TRUE,
                                    objective_scaling = FALSE,
                                    control = NULL) {
  stopifnot(inherits(x, "Problem"))

  if (exists(".pa_clone_data", mode = "function")) {
    x <- .pa_clone_data(x)
  }

  # ---- aliases
  if (
    !is.character(aliases) ||
    length(aliases) < 2L ||
    anyNA(aliases)
  ) {
    stop(
      paste0(
        "`aliases` must be a character vector with at least ",
        "two objective aliases."
      ),
      call. = FALSE
    )
  }

  aliases <- as.character(aliases)

  if (any(!nzchar(aliases))) {
    stop(
      "`aliases` must not contain empty strings.",
      call. = FALSE
    )
  }

  if (anyDuplicated(aliases) != 0L) {
    duplicates <- unique(
      aliases[duplicated(aliases)]
    )

    stop(
      "`aliases` must not contain duplicates: ",
      paste(duplicates, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  .pamo_get_objective_specs(
    x,
    aliases
  )

  # ---- flags
  if (
    !is.logical(normalize_weights) ||
    length(normalize_weights) != 1L ||
    is.na(normalize_weights)
  ) {
    stop(
      "`normalize_weights` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (
    !is.logical(objective_scaling) ||
    length(objective_scaling) != 1L ||
    is.na(objective_scaling)
  ) {
    stop(
      "`objective_scaling` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  # ---- backwards compatibility: weights -> run_manual()
  if (!is.null(weights)) {
    if (!is.null(runs)) {
      stop(
        "Use only one of `runs` or deprecated `weights`.",
        call. = FALSE
      )
    }

    .pa_deprecate_arg(
      old = "weights",
      new = "runs = run_manual(data.frame(weight_<alias> = ...))"
    )

    if (
      !is.numeric(weights) ||
      length(weights) != length(aliases) ||
      anyNA(weights)
    ) {
      stop(
        paste0(
          "`weights` must be a numeric vector with the same length ",
          "as `aliases` and without missing values."
        ),
        call. = FALSE
      )
    }

    weights <- as.numeric(weights)

    if (any(!is.finite(weights))) {
      stop(
        "`weights` must contain only finite values.",
        call. = FALSE
      )
    }

    if (any(weights < 0)) {
      stop(
        "`weights` must be non-negative.",
        call. = FALSE
      )
    }

    if (sum(weights) <= 0) {
      stop(
        "`weights` must assign a positive total weight.",
        call. = FALSE
      )
    }

    if (
      !isTRUE(normalize_weights) &&
      abs(sum(weights) - 1) > sqrt(.Machine$double.eps)
    ) {
      stop(
        paste0(
          "When `normalize_weights = FALSE`, deprecated `weights` ",
          "must sum to one."
        ),
        call. = FALSE
      )
    }

    # Do not include run_id here. run_id is assigned when the design is
    # resolved; it is not part of the user-supplied manual weight table.
    weight_df <- stats::setNames(
      as.data.frame(
        as.list(weights),
        stringsAsFactors = FALSE,
        check.names = FALSE
      ),
      paste0("weight_", aliases)
    )

    runs <- run_manual(weight_df)
  }

  if (is.null(runs)) {
    stop(
      paste0(
        "`runs` must be supplied. Use `runs = run_grid(n = ...)` ",
        "or `runs = run_manual(...)`."
      ),
      call. = FALSE
    )
  }

  .pamo_check_run_design(runs)

  # Validate manual columns only after the selected aliases and normalization
  # behaviour are known.
  .pamo_validate_manual_weight_design(
    runs = runs,
    aliases = aliases,
    normalize_weights = normalize_weights
  )

  # ---- control
  control <- .pamo_check_mo_control(control)

  x$data$method <- list(
    name = "weighted",
    type = "weighted",
    aliases = aliases,
    runs = runs,
    normalize_weights = isTRUE(normalize_weights),
    objective_scaling = isTRUE(objective_scaling),
    control = control,
    stop_on_infeasible = control$stop_on_infeasible,
    stop_on_no_solution = control$stop_on_no_solution,
    stop_on_error = control$stop_on_error
  )

  x
}



#' Validate a manual weighted-sum design
#'
#' @param runs A \code{RunManual} object.
#' @param aliases Character vector of objective aliases.
#' @param normalize_weights Logical indicating whether rows will be normalized.
#'
#' @return Invisibly returns \code{TRUE}.
#'
#' @noRd
.pamo_validate_manual_weight_design <- function(
    runs,
    aliases,
    normalize_weights = TRUE
) {
  if (!.pamo_is_run_manual(runs)) {
    return(invisible(TRUE))
  }

  if (
    is.null(runs$values) ||
    !inherits(runs$values, "data.frame") ||
    nrow(runs$values) == 0L
  ) {
    stop(
      "Invalid manual weighted-sum design: no run rows are available.",
      call. = FALSE
    )
  }

  required_columns <- paste0("weight_", aliases)

  supplied_weight_columns <- grep(
    "^weight_",
    names(runs$values),
    value = TRUE
  )

  missing_columns <- setdiff(
    required_columns,
    supplied_weight_columns
  )

  if (length(missing_columns) > 0L) {
    stop(
      "Manual weighted-sum design is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unknown_weight_columns <- setdiff(
    supplied_weight_columns,
    required_columns
  )

  if (length(unknown_weight_columns) > 0L) {
    stop(
      "Manual weighted-sum design contains unknown weight column(s): ",
      paste(unknown_weight_columns, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unsupported_columns <- setdiff(
    names(runs$values),
    required_columns
  )

  if (length(unsupported_columns) > 0L) {
    stop(
      "Manual weighted-sum design contains unsupported column(s): ",
      paste(unsupported_columns, collapse = ", "),
      ". Only columns named `weight_<alias>` are allowed.",
      call. = FALSE
    )
  }

  non_numeric <- required_columns[
    !vapply(
      runs$values[required_columns],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric) > 0L) {
    stop(
      "Manual weight column(s) must be numeric: ",
      paste(non_numeric, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  weight_matrix <- as.matrix(
    runs$values[, required_columns, drop = FALSE]
  )

  storage.mode(weight_matrix) <- "double"

  if (anyNA(weight_matrix)) {
    stop(
      "Manual weight columns must not contain missing values.",
      call. = FALSE
    )
  }

  if (any(!is.finite(weight_matrix))) {
    stop(
      "Manual weights must contain only finite values.",
      call. = FALSE
    )
  }

  if (any(weight_matrix < 0)) {
    stop(
      "Manual weights must be non-negative.",
      call. = FALSE
    )
  }

  totals <- rowSums(weight_matrix)

  if (any(totals <= 0)) {
    bad_rows <- which(totals <= 0)

    stop(
      "Each manual weighted-sum run must assign a positive total weight. ",
      "Invalid row(s): ",
      paste(bad_rows, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (!isTRUE(normalize_weights)) {
    tolerance <- sqrt(.Machine$double.eps)
    bad_rows <- which(abs(totals - 1) > tolerance)

    if (length(bad_rows) > 0L) {
      stop(
        paste0(
          "When `normalize_weights = FALSE`, the weights in each manual ",
          "run must sum to one. Invalid row(s): "
        ),
        paste(bad_rows, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}
