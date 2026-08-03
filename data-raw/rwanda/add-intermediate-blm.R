library(multiscape)
library(dplyr)

root <- "D:/Y6026159N/Desktop/multiscape"
setwd(root)

inputs <- readRDS("data-raw/rwanda/rwanda-reserve-inputs.rds")
stored <- readRDS("data-raw/rwanda/rwanda-reserve-results.rds")

problem <- create_problem(
  pu = inputs$planning_units,
  features = inputs$features,
  dist_features = inputs$feature_distribution,
  cost = "cost",
  pu_id_col = "id"
) |>
  add_actions(inputs$actions, cost = 0) |>
  add_effects(inputs$effects, effect_type = "after") |>
  add_constraint_targets_relative(0.30) |>
  add_constraint_locked_planning_units(
    locked_in = inputs$planning_units$protected
  ) |>
  add_spatial_boundary(
    name = "boundary",
    include_self = TRUE,
    edge_factor = 0.5
  ) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_min_fragmentation_planning_units(
    relation_name = "boundary",
    alias = "fragmentation"
  )

new_blm <- c(2e-2, 5e-2)
new_problem <- problem |>
  set_method_weighted_sum(
    aliases = c("cost", "fragmentation"),
    runs = set_runs_manual(data.frame(
      weight_cost = 1,
      weight_fragmentation = new_blm
    )),
    normalize_weights = FALSE,
    objective_scaling = FALSE
  ) |>
  set_solver_gurobi(gap_limit = 0, verbose = TRUE)

new_solutions <- solve(new_problem)
new_runs <- get_runs(new_solutions)
new_objectives <- get_objectives(new_solutions)
new_actions <- get_actions(new_solutions)
new_targets <- get_targets(new_solutions)

old_runs <- stored$blm$runs |>
  mutate(blm = stored$blm_values[run_id])
offset <- max(old_runs$solution_id, na.rm = TRUE)
id_map <- setNames(offset + seq_len(nrow(new_runs)), new_runs$solution_id)

remap_solution <- function(x) {
  x$solution_id <- unname(id_map[as.character(x$solution_id)])
  x
}

new_runs <- remap_solution(new_runs) |>
  mutate(blm = new_blm[run_id])
new_objectives <- remap_solution(new_objectives)
new_actions <- remap_solution(new_actions)
new_targets <- remap_solution(new_targets)

combined_runs <- bind_rows(old_runs, new_runs) |>
  arrange(blm) |>
  mutate(run_id = row_number())

stored$blm$runs <- combined_runs |>
  select(-blm)
stored$blm$objectives <- bind_rows(stored$blm$objectives, new_objectives)
stored$blm$actions <- bind_rows(stored$blm$actions, new_actions)
stored$blm$targets <- bind_rows(stored$blm$targets, new_targets)
stored$blm_values <- combined_runs$blm
stored$generated_with$generated_at <- as.character(Sys.time())

saveRDS(
  stored,
  "data-raw/rwanda/rwanda-reserve-results.rds",
  compress = "xz"
)

print(
  combined_runs |>
    left_join(stored$blm$objectives, by = "solution_id") |>
    select(run_id, solution_id, blm, status, gap, cost, fragmentation)
)
