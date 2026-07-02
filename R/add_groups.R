#' Add groups and their area distribution among planning units
#'
#' @param x A `Problem` object.
#' @param groups A data frame or `sf` object containing at least an `id` column.
#'   If `groups` is an `sf` object and `dist_groups = NULL`, group areas are
#'   derived from the spatial intersection between planning-unit geometries and
#'   group geometries.
#' @param dist_groups Optional data frame containing columns `pu`, `group`,
#'   and `area`. If `NULL`, `groups` must be an `sf` object and planning-unit
#'   geometries must be available in `x$data$pu_sf`.
#' @param group_id_col Character. Name of the group identifier column in
#'   `groups`. Defaults to `"id"`.
#' @param area_unit Unit of `dist_groups$area` and `min_overlap`. One of
#'   `"m2"`, `"ha"`, or `"km2"`. Areas are stored internally in square metres.
#' @param min_overlap Minimum overlap area used when deriving `dist_groups` from
#'   spatial group geometries. Values less than or equal to this threshold are
#'   discarded.
#'
#' @return A modified `Problem` object.
#'
#' @export
add_groups <- function(x,
                       groups,
                       dist_groups = NULL,
                       group_id_col = "id",
                       area_unit = c("m2", "ha", "km2"),
                       min_overlap = 0) {

  stopifnot(inherits(x, "Problem"))

  area_unit <- match.arg(area_unit)

  if (!is.character(group_id_col) ||
      length(group_id_col) != 1L ||
      is.na(group_id_col) ||
      !nzchar(group_id_col)) {
    stop(
      "`group_id_col` must be a single non-empty character value.",
      call. = FALSE
    )
  }

  if (!is.numeric(min_overlap) ||
      length(min_overlap) != 1L ||
      is.na(min_overlap) ||
      !is.finite(min_overlap) ||
      min_overlap < 0) {
    stop(
      "`min_overlap` must be a single finite non-negative number.",
      call. = FALSE
    )
  }

  if (!is.data.frame(groups)) {
    stop(
      "`groups` must be a data.frame or sf object.",
      call. = FALSE
    )
  }

  groups_is_sf <- inherits(groups, "sf")

  if (!group_id_col %in% names(groups)) {
    stop(
      "`groups` must contain column `",
      group_id_col,
      "`.",
      call. = FALSE
    )
  }

  dist_groups_from_sf <- FALSE

  if (is.null(dist_groups)) {
    if (!groups_is_sf) {
      stop(
        "`dist_groups` must be provided when `groups` is not an sf object.",
        call. = FALSE
      )
    }

    dist_groups <- .pa_make_dist_groups_from_sf(
      x = x,
      groups_sf = groups,
      group_id_col = group_id_col,
      area_unit = area_unit,
      min_overlap = min_overlap
    )

    dist_groups_from_sf <- TRUE
  }

  if (!is.data.frame(dist_groups)) {
    stop(
      "`dist_groups` must be a data.frame.",
      call. = FALSE
    )
  }

  groups_tbl <- if (groups_is_sf) {
    sf::st_drop_geometry(groups)
  } else {
    as.data.frame(groups, stringsAsFactors = FALSE)
  }

  groups_tbl <- as.data.frame(groups_tbl, stringsAsFactors = FALSE)

  if (!identical(group_id_col, "id")) {
    names(groups_tbl)[names(groups_tbl) == group_id_col] <- "id"
  }

  groups_tbl$id <- as.character(groups_tbl$id)

  required_group_cols <- "id"
  missing_group_cols <- setdiff(required_group_cols, names(groups_tbl))

  if (length(missing_group_cols) > 0L) {
    stop(
      "`groups` must contain column `id` after applying `group_id_col`.",
      call. = FALSE
    )
  }

  required_dist_cols <- c("pu", "group", "area")
  missing_dist_cols <- setdiff(required_dist_cols, names(dist_groups))

  if (length(missing_dist_cols) > 0L) {
    stop(
      "`dist_groups` is missing required columns: ",
      paste(missing_dist_cols, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (anyNA(groups_tbl$id)) {
    stop(
      "`groups$id` cannot contain missing values.",
      call. = FALSE
    )
  }

  if (anyDuplicated(groups_tbl$id)) {
    stop(
      "`groups$id` must contain unique values.",
      call. = FALSE
    )
  }

  if (anyNA(dist_groups$pu) ||
      anyNA(dist_groups$group) ||
      anyNA(dist_groups$area)) {
    stop(
      "`dist_groups` cannot contain missing values in `pu`, `group`, or `area`.",
      call. = FALSE
    )
  }

  if (!is.numeric(dist_groups$area) ||
      any(!is.finite(dist_groups$area)) ||
      any(dist_groups$area < 0)) {
    stop(
      "`dist_groups$area` must contain finite, non-negative values.",
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
    groups_tbl$id
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

  dist_groups <- as.data.frame(
    dist_groups,
    stringsAsFactors = FALSE
  )

  dist_groups$group <- as.character(dist_groups$group)

  # Convert supplied areas to square metres for internal storage.
  if (dist_groups_from_sf) {
    dist_groups$area <- as.numeric(dist_groups$area)
    min_overlap_m2 <- .pa_area_to_m2(
      min_overlap,
      unit = area_unit
    )
  } else {
    dist_groups$area <- .pa_area_to_m2(
      dist_groups$area,
      unit = area_unit
    )

    min_overlap_m2 <- .pa_area_to_m2(
      min_overlap,
      unit = area_unit
    )
  }

  # Remove zero or negligible rows because they do not contribute to constraints.
  dist_groups <- dist_groups[
    dist_groups$area > min_overlap_m2,
    ,
    drop = FALSE
  ]

  if (nrow(dist_groups) > 0L) {
    # Aggregate duplicated PU-group combinations.
    dist_groups <- stats::aggregate(
      area ~ pu + group,
      data = dist_groups,
      FUN = sum
    )
  } else {
    dist_groups <- data.frame(
      pu = character(),
      group = character(),
      area = numeric(),
      stringsAsFactors = FALSE
    )
  }

  # Add internal ids, following the package's current conventions.
  groups_tbl$internal_id <- seq_len(nrow(groups_tbl))

  pu_match <- match(
    dist_groups$pu,
    x$data$pu$id
  )

  group_match <- match(
    dist_groups$group,
    groups_tbl$id
  )

  dist_groups$internal_pu <-
    x$data$pu$internal_id[pu_match]

  dist_groups$internal_group <-
    groups_tbl$internal_id[group_match]

  # Keep deterministic ordering.
  dist_groups <- dist_groups[
    order(
      dist_groups$internal_group,
      dist_groups$internal_pu
    ),
    ,
    drop = FALSE
  ]

  rownames(groups_tbl) <- NULL
  rownames(dist_groups) <- NULL

  x$data$groups <- groups_tbl
  x$data$dist_groups <- dist_groups

  if (groups_is_sf) {
    groups_sf <- groups

    if (!identical(group_id_col, "id")) {
      names(groups_sf)[names(groups_sf) == group_id_col] <- "id"
    }

    x$data$groups_sf <- groups_sf
  } else {
    x$data$groups_sf <- NULL
  }

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}



.pa_area_to_m2 <- function(area, unit = c("m2", "ha", "km2")) {
  unit <- match.arg(unit)

  area <- as.numeric(area)

  switch(
    unit,
    m2 = area,
    ha = area * 1e4,
    km2 = area * 1e6
  )
}


.pa_make_dist_groups_from_sf <- function(x,
                                         groups_sf,
                                         group_id_col = "id",
                                         area_unit = c("m2", "ha", "km2"),
                                         min_overlap = 0) {
  area_unit <- match.arg(area_unit)

  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "Package `sf` is required to derive groups from spatial geometries.",
      call. = FALSE
    )
  }

  if (!inherits(groups_sf, "sf")) {
    stop(
      "`groups` must be an sf object when `dist_groups = NULL`.",
      call. = FALSE
    )
  }

  if (is.null(x$data$pu_sf) || !inherits(x$data$pu_sf, "sf")) {
    stop(
      "Spatial groups require planning-unit geometries in `x$data$pu_sf`.",
      call. = FALSE
    )
  }

  if (!group_id_col %in% names(groups_sf)) {
    stop(
      "`groups` must contain column `",
      group_id_col,
      "`.",
      call. = FALSE
    )
  }

  pu_sf <- x$data$pu_sf

  if (!"id" %in% names(pu_sf)) {
    stop(
      "`x$data$pu_sf` must contain column `id`.",
      call. = FALSE
    )
  }

  if (is.na(sf::st_crs(pu_sf))) {
    stop(
      "Planning-unit geometries in `x$data$pu_sf` must have a valid CRS.",
      call. = FALSE
    )
  }

  if (is.na(sf::st_crs(groups_sf))) {
    stop(
      "Group geometries must have a valid CRS.",
      call. = FALSE
    )
  }

  if (sf::st_crs(pu_sf) != sf::st_crs(groups_sf)) {
    groups_sf <- sf::st_transform(groups_sf, sf::st_crs(pu_sf))
  }

  min_overlap_m2 <- .pa_area_to_m2(
    min_overlap,
    unit = area_unit
  )

  pu_use <- pu_sf[, "id", drop = FALSE]
  names(pu_use)[names(pu_use) == "id"] <- "pu"

  group_use <- groups_sf[, group_id_col, drop = FALSE]
  names(group_use)[names(group_use) == group_id_col] <- "group"

  inter <- suppressWarnings(
    sf::st_intersection(pu_use, group_use)
  )

  if (nrow(inter) == 0L) {
    return(data.frame(
      pu = character(),
      group = character(),
      area = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  area_m2 <- as.numeric(sf::st_area(inter))

  out <- sf::st_drop_geometry(inter)
  out$area <- area_m2

  out <- out[
    !is.na(out$pu) &
      !is.na(out$group) &
      !is.na(out$area) &
      is.finite(out$area) &
      out$area > min_overlap_m2,
    c("pu", "group", "area"),
    drop = FALSE
  ]

  rownames(out) <- NULL

  out
}
