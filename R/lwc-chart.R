#' Create a lightweight chart
#'
#' `lwc_chart()` creates a TradingView lightweight chart widget from `xts`,
#' `zoo`, or data frame inputs. The result is a pipeable chart object that can
#' be extended with `add_*()` helpers.
#'
#' @param data Market data. Usually an `xts` object with OHLC or OHLCV columns.
#' @param type Base series type. `"auto"` chooses candlesticks when OHLC data is
#'   available and a line chart otherwise.
#' @param subset Optional quantmod-style subset string, passed through `xts`.
#' @param name Optional display name for the chart.
#' @param theme `"light"` or `"dark"`.
#' @param width,height Widget dimensions passed to `htmlwidgets`.
#' @param elementId Optional element id.
#' @param up_col,down_col Rising/falling color defaults for price series.
#' @param ta_tooltip Whether to show hover tooltips for price-pane technical
#'   analysis overlays.
#' @param ta_tooltip_threshold Pixel distance used to match the pointer to the
#'   nearest overlay line for the TA tooltip.
#'
#' @return An `htmlwidget` object that also supports pipe-based layer helpers.
#' @export
lwc_chart <- function(data,
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
                      ta_tooltip_threshold = 14) {
  type <- match.arg(type)
  theme <- match.arg(theme)

  if (!is.numeric(ta_tooltip_threshold) || length(ta_tooltip_threshold) != 1L || is.na(ta_tooltip_threshold) || ta_tooltip_threshold < 0) {
    stop("`ta_tooltip_threshold` must be a single non-negative number.", call. = FALSE)
  }

  xts_data <- ensure_xts(data)
  xts_data <- apply_subset(xts_data, subset)
  mapping <- detect_mapping(xts_data)
  base_type <- infer_base_type(mapping, type)
  main_series <- build_main_series(xts_data, mapping, base_type, up_col, down_col)

  spec <- list(
    options = theme_defaults(theme),
    panes = list(
      list(
        id = "price",
        height = 3,
        series = list(main_series)
      )
    )
  )

  widget <- htmlwidgets::createWidget(
    name = "lightweightchartR",
    x = list(
      spec = spec,
      sizing = list(height = height %||% "480px", width = width %||% "100%"),
      meta = list(
        name = name %||% deparse(substitute(data)),
        theme = theme,
        ta_tooltip = isTRUE(ta_tooltip),
        ta_tooltip_threshold = as.numeric(ta_tooltip_threshold)
      )
    ),
    width = width,
    height = height,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      defaultHeight = 600,
      padding = 0,
      viewer.padding = 0,
      viewer.fill = TRUE,
      viewer.paneHeight = 600,
      browser.padding = 0,
      browser.fill = TRUE,
      knitr.figure = FALSE,
      fill = TRUE
    ),
    package = "lightweightchartR",
    elementId = elementId
  )

  class(widget) <- c("lightweightchartR", class(widget))
  context <- list(
    data = xts_data,
    mapping = mapping,
    theme = theme,
    name = name %||% deparse(substitute(data)),
    up_col = up_col,
    down_col = down_col,
    last_pane = "price"
  )

  set_widget_context(widget, context)
}

#' Compatibility wrapper for quantmod users
#'
#' `chart_series_lwc()` offers a quantmod-flavored bridge into the pipe-first
#' chart API. It recognizes a small subset of common `chartSeries()` and
#' `addTA()` workflows.
#'
#' @param x Market data. Usually an `xts` object with OHLC or OHLCV columns.
#' @inheritParams lwc_chart
#' @param show.grid Included for API familiarity. Currently ignored.
#' @param TA Optional semicolon-delimited TA expressions like
#'   `"addVo();addSMA(n = 20)"`.
#' @param log.scale Included for API familiarity. Currently ignored.
#' @param up.col,dn.col Rising and falling colors for price series.
#' @param ... Reserved for future compatibility arguments.
#'
#' @return A `lightweightchartR` chart widget.
#' @export
chart_series_lwc <- function(x,
                             type = c("auto", "candles", "bars", "line", "area"),
                             subset = NULL,
                             show.grid = TRUE,
                             name = NULL,
                             log.scale = FALSE,
                             TA = NULL,
                             theme = c("light", "dark"),
                             up.col = "#26a69a",
                             dn.col = "#ef5350",
                             ...) {
  chart <- lwc_chart(
    data = x,
    type = type,
    subset = subset,
    name = name,
    theme = theme,
    up_col = up.col,
    down_col = dn.col
  )

  if (!is.null(TA) && nzchar(TA)) {
    calls <- strsplit(TA, ";", fixed = TRUE)[[1L]]
    calls <- calls[nzchar(trimws(calls))]

    for (call_text in calls) {
      parsed <- parse_ta_call(call_text)
      chart <- do.call(parsed$fn, c(list(chart = chart), parsed$args))
    }
  }

  chart
}

#' Reconfigure an existing chart
#'
#' `rechart_lwc()` updates global display options on an existing chart.
#'
#' @param chart A `lightweightchartR` chart object.
#' @param theme Optional replacement theme.
#' @param ... Additional lightweight-charts chart options merged into the
#'   existing top-level options.
#'
#' @return The updated chart object.
#' @export
rechart_lwc <- function(chart, theme = NULL, ...) {
  chart <- ensure_widget(chart)
  spec <- chart$x$spec
  context <- widget_context(chart)

  if (!is.null(theme)) {
    spec$options <- utils::modifyList(spec$options, theme_defaults(match.arg(theme, c("light", "dark"))))
    context$theme <- theme
  }

  extras <- list(...)
  if (length(extras)) {
    spec$options <- utils::modifyList(spec$options, extras)
  }

  chart <- update_spec(chart, spec)
  set_widget_context(chart, context)
}

#' Shiny bindings for lightweightchartR
#'
#' @param outputId Output variable to read from.
#' @param width,height CSS dimensions for the widget container.
#'
#' @name lightweightchartR-shiny
#' @export
lightweightchartROutput <- function(outputId, width = "100%", height = "480px") {
  htmlwidgets::shinyWidgetOutput(outputId, "lightweightchartR", width, height, package = "lightweightchartR")
}

#' @param expr An expression that generates a chart.
#' @param env The environment in which to evaluate `expr`.
#' @param quoted Is `expr` already quoted?
#'
#' @rdname lightweightchartR-shiny
#' @export
renderLightweightchartR <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }

  htmlwidgets::shinyRenderWidget(expr, lightweightchartROutput, env, quoted = TRUE)
}
