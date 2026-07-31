# Add distance-threshold spatial relations

Build and register a spatial relation connecting planning units whose
Euclidean distance is less than or equal to a user-defined threshold.

This constructor does not require polygon geometry and instead uses
planning-unit coordinates.

## Usage

``` r
add_spatial_distance(
  x,
  coords = NULL,
  max_distance,
  name = "distance",
  weight_mode = c("constant", "inverse", "inverse_sq"),
  distance_eps = 1e-09
)
```

## Arguments

- x:

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).

- coords:

  Optional coordinates specification, following the same rules as in
  [`add_spatial_knn`](https://josesalgr.github.io/multiscape/reference/add_spatial_knn.md).

- max_distance:

  Positive numeric scalar giving the maximum distance for an edge.

- name:

  Character string giving the key under which the relation is stored.

- weight_mode:

  Character string indicating how distance is converted to weight. Must
  be one of `"constant"`, `"inverse"`, or `"inverse_sq"`.

- distance_eps:

  Small positive numeric constant used to avoid division by zero in
  inverse-distance weighting.

## Value

An updated `Problem` object.

## Details

Use this function when neighbourhood should be defined by a fixed
distance radius rather than by polygon topology or a fixed number of
neighbours.

Let \\s_i = (x_i, y_i)\\ denote the coordinates of planning unit \\i\\.
Let \\d\_{ij}\\ be the Euclidean distance between planning units \\i\\
and \\j\\.

For a user-supplied threshold \\d\_{\max}\\, this constructor creates an
edge between \\i\\ and \\j\\ whenever: \$\$ d\_{ij} \le d\_{\max}. \$\$

Edge weights are assigned according to `weight_mode`:

- `"constant"`: \$\$\omega\_{ij} = 1,\$\$

- `"inverse"`: \$\$\omega\_{ij} = \frac{1}{\max(d\_{ij},
  \varepsilon)},\$\$

- `"inverse_sq"`: \$\$\omega\_{ij} = \frac{1}{\max(d\_{ij},
  \varepsilon)^2},\$\$

where \\\varepsilon\\ = `distance_eps` is a small constant.

The implementation computes an \\O(n^2)\\ distance matrix and is
therefore best suited to small or moderate numbers of planning units.
For large problems,
[`add_spatial_knn`](https://josesalgr.github.io/multiscape/reference/add_spatial_knn.md)
is often more scalable.

The resulting relation is registered as undirected.

## See also

[`add_spatial_knn`](https://josesalgr.github.io/multiscape/reference/add_spatial_knn.md),
[`add_spatial_relations`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

p <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
)

p <- add_spatial_distance(
  x = p,
  max_distance = 1.01,
  name = "within_1",
  weight_mode = "constant"
)

p$data$spatial_relations$within_1
#>     internal_pu1 internal_pu2 weight pu1 pu2 distance            source
#> 28            10           11      1  11  10        1 distance_constant
#> 29            10           18      1  18  10        1 distance_constant
#> 32            11           12      1  12  11        1 distance_constant
#> 33            11           19      1  19  11        1 distance_constant
#> 36            12           13      1  13  12        1 distance_constant
#> 37            12           20      1  20  12        1 distance_constant
#> 40            13           14      1  14  13        1 distance_constant
#> 41            13           21      1  21  13        1 distance_constant
#> 44            14           15      1  15  14        1 distance_constant
#> 45            14           22      1  22  14        1 distance_constant
#> 48            15           16      1  16  15        1 distance_constant
#> 49            15           23      1  23  15        1 distance_constant
#> 52            16           24      1  24  16        1 distance_constant
#> 54            17           18      1  18  17        1 distance_constant
#> 55            17           25      1  25  17        1 distance_constant
#> 58            18           19      1  19  18        1 distance_constant
#> 59            18           26      1  26  18        1 distance_constant
#> 62            19           20      1  20  19        1 distance_constant
#> 63            19           27      1  27  19        1 distance_constant
#> 1              1            2      1   2   1        1 distance_constant
#> 2              1            9      1   9   1        1 distance_constant
#> 66            20           21      1  21  20        1 distance_constant
#> 67            20           28      1  28  20        1 distance_constant
#> 70            21           22      1  22  21        1 distance_constant
#> 71            21           29      1  29  21        1 distance_constant
#> 74            22           23      1  23  22        1 distance_constant
#> 75            22           30      1  30  22        1 distance_constant
#> 78            23           24      1  24  23        1 distance_constant
#> 79            23           31      1  31  23        1 distance_constant
#> 82            24           32      1  32  24        1 distance_constant
#> 84            25           26      1  26  25        1 distance_constant
#> 85            25           33      1  33  25        1 distance_constant
#> 88            26           27      1  27  26        1 distance_constant
#> 89            26           34      1  34  26        1 distance_constant
#> 92            27           28      1  28  27        1 distance_constant
#> 93            27           35      1  35  27        1 distance_constant
#> 96            28           29      1  29  28        1 distance_constant
#> 97            28           36      1  36  28        1 distance_constant
#> 100           29           30      1  30  29        1 distance_constant
#> 101           29           37      1  37  29        1 distance_constant
#> 5              2           10      1  10   2        1 distance_constant
#> 4              2            3      1   3   2        1 distance_constant
#> 104           30           31      1  31  30        1 distance_constant
#> 105           30           38      1  38  30        1 distance_constant
#> 108           31           32      1  32  31        1 distance_constant
#> 109           31           39      1  39  31        1 distance_constant
#> 112           32           40      1  40  32        1 distance_constant
#> 114           33           34      1  34  33        1 distance_constant
#> 115           33           41      1  41  33        1 distance_constant
#> 118           34           35      1  35  34        1 distance_constant
#> 119           34           42      1  42  34        1 distance_constant
#> 122           35           36      1  36  35        1 distance_constant
#> 123           35           43      1  43  35        1 distance_constant
#> 126           36           37      1  37  36        1 distance_constant
#> 127           36           44      1  44  36        1 distance_constant
#> 130           37           38      1  38  37        1 distance_constant
#> 131           37           45      1  45  37        1 distance_constant
#> 134           38           39      1  39  38        1 distance_constant
#> 135           38           46      1  46  38        1 distance_constant
#> 138           39           40      1  40  39        1 distance_constant
#> 139           39           47      1  47  39        1 distance_constant
#> 8              3           11      1  11   3        1 distance_constant
#> 7              3            4      1   4   3        1 distance_constant
#> 142           40           48      1  48  40        1 distance_constant
#> 144           41           42      1  42  41        1 distance_constant
#> 145           41           49      1  49  41        1 distance_constant
#> 148           42           43      1  43  42        1 distance_constant
#> 149           42           50      1  50  42        1 distance_constant
#> 152           43           44      1  44  43        1 distance_constant
#> 153           43           51      1  51  43        1 distance_constant
#> 156           44           45      1  45  44        1 distance_constant
#> 157           44           52      1  52  44        1 distance_constant
#> 160           45           46      1  46  45        1 distance_constant
#> 161           45           53      1  53  45        1 distance_constant
#> 164           46           47      1  47  46        1 distance_constant
#> 165           46           54      1  54  46        1 distance_constant
#> 168           47           48      1  48  47        1 distance_constant
#> 169           47           55      1  55  47        1 distance_constant
#> 172           48           56      1  56  48        1 distance_constant
#> 174           49           50      1  50  49        1 distance_constant
#> 175           49           57      1  57  49        1 distance_constant
#> 11             4           12      1  12   4        1 distance_constant
#> 10             4            5      1   5   4        1 distance_constant
#> 178           50           51      1  51  50        1 distance_constant
#> 179           50           58      1  58  50        1 distance_constant
#> 182           51           52      1  52  51        1 distance_constant
#> 183           51           59      1  59  51        1 distance_constant
#> 186           52           53      1  53  52        1 distance_constant
#> 187           52           60      1  60  52        1 distance_constant
#> 190           53           54      1  54  53        1 distance_constant
#> 191           53           61      1  61  53        1 distance_constant
#> 194           54           55      1  55  54        1 distance_constant
#> 195           54           62      1  62  54        1 distance_constant
#> 198           55           56      1  56  55        1 distance_constant
#> 199           55           63      1  63  55        1 distance_constant
#> 202           56           64      1  64  56        1 distance_constant
#> 204           57           58      1  58  57        1 distance_constant
#> 207           58           59      1  59  58        1 distance_constant
#> 210           59           60      1  60  59        1 distance_constant
#> 14             5           13      1  13   5        1 distance_constant
#> 13             5            6      1   6   5        1 distance_constant
#> 213           60           61      1  61  60        1 distance_constant
#> 216           61           62      1  62  61        1 distance_constant
#> 219           62           63      1  63  62        1 distance_constant
#> 222           63           64      1  64  63        1 distance_constant
#> 17             6           14      1  14   6        1 distance_constant
#> 16             6            7      1   7   6        1 distance_constant
#> 20             7           15      1  15   7        1 distance_constant
#> 19             7            8      1   8   7        1 distance_constant
#> 22             8           16      1  16   8        1 distance_constant
#> 24             9           10      1  10   9        1 distance_constant
#> 25             9           17      1  17   9        1 distance_constant
#>     relation_name
#> 28       within_1
#> 29       within_1
#> 32       within_1
#> 33       within_1
#> 36       within_1
#> 37       within_1
#> 40       within_1
#> 41       within_1
#> 44       within_1
#> 45       within_1
#> 48       within_1
#> 49       within_1
#> 52       within_1
#> 54       within_1
#> 55       within_1
#> 58       within_1
#> 59       within_1
#> 62       within_1
#> 63       within_1
#> 1        within_1
#> 2        within_1
#> 66       within_1
#> 67       within_1
#> 70       within_1
#> 71       within_1
#> 74       within_1
#> 75       within_1
#> 78       within_1
#> 79       within_1
#> 82       within_1
#> 84       within_1
#> 85       within_1
#> 88       within_1
#> 89       within_1
#> 92       within_1
#> 93       within_1
#> 96       within_1
#> 97       within_1
#> 100      within_1
#> 101      within_1
#> 5        within_1
#> 4        within_1
#> 104      within_1
#> 105      within_1
#> 108      within_1
#> 109      within_1
#> 112      within_1
#> 114      within_1
#> 115      within_1
#> 118      within_1
#> 119      within_1
#> 122      within_1
#> 123      within_1
#> 126      within_1
#> 127      within_1
#> 130      within_1
#> 131      within_1
#> 134      within_1
#> 135      within_1
#> 138      within_1
#> 139      within_1
#> 8        within_1
#> 7        within_1
#> 142      within_1
#> 144      within_1
#> 145      within_1
#> 148      within_1
#> 149      within_1
#> 152      within_1
#> 153      within_1
#> 156      within_1
#> 157      within_1
#> 160      within_1
#> 161      within_1
#> 164      within_1
#> 165      within_1
#> 168      within_1
#> 169      within_1
#> 172      within_1
#> 174      within_1
#> 175      within_1
#> 11       within_1
#> 10       within_1
#> 178      within_1
#> 179      within_1
#> 182      within_1
#> 183      within_1
#> 186      within_1
#> 187      within_1
#> 190      within_1
#> 191      within_1
#> 194      within_1
#> 195      within_1
#> 198      within_1
#> 199      within_1
#> 202      within_1
#> 204      within_1
#> 207      within_1
#> 210      within_1
#> 14       within_1
#> 13       within_1
#> 213      within_1
#> 216      within_1
#> 219      within_1
#> 222      within_1
#> 17       within_1
#> 16       within_1
#> 20       within_1
#> 19       within_1
#> 22       within_1
#> 24       within_1
#> 25       within_1
```
