#' Configure group-equity data
#'
#' @description
#' Configure how groups previously registered with [add_groups()] enter equity
#' metrics. `add_groups()` remains the sole source of the group catalogue and
#' available-area denominators; this function adds only action-specific
#' contribution coefficients and equity-population choices.
#' Groups with no selected amount remain part of the equity population. Groups
#' that must not be evaluated (for example, structurally locked-in owners) can
#' be removed explicitly with `exclude_groups`.
#'
#' @param x A [Problem] object.
#' @param dist_group_actions A data frame with columns `pu`, `group`, `action`, and
#'   an amount column. Rows describe how much of a group is affected when an
#'   action is selected in a planning unit.
#' @param amount_col Name of the amount column in `dist_group_actions`.
#' @param area_unit Unit of the action-specific amounts. Group denominators are
#'   already stored internally in square metres by [add_groups()].
#' @param fixed_amounts Optional named numeric vector of group amounts that
#'   contribute irrespective of decision variables, expressed in `area_unit`.
#'   Do not use this when they are already represented by locked decisions.
#' @param actions Optional action ids or action sets to include. `NULL` uses all
#'   actions represented in `group_actions`.
#' @param exclude_groups Optional group ids excluded from all equity metrics.
#' @param name Name of the equity population.
#'
#' @return A modified [Problem] object.
#' @export
add_group_equity <- function(
    x,
    dist_group_actions,
    amount_col = "area",
    area_unit = c("m2", "ha", "km2"),
    fixed_amounts = NULL,
    actions = NULL,
    exclude_groups = NULL,
    name = "group_equity"
) {
  stopifnot(inherits(x, "Problem"))
  area_unit <- match.arg(area_unit)
  if (is.null(x$data$groups) || !is.data.frame(x$data$groups) ||
      is.null(x$data$dist_groups) || !is.data.frame(x$data$dist_groups)) {
    stop("Call `add_groups()` before `add_group_equity()`.", call. = FALSE)
  }
  if (!is.data.frame(dist_group_actions) || nrow(dist_group_actions) == 0L) {
    stop("`dist_group_actions` must be a non-empty data frame.", call. = FALSE)
  }
  req_ga <- c("pu", "group", "action", amount_col)
  if (!all(req_ga %in% names(dist_group_actions))) {
    stop("`dist_group_actions` must contain: ", paste(req_ga, collapse = ", "), ".", call. = FALSE)
  }

  amount <- .pa_group_area_to_m2(dist_group_actions[[amount_col]], area_unit)
  if (any(!is.finite(amount) | amount < 0)) {
    stop("All group-action amounts must be finite and non-negative.", call. = FALSE)
  }
  known <- as.character(x$data$groups$id)
  positive_dist <- x$data$dist_groups[x$data$dist_groups$area > 0, , drop = FALSE]
  if (!nrow(positive_dist)) stop("No groups have positive available area.", call. = FALSE)
  available_df <- stats::aggregate(area ~ group, data = positive_dist, FUN = sum)
  available <- stats::setNames(available_df$area, as.character(available_df$group))
  eligible <- known[known %in% names(available)]
  excluded <- unique(as.character(exclude_groups))
  excluded <- excluded[!is.na(excluded) & nzchar(excluded)]
  unknown_excluded <- setdiff(excluded, known)
  if (length(unknown_excluded)) {
    stop("Unknown `exclude_groups`: ", paste(unknown_excluded, collapse = ", "), ".", call. = FALSE)
  }

  included <- setdiff(eligible, excluded)
  if (!length(included)) stop("The equity population is empty.", call. = FALSE)

  fixed <- stats::setNames(rep(0, length(known)), known)
  if (!is.null(fixed_amounts)) {
    if (!is.numeric(fixed_amounts) || is.null(names(fixed_amounts)) ||
        anyNA(names(fixed_amounts)) || any(!nzchar(names(fixed_amounts)))) {
      stop("`fixed_amounts` must be a named numeric vector.", call. = FALSE)
    }
    bad_fixed <- setdiff(names(fixed_amounts), known)
    if (length(bad_fixed)) stop("Unknown groups in `fixed_amounts`: ", paste(bad_fixed, collapse = ", "), ".", call. = FALSE)
    fixed[names(fixed_amounts)] <- .pa_group_area_to_m2(fixed_amounts, area_unit)
  }
  if (any(!is.finite(fixed) | fixed < 0)) stop("Fixed amounts must be finite and non-negative.", call. = FALSE)

  totals <- data.frame(
    group = eligible,
    available_amount = unname(available[eligible]),
    fixed_amount = unname(fixed[eligible]),
    included = eligible %in% included,
    stringsAsFactors = FALSE
  )
  if (any(totals$fixed_amount > totals$available_amount + sqrt(.Machine$double.eps))) {
    stop("A fixed amount cannot exceed the available group area from `add_groups()`.", call. = FALSE)
  }

  ga <- data.frame(
    pu = dist_group_actions$pu,
    group = as.character(dist_group_actions$group),
    action = as.character(dist_group_actions$action),
    amount = amount,
    stringsAsFactors = FALSE
  )
  unknown_pu <- setdiff(unique(ga$pu), x$data$pu$id)
  if (length(unknown_pu)) {
    stop("Unknown planning units in `dist_group_actions`: ",
         paste(utils::head(unknown_pu, 20), collapse = ", "), ".", call. = FALSE)
  }
  unknown_actions <- setdiff(unique(ga$action), as.character(x$data$actions$id))
  if (length(unknown_actions)) {
    stop("Unknown actions in `dist_group_actions`: ", paste(unknown_actions, collapse = ", "), ".", call. = FALSE)
  }
  unknown_groups <- setdiff(unique(ga$group), known)
  if (length(unknown_groups)) {
    stop("Groups in `dist_group_actions` were not registered by `add_groups()`: ",
         paste(utils::head(unknown_groups, 20), collapse = ", "), ".", call. = FALSE)
  }

  action_ids <- NULL
  if (!is.null(actions)) {
    action_ids <- as.character(.pa_resolve_action_subset(x, actions)$id)
    ga <- ga[ga$action %in% action_ids, , drop = FALSE]
    if (nrow(ga) == 0L) stop("`actions` matched no group-action rows.", call. = FALSE)
  }

  x <- .pa_clone_data(x)
  x$data$group_equity <- list(
    name = as.character(name)[1],
    group_actions = ga,
    group_totals = totals,
    actions = action_ids,
    excluded_groups = excluded,
    unavailable_groups = setdiff(known, eligible),
    denominator_source = "dist_groups"
  )
  x
}

