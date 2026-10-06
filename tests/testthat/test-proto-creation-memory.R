test_that('problem prototypes do not retain their creation or predecessor frames', {
  p <- create_problem(data.frame(id=1:2,cost=0),data.frame(id=1,name='habitat'),
                      data.frame(pu=1:2,feature=1,amount=1))
  q <- add_actions(p,data.frame(id='restore'),cost=1)
  expect_identical(parent.env(p),asNamespace('multiscape'))
  expect_identical(parent.env(q),asNamespace('multiscape'))
  expect_false(exists('_inherit',parent.env(q),inherits=FALSE))
  expect_null(p$data$actions)
  expect_equal(q$data$actions$id,'restore')
})

test_that('data cloning isolates table, nested list, and environment changes', {
  p <- create_problem(data.frame(id=1:2,cost=0),data.frame(id=1,name='habitat'),
                      data.frame(pu=1:2,feature=1,amount=1))
  p$data$custom <- list(scope=c(1L,2L),env=new.env(parent=emptyenv()))
  p$data$custom$env$value <- 1
  q <- multiscape:::.pa_clone_data(p)
  q$data$pu$cost[1] <- 9
  q$data$custom$scope[1] <- 99L
  q$data$custom$env$value <- 9
  expect_equal(p$data$pu$cost,c(0,0))
  expect_equal(p$data$custom$scope,c(1L,2L))
  expect_equal(p$data$custom$env$value,1)
})
