#' Calculate selection frequency across solutions
#'
#' @description
#' Calculate how frequently each planning-unit/action assignment is selected
#' across the stored solutions in a
#' \code{\link{solutionset-class}} object.
#'
#' @details
#' Selection frequency is calculated at the planning-unit/action level. This is
#' the canonical decision representation used by this function because it
#' preserves differences between solutions that select the same planning unit
#' but assign different actions.
#'
#' For each planning-unit/action pair, the frequency is:
#'
#' \deqn{
#' f_{ia} =
#' \frac{\sum_{s \in S} x_{ias}}
#'      {|S|},
#' }
#'
#' where \eqn{x_{ias}} equals one when planning unit \eqn{i} receives action
#' \eqn{a} in solution \eqn{s}, and zero otherwise.
#'
#' The result is computed over all stored solutions in the supplied
#' \code{SolutionSet}. To calculate frequencies for only a subset of solutions,
#' first use \code{\link{solution_filter}} or
#' \code{\link{solution_unique}}.
#'
#' For simple conservation-planning problems without explicit actions,
#' selected planning units are represented using the canonical action name
#' \code{"conservation"}.
#'
#' Selection frequency measures recurrence across the supplied solutions. It
#' should not automatically be interpreted as formal irreplaceability because
#' it depends on the solutions included, their sampling across objective space,
#' and whether duplicate or dominated solutions have been retained.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @return A \code{data.frame} with one row per planning-unit/action pair and
#'   the following columns:
#' \itemize{
#'   \item \code{pu}: planning-unit identifier;
#'   \item \code{action}: action identifier or name;
#'   \item \code{n_selected}: number of stored solutions in which the
#'   planning-unit/action pair is selected;
#'   \item \code{n_solutions}: total number of stored solutions considered;
#'   \item \code{frequency}: proportion of stored solutions in which the pair
#'   is selected.
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
#'
#'   # Frequency across all stored solutions
#'   frequency <- selection_frequency(solutions)
#'   frequency
#'
#'   # Restrict the analysis to non-dominated solutions
#'   if (requireNamespace("moocore", quietly = TRUE)) {
#'     nondominated_solutions <- solution_filter(
#'       solutions,
#'       feasible_only = TRUE,
#'       nondominated = TRUE
#'     )
#'
#'     selection_frequency(nondominated_solutions)
#'   }
#'
#'   # Give each distinct decision configuration the same weight
#'   unique_solutions <- solution_unique(
#'     solutions,
#'     by = "decisions"
#'   )
#'
#'   unique_frequency <- selection_frequency(
#'     unique_solutions
#'   )
#'
#'   unique_frequency
#' }
#'
#' @seealso
#' \code{\link{selection_similarity}},
#' \code{\link{solution_filter}},
#' \code{\link{solution_unique}},
#' \code{\link{get_actions}},
#' \code{\link{get_pu}}
#'
#' @export
selection_frequency <- function(x) {
  if (!inherits(x, "SolutionSet")) {
    stop(
      "x must be a SolutionSet object returned by solve().",
      call. = FALSE
    )
  }

  selection <- .pa_get_selection_long(x)

  solution_ids <- .pa_get_stored_solution_ids(x)
  n_solutions <- length(solution_ids)

  if (n_solutions == 0L) {
    stop(
      "No stored solutions are available.",
      call. = FALSE
    )
  }

  pair_key <- paste(
    selection$pu,
    selection$action,
    sep = "\r"
  )

  pair_levels <- unique(pair_key)

  n_selected <- vapply(
    pair_levels,
    function(key) {
      rows <- pair_key == key
      sum(selection$selected[rows] > 0)
    },
    numeric(1)
  )

  first_row <- match(pair_levels, pair_key)

  out <- data.frame(
    pu = selection$pu[first_row],
    action = selection$action[first_row],
    n_selected = as.integer(n_selected),
    n_solutions = rep.int(
      as.integer(n_solutions),
      length(pair_levels)
    ),
    frequency = as.numeric(n_selected) / n_solutions,
    stringsAsFactors = FALSE
  )

  out <- out[
    order(
      as.character(out$pu),
      as.character(out$action)
    ),
    ,
    drop = FALSE
  ]

  rownames(out) <- NULL
  out
}


