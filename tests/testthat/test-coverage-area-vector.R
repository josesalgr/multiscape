test_that("area retrieval aligns raw data and converts inferred units", {
  get_area <- getFromNamespace(".pa_get_area_vec", "multiscape")
  p <- make_round3_tabular_problem()

  p$data$pu$area_ha <- c(1, 2, 3, 4)
  expect_equal(
    unname(get_area(p, area_col = "area_ha", area_unit = "m2")),
    c(1, 2, 3, 4) * 1e4
  )
  expect_equal(
    unname(get_area(p, area_col = "area_ha", area_unit = "km2")),
    c(0.01, 0.02, 0.03, 0.04)
  )

  raw <- make_round3_tabular_problem()
  raw$data$pu_data_raw <- data.frame(
    id = c(4, 2, 1, 3),
    area_km2 = c(4, 2, 1, 3)
  )
  expect_equal(
    unname(get_area(raw, area_unit = "m2")),
    c(1, 2, 3, 4) * 1e6
  )
  expect_equal(
    unname(get_area(raw, area_col = "area_km2", area_unit = "km2")),
    c(1, 2, 3, 4)
  )
})


test_that("area retrieval validates explicit columns and raw-data alignment", {
  get_area <- getFromNamespace(".pa_get_area_vec", "multiscape")
  p <- make_round3_tabular_problem()

  expect_error(get_area(p, area_col = ""), "non-empty string")
  expect_error(get_area(p, area_col = "missing"), "was not found")

  nonfinite <- make_round3_tabular_problem()
  nonfinite$data$pu$area <- c(1, 2, NA, 4)
  expect_error(get_area(nonfinite), "NA or non-finite")

  negative <- make_round3_tabular_problem()
  negative$data$pu$surface <- c(1, 2, -1, 4)
  expect_error(get_area(negative), "negative")

  no_raw_id <- make_round3_tabular_problem()
  no_raw_id$data$pu_data_raw <- data.frame(area = 1:4)
  expect_error(get_area(no_raw_id), "missing an 'id' column")

  duplicate_raw_id <- make_round3_tabular_problem()
  duplicate_raw_id$data$pu_data_raw <- data.frame(
    id = c(1, 1, 3, 4),
    area = 1:4
  )
  expect_error(get_area(duplicate_raw_id), "duplicated planning unit ids")

  unmatched <- make_round3_tabular_problem()
  unmatched$data$pu_data_raw <- data.frame(
    id = c(1, 2, 3, 99),
    area = 1:4
  )
  expect_error(get_area(unmatched), "Could not match all")
})