#' Minimize the mean relative contribution across groups
#'
#' @param x A [Problem] configured with [add_group_equity()].
#' @param alias Optional objective alias for multi-objective methods.
#' @return A modified [Problem] object.
#' @export
add_objective_min_group_mean <- function(x, alias = NULL) {
  stopifnot(inherits(x, "Problem"))
  if (is.null(x$data$group_equity)) {
    stop("Call `add_group_equity()` before adding a group-equity objective.", call. = FALSE)
  }
  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeGroupMean",
    objective_id = "min_group_mean",
    objective_args = list(equity_name = x$data$group_equity$name),
    sense = "min",
    alias = alias
  )
}

#' Constrain the mean relative contribution across groups
#'
#' @param x A [Problem] configured with [add_group_equity()].
#' @param mean Desired mean relative contribution, in `[0, 1]`.
#' @param tolerance Symmetric tolerance around `mean`.
#' @param lower Optional explicit lower bound. Overrides `mean - tolerance`.
#' @param upper Optional explicit upper bound. Overrides `mean + tolerance`.
#' @param name Constraint name.
#' @return A modified [Problem] object.
#' @export
add_constraint_group_mean <- function(
    x,
    mean,
    tolerance = 0,
    lower = NULL,
    upper = NULL,
    name = "group_mean"
) {
  stopifnot(inherits(x, "Problem"))
  if (is.null(x$data$group_equity)) {
    stop("Call `add_group_equity()` before adding a group-mean constraint.", call. = FALSE)
  }
  mean <- as.numeric(mean)[1]
  tolerance <- as.numeric(tolerance)[1]
  if (!is.finite(mean) || mean < 0 || mean > 1) stop("`mean` must be in [0, 1].", call. = FALSE)
  if (!is.finite(tolerance) || tolerance < 0) stop("`tolerance` must be non-negative.", call. = FALSE)
  lo <- if (is.null(lower)) mean - tolerance else as.numeric(lower)[1]
  hi <- if (is.null(upper)) mean + tolerance else as.numeric(upper)[1]
  lo <- max(0, lo)
  hi <- min(1, hi)
  if (!is.finite(lo) || !is.finite(hi) || lo > hi) {
    stop("The requested group-mean interval is invalid.", call. = FALSE)
  }

  x <- .pa_clone_data(x)
  x$data$constraints <- x$data$constraints %||% list()
  old <- x$data$constraints$group_mean %||% data.frame()
  row <- data.frame(name = as.character(name)[1], lower = lo, upper = hi,
                    stringsAsFactors = FALSE)
  x$data$constraints$group_mean <- if (nrow(old)) rbind(old, row) else row
  x
}

