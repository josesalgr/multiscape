test_that('cost and action fragmentation aliases agree with solver scalar values', {
  skip_if_not_installed('rcbc')
  for(directed in c(FALSE,TRUE)) {
    p <- suppressWarnings(create_problem(data.frame(id=1:2,cost=2),data.frame(id=1,name='feature'),
                        data.frame(pu=1:2,feature=1,amount=0))) |>
      add_actions(data.frame(id=c('allocate','other')),
                  cost=data.frame(pu=1:2,action=c('allocate','other'),cost=c(3,1)),
                  include_pairs=data.frame(pu=1:2,action=c('allocate','other'))) |>
      add_effects(data.frame(pu=1,action='allocate',feature=1,outcome=1)) |>
      add_constraint_targets_absolute(data.frame(feature=1,target=1)) |>
      add_spatial_relations(if(directed) data.frame(pu1=2,pu2=1,weight=3) else data.frame(pu1=c(1,1),pu2=c(2,1),weight=c(3,2)),
                            directed=directed,allow_self=TRUE,name='boundary') |>
      add_objective_min_cost(include_pu_cost=TRUE,alias='cost') |>
      add_objective_min_fragmentation_action(actions='allocate',action_weights=c(2,7),weight_multiplier=.5,alias='spatial') |>
      set_method_weighted_sum(aliases=c('cost','spatial'),runs=set_runs_manual(data.frame(weight_cost=1,weight_spatial=2))) |>
      set_solver_cbc(gap_limit=0,verbose=FALSE)
    s <- solve(p); v <- get_objectives(s)
    expect_equal(v$cost,5,tolerance=1e-7)
    expect_equal(v$spatial,if(directed) 0 else 5,tolerance=1e-7)
    expect_equal(s$solution$solutions[[1]]$solution$objective,v$cost+2*v$spatial,tolerance=1e-7)
  }
})
