# Prepare the official MaPP Rwanda tutorial for the reserve-design vignette.
#
# Download and extract the tutorial archive from:
# https://marxansolutions.org/marxanmapp/
#
# Set MAPP_RWANDA_DIRECTORY to the extracted directory before running this
# script. The generated RDS is a local reproduction artifact and is not
# distributed with multiscape.

library(dplyr)
library(sf)

source_dir <- Sys.getenv("MAPP_RWANDA_DIRECTORY", unset = "")

if (!nzchar(source_dir) || !dir.exists(source_dir)) {
  stop(
    "Set MAPP_RWANDA_DIRECTORY to the extracted MaPP Rwanda tutorial.",
    call. = FALSE
  )
}

feature_dir <- file.path(source_dir, "features")

required_paths <- c(
  file.path(source_dir, "planning_units_costs", "planning_units_costs.shp"),
  file.path(source_dir, "protected_areas", "protected_areas_d.shp"),
  feature_dir
)

if (any(!file.exists(required_paths) & !dir.exists(required_paths))) {
  stop(
    "The selected directory does not have the expected MaPP tutorial layout.",
    call. = FALSE
  )
}

planning_units <- st_read(required_paths[1], quiet = TRUE) |>
  st_make_valid() |>
  st_transform(32735) |>
  transmute(
    id = as.integer(puid),
    cost = as.numeric(cost),
    geometry = geometry
  )

protected_areas <- st_read(required_paths[2], quiet = TRUE) |>
  st_make_valid() |>
  st_transform(st_crs(planning_units)) |>
  summarise(geometry = st_union(geometry))

planning_area <- as.numeric(st_area(planning_units))
protected_intersection <- suppressWarnings(
  st_intersection(planning_units |> select(id), protected_areas)
) |>
  mutate(protected_area = as.numeric(st_area(geometry))) |>
  st_drop_geometry() |>
  group_by(id) |>
  summarise(protected_area = sum(protected_area), .groups = "drop")

planning_units <- planning_units |>
  left_join(protected_intersection, by = "id") |>
  mutate(
    area = planning_area,
    protected_area = coalesce(protected_area, 0),
    protected_fraction = pmin(protected_area / area, 1),
    protected = protected_fraction >= 0.75
  ) |>
  select(id, cost, area, protected_fraction, protected, geometry)

feature_labels <- c(
  Albertine_Rift_Montane_Forests = "Albertine Rift montane forests",
  Banded_mongoose = "Banded mongoose",
  Black_rhinoceros = "Black rhinoceros",
  Central_Zambezian_Miombo_Woodlands = "Central Zambezian miombo woodlands",
  Chimpanzee = "Chimpanzee",
  Elephant = "Elephant",
  Hill_horseshoe_bat = "Hill's horseshoe bat",
  Leopard = "Leopard",
  Rock_hyrax = "Rock hyrax",
  Ruwenzori_Virunga_Montane_Moorlands = "Ruwenzori-Virunga montane moorlands",
  Sitatunga = "Sitatunga",
  Tantalus_monkey = "Tantalus monkey",
  Victoria_Basin_Forest_Savanna_Mosaic = "Victoria Basin forest-savanna mosaic"
)

feature_types <- ifelse(
  grepl("Forests|Woodlands|Moorlands|Mosaic", names(feature_labels)),
  "ecoregion",
  "species"
)

features <- data.frame(
  id = seq_along(feature_labels),
  name = unname(feature_labels),
  type = unname(feature_types),
  source_name = names(feature_labels),
  stringsAsFactors = FALSE
)

feature_distribution <- vector("list", nrow(features))

for (j in seq_len(nrow(features))) {
  feature_file <- file.path(
    feature_dir,
    paste0(features$source_name[j], ".shp")
  )

  if (!file.exists(feature_file)) {
    stop("Missing tutorial feature file: ", feature_file, call. = FALSE)
  }

  feature_geometry <- st_read(feature_file, quiet = TRUE) |>
    st_make_valid() |>
    st_transform(st_crs(planning_units)) |>
    summarise(geometry = st_union(geometry))

  feature_distribution[[j]] <- suppressWarnings(
    st_intersection(planning_units |> select(id), feature_geometry)
  ) |>
    mutate(amount = as.numeric(st_area(geometry))) |>
    st_drop_geometry() |>
    group_by(id) |>
    summarise(amount = sum(amount), .groups = "drop") |>
    transmute(pu = id, feature = features$id[j], amount = amount) |>
    filter(amount > 0)
}

rwanda_reserve <- list(
  planning_units = planning_units,
  features = features |> select(id, name, type),
  feature_distribution = bind_rows(feature_distribution),
  actions = data.frame(id = "reserve", name = "Reserve"),
  effects = data.frame(
    action = "reserve",
    feature = features$id,
    multiplier = 1
  )
)

output_file <- file.path(
  "data-raw",
  "rwanda",
  "rwanda-reserve-inputs.rds"
)

saveRDS(rwanda_reserve, output_file, compress = "xz")
message("Prepared local reproduction input: ", output_file)

