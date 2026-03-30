# Compatibility wrapper for quantmod users

`chart_series_lwc()` offers a quantmod-flavored bridge into the
pipe-first chart API. It recognizes a small subset of common
[`chartSeries()`](https://rdrr.io/pkg/quantmod/man/chartSeries.html) and
[`addTA()`](https://rdrr.io/pkg/quantmod/man/newTA.html) workflows.

## Usage

``` r
chart_series_lwc(
  x,
  type = c("auto", "candles", "bars", "line", "area"),
  subset = NULL,
  show.grid = TRUE,
  name = NULL,
  log.scale = FALSE,
  TA = NULL,
  theme = c("light", "dark"),
  up.col = "#26a69a",
  dn.col = "#ef5350",
  ...
)
```

## Arguments

- x:

  Market data. Usually an `xts` object with OHLC or OHLCV columns.

- type:

  Base series type. `"auto"` chooses candlesticks when OHLC data is
  available and a line chart otherwise.

- subset:

  Optional quantmod-style subset string, passed through `xts`.

- show.grid:

  Included for API familiarity. Currently ignored.

- name:

  Optional display name for the chart.

- log.scale:

  Included for API familiarity. Currently ignored.

- TA:

  Optional semicolon-delimited TA expressions like
  `"addVo();addSMA(n = 20)"`.

- theme:

  `"light"` or `"dark"`.

- up.col, dn.col:

  Rising and falling colors for price series.

- ...:

  Reserved for future compatibility arguments.

## Value

A `lightweightchartR` chart widget.