#' Calculate structural similarity among solutions
#'
#' @description
#' Calculate pairwise structural similarity among the stored solutions in a
#' \code{\link{solutionset-class}} object.
#'
#' @details
#' Solutions are compared using their complete planning-unit/action assignment
#' vectors. Consequently, two solutions that select the same planning unit but
#' assign different actions are treated as structurally different.
#'
#' For simple conservation-planning problems without explicit actions,
#' selected planning units are represented using the canonical action name
#' \code{"conservation"}.
#'
#' Two similarity metrics are supported:
#'
#' \itemize{
#'   \item \code{"jaccard"} compares the sets of selected planning-unit/action
#'   assignments:
#'
#'   \deqn{
#'   J(A,B) =
#'   \frac{|A \cap B|}
#'        {|A \cup B|}.
#'   }
#'
#'   Jaccard similarity focuses on selected assignments and ignores joint
#'   absences. It is generally the preferred metric for sparse conservation and
#'   management portfolios.
#'
#'   \item \code{"hamming"} calculates the proportion of decision-vector
#'   positions that are equal:
#'
#'   \deqn{
#'   H(A,B) =
#'   \frac{1}{m}
#'   \sum_{k=1}^{m} I(A_k = B_k),
#'   }
#'
#'   where \eqn{m} is the number of feasible planning-unit/action assignments.
#'   Unlike Jaccard similarity, Hamming similarity includes shared
#'   non-selections.
#' }
#'
#' For both metrics, similarity ranges from zero to one:
#' \itemize{
#'   \item \code{1} indicates identical assignment structures;
#'   \item \code{0} indicates no structural agreement under the selected
#'   metric.
#' }
#'
#' The corresponding distance is calculated as:
#'
#' \deqn{
#' D(A,B) = 1 - S(A,B).
#' }
#'
#' The comparison is performed over all stored solutions in the supplied
#' object. To compare only a subset, first use
#' \code{\link{solution_filter}} or \code{\link{solution_unique}}.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#'
#' @param metric Character. Similarity metric to use. One of
#'   \code{"jaccard"} or \code{"hamming"}.
#'
#' @param format Character. Output format. If \code{"long"}, return one row per
#'   pair of solutions. If \code{"matrix"}, return a symmetric similarity
#'   matrix with solution ids as row and column names.
#'
#' @return
#' If \code{format = "long"}, a \code{data.frame} with columns:
#' \itemize{
#'   \item \code{solution_id_1};
#'   \item \code{solution_id_2};
#'   \item \code{similarity};
#'   \item \code{distance}.
#' }
#'
#' If \code{format = "matrix"}, a symmetric numeric matrix of similarities is
#' returned. Its diagonal is equal to one.
#'
#' The selected metric is stored in the \code{"metric"} attribute.
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
#'
#'   # Pairwise Jaccard similarity in long format
#'   jaccard_long <- selection_similarity(
#'     solutions
#'   )
#'
#'   jaccard_long
#'
#'   # Symmetric Jaccard similarity matrix
#'   jaccard_matrix <- selection_similarity(
#'     solutions,
#'     format = "matrix"
#'   )
#'
#'   jaccard_matrix
#'
#'   # Hamming similarity includes shared non-selections
#'   hamming_long <- selection_similarity(
#'     solutions,
#'     metric = "hamming"
#'   )
#'
#'   hamming_long
#'
#'   # Compare only structurally unique solutions
#'   unique_solutions <- solution_unique(
#'     solutions,
#'     by = "decisions"
#'   )
#'
#'   selection_similarity(
#'     unique_solutions,
#'     format = "matrix"
#'   )
#' }
#'
#' @seealso
#' \code{\link{selection_frequency}},
#' \code{\link{solution_filter}},
#' \code{\link{solution_unique}},
#' \code{\link{get_actions}},
#' \code{\link{get_pu}}
#'
#' @export
selection_similarity <- function(
    x,
    metric = c("jaccard", "hamming"),
    format = c("long", "matrix")
) {
  if (!inherits(x, "SolutionSet")) {
    stop(
      "x must be a SolutionSet object returned by solve().",
      call. = FALSE
    )
  }

  metric <- match.arg(metric)
  format <- match.arg(format)

  selection_matrix <- .pa_get_selection_matrix(x)

  if (
    !is.matrix(selection_matrix) ||
    nrow(selection_matrix) == 0L
  ) {
    stop(
      "No stored solution assignments are available.",
      call. = FALSE
    )
  }

  if (nrow(selection_matrix) == 1L) {
    similarity_matrix <- matrix(
      1,
      nrow = 1L,
      ncol = 1L,
      dimnames = list(
        rownames(selection_matrix),
        rownames(selection_matrix)
      )
    )
  } else {
    n <- nrow(selection_matrix)

    similarity_matrix <- matrix(
      NA_real_,
      nrow = n,
      ncol = n,
      dimnames = list(
        rownames(selection_matrix),
        rownames(selection_matrix)
      )
    )

    diag(similarity_matrix) <- 1

    for (i in seq_len(n - 1L)) {
      for (j in seq.int(i + 1L, n)) {
        a <- selection_matrix[i, ] > 0
        b <- selection_matrix[j, ] > 0

        if (identical(metric, "jaccard")) {
          union_count <- sum(a | b)

          similarity <- if (union_count == 0L) {
            1
          } else {
            sum(a & b) / union_count
          }
        } else {
          similarity <- mean(a == b)
        }

        similarity_matrix[i, j] <- similarity
        similarity_matrix[j, i] <- similarity
      }
    }
  }

  attr(similarity_matrix, "metric") <- metric

  if (identical(format, "matrix")) {
    return(similarity_matrix)
  }

  solution_ids <- rownames(similarity_matrix)

  if (length(solution_ids) < 2L) {
    out <- data.frame(
      solution_id_1 = character(0),
      solution_id_2 = character(0),
      similarity = numeric(0),
      distance = numeric(0),
      stringsAsFactors = FALSE
    )

    attr(out, "metric") <- metric
    return(out)
  }

  idx <- which(
    upper.tri(similarity_matrix),
    arr.ind = TRUE
  )

  out <- data.frame(
    solution_id_1 = solution_ids[idx[, "row"]],
    solution_id_2 = solution_ids[idx[, "col"]],
    similarity = similarity_matrix[idx],
    distance = 1 - similarity_matrix[idx],
    stringsAsFactors = FALSE
  )

  rownames(out) <- NULL
  attr(out, "metric") <- metric

  out
}


