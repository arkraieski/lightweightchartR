# Create a lightweight chart

`lwc_chart()` creates a TradingView lightweight chart widget from `xts`,
`zoo`, or data frame inputs. The result is a pipeable chart object that
can be extended with `add_*()` helpers.

## Usage

``` r
lwc_chart(
  data,
  type = c("auto", "candles", "bars", "line", "area"),
  subset = NULL,
  name = NULL,
  theme = c("light", "dark"),
  width = NULL,
  height = NULL,
  elementId = NULL,
  up_col = "#26a69a",
  down_col = "#ef5350",
  ta_tooltip = TRUE,
  ta_tooltip_threshold = 14
)
```

## Arguments

- data:

  Market data. Usually an `xts` object with OHLC or OHLCV columns.

- type:

  Base series type. `"auto"` chooses candlesticks when OHLC data is
  available and a line chart otherwise.

- subset:

  Optional quantmod-style subset string, passed through `xts`.

- name:

  Optional display name for the chart.

- theme:

  `"light"` or `"dark"`.

- width, height:

  Widget dimensions passed to `htmlwidgets`.

- elementId:

  Optional element id.

- up_col, down_col:

  Rising/falling color defaults for price series.

- ta_tooltip:

  Whether to show hover tooltips for price-pane technical analysis
  overlays.

- ta_tooltip_threshold:

  Pixel distance used to match the pointer to the nearest overlay line
  for the TA tooltip.

## Value

An `htmlwidget` object that also supports pipe-based layer helpers.