#' Minimize the numerator of the Gini coefficient across groups
#'
#' @description
#' Minimize `sum_{g<h} abs(p_g - p_h)`, where `p_g` is the selected amount of
#' group `g` divided by its available amount. If the group mean is fixed, this
#' is equivalent to minimizing the Gini coefficient.
#'
#' @param x A [Problem] configured with [add_group_equity()].
#' @param normalize If `TRUE`, minimize the mean pairwise absolute difference
#'   `2 D / n^2`; this has the same optimizer as the raw numerator `D`.
#' @param alias Optional objective alias for multi-objective methods.
#' @return A modified [Problem] object.
#' @export
add_objective_min_group_gini_numerator <- function(x, normalize = FALSE, alias = NULL) {
  stopifnot(inherits(x, "Problem"))
  if (is.null(x$data$group_equity)) {
    stop("Call `add_group_equity()` before adding a group-equity objective.", call. = FALSE)
  }
  .pa_set_active_and_register_objective(
    x = x,
    model_type = "minimizeGroupGiniNumerator",
    objective_id = "min_group_gini_numerator",
    objective_args = list(
      equity_name = x$data$group_equity$name,
      normalize = isTRUE(normalize)
    ),
    sense = "min",
    alias = alias
  )
}

#' Constrain the numerator of the Gini coefficient across groups
#'
#' @description
#' Adds an upper bound on `sum_{g<h} abs(p_g - p_h)`. This is useful for a
#' sequential workflow: first minimize the Gini numerator, then retain that
#' equity result while optimizing other objectives.
#'
#' @param x A [Problem] configured with [add_group_equity()].
#' @param upper Maximum raw Gini numerator.
#' @param tolerance Non-negative numerical allowance added to `upper`.
#' @param name Constraint name.
#' @return A modified [Problem] object.
#' @export
add_constraint_group_gini_numerator <- function(
    x,
    upper,
    tolerance = 0,
    name = "group_gini_numerator"
) {
  stopifnot(inherits(x, "Problem"))
  if (is.null(x$data$group_equity)) {
    stop("Call `add_group_equity()` before adding a Gini-numerator constraint.", call. = FALSE)
  }
  upper <- as.numeric(upper)[1]
  tolerance <- as.numeric(tolerance)[1]
  if (!is.finite(upper) || upper < 0) {
    stop("`upper` must be finite and non-negative.", call. = FALSE)
  }
  if (!is.finite(tolerance) || tolerance < 0) {
    stop("`tolerance` must be finite and non-negative.", call. = FALSE)
  }

  x <- .pa_clone_data(x)
  x$data$constraints <- x$data$constraints %||% list()
  old <- x$data$constraints$group_gini_numerator %||% data.frame()
  row <- data.frame(
    name = as.character(name)[1],
    upper = upper + tolerance,
    stringsAsFactors = FALSE
  )
  x$data$constraints$group_gini_numerator <- if (nrow(old)) rbind(old, row) else row
  x
}

