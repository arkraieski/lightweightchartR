#' Add a simple moving average
#'
#' @param chart A `lightweightchartR` chart object.
#' @param n Window size.
#' @param column Source column. Defaults to the close column.
#' @param pane Target pane.
#' @param color Series color.
#' @param ... Reserved for future extensions.
#'
#' @return The updated chart object.
#' @export
add_sma <- function(chart, n = 20, column = NULL, pane = "price", color = "#2563eb", ...) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)
  values <- TTR::SMA(as.numeric(context$data[, column, drop = TRUE]), n = n)
  series <- xts::xts(values, order.by = zoo::index(context$data), tzone = attr(zoo::index(context$data), "tzone"))
  colnames(series) <- sprintf("SMA(%s)", n)
  add_ta(chart, series, type = "line", pane = pane, name = colnames(series), color = color, overlay = identical(pane, "price"))
}

#' Add an exponential moving average
#'
#' @inheritParams add_sma
#'
#' @return The updated chart object.
#' @export
add_ema <- function(chart, n = 20, column = NULL, pane = "price", color = "#ea580c", ...) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)
  values <- TTR::EMA(as.numeric(context$data[, column, drop = TRUE]), n = n)
  series <- xts::xts(values, order.by = zoo::index(context$data), tzone = attr(zoo::index(context$data), "tzone"))
  colnames(series) <- sprintf("EMA(%s)", n)
  add_ta(chart, series, type = "line", pane = pane, name = colnames(series), color = color, overlay = identical(pane, "price"))
}

#' Add Bollinger Bands
#'
#' @param sd Number of standard deviations.
#'
#' @inheritParams add_sma
#'
#' @return The updated chart object.
#' @export
add_bbands <- function(chart, n = 20, sd = 2, column = NULL, pane = "price", color = "#7c3aed", ...) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)
  bands <- TTR::BBands(as.numeric(context$data[, column, drop = TRUE]), n = n, sd = sd)
  bands <- xts::xts(bands, order.by = zoo::index(context$data), tzone = attr(zoo::index(context$data), "tzone"))
  chart <- add_ta(chart, bands[, "up", drop = FALSE], type = "line", pane = pane, name = sprintf("BBands Up(%s)", n), color = color, overlay = identical(pane, "price"))
  chart <- add_ta(chart, bands[, "mavg", drop = FALSE], type = "line", pane = pane, name = sprintf("BBands Mid(%s)", n), color = "#475569", overlay = identical(pane, "price"))
  add_ta(chart, bands[, "dn", drop = FALSE], type = "line", pane = pane, name = sprintf("BBands Down(%s)", n), color = color, overlay = identical(pane, "price"))
}

#' Add RSI in a separate pane by default
#'
#' @inheritParams add_sma
#' @param pane_height Relative pane height for the RSI pane.
#'
#' @return The updated chart object.
#' @export
add_rsi <- function(chart, n = 14, column = NULL, pane = "rsi", color = "#dc2626", pane_height = 0.8, ...) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)
  values <- TTR::RSI(as.numeric(context$data[, column, drop = TRUE]), n = n)
  series <- xts::xts(values, order.by = zoo::index(context$data), tzone = attr(zoo::index(context$data), "tzone"))
  colnames(series) <- sprintf("RSI(%s)", n)
  add_ta(chart, series, type = "line", pane = pane, name = colnames(series), color = color, pane_height = pane_height, overlay = FALSE)
}

#' Add MACD in a separate pane by default
#'
#' @param nFast,nSlow,nSig MACD periods.
#'
#' @inheritParams add_rsi
#'
#' @return The updated chart object.
#' @export
add_macd <- function(chart,
                     nFast = 12,
                     nSlow = 26,
                     nSig = 9,
                     column = NULL,
                     pane = "macd",
                     pane_height = 1,
                     ...) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)
  values <- TTR::MACD(as.numeric(context$data[, column, drop = TRUE]), nFast = nFast, nSlow = nSlow, nSig = nSig)
  values <- xts::xts(values, order.by = zoo::index(context$data), tzone = attr(zoo::index(context$data), "tzone"))
  chart <- add_ta(chart, values[, "macd", drop = FALSE], type = "line", pane = pane, name = "MACD", color = "#2563eb", pane_height = pane_height, overlay = FALSE)
  chart <- add_ta(chart, values[, "signal", drop = FALSE], type = "line", pane = pane, name = "Signal", color = "#ea580c", pane_height = pane_height, overlay = FALSE)
  add_ta(chart, values[, "macd", drop = FALSE] - values[, "signal", drop = FALSE], type = "histogram", pane = pane, name = "Histogram", color = "#64748b", pane_height = pane_height, overlay = FALSE)
}
