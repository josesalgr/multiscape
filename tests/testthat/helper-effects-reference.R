reference_problem <- function() {
  suppressWarnings(create_problem(
    pu = data.frame(id = 1:2, cost = 1),
    features = data.frame(id = 1, name = "habitat"),
    dist_features = data.frame(pu = 1:2, feature = 1, amount = c(100, 0))
  )) |> add_actions(actions = data.frame(id = "restore"))
}
