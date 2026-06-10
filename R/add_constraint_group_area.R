#' Add group-level area constraints
#'
#' @param x A `Problem` object containing group-distribution data.
#' @param target Numeric scalar or named numeric vector.
#' @param sense One of `"min"`, `"max"`, or `"equal"`.
#' @param groups Optional subset of group identifiers.
#' @param actions Optional subset of actions.
#' @param relative Whether targets are proportions of the total amount
#'   available to each group.
#' @param tolerance Equality tolerance.
#' @param name Optional constraint-name prefix.
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

  x <- .pa_clone_data(x)

  selected_groups <- if (is.null(groups)) {
    x$data$groups$id
  } else {
    groups
  }

  unknown <- setdiff(selected_groups, x$data$groups$id)

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

  groups_txt <- .pa_subset_to_string(
    selected_groups
  )

  spec <- data.frame(
    type = "group_area",
    sense = sense,
    target = I(list(target)),
    relative = isTRUE(relative),
    tolerance = as.numeric(tolerance),
    groups = groups_txt,
    actions = actions_txt,
    name = if (is.null(name)) {
      paste0("group_area_", sense)
    } else {
      name
    },
    stringsAsFactors = FALSE
  )

  x$data$constraints <- x$data$constraints %||% list()
  x$data$constraints$group_area <-
    x$data$constraints$group_area %||% list()

  x$data$constraints$group_area[[length(x$data$constraints$group_area) + 1L]] <- spec

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}
