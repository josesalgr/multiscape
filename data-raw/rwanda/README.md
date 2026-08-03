# Reproducing the MaPP Rwanda case study

The spatial inputs used in the Rwanda vignette are distributed by the Marxan
Planning Platform (MaPP), not by `multiscape`. Download the official Rwanda
tutorial archive from <https://marxansolutions.org/marxanmapp/>, extract it,
and set `MAPP_RWANDA_DIRECTORY` to the extracted directory.

From the package source directory, run:

```r
Sys.setenv(MAPP_RWANDA_DIRECTORY = "path/to/extracted/tutorial")
source("data-raw/rwanda/prepare-data.R")
source("data-raw/build_rwanda_vignette_results.R")
source("data-raw/rwanda/render-figures.R")
```

`prepare-data.R` creates a local, ignored working file at
`data-raw/rwanda/rwanda-reserve-inputs.rds`. The second script writes its local
results to `data-raw/rwanda/rwanda-reserve-results.rds`. Neither file should be
added to the package. The second script requires Gurobi and solves every model
to proven optimality (`gap_limit = 0`), without a time limit. Figures shown in the
installed vignette are precomputed publication outputs; the underlying spatial
layers and planning-unit selections are not redistributed with `multiscape`.

The publication figures are written to `vignettes/figures/rwanda/`. Unlike the
local RDS files, these static images are included with the vignette so that it
can be built without the source layers or Gurobi.