#' Summarize group equity in a solved solution
#'
#' @param x A solved `Solution` or `SolutionSet` whose problem contains a
#'   group-equity configuration.
#' @param solution Optional solution id when `x` is a `SolutionSet`. It may be
#'   omitted when the set contains exactly one solution.
#' @return A list with group-level shares and population metrics: mean, mean
#'   absolute deviation from the mean, raw Gini numerator, mean pairwise
#'   absolute difference, and Gini coefficient.
#' @export
get_group_equity_metrics <- function(x, solution = NULL) {
  if (inherits(x, "SolutionSet")) {
    sols <- x$solution$solutions %||% list()
    if (!length(sols)) stop("The SolutionSet contains no stored solutions.", call. = FALSE)
    if (is.null(solution)) {
      if (length(sols) != 1L) {
        stop("`solution` must be supplied when the SolutionSet has multiple solutions.", call. = FALSE)
      }
      sol <- sols[[1L]]
    } else {
      key <- as.character(solution)[1]
      if (!is.null(names(sols)) && key %in% names(sols)) {
        sol <- sols[[key]]
      } else {
        pos <- as.integer(solution)[1]
        if (is.na(pos) || pos < 1L || pos > length(sols)) stop("Unknown `solution`.", call. = FALSE)
        sol <- sols[[pos]]
      }
    }
    if (is.null(sol$problem)) sol$problem <- x$problem
    x <- sol
  }
  if (!inherits(x, "Solution")) stop("`x` must be a Solution or SolutionSet.", call. = FALSE)
  problem <- x$problem %||% NULL
  if (is.null(problem) || !inherits(problem, "Problem")) {
    stop("The Solution does not retain its source Problem.", call. = FALSE)
  }
  reg <- problem$data$model_registry$vars$group_equity %||% NULL
  if (is.null(reg)) stop("The solved model has no group-equity variables.", call. = FALSE)
  sol <- .pamo_get_solution_vector(x)
  cols <- as.integer(reg$share_cols_0based) + 1L
  if (length(sol) < max(cols)) stop("The solution vector lacks group-share values.", call. = FALSE)
  share <- pmax(0, pmin(1, as.numeric(sol[cols])))
  n <- length(share)
  mu <- mean(share)
  d <- if (n >= 2L) sum(abs(outer(share, share, "-")[upper.tri(matrix(0, n, n))])) else 0
  gini <- if (mu <= sqrt(.Machine$double.eps)) 0 else d / (n^2 * mu)
  groups <- data.frame(
    group = as.character(reg$groups),
    share = share,
    selected_amount = share * as.numeric(reg$available_amount),
    available_amount = as.numeric(reg$available_amount),
    stringsAsFactors = FALSE
  )
  list(
    groups = groups,
    n_groups = n,
    excluded_groups = problem$data$group_equity$excluded_groups %||% character(0),
    mean = mu,
    mad_from_mean = mean(abs(share - mu)),
    gini_numerator = d,
    mean_pairwise_absolute_difference = 2 * d / n^2,
    gini = gini
  )
}

# Internal -----------------------------------------------------------------

.pa_has_group_equity <- function(x) {
  !is.null(x$data$group_equity) && is.list(x$data$group_equity)
}

