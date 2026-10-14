#' Add a group-level mean absolute deviation constraint
#'
#' @param x A `Problem` object containing group-area distribution data.
#' @param max_mad Maximum admissible mean absolute deviation of group-level
#'   selected-area proportions.
#' @param max_mean Optional maximum admissible unweighted mean of the same
#'   group-level proportions. Use this for lexicographic workflows that first
#'   minimize the mean and then minimize MAD conditional on that mean.
#' @param groups Optional subset of group identifiers.
#' @param actions Optional subset of actions.
#' @param group_areas Optional named numeric vector containing the denominator
#'   area for every selected group. When `NULL`, denominators are derived by
#'   summing `x$data$dist_groups$area` by group. Supply this argument whenever
#'   `dist_groups` represents restorable rather than total group area.
#' @param tolerance Non-negative feasibility tolerance added to `max_mad`.
#' @param name Constraint-name prefix.
#' @param dist_group_actions Optional precomputed group-action area table with
#'   columns `pu`, `group`, `action`, and `area`.
#'
#' @details
#' For each selected group `g`, the function defines the selected proportion
#'
#' `p[g] = selected_area[g] / group_area[g]`,
#'
#' its unweighted mean `mu`, and an absolute-deviation variable `d[g]`. The
#' compiled MILP contains the linear constraints
#'
#' `d[g] >= p[g] - mu`, `d[g] >= mu - p[g]`, and
#' `sum(d[g]) <= n_groups * (max_mad + tolerance)`.
#' When `max_mean` is supplied, the model also contains
#' `mu <= max_mean + tolerance`.
#'
#' The mean is endogenous. This function adds only a constraint; it does not
#' add a MAD objective.
#'
#' @return A modified `Problem` object.
#'
#' @export
add_constraint_group_mad <- function(
    x,
    max_mad,
    max_mean = NULL,
    groups = NULL,
    actions = NULL,
    group_areas = NULL,
    tolerance = 0,
    name = "group_mad",
    dist_group_actions = NULL
) {
  stopifnot(inherits(x, "Problem"))

  if (!is.numeric(max_mad) ||
      length(max_mad) != 1L ||
      is.na(max_mad) ||
      !is.finite(max_mad) ||
      max_mad < 0 ||
      max_mad > 1) {
    stop("`max_mad` must be a finite number between zero and one.", call. = FALSE)
  }

  if (!is.null(max_mean) &&
      (!is.numeric(max_mean) ||
       length(max_mean) != 1L ||
       is.na(max_mean) ||
       !is.finite(max_mean) ||
       max_mean < 0 ||
       max_mean > 1)) {
    stop("`max_mean` must be NULL or a finite number between zero and one.", call. = FALSE)
  }

  if (!is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance < 0) {
    stop("`tolerance` must be a single non-negative number.", call. = FALSE)
  }

  if (!is.character(name) ||
      length(name) != 1L ||
      is.na(name) ||
      !nzchar(trimws(name))) {
    stop("`name` must be one non-empty character value.", call. = FALSE)
  }

  existing <- x$data$constraints$group_mad %||% NULL
  if (!is.null(existing) && is.data.frame(existing) && nrow(existing) > 0L) {
    stop(
      "A group MAD constraint already exists. Build a new Problem for each ",
      "`max_mad` value.",
      call. = FALSE
    )
  }

  # Reuse the mature group/action validation and precomputed-area handling from
  # add_constraint_group_area(). The temporary zero lower bound is removed
  # immediately; only its validated group/action specification is retained.
  old_group_area <- x$data$constraints$group_area %||% NULL
  old_n <- if (is.null(old_group_area)) 0L else nrow(old_group_area)

  x <- add_constraint_group_area(
    x = x,
    target = 0,
    sense = "min",
    groups = groups,
    actions = actions,
    relative = FALSE,
    tolerance = 0,
    name = paste0(name, "_validation"),
    dist_group_actions = dist_group_actions
  )

  validated <- x$data$constraints$group_area
  new_rows <- validated[
    seq.int(old_n + 1L, nrow(validated)),
    ,
    drop = FALSE
  ]

  if (is.null(old_group_area)) {
    x$data$constraints$group_area <- NULL
  } else {
    x$data$constraints$group_area <- old_group_area
  }

  selected_groups <- as.character(new_rows$group)

  if (is.null(group_areas)) {
    derived_group_areas <- x$data$dist_groups |>
      dplyr::filter(.data$group %in% selected_groups) |>
      dplyr::group_by(.data$group) |>
      dplyr::summarise(
        group_area = sum(.data$area, na.rm = TRUE),
        .groups = "drop"
      )

    group_areas <- stats::setNames(
      derived_group_areas$group_area,
      as.character(derived_group_areas$group)
    )
  } else {
    if (!is.numeric(group_areas) ||
        is.null(names(group_areas)) ||
        anyNA(names(group_areas)) ||
        any(!nzchar(names(group_areas)))) {
      stop("`group_areas` must be a named numeric vector.", call. = FALSE)
    }

    missing_groups <- setdiff(selected_groups, names(group_areas))
    if (length(missing_groups) > 0L) {
      stop(
        "`group_areas` is missing selected group(s): ",
        paste(missing_groups, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    group_areas <- group_areas[selected_groups]
  }

  group_areas <- as.numeric(group_areas[selected_groups])

  if (length(group_areas) != length(selected_groups) ||
      anyNA(group_areas) ||
      any(!is.finite(group_areas)) ||
      any(group_areas <= 0)) {
    stop(
      "Every selected group must have one finite, strictly positive denominator area.",
      call. = FALSE
    )
  }

  spec <- data.frame(
    type = "group_mad",
    group = selected_groups,
    group_area = group_areas,
    max_mad = rep(as.numeric(max_mad), length(selected_groups)),
    max_mean = rep(
      if (is.null(max_mean)) NA_real_ else as.numeric(max_mean),
      length(selected_groups)
    ),
    tolerance = rep(as.numeric(tolerance), length(selected_groups)),
    actions = as.character(new_rows$actions),
    name = paste0(name, "_", selected_groups),
    stringsAsFactors = FALSE
  )

  x$data$constraints <- x$data$constraints %||% list()
  x$data$constraints$group_mad <- spec

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}


# Apply a stored group MAD constraint to the compiled C++ model.
# @noRd
.pa_apply_group_mad_constraint_if_present <- function(x) {
  stopifnot(inherits(x, "Problem"))

  specs <- x$data$constraints$group_mad %||% NULL
  if (is.null(specs) || !is.data.frame(specs) || nrow(specs) == 0L) {
    return(x)
  }

  if (is.null(x$data$model_ptr)) {
    stop("Model pointer is missing while applying the group MAD constraint.", call. = FALSE)
  }

  required <- c(
    "group", "group_area", "max_mad", "max_mean", "tolerance", "actions", "name"
  )
  missing <- setdiff(required, names(specs))
  if (length(missing) > 0L) {
    stop(
      "Stored group MAD specification is missing column(s): ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  max_values <- unique(as.numeric(specs$max_mad))
  mean_values <- unique(as.numeric(specs$max_mean))
  tolerances <- unique(as.numeric(specs$tolerance))
  actions_values <- unique(as.character(specs$actions))

  if (length(max_values) != 1L || !is.finite(max_values)) {
    stop("Stored group MAD rows must share one finite `max_mad`.", call. = FALSE)
  }
  if (length(mean_values) != 1L ||
      !(is.na(mean_values) || is.finite(mean_values))) {
    stop("Stored group MAD rows must share one finite or NA `max_mean`.", call. = FALSE)
  }
  if (length(tolerances) != 1L || !is.finite(tolerances)) {
    stop("Stored group MAD rows must share one finite `tolerance`.", call. = FALSE)
  }
  if (length(actions_values) != 1L) {
    stop("Stored group MAD rows must share one action subset.", call. = FALSE)
  }

  groups <- as.character(specs$group)
  group_areas <- stats::setNames(as.numeric(specs$group_area), groups)
  n_groups <- length(groups)

  if (n_groups < 1L || anyDuplicated(groups) ||
      anyNA(group_areas) || any(!is.finite(group_areas)) ||
      any(group_areas <= 0)) {
    stop("Stored group MAD groups or denominator areas are invalid.", call. = FALSE)
  }

  dga <- x$data$dist_group_actions %||% NULL
  if (is.null(dga) || !is.data.frame(dga) || nrow(dga) == 0L) {
    stop(
      "The group MAD constraint requires positive `dist_group_actions` rows.",
      call. = FALSE
    )
  }

  if (!("internal_row" %in% names(dga))) {
    da <- x$data$dist_actions_model %||% NULL
    if (!all(c("pu", "action") %in% names(dga)) ||
        is.null(da) || !is.data.frame(da) ||
        !all(c("pu", "action", "internal_row") %in% names(da))) {
      stop(
        "`dist_group_actions` must contain `internal_row`, or contain `pu` and ",
        "`action` that can be matched to `dist_actions_model`.",
        call. = FALSE
      )
    }
    dga <- merge(
      dga,
      da[, c("pu", "action", "internal_row"), drop = FALSE],
      by = c("pu", "action"), all = FALSE, sort = FALSE
    )
  }

  required_dga <- c("group", "action", "area", "internal_row")
  missing_dga <- setdiff(required_dga, names(dga))
  if (length(missing_dga) > 0L) {
    stop(
      "`x$data$dist_group_actions` is missing column(s): ",
      paste(missing_dga, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  actions_txt <- actions_values[1]
  if (!is.na(actions_txt) && nzchar(trimws(actions_txt)) &&
      trimws(actions_txt) != "NA") {
    selected_actions <- trimws(strsplit(actions_txt, "\\|", fixed = FALSE)[[1]])
    selected_actions <- selected_actions[nzchar(selected_actions)]
    dga <- dga[as.character(dga$action) %in% selected_actions, , drop = FALSE]
  }

  dga <- dga[as.character(dga$group) %in% groups, , drop = FALSE]
  if (nrow(dga) == 0L) {
    stop("No group-action coefficients remain for the MAD constraint.", call. = FALSE)
  }

  x <- .pa_refresh_model_snapshot(x)
  x0 <- as.integer(x$data$model_list$x_offset)

  # One endogenous mean followed by one absolute-deviation variable per group.
  aux_names <- c("group_mad_mean", paste0("group_mad_dev_", groups))
  aux <- rcpp_model_add_columns(
    x = x$data$model_ptr,
    obj = rep(0, n_groups + 1L),
    lb = rep(0, n_groups + 1L),
    ub = rep(1, n_groups + 1L),
    vtype = rep("C", n_groups + 1L),
    names = aux_names,
    block_name = "group_mad_variables",
    tag = paste0("n_groups=", n_groups)
  )

  mean_col0 <- as.integer(aux$col0[1])
  dev_col0 <- as.integer(aux$col0[-1])
  names(dev_col0) <- groups

  group_terms <- vector("list", n_groups)
  names(group_terms) <- groups

  for (g in groups) {
    matched <- dga[as.character(dga$group) == g, , drop = FALSE]
    if (nrow(matched) == 0L) {
      stop("Group `", g, "` has no positive coefficients for MAD.", call. = FALSE)
    }

    aggregated <- stats::aggregate(
      area ~ internal_row,
      data = matched,
      FUN = sum
    )

    group_terms[[g]] <- data.frame(
      j0 = x0 + as.integer(aggregated$internal_row) - 1L,
      coefficient = as.numeric(aggregated$area) / group_areas[[g]],
      stringsAsFactors = FALSE
    )
  }

  # Definition of the endogenous unweighted mean:
  # sum_g p_g - n_groups * mu = 0.
  mean_terms <- do.call(rbind, group_terms)
  mean_terms <- stats::aggregate(
    coefficient ~ j0,
    data = mean_terms,
    FUN = sum
  )

  mean_result <- rcpp_add_linear_constraint(
    model_ptr = x$data$model_ptr,
    j0 = c(as.integer(mean_terms$j0), mean_col0),
    x = c(as.numeric(mean_terms$coefficient), -n_groups),
    sense = "==",
    rhs = 0,
    name = "group_mad_mean_definition",
    block_name = "group_mad_mean_definition",
    tag = paste0("n_groups=", n_groups)
  )

  mean_upper_result <- NULL
  if (is.finite(mean_values)) {
    mean_upper_result <- rcpp_add_linear_constraint(
      model_ptr = x$data$model_ptr,
      j0 = mean_col0,
      x = 1,
      sense = "<=",
      rhs = mean_values + tolerances,
      name = "group_mean_upper_bound",
      block_name = "group_mean_upper_bound",
      tag = paste0("max_mean=", format(mean_values, digits = 16))
    )
  }

  deviation_results <- vector("list", 2L * n_groups)
  result_index <- 0L

  for (g in groups) {
    term <- group_terms[[g]]
    dev <- unname(dev_col0[[g]])

    # p_g - mu - d_g <= 0
    result_index <- result_index + 1L
    deviation_results[[result_index]] <- rcpp_add_linear_constraint(
      model_ptr = x$data$model_ptr,
      j0 = c(as.integer(term$j0), mean_col0, dev),
      x = c(as.numeric(term$coefficient), -1, -1),
      sense = "<=",
      rhs = 0,
      name = paste0("group_mad_positive_", g),
      block_name = "group_mad_deviations",
      tag = paste0("group=", g)
    )

    # mu - p_g - d_g <= 0
    result_index <- result_index + 1L
    deviation_results[[result_index]] <- rcpp_add_linear_constraint(
      model_ptr = x$data$model_ptr,
      j0 = c(as.integer(term$j0), mean_col0, dev),
      x = c(-as.numeric(term$coefficient), 1, -1),
      sense = "<=",
      rhs = 0,
      name = paste0("group_mad_negative_", g),
      block_name = "group_mad_deviations",
      tag = paste0("group=", g)
    )
  }

  mad_result <- rcpp_add_linear_constraint(
    model_ptr = x$data$model_ptr,
    j0 = unname(dev_col0),
    x = rep(1, n_groups),
    sense = "<=",
    rhs = n_groups * (max_values + tolerances),
    name = "group_mad_upper_bound",
    block_name = "group_mad_upper_bound",
    tag = paste0("max_mad=", format(max_values, digits = 16))
  )

  x$data$model_registry <- x$data$model_registry %||% list(
    cons = list(), vars = list(), obj_templates = list(), objective = list()
  )
  x$data$model_registry$vars$group_mad <- aux
  x$data$model_registry$cons$group_mad_mean <- mean_result
  x$data$model_registry$cons$group_mean_upper_bound <- mean_upper_result
  x$data$model_registry$cons$group_mad_deviations <- deviation_results
  x$data$model_registry$cons$group_mad_upper_bound <- mad_result
  x$data$model_registry$group_mad <- list(
    groups = groups,
    group_areas = group_areas,
    max_mad = max_values,
    max_mean = mean_values,
    tolerance = tolerances,
    mean_col0 = mean_col0,
    deviation_col0 = dev_col0
  )

  .pa_refresh_model_snapshot(x)
}
