#' Add groups and their distribution among planning units
#'
#' @param x A `Problem` object.
#' @param groups A data frame containing at least an `id` column.
#' @param dist_groups A data frame containing columns `pu`, `group`,
#'   and `amount`.
#'
#' @return A modified `Problem` object.
#'
#' @export
add_groups <- function(x, groups, dist_groups) {

  stopifnot(inherits(x, "Problem"))

  if (!is.data.frame(groups)) {
    stop("`groups` must be a data.frame.", call. = FALSE)
  }

  if (!is.data.frame(dist_groups)) {
    stop("`dist_groups` must be a data.frame.", call. = FALSE)
  }

  required_group_cols <- "id"
  missing_group_cols <- setdiff(required_group_cols, names(groups))

  if (length(missing_group_cols) > 0L) {
    stop(
      "`groups` must contain column `id`.",
      call. = FALSE
    )
  }

  required_dist_cols <- c("pu", "group", "amount")
  missing_dist_cols <- setdiff(required_dist_cols, names(dist_groups))

  if (length(missing_dist_cols) > 0L) {
    stop(
      "`dist_groups` is missing required columns: ",
      paste(missing_dist_cols, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (anyNA(groups$id)) {
    stop("`groups$id` cannot contain missing values.", call. = FALSE)
  }

  if (anyDuplicated(groups$id)) {
    stop("`groups$id` must contain unique values.", call. = FALSE)
  }

  if (anyNA(dist_groups$pu) ||
      anyNA(dist_groups$group) ||
      anyNA(dist_groups$amount)) {
    stop(
      "`dist_groups` cannot contain missing values in `pu`, `group`, or `amount`.",
      call. = FALSE
    )
  }

  if (!is.numeric(dist_groups$amount) ||
      any(!is.finite(dist_groups$amount)) ||
      any(dist_groups$amount < 0)) {
    stop(
      "`dist_groups$amount` must contain finite, non-negative values.",
      call. = FALSE
    )
  }

  unknown_pu <- setdiff(
    unique(dist_groups$pu),
    x$data$pu$id
  )

  if (length(unknown_pu) > 0L) {
    stop(
      "`dist_groups$pu` contains unknown planning-unit ids: ",
      paste(utils::head(unknown_pu, 10L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unknown_groups <- setdiff(
    unique(dist_groups$group),
    groups$id
  )

  if (length(unknown_groups) > 0L) {
    stop(
      "`dist_groups$group` contains unknown group ids: ",
      paste(utils::head(unknown_groups, 10L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  x <- .pa_clone_data(x)

  groups <- as.data.frame(groups, stringsAsFactors = FALSE)
  dist_groups <- as.data.frame(
    dist_groups,
    stringsAsFactors = FALSE
  )

  # Remove zero rows because they do not contribute to constraints.
  dist_groups <- dist_groups[
    dist_groups$amount > 0,
    ,
    drop = FALSE
  ]

  # Aggregate duplicated PU-group combinations.
  dist_groups <- stats::aggregate(
    amount ~ pu + group,
    data = dist_groups,
    FUN = sum
  )

  # Add internal ids, following the package's current conventions.
  groups$internal_id <- seq_len(nrow(groups))

  pu_match <- match(
    dist_groups$pu,
    x$data$pu$id
  )

  group_match <- match(
    dist_groups$group,
    groups$id
  )

  dist_groups$internal_pu <-
    x$data$pu$internal_id[pu_match]

  dist_groups$internal_group <-
    groups$internal_id[group_match]

  # Keep deterministic ordering.
  dist_groups <- dist_groups[
    order(
      dist_groups$internal_group,
      dist_groups$internal_pu
    ),
    ,
    drop = FALSE
  ]

  rownames(groups) <- NULL
  rownames(dist_groups) <- NULL

  x$data$groups <- groups
  x$data$dist_groups <- dist_groups

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}
