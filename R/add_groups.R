#' Add groups and their area distribution among planning units
#'
#' @description
#' Register a group catalogue and the area of each group in each planning unit.
#' This is the canonical source of group membership and group available-area
#' denominators used by group constraints and equity metrics.
#'
#' @param x A [Problem] object.
#' @param groups A data frame or `sf` object with a group identifier column.
#' @param dist_groups Optional data frame with columns `pu`, `group`, and
#'   `area`. If omitted, `groups` must be an `sf` object and planning-unit
#'   geometries must be available in the problem.
#' @param group_id_col Name of the identifier column in `groups`.
#' @param area_unit Unit of `dist_groups$area` and `min_overlap`.
#' @param min_overlap Intersections at or below this area are discarded.
#'
#' @return A modified [Problem] object.
#' @export
add_groups <- function(
    x,
    groups,
    dist_groups = NULL,
    group_id_col = "id",
    area_unit = c("m2", "ha", "km2"),
    min_overlap = 0
) {
  stopifnot(inherits(x, "Problem"))
  area_unit <- match.arg(area_unit)
  if (!is.character(group_id_col) || length(group_id_col) != 1L ||
      is.na(group_id_col) || !nzchar(group_id_col)) {
    stop("`group_id_col` must be a non-empty string.", call. = FALSE)
  }
  if (!is.numeric(min_overlap) || length(min_overlap) != 1L ||
      !is.finite(min_overlap) || min_overlap < 0) {
    stop("`min_overlap` must be a finite non-negative number.", call. = FALSE)
  }
  if (!is.data.frame(groups)) stop("`groups` must be a data.frame or sf object.", call. = FALSE)
  groups_is_sf <- inherits(groups, "sf")
  if (!(group_id_col %in% names(groups))) {
    stop("`groups` does not contain `", group_id_col, "`.", call. = FALSE)
  }

  from_sf <- is.null(dist_groups)
  if (from_sf) {
    if (!groups_is_sf) {
      stop("`dist_groups` is required when `groups` is not an sf object.", call. = FALSE)
    }
    dist_groups <- .pa_make_dist_groups_from_sf(
      x, groups, group_id_col = group_id_col,
      min_overlap_m2 = .pa_group_area_to_m2(min_overlap, area_unit)
    )
  }
  if (!is.data.frame(dist_groups)) stop("`dist_groups` must be a data.frame.", call. = FALSE)
  required <- c("pu", "group", "area")
  if (!all(required %in% names(dist_groups))) {
    stop("`dist_groups` must contain: ", paste(required, collapse = ", "), ".", call. = FALSE)
  }

  groups_tbl <- if (groups_is_sf) sf::st_drop_geometry(groups) else as.data.frame(groups)
  groups_tbl <- as.data.frame(groups_tbl, stringsAsFactors = FALSE)
  names(groups_tbl)[names(groups_tbl) == group_id_col] <- "id"
  groups_tbl$id <- as.character(groups_tbl$id)
  if (anyNA(groups_tbl$id) || any(!nzchar(groups_tbl$id))) {
    stop("Group identifiers cannot be missing or empty.", call. = FALSE)
  }
  if (anyDuplicated(groups_tbl$id)) stop("Group identifiers must be unique.", call. = FALSE)

  dg <- data.frame(
    pu = dist_groups$pu,
    group = as.character(dist_groups$group),
    area = as.numeric(dist_groups$area),
    stringsAsFactors = FALSE
  )
  if (anyNA(dg) || any(!is.finite(dg$area)) || any(dg$area < 0)) {
    stop("`dist_groups` cannot contain missing, non-finite, or negative values.", call. = FALSE)
  }
  unknown_pu <- setdiff(unique(dg$pu), x$data$pu$id)
  if (length(unknown_pu)) {
    stop("Unknown planning units in `dist_groups`: ",
         paste(utils::head(unknown_pu, 20), collapse = ", "), ".", call. = FALSE)
  }
  unknown_group <- setdiff(unique(dg$group), groups_tbl$id)
  if (length(unknown_group)) {
    stop("Unknown groups in `dist_groups`: ",
         paste(utils::head(unknown_group, 20), collapse = ", "), ".", call. = FALSE)
  }

  # Spatial intersections are already returned in square metres.
  if (!from_sf) dg$area <- .pa_group_area_to_m2(dg$area, area_unit)
  threshold <- .pa_group_area_to_m2(min_overlap, area_unit)
  dg <- dg[dg$area > threshold, , drop = FALSE]
  if (nrow(dg)) {
    dg <- stats::aggregate(area ~ pu + group, data = dg, FUN = sum)
  }

  groups_tbl$internal_id <- seq_len(nrow(groups_tbl))
  if (nrow(dg)) {
    dg$internal_pu <- x$data$pu$internal_id[match(dg$pu, x$data$pu$id)]
    dg$internal_group <- groups_tbl$internal_id[match(dg$group, groups_tbl$id)]
    dg <- dg[order(dg$internal_group, dg$internal_pu), , drop = FALSE]
  } else {
    dg$internal_pu <- integer(0)
    dg$internal_group <- integer(0)
  }
  # `area` is the public canonical name; `amount` is retained as a model-layer
  # compatibility alias for existing group-area constraints.
  dg$amount <- dg$area
  rownames(groups_tbl) <- NULL
  rownames(dg) <- NULL

  x <- .pa_clone_data(x)
  x$data$groups <- groups_tbl
  x$data$dist_groups <- dg
  if (groups_is_sf) {
    groups_sf <- groups
    names(groups_sf)[names(groups_sf) == group_id_col] <- "id"
    x$data$groups_sf <- groups_sf
  } else {
    x$data$groups_sf <- NULL
  }
  x
}

.pa_group_area_to_m2 <- function(area, unit = c("m2", "ha", "km2")) {
  unit <- match.arg(unit)
  area <- as.numeric(area)
  switch(unit, m2 = area, ha = area * 1e4, km2 = area * 1e6)
}

.pa_make_dist_groups_from_sf <- function(x, groups_sf, group_id_col, min_overlap_m2 = 0) {
  if (!requireNamespace("sf", quietly = TRUE)) stop("Package `sf` is required.", call. = FALSE)
  pu_sf <- x$data$pu_sf
  if (is.null(pu_sf) || !inherits(pu_sf, "sf")) {
    stop("Spatial groups require planning-unit geometries in `x$data$pu_sf`.", call. = FALSE)
  }
  if (is.na(sf::st_crs(pu_sf)) || is.na(sf::st_crs(groups_sf))) {
    stop("Planning units and groups must have a valid CRS.", call. = FALSE)
  }
  if (sf::st_crs(pu_sf) != sf::st_crs(groups_sf)) {
    groups_sf <- sf::st_transform(groups_sf, sf::st_crs(pu_sf))
  }
  pu_use <- pu_sf[, "id", drop = FALSE]
  names(pu_use)[names(pu_use) == "id"] <- "pu"
  group_use <- groups_sf[, group_id_col, drop = FALSE]
  names(group_use)[names(group_use) == group_id_col] <- "group"
  inter <- suppressWarnings(sf::st_intersection(pu_use, group_use))
  if (!nrow(inter)) {
    return(data.frame(pu = x$data$pu$id[0], group = character(0), area = numeric(0)))
  }
  out <- sf::st_drop_geometry(inter)
  out$area <- as.numeric(sf::st_area(inter))
  out <- out[is.finite(out$area) & out$area > min_overlap_m2,
             c("pu", "group", "area"), drop = FALSE]
  rownames(out) <- NULL
  out
}
