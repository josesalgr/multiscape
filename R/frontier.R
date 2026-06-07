#' Find objective-wise extreme solutions
#'
#' @description
#' Identify the observed minimum and maximum values for each objective in a
#' \code{\link{solutionset-class}} object.
#'
#' This function returns the solutions that define the observed range of each
#' selected objective. It also labels each extreme as \code{"best"} or
#' \code{"worst"} according to the registered optimization sense of the
#' objective.
#'
#' @details
#' Objective values are obtained from \code{\link{get_objectives}} with
#' \code{format = "wide"}. Objective senses are obtained from
#' \code{\link{get_objective_specs}}.
#'
#' For objectives with \code{sense = "min"}, the observed minimum is labelled
#' as \code{"best"} and the observed maximum is labelled as \code{"worst"}.
#' For objectives with \code{sense = "max"}, the observed maximum is labelled
#' as \code{"best"} and the observed minimum is labelled as \code{"worst"}.
#'
#' Runs without a stored \code{solution_id} or with missing objective values for
#' the selected objectives are ignored automatically. Therefore, infeasible runs
#' are not considered in the computation.
#'
#' If several solutions have the same extreme value for an objective, the
#' behaviour is controlled by \code{ties}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param objectives Optional character vector of objective names to inspect.
#'   If \code{NULL}, all available objective-value columns are used.
#'
#' @param ties Character. How to handle ties. If \code{"all"}, all tied
#'   solutions are returned. If \code{"first"}, only the first tied solution is
#'   returned.
#'
#' @return A \code{data.frame} with one or more rows per objective. The returned
#'   columns are:
#' \itemize{
#'   \item \code{objective}: objective name;
#'   \item \code{sense}: optimization sense, either \code{"min"} or
#'   \code{"max"};
#'   \item \code{bound}: observed bound, either \code{"min"} or \code{"max"};
#'   \item \code{role}: interpretation of the bound, either \code{"best"} or
#'   \code{"worst"};
#'   \item \code{run_id}: run id of the solution;
#'   \item \code{solution_id}: solution id;
#'   \item \code{value}: objective value at the observed bound.
#' }
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
#'   # Observed minimum and maximum for every objective
#'   frontier_extremes(solutions)
#'
#'   # Inspect only selected objectives
#'   frontier_extremes(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   # Keep only the first solution when several solutions share an extreme
#'   frontier_extremes(
#'     solutions,
#'     ties = "first"
#'   )
#' }
#'
#' @seealso
#' \code{\link{get_objectives}},
#' \code{\link{get_objective_specs}},
#' \code{\link{solution_filter}}
#'
#' @include internal.R
#' @export
frontier_extremes <- function(x,
                              objectives = NULL,
                              ties = c("all", "first")) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  ties <- match.arg(ties)

  vals <- get_objectives(
    x,
    format = "wide",
    feasible_only = FALSE
  )

  if (!inherits(vals, "data.frame") || nrow(vals) == 0L) {
    stop("No objective values are available.", call. = FALSE)
  }

  if (!("run_id" %in% names(vals))) {
    stop("Objective table must contain a 'run_id' column.", call. = FALSE)
  }

  if (!("solution_id" %in% names(vals))) {
    vals$solution_id <- NA_character_
  }

  available <- setdiff(names(vals), c("run_id", "solution_id"))

  if (length(available) == 0L) {
    stop("No objective columns found.", call. = FALSE)
  }

  if (is.null(objectives)) {
    objectives <- available
  } else {
    objectives <- as.character(objectives)
    objectives <- objectives[!is.na(objectives) & nzchar(objectives)]

    if (length(objectives) == 0L) {
      stop("`objectives` must contain at least one objective name.", call. = FALSE)
    }

    bad <- setdiff(objectives, available)

    if (length(bad) > 0L) {
      stop(
        "Unknown objective(s): ",
        paste(bad, collapse = ", "),
        ". Available objectives are: ",
        paste(available, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }

  specs <- get_objective_specs(x)

  if (!all(c("objective", "sense") %in% names(specs))) {
    stop(
      "Objective specifications must contain 'objective' and 'sense' columns.",
      call. = FALSE
    )
  }

  sense <- stats::setNames(as.character(specs$sense), specs$objective)
  sense <- sense[objectives]

  if (anyNA(sense) || any(!nzchar(sense))) {
    missing <- objectives[is.na(sense) | !nzchar(sense)]

    stop(
      "Missing optimization sense for objective(s): ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (!all(sense %in% c("min", "max"))) {
    bad <- objectives[!sense %in% c("min", "max")]

    stop(
      "Invalid optimization sense for objective(s): ",
      paste(bad, collapse = ", "),
      ". Expected 'min' or 'max'.",
      call. = FALSE
    )
  }

  # Keep only stored solutions with complete objective values for the selected
  # objectives. This automatically removes infeasible runs with NA values.
  has_solution <- !is.na(vals$solution_id) & nzchar(vals$solution_id)
  complete_obj <- stats::complete.cases(vals[, objectives, drop = FALSE])

  vals <- vals[has_solution & complete_obj, , drop = FALSE]

  if (nrow(vals) == 0L) {
    stop(
      "No stored solutions with complete objective values are available.",
      call. = FALSE
    )
  }

  eps <- sqrt(.Machine$double.eps)

  out <- lapply(objectives, function(obj) {
    z <- as.numeric(vals[[obj]])
    s <- sense[[obj]]

    min_value <- min(z, na.rm = TRUE)
    max_value <- max(z, na.rm = TRUE)

    min_idx <- which(z <= min_value + eps)
    max_idx <- which(z >= max_value - eps)

    if (identical(ties, "first")) {
      min_idx <- min_idx[1L]
      max_idx <- max_idx[1L]
    }

    min_role <- if (identical(s, "min")) "best" else "worst"
    max_role <- if (identical(s, "min")) "worst" else "best"

    min_out <- data.frame(
      objective = obj,
      sense = s,
      bound = "min",
      role = min_role,
      run_id = vals$run_id[min_idx],
      solution_id = vals$solution_id[min_idx],
      value = z[min_idx],
      stringsAsFactors = FALSE
    )

    max_out <- data.frame(
      objective = obj,
      sense = s,
      bound = "max",
      role = max_role,
      run_id = vals$run_id[max_idx],
      solution_id = vals$solution_id[max_idx],
      value = z[max_idx],
      stringsAsFactors = FALSE
    )

    # If the objective has the same min and max, the same solution may define
    # both bounds. We still return both rows because they represent different
    # roles in the observed objective range.
    rbind(min_out, max_out)
  })

  out <- do.call(rbind, out)
  rownames(out) <- NULL

  out
}


#' Compute distances to observed ideal or nadir points
#'
#' @description
#' Compute normalized distances from each stored solution in a
#' \code{\link{solutionset-class}} object to the observed ideal and/or nadir
#' point in objective space.
#'
#' @details
#' This function supports the interpretation and ranking of trade-offs among
#' solutions stored in a \code{SolutionSet}.
#'
#' The calculations are based on the solutions contained in the supplied
#' object. Therefore, the observed ideal point, observed nadir point, objective
#' ranges, normalized values, and distances may change when the input
#' \code{SolutionSet} is filtered.
#'
#' To calculate distances using only non-dominated solutions, first use:
#'
#' \preformatted{
#' x_nd <- solution_filter(x, nondominated = TRUE)
#' frontier_distances(x_nd)
#' }
#'
#' Objective values are internally transformed to a common minimization space
#' using the objective senses registered in
#' \code{\link{get_objective_specs}}. Objectives with
#' \code{sense = "min"} are kept unchanged, whereas objectives with
#' \code{sense = "max"} are multiplied by \eqn{-1}. In this transformed space,
#' lower values are always better.
#'
#' The observed ideal point is defined by the best observed value for each
#' objective:
#'
#' \deqn{
#' z_j^{ideal} = \min_i z_{ij},
#' }
#'
#' where \eqn{z_{ij}} is the transformed value of solution \eqn{i} for
#' objective \eqn{j}.
#'
#' The observed nadir point is defined by the worst observed value for each
#' objective:
#'
#' \deqn{
#' z_j^{nadir} = \max_i z_{ij}.
#' }
#'
#' These reference points are empirical bounds derived from the supplied
#' solutions. They are not necessarily the true ideal and nadir points of the
#' complete feasible objective space.
#'
#' Objective values are normalized to the interval \eqn{[0,1]} using:
#'
#' \deqn{
#' \tilde{z}_{ij} =
#' \frac{z_{ij} - z_j^{ideal}}
#'      {z_j^{nadir} - z_j^{ideal}}.
#' }
#'
#' After normalization:
#' \itemize{
#'   \item \code{0} represents the best observed value for an objective;
#'   \item \code{1} represents the worst observed value for an objective.
#' }
#'
#' This interpretation is independent of whether the original objective was
#' minimized or maximized.
#'
#' If an objective has zero observed range, all normalized values for that
#' objective are set to zero. The objective therefore does not contribute to
#' the calculated distances.
#'
#' For distances to the ideal point, smaller values are preferred and
#' \code{rank_to_ideal = 1} identifies the closest solution.
#'
#' For distances to the nadir point, larger values are preferred and
#' \code{rank_from_nadir = 1} identifies the solution farthest from the
#' observed nadir point.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param objectives Optional character vector of objective names to use. If
#'   \code{NULL}, all available objective-value columns are used.
#'
#' @param reference Character vector indicating the reference point or points
#'   to use. Allowed values are \code{"ideal"} and \code{"nadir"}. If both are
#'   supplied, distances and ranks for both reference points are returned.
#'   Default is \code{"ideal"}.
#'
#' @param metric Character. Distance metric to use. One of
#'   \code{"euclidean"}, \code{"manhattan"}, or \code{"chebyshev"}.
#'
#' @return A \code{data.frame} with one row per stored solution having complete
#'   values for the selected objectives.
#'
#' The table contains:
#' \itemize{
#'   \item \code{run_id} and \code{solution_id};
#'   \item the original objective values;
#'   \item normalized objective values prefixed with \code{norm_};
#'   \item distance and rank columns for the requested reference points.
#' }
#'
#' The returned table also contains the following attributes:
#' \itemize{
#'   \item \code{"ideal"}: observed ideal point in the original objective
#'   scales;
#'   \item \code{"nadir"}: observed nadir point in the original objective
#'   scales;
#'   \item \code{"ranges"}: observed absolute ranges in the original objective
#'   scales;
#'   \item \code{"objectives"}: objective names used;
#'   \item \code{"sense"}: optimization sense of each objective;
#'   \item \code{"metric"}: distance metric used;
#'   \item \code{"reference"}: requested reference point or points;
#'   \item \code{"normalized"}: whether normalized values were used;
#'   \item \code{"space"}: objective space used for distance calculations.
#' }
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
#'   # Normalized Euclidean distance to the observed ideal point
#'   frontier_distances(solutions)
#'
#'   # Distances to both observed ideal and nadir points
#'   distances <- frontier_distances(
#'     solutions,
#'     reference = c("ideal", "nadir")
#'   )
#'
#'   # Use only selected objectives
#'   frontier_distances(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   # Use Manhattan distance
#'   frontier_distances(
#'     solutions,
#'     metric = "manhattan"
#'   )
#'
#'   # Use Chebyshev distance
#'   frontier_distances(
#'     solutions,
#'     metric = "chebyshev"
#'   )
#'
#'   # Inspect observed reference points and objective ranges
#'   attr(distances, "ideal")
#'   attr(distances, "nadir")
#'   attr(distances, "ranges")
#'
#'   # Calculate distances only over non-dominated solutions
#'   if (requireNamespace("moocore", quietly = TRUE)) {
#'     nondominated_solutions <- solution_filter(
#'       solutions,
#'       feasible_only = TRUE,
#'       nondominated = TRUE
#'     )
#'
#'     frontier_distances(
#'       nondominated_solutions,
#'       reference = c("ideal", "nadir")
#'     )
#'   }
#' }
#'
#' @seealso
#' \code{\link{frontier_extremes}},
#' \code{\link{get_objectives}},
#' \code{\link{get_objective_specs}},
#' \code{\link{solution_filter}}
#'
#' @export
frontier_distances <- function(
    x,
    objectives = NULL,
    reference = "ideal",
    metric = c("euclidean", "manhattan", "chebyshev")
) {
  if (!inherits(x, "SolutionSet")) {
    stop(
      "x must be a SolutionSet object returned by solve().",
      call. = FALSE
    )
  }

  metric <- match.arg(metric)

  reference <- match.arg(
    arg = reference,
    choices = c("ideal", "nadir"),
    several.ok = TRUE
  )

  reference <- unique(reference)

  # Construct the objective matrix in minimization space. Rows with missing
  # objective values are removed internally.
  obj <- .pa_get_objective_matrix(
    x,
    objectives = objectives,
    feasible_only = FALSE,
    minimize = TRUE,
    drop_na = TRUE
  )

  mat <- obj$matrix

  if (!is.matrix(mat) || nrow(mat) == 0L || ncol(mat) == 0L) {
    stop("No objective matrix could be constructed.", call. = FALSE)
  }

  objectives <- obj$objectives

  # Retrieve original objective values for the output and for reporting the
  # reference points in their original scales.
  vals <- get_objectives(
    x,
    format = "wide",
    feasible_only = FALSE
  )

  if (!("run_id" %in% names(vals))) {
    stop(
      "Objective table must contain a 'run_id' column.",
      call. = FALSE
    )
  }

  if (!("solution_id" %in% names(vals))) {
    vals$solution_id <- NA_character_
  }

  # Keep and order exactly the rows retained by .pa_get_objective_matrix().
  keep_key <- paste(obj$run_id, obj$solution_id, sep = "||")
  vals_key <- paste(vals$run_id, vals$solution_id, sep = "||")

  vals <- vals[vals_key %in% keep_key, , drop = FALSE]

  vals_key <- paste(vals$run_id, vals$solution_id, sep = "||")
  vals <- vals[match(keep_key, vals_key), , drop = FALSE]

  if (nrow(vals) != nrow(mat) || anyNA(vals$run_id)) {
    stop(
      paste0(
        "Internal error: objective values and objective matrix ",
        "have incompatible rows."
      ),
      call. = FALSE
    )
  }

  # --------------------------------------------------------------------------
  # Reference points in minimization space
  # --------------------------------------------------------------------------
  ideal_min <- apply(mat, 2, min, na.rm = TRUE)
  nadir_min <- apply(mat, 2, max, na.rm = TRUE)
  ranges_min <- nadir_min - ideal_min

  # --------------------------------------------------------------------------
  # Reference points in the original objective scales
  # --------------------------------------------------------------------------
  original_mat <- as.matrix(vals[, objectives, drop = FALSE])
  storage.mode(original_mat) <- "double"

  sense <- obj$sense[objectives]

  ideal_original <- vapply(
    seq_along(objectives),
    function(j) {
      if (identical(unname(sense[j]), "min")) {
        min(original_mat[, j], na.rm = TRUE)
      } else {
        max(original_mat[, j], na.rm = TRUE)
      }
    },
    numeric(1)
  )

  nadir_original <- vapply(
    seq_along(objectives),
    function(j) {
      if (identical(unname(sense[j]), "min")) {
        max(original_mat[, j], na.rm = TRUE)
      } else {
        min(original_mat[, j], na.rm = TRUE)
      }
    },
    numeric(1)
  )

  ranges_original <- apply(original_mat, 2, function(z) {
    max(z, na.rm = TRUE) - min(z, na.rm = TRUE)
  })

  names(ideal_original) <- objectives
  names(nadir_original) <- objectives
  names(ranges_original) <- objectives

  # --------------------------------------------------------------------------
  # Normalize to [0, 1]
  #
  # 0 = best observed value
  # 1 = worst observed value
  #
  # Objectives with zero range are set to zero and do not contribute to
  # distances.
  # --------------------------------------------------------------------------
  norm_mat <- mat

  for (j in seq_len(ncol(mat))) {
    if (
      is.finite(ranges_min[j]) &&
      abs(ranges_min[j]) > .Machine$double.eps
    ) {
      norm_mat[, j] <-
        (mat[, j] - ideal_min[j]) / ranges_min[j]
    } else {
      norm_mat[, j] <- 0
    }
  }

  colnames(norm_mat) <- paste0("norm_", objectives)

  # --------------------------------------------------------------------------
  # Build output
  # --------------------------------------------------------------------------
  out <- vals[, c("run_id", "solution_id", objectives), drop = FALSE]

  norm_df <- as.data.frame(
    norm_mat,
    stringsAsFactors = FALSE
  )

  rownames(norm_df) <- NULL
  out <- cbind(out, norm_df)

  # --------------------------------------------------------------------------
  # Distance to observed ideal
  # --------------------------------------------------------------------------
  if ("ideal" %in% reference) {
    distance_ideal <- .pa_frontier_distance(
      mat = norm_mat,
      ref = rep(0, ncol(norm_mat)),
      metric = metric
    )

    out$distance_to_ideal <- distance_ideal
    out$rank_to_ideal <- rank(
      distance_ideal,
      ties.method = "min"
    )
  }

  # --------------------------------------------------------------------------
  # Distance from observed nadir
  # --------------------------------------------------------------------------
  if ("nadir" %in% reference) {
    distance_nadir <- .pa_frontier_distance(
      mat = norm_mat,
      ref = rep(1, ncol(norm_mat)),
      metric = metric
    )

    out$distance_to_nadir <- distance_nadir

    # Larger distance means farther from the worst observed point.
    out$rank_from_nadir <- rank(
      -distance_nadir,
      ties.method = "min"
    )
  }

  rownames(out) <- NULL

  # User-facing reference points are stored in the original objective scales.
  attr(out, "ideal") <- ideal_original
  attr(out, "nadir") <- nadir_original
  attr(out, "ranges") <- ranges_original
  attr(out, "objectives") <- objectives
  attr(out, "sense") <- sense
  attr(out, "metric") <- metric
  attr(out, "reference") <- reference
  attr(out, "normalized") <- TRUE
  attr(out, "space") <- "normalized minimization"
  attr(out, "reference_scope") <- "supplied SolutionSet"

  out
}


#' Compute row-wise distances to a reference point
#'
#' @noRd
.pa_frontier_distance <- function(
    mat,
    ref,
    metric = c("euclidean", "manhattan", "chebyshev")
) {
  metric <- match.arg(metric)

  if (!is.matrix(mat)) {
    mat <- as.matrix(mat)
  }

  storage.mode(mat) <- "double"
  ref <- as.numeric(ref)

  if (length(ref) != ncol(mat)) {
    stop(
      paste0(
        "Reference point length must match the number of ",
        "objective columns."
      ),
      call. = FALSE
    )
  }

  if (anyNA(mat) || any(!is.finite(mat))) {
    stop(
      "Objective matrix contains missing or non-finite values.",
      call. = FALSE
    )
  }

  if (anyNA(ref) || any(!is.finite(ref))) {
    stop(
      "Reference point contains missing or non-finite values.",
      call. = FALSE
    )
  }

  dif <- sweep(mat, 2, ref, FUN = "-")
  abs_dif <- abs(dif)

  if (identical(metric, "euclidean")) {
    return(sqrt(rowSums(abs_dif^2)))
  }

  if (identical(metric, "manhattan")) {
    return(rowSums(abs_dif))
  }

  if (identical(metric, "chebyshev")) {
    return(apply(abs_dif, 1, max))
  }

  stop("Unknown distance metric.", call. = FALSE)
}
