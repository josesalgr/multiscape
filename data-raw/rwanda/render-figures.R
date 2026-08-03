# Render the publication figures used by the static Rwanda vignette.

library(dplyr)
library(ggplot2)
library(sf)

input_file <- file.path(
  "data-raw", "rwanda", "rwanda-reserve-inputs.rds"
)
result_file <- file.path(
  "data-raw", "rwanda", "rwanda-reserve-results.rds"
)

if (!file.exists(input_file) || !file.exists(result_file)) {
  stop(
    "Prepare the MaPP data and rebuild the optimization results first.",
    call. = FALSE
  )
}

rwanda_reserve <- readRDS(input_file)
rwanda_results <- readRDS(result_file)

run_summary <- function(method, parameter_name, parameter_values) {
  out <- rwanda_results[[method]]$runs |>
    left_join(
      rwanda_results[[method]]$objectives,
      by = "solution_id"
    ) |>
    arrange(run_id)

  out[[parameter_name]] <- parameter_values[out$run_id]
  out |>
    select(
      run_id,
      solution_id,
      all_of(parameter_name),
      status,
      runtime,
      gap,
      cost,
      fragmentation
    )
}

table_directory <- file.path("vignettes", "results", "rwanda")
dir.create(table_directory, recursive = TRUE, showWarnings = FALSE)

write.csv(
  run_summary("blm", "blm", rwanda_results$blm_values),
  file.path(table_directory, "blm-run-summary.csv"),
  row.names = FALSE
)

write.csv(
  run_summary(
    "epsilon",
    "epsilon_fragmentation",
    rwanda_results$epsilon_limits
  ),
  file.path(table_directory, "epsilon-run-summary.csv"),
  row.names = FALSE
)

figure_path <- function(name) {
  output_directory <- file.path("vignettes", "figures", "rwanda")
  dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  file.path(
    output_directory,
    paste0("reserve-design-rwanda-", name, "-1.png")
  )
}

planning_map <- rwanda_reserve$planning_units |>
  mutate(
    protection_status = if_else(
      protected,
      "Existing protected area",
      "Available for selection"
    )
  )

planning_plot <- ggplot(planning_map) +
  geom_sf(aes(fill = cost), color = NA) +
  geom_sf(
    data = filter(planning_map, protected),
    fill = NA,
    color = "#1B7837",
    linewidth = 0.25
  ) +
  scale_fill_viridis_c(option = "C", name = "Human\nmodification") +
  coord_sf(datum = NA) +
  labs(
    title = "Planning context",
    subtitle = paste(
      "Green outlines identify units with at least 75%",
      "protected-area coverage"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

ggsave(
  figure_path("planning-context"),
  planning_plot,
  width = 8,
  height = 5.5,
  dpi = 96
)

feature_map <- rwanda_reserve$feature_distribution |>
  left_join(rwanda_reserve$features, by = c("feature" = "id")) |>
  group_by(feature) |>
  mutate(relative_amount = amount / max(amount)) |>
  ungroup() |>
  left_join(
    select(rwanda_reserve$planning_units, id, geometry),
    by = c("pu" = "id")
  ) |>
  st_as_sf()

feature_plot <- ggplot(feature_map) +
  geom_sf(aes(fill = relative_amount), color = NA) +
  facet_wrap(~name, ncol = 4) +
  scale_fill_viridis_c(
    option = "C",
    limits = c(0, 1),
    name = "Relative\namount"
  ) +
  coord_sf(datum = NA) +
  theme_void(base_size = 9) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 8)
  )

ggsave(
  figure_path("feature-distributions"),
  feature_plot,
  width = 9,
  height = 9,
  dpi = 96
)

blm_results <- rwanda_results$blm$runs |>
  left_join(rwanda_results$blm$objectives, by = "solution_id") |>
  mutate(blm = rwanda_results$blm_values[run_id])

minimum_cost <- min(blm_results$cost, na.rm = TRUE)
minimum_cost_fragmentation <- blm_results$fragmentation[
  which.min(blm_results$cost)
]

blm_results <- blm_results |>
  mutate(
    additional_cost = 100 * (cost - minimum_cost) / minimum_cost,
    boundary_km = fragmentation / 1000,
    blm_label = paste0("BLM = ", format(blm, scientific = TRUE))
  )

