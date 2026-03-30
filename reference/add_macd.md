# Add MACD in a separate pane by default

Add MACD in a separate pane by default

## Usage

``` r
add_macd(
  chart,
  nFast = 12,
  nSlow = 26,
  nSig = 9,
  column = NULL,
  pane = "macd",
  pane_height = 1,
  ...
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- nFast, nSlow, nSig:

  MACD periods.

- column:

  Source column. Defaults to the close column.

- pane:

  Target pane.

- pane_height:

  Relative pane height for the RSI pane.

- ...:

  Reserved for future extensions.

## Value

The updated chart object.
