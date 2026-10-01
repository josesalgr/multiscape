#' @title Select informative solution contrasts
#'
#' @description
#' Rank pairwise linkage results to identify solution pairs that are especially
#' informative in objective space, decision space, or their relationship.
#'
#' @param x A \code{data.frame} returned by \code{\link{linkage_distances}} or
#'   \code{\link{linkage_turnover}}.
#' @param type Contrast to rank: \code{"objective_similar"},
#'   \code{"decision_similar"}, \code{"high_turnover"},
#'   \code{"high_reconfiguration"}, \code{"low_reconfiguration"}, or
#'   \code{"objective_tie"}.
#' @param n Number of contrasts to return.
#'
#' @details
#' \code{"objective_similar"} ranks pairs by increasing objective distance and
#' uses larger decision distance as a secondary criterion. Conversely,
#' \code{"decision_similar"} ranks pairs by increasing decision distance and
#' then decreasing objective distance. \code{"high_turnover"} ranks pairs by
#' decreasing decision distance.
#'
#' The \code{"high_reconfiguration"} and \code{"low_reconfiguration"} types
#' require a numeric \code{reconfiguration_rate} column, as returned by
#' \code{\link{linkage_turnover}}. Rows with an undefined
#' \code{reconfiguration_rate} are excluded from these rankings.
#'
#' \code{"objective_tie"} returns objective-equivalent pairs with non-zero
#' decision distance, ranked from largest to smallest spatial difference. This
#' type requires the logical \code{objective_tie} column returned by
#' \code{\link{linkage_turnover}}. The numerical tolerance used to identify
#' objective ties is therefore controlled only by \code{linkage_turnover()}.
#'
#' \code{from_solution} and \code{to_solution} must contain positive integer
#' solution ids. Numeric values such as \code{1} are accepted when they are
#' integer-valued and are returned as integers.
#'
#' @return The first \code{n} ranked rows. The columns in \code{x} are
#'   preserved, with \code{contrast_rank} and \code{contrast_type} prepended to
#'   identify the rank and contrast criterion used.
#'
#' @examples
#' # Load a complete simulated multi-action problem.
#' example_data <- load_sim_multiaction()
#'
#' problem <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     example_data$actions,
#'     cost = example_data$action_costs
#'   ) |>
#'   add_effects(
#'     example_data$effect_assumptions
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(
#'     alias = "cost",
#'     include_pu_cost = FALSE
#'   ) |>
#'   add_objective_max_benefit(
#'     alias = "benefit"
#'   ) |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(n = 5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(problem, verbose = FALSE)
#'   solutions <- solve(problem)
#'
#'   linkage <- linkage_distances(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   linkage_contrasts(
#'     linkage,
#'     type = "objective_similar",
#'     n = 3
#'   )
#'
#'   turnover <- linkage_turnover(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   linkage_contrasts(
#'     turnover,
#'     type = "high_reconfiguration",
#'     n = 3
#'   )
#' }
#'
#' @seealso
#' \code{\link{linkage_distances}}, \code{\link{linkage_turnover}}
#' @family Objective--decision linkage
#' @export
linkage_contrasts <- function(
    x,
    type = c(
      "objective_similar",
      "decision_similar",
      "high_turnover",
      "high_reconfiguration",
      "low_reconfiguration",
      "objective_tie"
    ),
    n = 3L
) {
  if (!inherits(x, "data.frame")) {
    stop("`x` must be a linkage data frame.", call. = FALSE)
  }

  required <- c(
    "from_solution",
    "to_solution",
    "objective_distance",
    "decision_distance"
  )
  missing <- setdiff(required, names(x))

  if (length(missing) > 0L) {
    stop(
      "`x` is missing required column(s): ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  type <- match.arg(type)

  if (
    length(n) != 1L ||
    !is.numeric(n) ||
    is.na(n) ||
    !is.finite(n) ||
    n < 1 ||
    n != floor(n) ||
    n > .Machine$integer.max
  ) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  n <- as.integer(n)

  if (
    !is.numeric(x$from_solution) ||
    !is.numeric(x$to_solution)
  ) {
    stop(
      "`from_solution` and `to_solution` must be numeric solution ids.",
      call. = FALSE
    )
  }

  valid_solution_ids <- function(ids) {
    !anyNA(ids) &&
      all(is.finite(ids)) &&
      all(ids >= 1) &&
      all(ids == floor(ids)) &&
      all(ids <= .Machine$integer.max)
  }

  if (
    !valid_solution_ids(x$from_solution) ||
    !valid_solution_ids(x$to_solution)
  ) {
    stop(
      "`from_solution` and `to_solution` must contain positive integer solution ids.",
      call. = FALSE
    )
  }

  x$from_solution <- as.integer(x$from_solution)
  x$to_solution <- as.integer(x$to_solution)

  if (
    !is.numeric(x$objective_distance) ||
    anyNA(x$objective_distance) ||
    any(!is.finite(x$objective_distance)) ||
    any(x$objective_distance < 0)
  ) {
    stop(
      "`objective_distance` must contain finite, non-negative numbers.",
      call. = FALSE
    )
  }

  if (
    !is.numeric(x$decision_distance) ||
    anyNA(x$decision_distance) ||
    any(!is.finite(x$decision_distance)) ||
    any(x$decision_distance < 0) ||
    any(x$decision_distance > 1)
  ) {
    stop(
      "`decision_distance` must contain finite numbers between zero and one.",
      call. = FALSE
    )
  }

  if (type %in% c("high_reconfiguration", "low_reconfiguration")) {
    if (!("reconfiguration_rate" %in% names(x))) {
      stop(
        "`type = \"", type,
        "\"` requires a `reconfiguration_rate` column; ",
        "use `linkage_turnover()` first.",
        call. = FALSE
      )
    }

    if (
      !is.numeric(x$reconfiguration_rate) ||
      any(
        !is.na(x$reconfiguration_rate) &
        (
          !is.finite(x$reconfiguration_rate) |
          x$reconfiguration_rate < 0
        )
      )
    ) {
      stop(
        "`reconfiguration_rate` must contain non-negative finite numbers or `NA`.",
        call. = FALSE
      )
    }
  }

  if (identical(type, "objective_tie")) {
    if (!("objective_tie" %in% names(x))) {
      stop(
        "`type = \"objective_tie\"` requires an `objective_tie` column; ",
        "use `linkage_turnover()` first.",
        call. = FALSE
      )
    }

    if (!is.logical(x$objective_tie) || anyNA(x$objective_tie)) {
      stop(
        "`objective_tie` must be a logical column without missing values.",
        call. = FALSE
      )
    }
  }

  ord <- switch(
    type,
    objective_similar = order(
      x$objective_distance,
      -x$decision_distance,
      x$from_solution,
      x$to_solution
    ),
    decision_similar = order(
      x$decision_distance,
      -x$objective_distance,
      x$from_solution,
      x$to_solution
    ),
    high_turnover = order(
      -x$decision_distance,
      x$objective_distance,
      x$from_solution,
      x$to_solution
    ),
    high_reconfiguration = {
      candidates <- which(!is.na(x$reconfiguration_rate))
      candidates[order(
        -x$reconfiguration_rate[candidates],
        x$objective_distance[candidates],
        x$from_solution[candidates],
        x$to_solution[candidates]
      )]
    },
    low_reconfiguration = {
      candidates <- which(!is.na(x$reconfiguration_rate))
      candidates[order(
        x$reconfiguration_rate[candidates],
        -x$objective_distance[candidates],
        x$from_solution[candidates],
        x$to_solution[candidates]
      )]
    },
    objective_tie = {
      candidates <- which(
        x$objective_tie &
          x$decision_distance > 0
      )
      candidates[order(
        -x$decision_distance[candidates],
        x$objective_distance[candidates],
        x$from_solution[candidates],
        x$to_solution[candidates]
      )]
    }
  )

  keep <- utils::head(ord, min(n, length(ord)))
  out <- x[keep, , drop = FALSE]
  out$contrast_rank <- seq_len(nrow(out))
  out$contrast_type <- rep(type, nrow(out))
  out <- out[, c(
    "contrast_rank",
    "contrast_type",
    setdiff(names(out), c("contrast_rank", "contrast_type"))
  ), drop = FALSE]

  attr(out, "type") <- type
  rownames(out) <- NULL
  out
}

#' @title Compare objective and decision distances
#'
#' @description
#' Measure separately how far pairs of stored solutions are in objective space
#' and how much their planning-unit/action assignments differ.
#'
#' @details
#' Objective values are oriented to minimization and normalized using the
#' solutions retained in the supplied \code{SolutionSet}. Decision distances
#' are always calculated on the complete planning-unit/action assignment space
#' represented by the supplied solutions.
#'
#' If \code{pairs = NULL}, all unordered pairs are generated and oriented from
#' worse to better on the first selected objective. If \code{pairs} is supplied,
#' its \code{from_solution} and \code{to_solution} direction is preserved.
#' Distances are symmetric, but signed objective changes and action additions or
#' removals depend on pair direction.
#'
#' No combined linkage score is calculated.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param objectives Optional character vector with two or more unique objective
#'   aliases. If \code{NULL}, all registered objectives are used.
#' @param pairs Either \code{NULL}, or a non-empty \code{data.frame} containing
#'   numeric positive-integer \code{from_solution} and \code{to_solution}
#'   columns. Output from \code{\link{frontier_neighbors}} can be supplied
#'   directly.
#' @param objective_metric Objective-space distance metric:
#'   \code{"euclidean"}, \code{"manhattan"}, or \code{"chebyshev"}.
#' @param decision_metric Decision-space metric: \code{"jaccard"} or
#'   \code{"hamming"}.
#'
#' @return A \code{data.frame} with one row per directed pair, including
#'   \code{objective_distance}, \code{decision_similarity},
#'   \code{decision_distance}, decision-change counts, and objective-specific
#'   from/to values, changes, and improvements.
#'
#' @examples
#' # Load a complete simulated multi-action problem.
#' example_data <- load_sim_multiaction()
#'
#' problem <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     example_data$actions,
#'     cost = example_data$action_costs
#'   ) |>
#'   add_effects(
#'     example_data$effect_assumptions
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(
#'     alias = "cost",
#'     include_pu_cost = FALSE
#'   ) |>
#'   add_objective_max_benefit(
#'     alias = "benefit"
#'   ) |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(n = 5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(problem, verbose = FALSE)
#'   solutions <- solve(problem)
#'
#'   linkage <- linkage_distances(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   head(linkage)
#'
#'   neighbors <- frontier_neighbors(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   linkage_distances(
#'     solutions,
#'     objectives = c("cost", "benefit"),
#'     pairs = neighbors
#'   )
#' }
#'
#' @seealso
#' \code{\link{frontier_neighbors}}, \code{\link{frontier_distances}},
#' \code{\link{selection_similarity}}, \code{\link{linkage_transition}}
#' @family Objective--decision linkage
#' @export
linkage_distances <- function(
    x,
    objectives = NULL,
    pairs = NULL,
    objective_metric = c("euclidean", "manhattan", "chebyshev"),
    decision_metric = c("jaccard", "hamming")
) {
  objective_metric <- match.arg(objective_metric)
  decision_metric <- match.arg(decision_metric)

  obj <- .pa_linkage_objectives(x, objectives)
  pairs_missing <- is.null(pairs)

  pair_idx <- .pa_prepare_linkage_pairs(
    obj$solution_id,
    pairs
  )

  if (pairs_missing) {
    swap <- vapply(seq_len(nrow(pair_idx)), function(i) {
      from <- pair_idx[i, 1L]
      to <- pair_idx[i, 2L]

      first_from <- obj$minimize[from, 1L]
      first_to <- obj$minimize[to, 1L]

      first_from < first_to ||
        (
          first_from == first_to &&
            as.integer(obj$solution_id[from]) >
            as.integer(obj$solution_id[to])
        )
    }, logical(1))

    if (any(swap)) {
      pair_idx[swap, ] <- pair_idx[swap, 2:1, drop = FALSE]
    }
  }

  selection <- .pa_get_selection_matrix(x)[
    as.character(obj$solution_id),
    ,
    drop = FALSE
  ]

  states <- get_solution_states(x)

  objective_rows <- .pa_linkage_pair_objectives(
    obj,
    pair_idx[, 1L],
    pair_idx[, 2L]
  )

  objective_changes <- abs(
    obj$normalized[pair_idx[, 2L], , drop = FALSE] -
      obj$normalized[pair_idx[, 1L], , drop = FALSE]
  )

  objective_rows$objective_distance <- switch(
    objective_metric,
    euclidean = sqrt(rowSums(objective_changes^2)),
    manhattan = rowSums(objective_changes),
    chebyshev = apply(objective_changes, 1L, max)
  )

  decision_rows <- lapply(seq_len(nrow(pair_idx)), function(i) {
    from <- pair_idx[i, 1L]
    to <- pair_idx[i, 2L]

    a <- selection[from, , drop = TRUE] > 0
    b <- selection[to, , drop = TRUE] > 0

    if (length(a) == 0L) {
      similarity <- 1
    } else if (identical(decision_metric, "jaccard")) {
      union_count <- sum(a | b)
      similarity <- if (union_count == 0L) 1 else sum(a & b) / union_count
    } else {
      similarity <- mean(a == b)
    }

    pu_change <- .pa_planning_unit_changes(
      states,
      obj$solution_id[from],
      obj$solution_id[to]
    )


    data.frame(
      decision_similarity = similarity,
      decision_distance = 1 - similarity,
      changed_assignments = as.integer(sum(a != b)),
      changed_planning_units = as.integer(sum(pu_change$changed)),
      additions = as.integer(sum(!a & b)),
      removals = as.integer(sum(a & !b)),
      activated_planning_units = as.integer(
        sum(pu_change$transition == "activated")
      ),
      deactivated_planning_units = as.integer(
        sum(pu_change$transition == "deactivated")
      ),
      action_switches = as.integer(
        sum(pu_change$transition == "switched")
      ),
      composition_changes = as.integer(
        sum(pu_change$transition == "composition_changed")
      ),
      stringsAsFactors = FALSE
    )
  })

  decision_rows <- do.call(rbind, decision_rows)

  out <- cbind(
    objective_rows,
    decision_rows
  )

  out <- out[, c(
    "from_solution",
    "to_solution",
    "objective_distance",
    "decision_similarity",
    "decision_distance",
    "changed_assignments",
    "changed_planning_units",
    "additions",
    "removals",
    "activated_planning_units",
    "deactivated_planning_units",
    "action_switches",
    "composition_changes",
    setdiff(
      names(objective_rows),
      c("from_solution", "to_solution", "objective_distance")
    )
  ), drop = FALSE]

  attr(out, "objective_metric") <- objective_metric
  attr(out, "decision_metric") <- decision_metric

  attr(out, "objectives") <- obj$objectives
  attr(out, "ideal") <- obj$ideal
  attr(out, "nadir") <- obj$nadir
  attr(out, "ranges") <- obj$ranges
  attr(out, "reference_scope") <- "supplied SolutionSet"

  rownames(out) <- NULL
  out
}


# Internal helpers -----------------------------------------------------------

.pa_linkage_objectives <- function(
    x,
    objectives = NULL,
    minimum_objectives = 2L
) {
  if (!inherits(x, "SolutionSet")) {
    stop("x must be a SolutionSet object returned by solve().", call. = FALSE)
  }

  if (
    length(minimum_objectives) != 1L ||
    !is.numeric(minimum_objectives) ||
    is.na(minimum_objectives) ||
    !is.finite(minimum_objectives) ||
    minimum_objectives < 1L ||
    minimum_objectives != floor(minimum_objectives)
  ) {
    stop(
      "Internal error: `minimum_objectives` must be a positive integer.",
      call. = FALSE
    )
  }

  minimum_objectives <- as.integer(minimum_objectives)

  if (!is.null(objectives)) {
    if (
      !is.character(objectives) ||
      length(objectives) < minimum_objectives
    ) {
      objective_word <- if (minimum_objectives == 1L) {
        "one or more aliases"
      } else if (minimum_objectives == 2L) {
        "at least two aliases"
      } else {
        paste0("at least ", minimum_objectives, " aliases")
      }

      stop(
        paste0(
          "`objectives` must be NULL or a character vector with ",
          objective_word,
          "."
        ),
        call. = FALSE
      )
    }

    if (anyNA(objectives) || any(!nzchar(objectives))) {
      stop(
        "`objectives` must not contain missing or empty aliases.",
        call. = FALSE
      )
    }

    if (anyDuplicated(objectives)) {
      stop(
        "`objectives` must contain unique aliases.",
        call. = FALSE
      )
    }
  }

  obj <- .pa_get_objective_matrix(
    x,
    objectives = objectives,
    minimize = TRUE,
    drop_na = TRUE,
    minimum_objectives = minimum_objectives
  )

  keep <- !is.na(obj$solution_id) &
    nzchar(as.character(obj$solution_id))

  if (!any(keep)) {
    stop(
      "No stored solutions with complete objective values are available.",
      call. = FALSE
    )
  }

  mat <- obj$matrix[keep, , drop = FALSE]
  solution_id <- obj$solution_id[keep]

  if (
    !is.numeric(solution_id) ||
    anyNA(solution_id) ||
    any(!is.finite(solution_id)) ||
    any(solution_id < 1) ||
    any(solution_id != floor(solution_id)) ||
    any(solution_id > .Machine$integer.max)
  ) {
    stop(
      "Stored solution ids must be positive integers.",
      call. = FALSE
    )
  }

  solution_id <- as.integer(solution_id)

  if (anyDuplicated(solution_id)) {
    stop(
      "Stored solution ids are not unique in the objective table.",
      call. = FALSE
    )
  }

  normalized_info <- .pa_normalize_min_objective_matrix(mat)

  original <- mat
  max_cols <- which(obj$sense[obj$objectives] == "max")

  if (length(max_cols) > 0L) {
    original[, max_cols] <- -original[, max_cols, drop = FALSE]
  }

  solution_names <- as.character(solution_id)
  rownames(original) <- solution_names
  rownames(mat) <- solution_names
  rownames(normalized_info$matrix) <- solution_names

  sense <- obj$sense[obj$objectives]

  ideal <- normalized_info$ideal
  nadir <- normalized_info$nadir

  max_names <- obj$objectives[sense == "max"]

  if (length(max_names) > 0L) {
    ideal[max_names] <- -ideal[max_names]
    nadir[max_names] <- -nadir[max_names]
  }

  list(
    solution_id = solution_id,
    objectives = obj$objectives,
    sense = sense,
    original = original,
    minimize = mat,
    normalized = normalized_info$matrix,
    ideal = ideal,
    nadir = nadir,
    ranges = normalized_info$ranges
  )
}


.pa_linkage_pair_objectives <- function(obj, from, to) {
  out <- data.frame(
    from_solution = obj$solution_id[from],
    to_solution = obj$solution_id[to],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  for (j in seq_along(obj$objectives)) {
    objective <- obj$objectives[j]

    from_value <- obj$original[from, j]
    to_value <- obj$original[to, j]
    change <- to_value - from_value
    improvement <- if (obj$sense[j] == "min") -change else change

    out[[paste0("from_", objective)]] <- from_value
    out[[paste0("to_", objective)]] <- to_value
    out[[paste0("delta_", objective)]] <- change
    out[[paste0("improvement_", objective)]] <- improvement
  }

  out
}


.pa_prepare_linkage_pairs <- function(solution_ids, pairs = NULL) {
  if (
    !is.numeric(solution_ids) ||
    anyNA(solution_ids) ||
    any(!is.finite(solution_ids)) ||
    any(solution_ids < 1) ||
    any(solution_ids != floor(solution_ids)) ||
    any(solution_ids > .Machine$integer.max)
  ) {
    stop(
      "Stored solution ids must be positive integers.",
      call. = FALSE
    )
  }

  solution_ids <- as.integer(solution_ids)
  n <- length(solution_ids)

  if (is.null(pairs)) {
    if (n < 2L) {
      stop("At least two stored solutions are required.", call. = FALSE)
    }

    return(t(utils::combn(seq_len(n), 2L)))
  }

  if (!inherits(pairs, "data.frame")) {
    stop(
      "`pairs` must be NULL or a data frame with directed solution pairs.",
      call. = FALSE
    )
  }

  if (nrow(pairs) == 0L) {
    stop("`pairs` must contain at least one row.", call. = FALSE)
  }

  required <- c("from_solution", "to_solution")

  if (!all(required %in% names(pairs))) {
    stop(
      "`pairs` must contain `from_solution` and `to_solution`.",
      call. = FALSE
    )
  }

  pair_ids <- pairs[, required, drop = FALSE]

  if (!is.numeric(pair_ids$from_solution) ||
      !is.numeric(pair_ids$to_solution)) {
    stop(
      "`from_solution` and `to_solution` in `pairs` must be numeric solution ids.",
      call. = FALSE
    )
  }

  valid_ids <- function(ids) {
    !anyNA(ids) &&
      all(is.finite(ids)) &&
      all(ids >= 1) &&
      all(ids == floor(ids)) &&
      all(ids <= .Machine$integer.max)
  }

  if (!valid_ids(pair_ids$from_solution) ||
      !valid_ids(pair_ids$to_solution)) {
    stop(
      "`pairs` must contain positive integer solution ids.",
      call. = FALSE
    )
  }

  from_id <- as.integer(pair_ids$from_solution)
  to_id <- as.integer(pair_ids$to_solution)

  from <- match(from_id, solution_ids)
  to <- match(to_id, solution_ids)

  if (anyNA(from) || anyNA(to)) {
    bad <- unique(c(
      from_id[is.na(from)],
      to_id[is.na(to)]
    ))

    stop(
      "Unknown solution id(s) in `pairs`: ",
      paste(bad, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (any(from == to)) {
    stop("A solution cannot be paired with itself.", call. = FALSE)
  }

  key <- paste(from_id, to_id, sep = "\r")

  if (anyDuplicated(key)) {
    stop(
      "`pairs` contains duplicate directed pairs.",
      call. = FALSE
    )
  }

  cbind(from, to)
}

.pa_planning_unit_changes <- function(states, from_id, to_id) {
  from_states <- states[
    states$solution_id == as.integer(from_id),
    ,
    drop = FALSE
  ]

  to_states <- states[
    states$solution_id == as.integer(to_id),
    ,
    drop = FALSE
  ]

  pu <- union(from_states$pu, to_states$pu)

  from_match <- match(
    as.character(pu),
    as.character(from_states$pu)
  )

  to_match <- match(
    as.character(pu),
    as.character(to_states$pu)
  )

  from_state <- from_states$state[from_match]
  to_state <- to_states$state[to_match]

  from_state[is.na(from_state)] <- "unmanaged"
  to_state[is.na(to_state)] <- "unmanaged"

  from_n <- from_states$n_actions[from_match]
  to_n <- to_states$n_actions[to_match]

  from_n[is.na(from_n)] <- 0L
  to_n[is.na(to_n)] <- 0L

  from_managed <- from_n > 0L
  to_managed <- to_n > 0L
  changed <- from_state != to_state

  transition <- ifelse(
    !changed,
    "unchanged",
    ifelse(
      !from_managed & to_managed,
      "activated",
      ifelse(
        from_managed & !to_managed,
        "deactivated",
        ifelse(
          from_n == 1L & to_n == 1L,
          "switched",
          "composition_changed"
        )
      )
    )
  )

  data.frame(
    pu = pu,
    from_state = from_state,
    to_state = to_state,
    from_managed = from_managed,
    to_managed = to_managed,
    n_actions_from = as.integer(from_n),
    n_actions_to = as.integer(to_n),
    changed = changed,
    transition = transition,
    stringsAsFactors = FALSE
  )
}

#' @title Describe the transition between two solutions
#'
#' @description
#' Explain the objective and spatial changes required to transform one stored
#' solution into another.
#'
#' @details
#' The transition is directional. Reversing \code{from} and \code{to} reverses
#' signed objective changes, additions and removals, and planning-unit
#' activations and deactivations. Canonical planning-unit states are obtained
#' from \code{\link{get_solution_states}}.
#'
#' The complete landscape is always returned in \code{transitions}, including
#' planning units whose state is unchanged. To keep the action-level output
#' compact, \code{actions} contains assignments selected in at least one of the
#' two solutions; added, removed, and retained actions remain explicit.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param from A single numeric positive-integer id identifying the starting
#'   stored solution.
#' @param to A single numeric positive-integer id identifying the destination
#'   stored solution.
#' @param objectives Optional character vector with one or more objective
#'   aliases. If \code{NULL}, all registered objectives are reported.
#'
#' @return An object of class \code{multiscape_linkage_transition} containing:
#' \itemize{
#'   \item \code{summary}: the directed solution ids and transition counts;
#'   \item \code{objectives}: objective values and signed changes;
#'   \item \code{transitions}: one row per planning unit in the complete
#'   landscape, including unchanged units;
#'   \item \code{actions}: action assignments selected in either solution;
#'   \item \code{state_matrix}: counts of planning-unit state transitions.
#' }
#'
#' @examples
#' # Load a complete simulated multi-action problem.
#' example_data <- load_sim_multiaction()
#'
#' problem <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     example_data$actions,
#'     cost = example_data$action_costs
#'   ) |>
#'   add_effects(
#'     example_data$effect_assumptions
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(
#'     alias = "cost",
#'     include_pu_cost = FALSE
#'   ) |>
#'   add_objective_max_benefit(
#'     alias = "benefit"
#'   ) |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(n = 5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(problem, verbose = FALSE)
#'   solutions <- solve(problem)
#'
#'   neighbors <- frontier_neighbors(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   transition <- linkage_transition(
#'     solutions,
#'     from = neighbors$from_solution[1],
#'     to = neighbors$to_solution[1],
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   transition$summary
#'   transition$objectives
#'
#'   transition$transitions[
#'     transition$transitions$changed,
#'     ,
#'     drop = FALSE
#'   ]
#' }
#'
#' @seealso
#' \code{\link{get_solution_states}}, \code{\link{linkage_distances}},
#' \code{\link{frontier_neighbors}}
#' @family Objective--decision linkage
#' @export
linkage_transition <- function(
    x,
    from,
    to,
    objectives = NULL
) {
  valid_id <- function(value) {
    length(value) == 1L &&
      is.numeric(value) &&
      !is.na(value) &&
      is.finite(value) &&
      value >= 1 &&
      value == floor(value) &&
      value <= .Machine$integer.max
  }

  if (!valid_id(from)) {
    stop(
      "`from` must be a single numeric positive-integer solution id.",
      call. = FALSE
    )
  }

  if (!valid_id(to)) {
    stop(
      "`to` must be a single numeric positive-integer solution id.",
      call. = FALSE
    )
  }

  from <- as.integer(from)
  to <- as.integer(to)

  obj <- .pa_linkage_objectives(
    x,
    objectives,
    minimum_objectives = 1L
  )

  pair_idx <- .pa_prepare_linkage_pairs(
    obj$solution_id,
    data.frame(
      from_solution = from,
      to_solution = to
    )
  )

  from_id <- obj$solution_id[pair_idx[1L, 1L]]
  to_id <- obj$solution_id[pair_idx[1L, 2L]]

  objective_table <- data.frame(
    objective = obj$objectives,
    sense = unname(obj$sense),
    from_value = as.numeric(
      obj$original[pair_idx[1L, 1L], ]
    ),
    to_value = as.numeric(
      obj$original[pair_idx[1L, 2L], ]
    ),
    stringsAsFactors = FALSE
  )

  objective_table$change <-
    objective_table$to_value -
    objective_table$from_value

  objective_table$improvement <- ifelse(
    objective_table$sense == "min",
    -objective_table$change,
    objective_table$change
  )

  objective_table$normalized_improvement <- as.numeric(
    obj$normalized[pair_idx[1L, 1L], ] -
      obj$normalized[pair_idx[1L, 2L], ]
  )

  states <- get_solution_states(x)

  transition_table <- .pa_planning_unit_changes(
    states,
    from_id,
    to_id
  )

  selection <- .pa_get_selection_long(x)

  from_actions <- selection[
    selection$solution_id == as.character(from_id),
    ,
    drop = FALSE
  ]

  to_actions <- selection[
    selection$solution_id == as.character(to_id),
    ,
    drop = FALSE
  ]

  assignment_key_from <- paste(
    from_actions$pu,
    from_actions$action,
    sep = "\r"
  )

  assignment_key_to <- paste(
    to_actions$pu,
    to_actions$action,
    sep = "\r"
  )

  assignment_keys <- union(
    assignment_key_from,
    assignment_key_to
  )

  from_selected <- from_actions$selected[
    match(assignment_keys, assignment_key_from)
  ]

  to_selected <- to_actions$selected[
    match(assignment_keys, assignment_key_to)
  ]

  from_selected[is.na(from_selected)] <- 0L
  to_selected[is.na(to_selected)] <- 0L

  key_parts <- strsplit(
    assignment_keys,
    "\r",
    fixed = TRUE
  )

  action_table <- data.frame(
    pu = vapply(
      key_parts,
      function(z) z[1L],
      character(1)
    ),
    action = vapply(
      key_parts,
      function(z) z[2L],
      character(1)
    ),
    from_selected = as.integer(from_selected),
    to_selected = as.integer(to_selected),
    stringsAsFactors = FALSE
  )

  action_table <- action_table[
    action_table$from_selected > 0L |
      action_table$to_selected > 0L,
    ,
    drop = FALSE
  ]

  action_table$transition <- ifelse(
    action_table$from_selected == 1L &
      action_table$to_selected == 1L,
    "retained",
    ifelse(
      action_table$to_selected == 1L,
      "added",
      "removed"
    )
  )

  action_table <- action_table[
    order(
      as.character(action_table$pu),
      as.character(action_table$action)
    ),
    ,
    drop = FALSE
  ]

  rownames(action_table) <- NULL

  if (nrow(action_table) > 0L && nrow(transition_table) > 0L) {
    action_pu_match <- match(
      as.character(action_table$pu),
      as.character(transition_table$pu)
    )

    if (anyNA(action_pu_match)) {
      stop(
        "Action assignments could not be matched to planning-unit transitions.",
        call. = FALSE
      )
    }

    action_table$pu <-
      transition_table$pu[action_pu_match]
  }

  action_sets <- function(type) {
    out <- rep(
      NA_character_,
      nrow(transition_table)
    )

    selected <- action_table[
      action_table$transition == type,
      ,
      drop = FALSE
    ]

    if (
      nrow(selected) == 0L ||
      nrow(transition_table) == 0L
    ) {
      return(out)
    }

    values <- vapply(
      split(
        selected$action,
        as.character(selected$pu)
      ),
      function(z) {
        paste(
          sort(unique(z)),
          collapse = "+"
        )
      },
      character(1)
    )

    matched <- match(
      as.character(transition_table$pu),
      names(values)
    )

    out[!is.na(matched)] <-
      unname(values[matched[!is.na(matched)]])

    out
  }

  transition_table$added_actions <-
    action_sets("added")

  transition_table$removed_actions <-
    action_sets("removed")

  transition_table$retained_actions <-
    action_sets("retained")

  state_matrix <- table(
    from_state = transition_table$from_state,
    to_state = transition_table$to_state
  )

  summary <- data.frame(
    from_solution = as.integer(from_id),
    to_solution = as.integer(to_id),
    n_planning_units = as.integer(nrow(transition_table)),
    changed_planning_units = as.integer(sum(transition_table$changed)),
    unchanged_planning_units = as.integer(sum(!transition_table$changed)),
    activated_planning_units = as.integer(
      sum(transition_table$transition == "activated")
    ),
    deactivated_planning_units = as.integer(
      sum(transition_table$transition == "deactivated")
    ),
    action_switches = as.integer(
      sum(transition_table$transition == "switched")
    ),
    composition_changes = as.integer(
      sum(transition_table$transition == "composition_changed")
    ),
    additions = as.integer(sum(action_table$transition == "added")),
    removals = as.integer(sum(action_table$transition == "removed")),
    stringsAsFactors = FALSE
  )

  out <- list(
    summary = summary,
    objectives = objective_table,
    transitions = transition_table,
    actions = action_table,
    state_matrix = state_matrix
  )


  class(out) <- c(
    "multiscape_linkage_transition",
    "list"
  )

  out
}

#' @title Measure decision turnover along an objective-space neighborhood
#'
#' @description
#' Measure decision-space change between selected solution pairs and relate it
#' to their normalized objective-space distance.
#'
#' @details
#' Decision turnover is the \code{decision_distance} returned by
#' \code{\link{linkage_distances}}. The reconfiguration rate relates that
#' turnover to normalized objective-space separation:
#' \deqn{R_{rs} = d_X(r,s) / d_Z(r,s).}
#' It is a unitless ratio, not a temporal rate or a percentage of landscape
#' area. No additional \code{turnover} column is returned because it would
#' duplicate \code{decision_distance}.
#'
#' A pair is an objective tie when \code{objective_distance <= tolerance}.
#' Tied pairs receive \code{NA_real_} for \code{reconfiguration_rate},
#' including pairs with identical decisions, avoiding undefined or infinite
#' ratios. Non-tied pairs with identical decisions receive a rate of zero.
#'
#' If \code{pairs = NULL}, neighboring pairs are generated with
#' \code{\link{frontier_neighbors}} using \code{method = "auto"} and the
#' requested \code{objective_metric}. Supplied pairs preserve their direction.
#' Reconfiguration rates should be compared only among analyses using the same
#' objectives, supplied \code{SolutionSet}, normalization basis, and distance
#' metrics.
#'
#' @param x A \code{\link{solutionset-class}} object returned by
#'   \code{\link{solve}}.
#' @param objectives Optional character vector with two or more unique
#'   objective aliases. If \code{NULL}, objectives stored on \code{pairs} are
#'   reused when available; otherwise all registered objectives are used.
#' @param pairs Either \code{NULL}, or a non-empty \code{data.frame}
#'   containing numeric positive-integer \code{from_solution} and
#'   \code{to_solution} columns. Output from
#'   \code{\link{frontier_neighbors}} can be supplied directly.
#' @param objective_metric Objective-space metric: \code{"euclidean"},
#'   \code{"manhattan"}, or \code{"chebyshev"}. The metric is also used
#'   to generate neighbors when \code{pairs = NULL}.
#' @param decision_metric Decision-space metric over the complete
#'   planning-unit/action assignment space: \code{"jaccard"} or
#'   \code{"hamming"}.
#' @param tolerance A single finite non-negative number. Pairs whose normalized
#'   objective distance is less than or equal to this value are treated as
#'   objective ties.
#'
#' @return A \code{data.frame} extending the output of
#'   \code{\link{linkage_distances}} with logical \code{objective_tie} and
#'   numeric \code{reconfiguration_rate} columns. Decision turnover is the
#'   existing \code{decision_distance} column.
#'
#' @examples
#' # Load a complete simulated multi-action problem.
#' example_data <- load_sim_multiaction()
#'
#' problem <- create_problem(
#'   pu = example_data$planning_units,
#'   features = example_data$features,
#'   dist_features = example_data$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     example_data$actions,
#'     cost = example_data$action_costs
#'   ) |>
#'   add_effects(
#'     example_data$effect_assumptions
#'   ) |>
#'   add_constraint_targets_relative(0.05) |>
#'   add_objective_min_cost(
#'     alias = "cost",
#'     include_pu_cost = FALSE
#'   ) |>
#'   add_objective_max_benefit(
#'     alias = "benefit"
#'   ) |>
#'   set_method_weighted_sum(
#'     aliases = c("cost", "benefit"),
#'     runs = set_runs_grid(n = 5),
#'     normalize_weights = TRUE
#'   )
#'
#' if (requireNamespace("rcbc", quietly = TRUE)) {
#'   problem <- set_solver_cbc(problem, verbose = FALSE)
#'   solutions <- solve(problem)
#'
#'   neighbors <- frontier_neighbors(
#'     solutions,
#'     objectives = c("cost", "benefit")
#'   )
#'
#'   turnover <- linkage_turnover(
#'     solutions,
#'     objectives = c("cost", "benefit"),
#'     pairs = neighbors
#'   )
#'
#'   turnover
#'
#'   turnover[
#'     turnover$objective_tie &
#'       turnover$decision_distance > 0,
#'     ,
#'     drop = FALSE
#'   ]
#' }
#'
#' @seealso
#' \code{\link{frontier_neighbors}}, \code{\link{linkage_distances}},
#' \code{\link{linkage_contrasts}}
#' @family Objective--decision linkage
#' @export
linkage_turnover <- function(
    x,
    objectives = NULL,
    pairs = NULL,
    objective_metric = c("euclidean", "manhattan", "chebyshev"),
    decision_metric = c("jaccard", "hamming"),
    tolerance = sqrt(.Machine$double.eps)
) {
  objective_metric <- match.arg(objective_metric)
  decision_metric <- match.arg(decision_metric)

  if (
    length(tolerance) != 1L ||
    !is.numeric(tolerance) ||
    is.na(tolerance) ||
    !is.finite(tolerance) ||
    tolerance < 0
  ) {
    stop(
      "`tolerance` must be a single, finite, non-negative number.",
      call. = FALSE
    )
  }

  if (is.null(pairs)) {
    pairs <- frontier_neighbors(
      x,
      objectives = objectives,
      method = "auto",
      metric = objective_metric
    )
  }

  if (is.null(objectives)) {
    pair_objectives <- attr(
      pairs,
      "objectives",
      exact = TRUE
    )

    if (!is.null(pair_objectives)) {
      objectives <- pair_objectives
    }
  }

  out <- linkage_distances(
    x,
    objectives = objectives,
    pairs = pairs,
    objective_metric = objective_metric,
    decision_metric = decision_metric
  )

  distance_attributes <- attributes(out)[
    setdiff(
      names(attributes(out)),
      c("names", "row.names", "class")
    )
  ]

  out$objective_tie <-
    out$objective_distance <= tolerance

  out$reconfiguration_rate <- ifelse(
    out$objective_tie,
    NA_real_,
    out$decision_distance /
      out$objective_distance
  )

  leading <- c(
    "from_solution",
    "to_solution",
    "objective_distance",
    "decision_similarity",
    "decision_distance",
    "objective_tie",
    "reconfiguration_rate"
  )

  out <- out[, c(
    leading,
    setdiff(names(out), leading)
  ), drop = FALSE]

  for (attribute_name in names(distance_attributes)) {
    attr(out, attribute_name) <-
      distance_attributes[[attribute_name]]
  }

  attr(out, "tolerance") <- tolerance
  attr(out, "method") <- attr(
    pairs,
    "method",
    exact = TRUE
  )
  attr(out, "method_requested") <- attr(
    pairs,
    "method_requested",
    exact = TRUE
  )

  rownames(out) <- NULL
  out
}
