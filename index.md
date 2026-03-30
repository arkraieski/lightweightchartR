# lightweightchartR

`lightweightchartR` brings TradingView’s
[`lightweight-charts`](https://tradingview.github.io/lightweight-charts/)
library to R in a package designed for `quantmod` users.

The goal is simple:

- make interactive market charts feel natural in R
- keep the workflow pipe-friendly
- support common trading-chart patterns like volume overlays, moving
  averages, and indicator panes without a lot of setup

## Why this package?

If you already work with `quantmod`, `xts`, and pipe-based workflows,
this package gives you a more modern interactive charting layer while
keeping the data pipeline familiar.

Instead of building chart specs by hand, you can do this:

``` r
library(quantmod)
library(lightweightchartR)

getSymbols("SPY", from = "2024-01-01")

SPY |>
  lwc_chart(theme = "dark", name = "SPY") |>
  add_volume() |>
  add_sma(50, color = "blue") |>
  add_sma(200, color = "goldenrod") |>
  add_rsi()
```

## Features

- TradingView `lightweight-charts` powered htmlwidget
- Pipe-first API
- Works naturally with `xts`, `zoo`, and `quantmod`
- Candles, bars, lines, areas, and histograms
- Volume overlays in the main price pane
- Technical indicators like SMA, EMA, BBands, RSI, and MACD
- Multi-pane charts
- Hover tooltips for technical overlays in the price pane
- Shiny support
- A small compatibility bridge for
  [`chartSeries()`](https://rdrr.io/pkg/quantmod/man/chartSeries.html)-style
  workflows

## Example

``` r
library(quantmod)
library(lightweightchartR)

getSymbols("AAPL", from = "2023-01-01")

AAPL |>
  lwc_chart(theme = "dark", name = "AAPL") |>
  add_volume() |>
  add_sma(20, color = "#2563eb") |>
  add_sma(50, color = "#f59e0b")
```

## Quantmod-style bridge

For users migrating from
[`quantmod::chartSeries()`](https://rdrr.io/pkg/quantmod/man/chartSeries.html),
there is also a compact wrapper:

``` r
chart_series_lwc(
  AAPL,
  theme = "dark",
  TA = "addVo();addSMA(n = 20);addRSI()"
)
```

## Installation

Install from GitHub once the repository is published:

``` r
pak::pak("arkraieski/lightweightchartR")
```

## Status

The package is currently focused on:

- quantmod workflows
- clean defaults for market-chart use cases
- a small, practical API rather than exposing every charting knob up
  front

More advanced customization can be added over time where it clearly
improves real workflows.