.pa_prepare_group_equity_model <- function(x) {
  stopifnot(inherits(x, "Problem"))
  if (!.pa_has_group_equity(x)) return(x)
  if (is.null(x$data$model_ptr)) stop("Model pointer missing while preparing group equity.", call. = FALSE)

  eq <- x$data$group_equity
  totals <- eq$group_totals
  totals <- totals[totals$included, , drop = FALSE]
  totals <- totals[order(totals$group), , drop = FALSE]
  n_group <- nrow(totals)
  if (n_group == 0L) stop("The configured equity population is empty.", call. = FALSE)

  da <- x$data$dist_actions_model
  if (is.null(da) || !is.data.frame(da) || nrow(da) == 0L) {
    stop("Group equity requires non-empty action decisions.", call. = FALSE)
  }
  for (nm in c("pu", "action", "internal_row")) {
    if (!(nm %in% names(da))) stop("`dist_actions_model` lacks `", nm, "`.", call. = FALSE)
  }

  ga <- eq$group_actions
  ga <- ga[ga$group %in% totals$group, , drop = FALSE]
  matched <- merge(
    ga,
    da[, c("pu", "action", "internal_row"), drop = FALSE],
    by = c("pu", "action"), all = FALSE, sort = FALSE
  )
  if (nrow(ga) && nrow(matched) == 0L) {
    stop("No configured group-action amounts match feasible decision variables.", call. = FALSE)
  }

  m0 <- .pa_model_from_ptr(x$data$model_ptr, args = x$data$model_args %||% list(),
                           drop_triplets = TRUE)
  n_old <- length(m0$obj)
  x0 <- as.integer(m0$x_offset %||% x$data$model_list$x_offset %||% NA_integer_)
  if (!is.finite(x0)) {
    x <- .pa_refresh_model_snapshot(x)
    x0 <- as.integer(x$data$model_list$x_offset)
  }

  p_names <- paste0("group_share[", totals$group, "]")
  rcpp_model_add_columns(
    x = x$data$model_ptr, obj = rep(0, n_group), lb = rep(0, n_group),
    ub = rep(1, n_group), vtype = rep("C", n_group), names = p_names,
    block_name = "group_equity_share", tag = eq$name
  )
  p_cols <- seq.int(n_old, length.out = n_group)

  # p_g - sum(q_iag / A_g) x_ia = fixed_g / A_g
  for (g in seq_len(n_group)) {
    gid <- totals$group[g]
    rows <- matched[matched$group == gid & matched$amount != 0, , drop = FALSE]
    idx <- p_cols[g]
    coef <- 1
    if (nrow(rows)) {
      idx <- c(idx, x0 + as.integer(rows$internal_row) - 1L)
      coef <- c(coef, -as.numeric(rows$amount) / totals$available_amount[g])
    }
    x <- .pa_add_linear_constraint(
      x, var_index_0based = idx, coeff = coef, sense = "==",
      rhs = totals$fixed_amount[g] / totals$available_amount[g],
      name = paste0("group_share_link_", gid), block_name = "group_equity_link",
      tag = gid, refresh_snapshot = FALSE
    )
  }

  needs <- x$data$model_args$needs %||% list()
  active_gini <- identical(x$data$model_args$model_type, "minimizeGroupGiniNumerator")
  has_gini_constraint <- !is.null(x$data$constraints$group_gini_numerator) &&
    nrow(x$data$constraints$group_gini_numerator) > 0L
  make_gini <- isTRUE(needs$group_gini) || active_gini || has_gini_constraint
  pair_df <- data.frame()
  d_cols <- integer(0)

  if (make_gini && n_group >= 2L) {
    pair_mat <- utils::combn(seq_len(n_group), 2L)
    pair_df <- data.frame(g1 = pair_mat[1, ], g2 = pair_mat[2, ])
    n_pair <- nrow(pair_df)
    m1 <- .pa_model_from_ptr(x$data$model_ptr, args = x$data$model_args %||% list(),
                             drop_triplets = TRUE)
    d_start <- length(m1$obj)
    d_names <- paste0("group_absdiff[", totals$group[pair_df$g1], ",",
                      totals$group[pair_df$g2], "]")
    rcpp_model_add_columns(
      x = x$data$model_ptr, obj = rep(0, n_pair), lb = rep(0, n_pair),
      ub = rep(1, n_pair), vtype = rep("C", n_pair), names = d_names,
      block_name = "group_equity_absdiff", tag = eq$name
    )
    d_cols <- seq.int(d_start, length.out = n_pair)

    for (k in seq_len(n_pair)) {
      g1 <- pair_df$g1[k]
      g2 <- pair_df$g2[k]
      # d >= p1-p2 and d >= p2-p1
      x <- .pa_add_linear_constraint(
        x, c(d_cols[k], p_cols[g1], p_cols[g2]), c(1, -1, 1), ">=", 0,
        name = paste0("group_absdiff_pos_", k), block_name = "group_equity_absdiff",
        tag = eq$name, refresh_snapshot = FALSE
      )
      x <- .pa_add_linear_constraint(
        x, c(d_cols[k], p_cols[g1], p_cols[g2]), c(1, 1, -1), ">=", 0,
        name = paste0("group_absdiff_neg_", k), block_name = "group_equity_absdiff",
        tag = eq$name, refresh_snapshot = FALSE
      )
    }
  }

  x$data$model_registry <- x$data$model_registry %||% list()
  x$data$model_registry$vars <- x$data$model_registry$vars %||% list()
  x$data$model_registry$vars$group_equity <- list(
    groups = totals$group,
    available_amount = totals$available_amount,
    fixed_amount = totals$fixed_amount,
    share_cols_0based = p_cols,
    pair_index = pair_df,
    absdiff_cols_0based = d_cols
  )

  # Stored mean bands use the same unweighted population and retain zero groups.
  specs <- x$data$constraints$group_mean %||% NULL
  if (!is.null(specs) && nrow(specs)) {
    mean_coef <- rep(1 / n_group, n_group)
    for (k in seq_len(nrow(specs))) {
      x <- .pa_add_linear_constraint(
        x, p_cols, mean_coef, ">=", specs$lower[k],
        name = paste0(specs$name[k], "_lower"), block_name = "group_mean",
        tag = eq$name, refresh_snapshot = FALSE
      )
      x <- .pa_add_linear_constraint(
        x, p_cols, mean_coef, "<=", specs$upper[k],
        name = paste0(specs$name[k], "_upper"), block_name = "group_mean",
        tag = eq$name, refresh_snapshot = FALSE
      )
    }
  }

  gini_specs <- x$data$constraints$group_gini_numerator %||% NULL
  if (!is.null(gini_specs) && nrow(gini_specs)) {
    if (!length(d_cols)) {
      stop("A Gini-numerator constraint requires at least two equity groups.", call. = FALSE)
    }
    for (k in seq_len(nrow(gini_specs))) {
      x <- .pa_add_linear_constraint(
        x, d_cols, rep(1, length(d_cols)), "<=", gini_specs$upper[k],
        name = gini_specs$name[k], block_name = "group_gini_numerator",
        tag = eq$name, refresh_snapshot = FALSE
      )
    }
  }

  .pa_refresh_model_snapshot(x)
}

.pa_group_equity_objective_vector <- function(x, type, normalize = FALSE) {
  reg <- x$data$model_registry$vars$group_equity %||% NULL
  if (is.null(reg)) stop("Group-equity variables were not prepared.", call. = FALSE)
  m <- .pa_model_from_ptr(x$data$model_ptr, args = x$data$model_args %||% list(),
                          drop_triplets = TRUE)
  v <- numeric(length(m$obj))
  if (identical(type, "mean")) {
    v[reg$share_cols_0based + 1L] <- 1 / length(reg$share_cols_0based)
  } else if (identical(type, "gini_numerator")) {
    if (!length(reg$absdiff_cols_0based)) {
      stop("Gini numerator requires at least two groups and prepared pairwise variables.", call. = FALSE)
    }
    scale <- if (isTRUE(normalize)) 2 / length(reg$share_cols_0based)^2 else 1
    v[reg$absdiff_cols_0based + 1L] <- scale
  } else stop("Unknown group-equity objective type.", call. = FALSE)
  v
}
