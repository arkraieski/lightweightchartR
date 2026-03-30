# Add OHLC bars from chart data

Add OHLC bars from chart data

## Usage

``` r
add_bars(
  chart,
  pane = "price",
  name = "Bars",
  up_col = "#26a69a",
  down_col = "#ef5350"
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- pane:

  Target pane.

- name:

  Optional series name.

- up_col, down_col:

  Rising and falling colors.

## Value

The updated chart object.