#' Get stored solution ids
#'
#' @noRd
.pa_get_stored_solution_ids <- function(x) {
  runs <- x$solution$runs %||% NULL

  if (is.null(runs) || !inherits(runs, "data.frame")) {
    stop(
      "No run table found in x$solution$runs.",
      call. = FALSE
    )
  }

  if (!("solution_id" %in% names(runs))) {
    stop(
      paste0(
        "Run table must contain a 'solution_id' column. ",
        "Recreate the SolutionSet using the current version of multiscape."
      ),
      call. = FALSE
    )
  }

  solution_ids <- runs$solution_id
  solution_ids <- solution_ids[
    !is.na(solution_ids) & solution_ids >= 1L
  ]

  unique(as.character(solution_ids))
}


#' Build the canonical planning-unit/action selection table
#'
#' @description
#' Internal helper that returns one row per solution and planning-unit/action
#' pair. The returned table contains explicit zero and one selections.
#'
#' @noRd
.pa_get_selection_long <- function(x) {
  solution_ids <- .pa_get_stored_solution_ids(x)

  if (length(solution_ids) == 0L) {
    stop(
      "No stored solutions are available.",
      call. = FALSE
    )
  }

  # Prefer the action-level summary because it preserves the complete
  # planning-unit/action assignment.
  action_data <- tryCatch(
    get_actions(x),
    error = function(e) NULL
  )

  selection <- NULL

  if (
    !is.null(action_data) &&
    inherits(action_data, "data.frame") &&
    nrow(action_data) > 0L
  ) {
    pu_col <- .pa_find_selection_column(
      action_data,
      candidates = c(
        "pu",
        "id",
        "planning_unit",
        "planning_unit_id"
      ),
      label = "planning-unit"
    )

    action_col <- .pa_find_selection_column(
      action_data,
      candidates = c(
        "action",
        "action_name",
        "name"
      ),
      label = "action"
    )

    selected_col <- .pa_find_selection_column(
      action_data,
      candidates = c(
        "selected",
        "value"
      ),
      label = "selection"
    )

    if (!("solution_id" %in% names(action_data))) {
      stop(
        "Action results must contain a 'solution_id' column.",
        call. = FALSE
      )
    }

    selection <- data.frame(
      solution_id = as.character(action_data$solution_id),
      pu = action_data[[pu_col]],
      action = as.character(action_data[[action_col]]),
      selected = as.numeric(action_data[[selected_col]]),
      stringsAsFactors = FALSE
    )
  }

  # Fall back to planning-unit results for the implicit simple conservation
  # model.
  if (is.null(selection)) {
    pu_data <- tryCatch(
      get_pu(x),
      error = function(e) NULL
    )

    if (
      is.null(pu_data) ||
      !inherits(pu_data, "data.frame") ||
      nrow(pu_data) == 0L
    ) {
      stop(
        paste0(
          "No planning-unit/action results are available. ",
          "Expected get_actions() or get_pu() to return stored selections."
        ),
        call. = FALSE
      )
    }

    pu_col <- .pa_find_selection_column(
      pu_data,
      candidates = c(
        "pu",
        "id",
        "planning_unit",
        "planning_unit_id"
      ),
      label = "planning-unit"
    )

    selected_col <- .pa_find_selection_column(
      pu_data,
      candidates = c(
        "selected",
        "value"
      ),
      label = "selection"
    )

    if (!("solution_id" %in% names(pu_data))) {
      stop(
        "Planning-unit results must contain a 'solution_id' column.",
        call. = FALSE
      )
    }

    selection <- data.frame(
      solution_id = as.character(pu_data$solution_id),
      pu = pu_data[[pu_col]],
      action = rep(
        "conservation",
        nrow(pu_data)
      ),
      selected = as.numeric(pu_data[[selected_col]]),
      stringsAsFactors = FALSE
    )
  }

  selection <- selection[
    selection$solution_id %in% solution_ids,
    ,
    drop = FALSE
  ]

  if (nrow(selection) == 0L) {
    stop(
      "No selection rows correspond to stored solutions.",
      call. = FALSE
    )
  }

  if (
    anyNA(selection$pu) ||
    anyNA(selection$action) ||
    any(!nzchar(selection$action))
  ) {
    stop(
      "Selection data contain missing planning-unit or action identifiers.",
      call. = FALSE
    )
  }

  if (
    anyNA(selection$selected) ||
    any(!is.finite(selection$selected))
  ) {
    stop(
      "Selection data contain missing or non-finite selection values.",
      call. = FALSE
    )
  }

  # Convert any positive decision value to a binary selection.
  selection$selected <- as.integer(selection$selected > 0)

  # Collapse accidental duplicate rows for the same solution and assignment.
  key <- paste(
    selection$solution_id,
    selection$pu,
    selection$action,
    sep = "\r"
  )

  if (anyDuplicated(key)) {
    split_rows <- split(
      seq_len(nrow(selection)),
      key
    )

    selection <- do.call(
      rbind,
      lapply(
        split_rows,
        function(idx) {
          data.frame(
            solution_id = selection$solution_id[idx[1L]],
            pu = selection$pu[idx[1L]],
            action = selection$action[idx[1L]],
            selected = as.integer(
              any(selection$selected[idx] > 0)
            ),
            stringsAsFactors = FALSE
          )
        }
      )
    )

    rownames(selection) <- NULL
  }

  # Construct the complete solution x PU-action grid so that missing rows are
  # interpreted as zero selections.
  pair_data <- unique(
    selection[, c("pu", "action"), drop = FALSE]
  )

  grid <- merge(
    data.frame(
      solution_id = solution_ids,
      stringsAsFactors = FALSE
    ),
    pair_data,
    by = NULL,
    sort = FALSE
  )

  grid_key <- paste(
    grid$solution_id,
    grid$pu,
    grid$action,
    sep = "\r"
  )

  selection_key <- paste(
    selection$solution_id,
    selection$pu,
    selection$action,
    sep = "\r"
  )

  idx <- match(grid_key, selection_key)

  grid$selected <- 0L

  matched <- !is.na(idx)

  grid$selected[matched] <-
    selection$selected[idx[matched]]

  grid <- grid[
    order(
      match(grid$solution_id, solution_ids),
      as.character(grid$pu),
      as.character(grid$action)
    ),
    ,
    drop = FALSE
  ]

  rownames(grid) <- NULL
  grid
}


#' Build a binary solution-by-assignment matrix
#'
#' @noRd
.pa_get_selection_matrix <- function(x) {
  selection <- .pa_get_selection_long(x)
  solution_ids <- .pa_get_stored_solution_ids(x)

  assignment_key <- paste(
    selection$pu,
    selection$action,
    sep = "::"
  )

  assignment_ids <- unique(assignment_key)

  mat <- matrix(
    0L,
    nrow = length(solution_ids),
    ncol = length(assignment_ids),
    dimnames = list(
      solution_ids,
      assignment_ids
    )
  )

  row_idx <- match(
    selection$solution_id,
    solution_ids
  )

  col_idx <- match(
    assignment_key,
    assignment_ids
  )

  mat[
    cbind(row_idx, col_idx)
  ] <- selection$selected

  storage.mode(mat) <- "integer"
  mat
}


#' Find a column in a selection-result table
#'
#' @noRd
.pa_find_selection_column <- function(
    x,
    candidates,
    label
) {
  found <- intersect(candidates, names(x))

  if (length(found) == 0L) {
    stop(
      "Could not identify the ",
      label,
      " column. Expected one of: ",
      paste(candidates, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  found[1L]
}
