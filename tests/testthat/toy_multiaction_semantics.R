toy_multiaction_semantics <- function() {
  pu <- data.frame(
    id = 1:5,
    cost = c(5, 6, 8, 9, 20),
    locked_in = c(0, 0, 0, 0, 0),
    locked_out = c(0, 0, 0, 0, 0)
  )

  features <- data.frame(
    id = 1:2,
    name = c("common", "restoration_only")
  )

  dist_features <- data.frame(
    pu = c(1, 2, 3, 4, 5, 1, 2, 3, 4, 5),
    feature = c(1, 1, 1, 1, 1, 2, 2, 2, 2, 2),
    amount = c(
      5, 5, 5, 5, 5,
      0.5, 0.5, 0.5, 0.5, 0.5
    )
  )

  actions <- data.frame(
    id = c("conservation", "restoration"),
    name = c("conservation", "restoration")
  )

  effects <- data.frame(
    action = c(
      "conservation", "conservation",
      "restoration", "restoration"
    ),
    feature = c(1, 2, 1, 2),
    multiplier = c(
      1.2, 1.0,
      1.1, 2.0
    )
  )

  boundary <- data.frame(
    pu1 = c(1, 2, 3, 4),
    pu2 = c(2, 3, 4, 5),
    boundary = c(1, 1, 1, 1)
  )

  list(
    pu = pu,
    features = features,
    dist_features = dist_features,
    actions = actions,
    effects = effects,
    boundary = boundary
  )
}
