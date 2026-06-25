test_that("internal formatting, cost, model, and relation helpers cover defensive branches", {
  expect_null(multiscape:::.pa_safe_range(c(NA, Inf, -Inf)))
  expect_equal(multiscape:::.pa_safe_range(c(1.111111, 3.999999), digits = 2), c(1.11, 4))

  expect_equal(multiscape:::.pa_get_cost_vec(NULL), numeric(0))
  expect_equal(multiscape:::.pa_get_cost_vec(data.frame(id = 1:2)), numeric(0))
  expect_equal(multiscape:::.pa_get_cost_vec(data.frame(id = 1:2, monitoring_cost = c(5, 6))), c(5, 6))
  expect_equal(multiscape:::.pa_nrow0(NULL), 0L)
  expect_equal(multiscape:::.pa_nrow0(list(a = 1)), 0L)
  expect_equal(multiscape:::.pa_nrow0(data.frame(a = 1:3)), 3L)

  p <- make_round4_problem(with_actions = TRUE)
  expect_true(multiscape:::.pa_has_model(multiscape:::pproto(NULL, multiscape:::Problem, data = list(model_list = list()))))
  expect_false(multiscape:::.pa_has_model(p))
  expect_equal(multiscape:::.pa_get_action_cost_vec(p), p$data$dist_actions$cost)

  empty_dims <- multiscape:::.pa_model_dims(p)
  expect_equal(empty_dims$n_con, 0L)
  expect_equal(empty_dims$n_var, 0L)
  expect_equal(empty_dims$nnz, 0L)

  p$data$model_list <- list(rhs = c(1, 2), obj = c(0, 1, 2), A_i = c(1L, 2L, 2L), A_j = c(1L, 1L, 2L))
  dims <- multiscape:::.pa_model_dims(p)
  expect_equal(dims$n_con, 2L)
  expect_equal(dims$n_var, 3L)
  expect_equal(dims$nnz, 3L)

  p$data$model_index <- list(w_index = 1:4, x_index = 5:8)

  p$data$model_args <- list(model_type = "test", modelsense = "max", objective_id = "benefit")

  rel <- data.frame(internal_pu1 = c(1, 2), internal_pu2 = c(2, 3), weight = c(0.5, 2))
  p$data$spatial_relations <- list(neighbour = rel, empty = data.frame())
  sm <- multiscape:::.pa_spatial_relations_summary(p)
  expect_equal(sm$name, c("neighbour", "empty"))
  expect_equal(sm$edges, c(2L, 0L))

  filled <- multiscape:::.pa_rbind_fill(data.frame(a = 1), data.frame(b = 2))
  expect_true(all(c("a", "b") %in% names(filled)))
  swapped <- multiscape:::.pa_swap_edges(data.frame(internal_pu1 = 1L, internal_pu2 = 2L, pu1 = 10L, pu2 = 20L, weight = 1))
  expect_equal(swapped$internal_pu1, 2L)
  expect_equal(swapped$pu1, 20L)
})


test_that("input mode and coordinate helpers validate common paths", {
  d <- make_round4_base_data()

  p <- make_round4_problem()
  coords_df <- data.frame(id = 1:4, x = 1:4, y = 4:1, extra = letters[1:4])
  out_df <- multiscape:::.pa_coords_from_input(p, coords = coords_df)
  expect_equal(names(out_df), c("id", "x", "y"))
  expect_equal(out_df$x, 1:4)

  coords_mat <- cbind(x = 10:13, y = 20:23)
  out_mat <- multiscape:::.pa_coords_from_input(p, coords = coords_mat)
  expect_equal(out_mat$id, p$data$pu$id)
  expect_equal(out_mat$y, 20:23)

  p$data$pu_coords <- coords_df
  expect_equal(multiscape:::.pa_coords_from_input(p)$x, 1:4)
  p$data$pu_coords <- NULL
  p$data$pu$x <- c(0, 1, 0, 1)
  p$data$pu$y <- c(0, 0, 1, 1)
  expect_equal(multiscape:::.pa_coords_from_input(p)$y, c(0, 0, 1, 1))

  expect_error(multiscape:::.pa_coords_from_input(p, coords = data.frame(id = 1:4, x = 1:4)), "id, x, y")
  expect_error(multiscape:::.pa_coords_from_input(p, coords = matrix(1:4, ncol = 1)), "at least 2 columns")
  expect_error(multiscape:::.pa_coords_from_input(p, coords = list()), "Unsupported coords")
})


test_that("action weight helper covers subset and validation branches", {
  actions <- data.frame(id = c("a", "b", "c"))
  expect_equal(multiscape:::.pa_action_weights_vector(actions), c(1, 1, 1))
  expect_equal(multiscape:::.pa_action_weights_vector(actions, subset_actions = c(1, 3)), c(1, 0, 1))
  expect_equal(multiscape:::.pa_action_weights_vector(actions, action_weights = c(2, 4, 6)), c(2, 4, 6))
  expect_equal(multiscape:::.pa_action_weights_vector(actions, subset_actions = c(1, 3), action_weights = c(5, 7)), c(5, 0, 7))

  expect_error(multiscape:::.pa_action_weights_vector(actions, subset_actions = c(1, NA)), "NA")
  expect_error(multiscape:::.pa_action_weights_vector(actions, subset_actions = 4), "out of range")
  expect_error(multiscape:::.pa_action_weights_vector(actions, action_weights = c(1, -1, 2)), ">= 0")
  expect_error(multiscape:::.pa_action_weights_vector(actions, action_weights = c(1, 2)), "length")
})
