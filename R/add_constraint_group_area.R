#' Add group-level area constraints
#'
#' @param x A `Problem` object containing group-area distribution data.
#' @param target Numeric scalar or named numeric vector.
#' @param sense One of `"min"`, `"max"`, or `"equal"`.
#' @param groups Optional subset of group identifiers.
#' @param actions Optional subset of actions.
#' @param relative Whether targets are proportions of the total area
#'   available to each group.
#' @param tolerance Equality tolerance.
#' @param name Optional constraint-name prefix.
#'
#' @details
#' This function stores group-level area constraints. Group areas must have been
#' added previously with [add_groups()]. Internally, group areas are represented
#' by `x$data$dist_groups$area`, which is interpreted as the area of group `g`
#' within planning unit `i`.
#'
#' If `relative = TRUE`, each target is interpreted as a proportion of the total
#' area available to the corresponding group. If `relative = FALSE`, each target
#' is interpreted as an absolute area in the same internal units used by
#' `dist_groups$area`.
#'
#' When `actions` is not `NULL`, the constraint applies only to the selected
#' subset of actions. In the current formulation, the group-area coefficients are
#' derived downstream when the optimization model is assembled.
#'
#' @return A modified `Problem` object.
#'
#' @export
add_constraint_group_area <- function(
    x,
    target,
    sense = c("min", "max", "equal"),
    groups = NULL,
    actions = NULL,
    relative = TRUE,
    tolerance = 0,
    name = NULL
) {
  stopifnot(inherits(x, "Problem"))

  sense <- match.arg(sense)

  if (is.null(x$data$groups) ||
      is.null(x$data$dist_groups)) {
    stop(
      "Group data are missing. Add them first using `add_groups()`.",
      call. = FALSE
    )
  }

  if (!is.data.frame(x$data$groups)) {
    stop(
      "`x$data$groups` must be a data.frame.",
      call. = FALSE
    )
  }

  if (!is.data.frame(x$data$dist_groups)) {
    stop(
      "`x$data$dist_groups` must be a data.frame.",
      call. = FALSE
    )
  }

  if (!"id" %in% names(x$data$groups)) {
    stop(
      "`x$data$groups` must contain column `id`.",
      call. = FALSE
    )
  }

  required_dist_cols <- c("pu", "group", "area")
  missing_dist_cols <- setdiff(
    required_dist_cols,
    names(x$data$dist_groups)
  )

  if (length(missing_dist_cols) > 0L) {
    stop(
      "`x$data$dist_groups` is missing required columns: ",
      paste(missing_dist_cols, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (!is.numeric(x$data$dist_groups$area) ||
      anyNA(x$data$dist_groups$area) ||
      any(!is.finite(x$data$dist_groups$area)) ||
      any(x$data$dist_groups$area < 0)) {
    stop(
      "`x$data$dist_groups$area` must contain finite, non-negative values.",
      call. = FALSE
    )
  }

  if (!is.logical(relative) ||
      length(relative) != 1L ||
      is.na(relative)) {
    stop("`relative` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.numeric(target) ||
      length(target) < 1L ||
      anyNA(target) ||
      any(!is.finite(target)) ||
      any(target < 0)) {
    stop(
      "`target` must contain finite, non-negative values.",
      call. = FALSE
    )
  }

  if (isTRUE(relative) && any(target > 1)) {
    stop(
      "Relative group-area targets must lie between zero and one.",
      call. = FALSE
    )
  }

  if (!is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance < 0) {
    stop("`tolerance` must be a single non-negative number.", call. = FALSE)
  }

  x <- .pa_clone_data(x)

  # If groups = NULL, constrain only groups with positive available area in
  # dist_groups. This avoids adding constraints for groups present in the group
  # catalogue but absent from the current planning-unit subset.
  selected_groups <- if (is.null(groups)) {
    active_groups <- x$data$dist_groups |>
      dplyr::filter(
        !is.na(.data$group),
        !is.na(.data$area),
        is.finite(.data$area),
        .data$area > 0
      ) |>
      dplyr::distinct(.data$group) |>
      dplyr::pull(.data$group)

    # Keep the same order as x$data$groups$id when possible.
    active_groups <- as.character(active_groups)

    groups_order <- as.character(x$data$groups$id)

    groups_order[
      groups_order %in% active_groups
    ]
  } else {
    groups
  }

  selected_groups <- as.character(selected_groups)

  if (length(selected_groups) == 0L ||
      anyNA(selected_groups) ||
      any(!nzchar(selected_groups))) {
    stop(
      "`groups` must identify at least one group with positive available area.",
      call. = FALSE
    )
  }

  if (length(selected_groups) == 0L ||
      anyNA(selected_groups) ||
      any(!nzchar(selected_groups))) {
    stop(
      "`groups` must identify at least one valid group.",
      call. = FALSE
    )
  }

  unknown <- setdiff(
    selected_groups,
    as.character(x$data$groups$id)
  )

  if (length(unknown) > 0L) {
    stop(
      "Unknown groups: ",
      paste(unknown, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  actions_txt <- NA_character_

  if (!is.null(actions)) {
    action_subset <- .pa_resolve_action_subset(
      x,
      subset = actions
    )

    actions_txt <- .pa_subset_to_string(
      action_subset$id
    )
  }

  if (length(target) == 1L) {
    target_values <- rep(
      as.numeric(target),
      length(selected_groups)
    )

    names(target_values) <- selected_groups
  } else {
    if (is.null(names(target)) || any(!nzchar(names(target)))) {
      stop(
        "When `target` has length greater than one, it must be a named numeric vector.",
        call. = FALSE
      )
    }

    missing_targets <- setdiff(
      selected_groups,
      names(target)
    )

    if (length(missing_targets) > 0L) {
      stop(
        "`target` is missing values for group(s): ",
        paste(missing_targets, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    target_values <- as.numeric(target[selected_groups])
    names(target_values) <- selected_groups
  }

  spec <- data.frame(
    type = "group_area",
    group = selected_groups,
    sense = sense,
    value = as.numeric(target_values),
    relative = isTRUE(relative),
    tolerance = as.numeric(tolerance),
    actions = actions_txt,
    name = if (is.null(name)) {
      paste0("group_area_", sense, "_", selected_groups)
    } else {
      paste0(name, "_", selected_groups)
    },
    stringsAsFactors = FALSE
  )

  x$data$constraints <- x$data$constraints %||% list()

  if (is.null(x$data$constraints$group_area)) {
    x$data$constraints$group_area <- spec
  } else {
    x$data$constraints$group_area <- rbind(
      x$data$constraints$group_area,
      spec
    )

    rownames(x$data$constraints$group_area) <- NULL
  }

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}