blm_plot <- ggplot(
  blm_results,
  aes(boundary_km, additional_cost)
) +
  geom_path(
    data = arrange(blm_results, boundary_km),
    color = "grey70",
    linewidth = 0.5
  ) +
  geom_point(color = "#2C7FB8", size = 2.8) +
  ggrepel::geom_text_repel(
    aes(label = blm_label),
    size = 3,
    min.segment.length = 0,
    seed = 500
  ) +
  scale_y_continuous(labels = function(x) paste0(round(x, 1), "%")) +
  labs(
    x = "Exposed boundary (km)",
    y = "Additional cost relative to the minimum-cost plan",
    title = "BLM calibration",
    subtitle = paste(
      "Higher BLM values exchange additional cost for",
      "a more compact network"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

ggsave(
  figure_path("plot-blm"),
  blm_plot,
  width = 8,
  height = 5.5,
  dpi = 96
)

epsilon_results <- rwanda_results$epsilon$runs |>
  left_join(rwanda_results$epsilon$objectives, by = "solution_id") |>
  filter(!is.na(solution_id), is.finite(cost), is.finite(fragmentation)) |>
  mutate(
    additional_cost = 100 * (cost - minimum_cost) / minimum_cost,
    boundary_km = fragmentation / 1000
  )

comparison_data <- bind_rows(
  blm_results |>
    transmute(
      solution_id,
      additional_cost,
      boundary_km,
      method = "BLM weighted sum"
    ),
  epsilon_results |>
    transmute(
      solution_id,
      additional_cost,
      boundary_km,
      method = "Epsilon-constraint"
    )
)

comparison_plot <- ggplot(
  comparison_data,
  aes(
    boundary_km,
    additional_cost,
    color = method,
    shape = method
  )
) +
  geom_point(size = 3, alpha = 0.9) +
  scale_color_manual(
    values = c(
      "BLM weighted sum" = "#D95F02",
      "Epsilon-constraint" = "#1B9E77"
    )
  ) +
  scale_y_continuous(labels = function(x) paste0(round(x, 1), "%")) +
  labs(
    x = "Exposed boundary (km)",
    y = "Additional cost relative to the minimum-cost plan",
    color = NULL,
    shape = NULL,
    title = "Two ways to express the same planning tension"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

ggsave(
  figure_path("compare-methods"),
  comparison_plot,
  width = 8,
  height = 5.5,
  dpi = 96
)

cost_range <- diff(range(epsilon_results$cost))
fragmentation_range <- diff(range(epsilon_results$fragmentation))

epsilon_ranked <- epsilon_results |>
  mutate(
    normalized_cost = if (cost_range > 0) {
      (cost - min(cost)) / cost_range
    } else {
      0
    },
    normalized_fragmentation = if (fragmentation_range > 0) {
      (fragmentation - min(fragmentation)) / fragmentation_range
    } else {
      0
    },
    distance_to_ideal = sqrt(
      normalized_cost^2 + normalized_fragmentation^2
    )
  )

representative_ids <- c(
  "Minimum cost" = epsilon_ranked$solution_id[which.min(epsilon_ranked$cost)],
  "Observed compromise" = epsilon_ranked$solution_id[
    which.min(epsilon_ranked$distance_to_ideal)
  ],
  "Minimum fragmentation" = epsilon_ranked$solution_id[
    which.min(epsilon_ranked$fragmentation)
  ]
)
representative_ids <- representative_ids[!duplicated(representative_ids)]

action_results <- rwanda_results$epsilon$actions
selected_units <- action_results |>
  filter(
    solution_id %in% unname(representative_ids),
    selected == 1
  ) |>
  mutate(
    plan = names(representative_ids)[match(solution_id, representative_ids)]
  ) |>
  select(pu, solution_id, plan)

representative_maps <- bind_rows(lapply(
  names(representative_ids),
  function(plan_name) {
    rwanda_reserve$planning_units |>
      select(id, protected) |>
      mutate(plan = plan_name)
  }
)) |>
  left_join(selected_units, by = c("id" = "pu", "plan" = "plan")) |>
  mutate(
    status = case_when(
      protected ~ "Existing protected area",
      !is.na(solution_id) ~ "Additional selected unit",
      TRUE ~ "Not selected"
    ),
    plan = factor(plan, levels = names(representative_ids))
  )

map_plot <- ggplot(representative_maps) +
  geom_sf(aes(fill = status), color = NA) +
  facet_wrap(~plan, ncol = 2) +
  scale_fill_manual(
    values = c(
      "Existing protected area" = "#238B45",
      "Additional selected unit" = "#F39C12",
      "Not selected" = "#F2F2F2"
    ),
    breaks = c(
      "Existing protected area",
      "Additional selected unit",
      "Not selected"
    )
  ) +
  coord_sf(datum = NA) +
  labs(fill = NULL, title = "Alternative reserve designs") +
  theme_void(base_size = 10) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

ggsave(
  figure_path("representative-maps"),
  map_plot,
  width = 8,
  height = 7.5,
  dpi = 96
)

frequency_data <- action_results |>
  filter(selected == 1) |>
  count(pu, name = "selected_runs") |>
  mutate(frequency = selected_runs / nrow(epsilon_results))

frequency_map <- rwanda_reserve$planning_units |>
  left_join(frequency_data, by = c("id" = "pu")) |>
  mutate(
    frequency = coalesce(frequency, 0),
    frequency_available = if_else(protected, NA_real_, frequency)
  )

frequency_plot <- ggplot(frequency_map) +
  geom_sf(aes(fill = frequency_available), color = NA) +
  geom_sf(
    data = filter(frequency_map, protected),
    fill = "#238B45",
    color = NA
  ) +
  scale_fill_viridis_c(
    option = "B",
    limits = c(0, 1),
    na.value = "#238B45",
    name = "Selection\nfrequency"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Spatial stability across the frontier",
    subtitle = "Green units were already protected and locked into every solution"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

ggsave(
  figure_path("selection-frequency"),
  frequency_plot,
  width = 7.5,
  height = 5.2,
  dpi = 96
)
