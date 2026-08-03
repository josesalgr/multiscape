# Generate the small spatial multi-action example used in the README.
# Run this script from the package root when the dataset needs to be rebuilt.

grid <- sf::st_make_grid(
  sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 8, ymax = 8)),
  n = c(8, 8)
)
planning_units <- sf::st_sf(id = seq_along(grid), geometry = grid)
xy <- sf::st_coordinates(sf::st_centroid(planning_units))
planning_units$x <- xy[, 1]
planning_units$y <- xy[, 2]
planning_units$cost <- 0

woodland <- exp(-((planning_units$x - 2)^2 +
                  (planning_units$y - 6)^2) / 5)
riparian <- exp(-(planning_units$y -
                  (0.65 * planning_units$x + 1.2))^2 / 0.9)
woodland <- woodland / max(woodland)
riparian <- riparian / max(riparian)

features <- data.frame(
  id = 1:2,
  name = c("woodland", "riparian")
)

dist_features <- rbind(
  data.frame(pu = planning_units$id, feature = 1, amount = woodland),
  data.frame(pu = planning_units$id, feature = 2, amount = riparian)
)

actions <- data.frame(
  id = c("protect", "restore"),
  name = c("Protect", "Restore")
)

action_costs <- rbind(
  data.frame(
    pu = planning_units$id,
    action = "protect",
    cost = 1 + 0.10 * planning_units$x
  ),
  data.frame(
    pu = planning_units$id,
    action = "restore",
    cost = 1.4 + 0.12 * (8 - planning_units$x)
  )
)

effect_assumptions <- data.frame(
  action = rep(c("protect", "restore"), each = 2),
  feature = rep(features$id, times = 2),
  relative_change = c(1.00, 0.30, 0.25, 1.30)
)

effects <- merge(
  dist_features,
  effect_assumptions,
  by = "feature",
  all = FALSE
)
effects$delta <- effects$amount * effects$relative_change
effects <- effects[, c("pu", "action", "feature", "delta")]
effects <- effects[order(effects$pu, effects$action, effects$feature), ]
row.names(effects) <- NULL

sim_multiaction <- list(
  planning_units = planning_units,
  features = features,
  dist_features = dist_features,
  actions = actions,
  action_costs = action_costs,
  effect_assumptions = effect_assumptions,
  effects = effects
)

save(sim_multiaction, file = "data/sim_multiaction.rda", compress = "xz")
