# Getting Started

`lightweightchartR` brings TradingView’s `lightweight-charts` library to
R with an API that feels natural for `quantmod` and `xts` users.

The package is built around a simple idea:

- start with market data
- create a chart with
  [`lwc_chart()`](https://arkraieski.github.io/lightweightchartR/reference/lwc_chart.md)
- add layers and indicators with pipes

## Load packages

``` r
library(quantmod)
#> Loading required package: xts
#> Loading required package: zoo
#> 
#> Attaching package: 'zoo'
#> The following objects are masked from 'package:base':
#> 
#>     as.Date, as.Date.numeric
#> Loading required package: TTR
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo
library(lightweightchartR)
```

## Download some market data

We’ll use Apple price data from Yahoo Finance.

``` r
getSymbols("AAPL", from = "2024-01-01", auto.assign = TRUE)
#> [1] "AAPL"

aapl <- AAPL
head(aapl)
#>            AAPL.Open AAPL.High AAPL.Low AAPL.Close AAPL.Volume AAPL.Adjusted
#> 2024-01-02    187.15    188.44   183.89     185.64    82488700      183.7313
#> 2024-01-03    184.22    185.88   183.43     184.25    58414500      182.3556
#> 2024-01-04    182.15    183.09   180.88     181.91    71983600      180.0397
#> 2024-01-05    181.99    182.76   180.17     181.18    62379700      179.3172
#> 2024-01-08    182.09    185.60   181.50     185.56    59144500      183.6521
#> 2024-01-09    183.92    185.15   182.73     185.14    42841800      183.2364
```

## Create a basic chart

If your data has OHLC columns,
[`lwc_chart()`](https://arkraieski.github.io/lightweightchartR/reference/lwc_chart.md)
will automatically choose a candlestick chart.

``` r
aapl |>
  lwc_chart(theme = "dark", name = "AAPL")
```

## Add volume and moving averages

You can layer additional series with a pipe-first workflow.

``` r
aapl |>
  lwc_chart(theme = "dark", name = "AAPL") |>
  add_volume() |>
  add_sma(20, color = "#2563eb") |>
  add_sma(50, color = "#f59e0b")
```

By default:

- volume overlays into the main price pane
- moving averages added with
  [`add_sma()`](https://arkraieski.github.io/lightweightchartR/reference/add_sma.md)
  are drawn in the price pane

## Add an indicator pane

Indicators like RSI can go into their own pane.

``` r
aapl |>
  lwc_chart(theme = "dark", name = "AAPL") |>
  add_volume() |>
  add_sma(20, color = "#2563eb") |>
  add_sma(50, color = "#f59e0b") |>
  add_rsi()
```

## Use the quantmod-style bridge

If you’re coming from
[`chartSeries()`](https://rdrr.io/pkg/quantmod/man/chartSeries.html),
the package also includes a compact compatibility wrapper.

``` r
chart_series_lwc(
  aapl,
  theme = "dark",
  TA = "addVo();addSMA(n = 20);addRSI()"
)
```

## Customize chart-level behavior

[`lwc_chart()`](https://arkraieski.github.io/lightweightchartR/reference/lwc_chart.md)
also lets you control chart-wide behavior such as widget height and
technical-analysis hover tooltips.

``` r
aapl |>
  lwc_chart(
    theme = "dark",
    name = "AAPL",
    height = 260,
    ta_tooltip = TRUE,
    ta_tooltip_threshold = 10
  ) |>
  add_volume() |>
  add_sma(20, color = "#2563eb") |>
  add_sma(50, color = "#f59e0b")
```

## Summary

The basic workflow is:

1.  Start with `xts` market data
2.  Call
    [`lwc_chart()`](https://arkraieski.github.io/lightweightchartR/reference/lwc_chart.md)
3.  Add layers and indicators with `add_*()` helpers

That gives you a modern interactive chart while keeping the workflow
familiar for `quantmod` users.
