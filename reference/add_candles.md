# Add candlesticks from chart data

Add candlesticks from chart data

## Usage

``` r
add_candles(
  chart,
  pane = "price",
  name = "Candles",
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
