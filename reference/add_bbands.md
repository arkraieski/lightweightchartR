# Add Bollinger Bands

Add Bollinger Bands

## Usage

``` r
add_bbands(
  chart,
  n = 20,
  sd = 2,
  column = NULL,
  pane = "price",
  color = "#7c3aed",
  ...
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- n:

  Window size.

- sd:

  Number of standard deviations.

- column:

  Source column. Defaults to the close column.

- pane:

  Target pane.

- color:

  Series color.

- ...:

  Reserved for future extensions.

## Value

The updated chart object.
