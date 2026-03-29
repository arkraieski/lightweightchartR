#' @keywords internal
upsert_pane <- function(spec, pane, height = NULL) {
  ids <- vapply(spec$panes, `[[`, character(1), "id")
  if (pane %in% ids) {
    return(spec)
  }

  spec$panes[[length(spec$panes) + 1L]] <- list(id = pane, height = height %||% 1, series = list())
  spec
}

#' @keywords internal
append_series <- function(chart, series, pane_height = NULL) {
  chart <- ensure_widget(chart)
  spec <- upsert_pane(chart$x$spec, series$pane, pane_height)
  pane_ids <- vapply(spec$panes, `[[`, character(1), "id")
  idx <- match(series$pane, pane_ids)
  spec$panes[[idx]]$series[[length(spec$panes[[idx]]$series) + 1L]] <- series

  context <- widget_context(chart)
  context$last_pane <- series$pane

  chart <- update_spec(chart, spec)
  set_widget_context(chart, context)
}

#' Add a generic indicator or comparison series
#'
#' @param chart A `lightweightchartR` chart object.
#' @param values An `xts`, `zoo`, or data frame object with a `time` column.
#' @param type One of `"line"`, `"area"`, or `"histogram"`.
#' @param pane Target pane. Defaults to `"price"`.
#' @param name Optional display name.
#' @param color Optional series color.
#' @param pane_height Relative pane height for new panes.
#' @param overlay Whether to overlay on the existing price scale.
#'
#' @return The updated chart object.
#' @export
add_ta <- function(chart,
                   values,
                   type = c("line", "area", "histogram"),
                   pane = "price",
                   name = NULL,
                   color = "#2563eb",
                   pane_height = NULL,
                   overlay = identical(pane, "price")) {
  chart <- ensure_widget(chart)
  type <- match.arg(type)
  series_data <- normalize_indicator_xts(values, default_name = name %||% "Indicator")

  for (i in seq_along(series_data)) {
    entry <- series_data[[i]]
    series_name <- name %||% entry$name
    options <- switch(
      type,
      line = list(color = color, lineWidth = 2),
      area = list(lineColor = color, topColor = paste0(color, "55"), bottomColor = paste0(color, "08")),
      histogram = list(color = color)
    )

    chart <- append_series(
      chart,
      make_series(
        id = paste0(gsub("[^A-Za-z0-9]+", "-", tolower(series_name)), "-", i),
        type = type,
        data = entry$data,
        pane = pane,
        name = series_name,
        options = options,
        overlay = overlay
      ),
      pane_height = pane_height
    )
  }

  chart
}

#' Add candlesticks from chart data
#'
#' @param chart A `lightweightchartR` chart object.
#' @param pane Target pane.
#' @param name Optional series name.
#' @param up_col,down_col Rising and falling colors.
#'
#' @return The updated chart object.
#' @export
add_candles <- function(chart, pane = "price", name = "Candles", up_col = "#26a69a", down_col = "#ef5350") {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  required <- context$mapping[c("open", "high", "low", "close")]

  if (any(vapply(required, is.null, logical(1)))) {
    stop("Candlestick layers require open, high, low, and close columns.", call. = FALSE)
  }

  append_series(
    chart,
    make_series(
      id = paste0("candles-", length(chart$x$spec$panes[[1]]$series) + 1L),
      type = "candlestick",
      data = xts_to_records(context$data, required),
      pane = pane,
      name = name,
      options = list(upColor = up_col, downColor = down_col, borderVisible = FALSE, wickUpColor = up_col, wickDownColor = down_col),
      overlay = identical(pane, "price")
    )
  )
}

#' Add OHLC bars from chart data
#'
#' @inheritParams add_candles
#'
#' @return The updated chart object.
#' @export
add_bars <- function(chart, pane = "price", name = "Bars", up_col = "#26a69a", down_col = "#ef5350") {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  required <- context$mapping[c("open", "high", "low", "close")]

  if (any(vapply(required, is.null, logical(1)))) {
    stop("OHLC bar layers require open, high, low, and close columns.", call. = FALSE)
  }

  append_series(
    chart,
    make_series(
      id = paste0("bars-", length(chart$x$spec$panes[[1]]$series) + 1L),
      type = "bar",
      data = xts_to_records(context$data, required),
      pane = pane,
      name = name,
      options = list(upColor = up_col, downColor = down_col),
      overlay = identical(pane, "price")
    )
  )
}

#' Add volume bars
#'
#' @param chart A `lightweightchartR` chart object.
#' @param pane Target pane. Defaults to `"volume"`.
#' @param color_up,color_down Colors for rising/falling volume bars.
#' @param pane_height Relative pane height for the volume pane.
#'
#' @return The updated chart object.
#' @export
add_volume <- function(chart,
                       pane = "price",
                       color_up = "#26a69a",
                       color_down = "#ef5350",
                       pane_height = 0.6) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  volume_col <- context$mapping$volume

  if (is.null(volume_col)) {
    stop("No volume column detected in the chart data.", call. = FALSE)
  }

  data <- context$data
  frame <- data.frame(
    time = format_time_index(zoo::index(data)),
    value = as.numeric(data[, volume_col, drop = TRUE]),
    stringsAsFactors = FALSE
  )

  if (!is.null(context$mapping$close) && !is.null(context$mapping$open)) {
    up <- as.numeric(data[, context$mapping$close, drop = TRUE]) >= as.numeric(data[, context$mapping$open, drop = TRUE])
    frame$color <- ifelse(up, color_up, color_down)
  } else {
    frame$color <- color_up
  }

  records <- data_frame_to_records(frame)
  chart <- append_series(
    chart,
    make_series(
      id = "volume",
      type = "histogram",
      data = records,
      pane = pane,
      name = "Volume",
      options = list(
        priceFormat = list(type = "volume"),
        priceScaleId = if (identical(pane, "price")) "" else "right",
        priceLineVisible = FALSE,
        lastValueVisible = FALSE
      ),
      overlay = identical(pane, "price"),
      scale_margins = if (identical(pane, "price")) list(top = 0.8, bottom = 0) else NULL
    ),
    pane_height = if (identical(pane, "price")) NULL else pane_height
  )

  if (identical(pane, "price")) {
    spec <- chart$x$spec
    spec$panes[[1]]$series[[1]]$scaleMargins <- list(top = 0.06, bottom = 0.22)
    chart <- update_spec(chart, spec)
  }

  chart
}

#' Add a line series from a chart column
#'
#' @param chart A `lightweightchartR` chart object.
#' @param column Source column. Defaults to the close column.
#' @param pane Target pane.
#' @param name Optional series name.
#' @param color Series color.
#'
#' @return The updated chart object.
#' @export
add_line <- function(chart, column = NULL, pane = "price", name = NULL, color = "#2563eb") {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)

  add_ta(
    chart = chart,
    values = context$data[, column, drop = FALSE],
    type = "line",
    pane = pane,
    name = name %||% column,
    color = color,
    overlay = identical(pane, "price")
  )
}

#' Add an area series from a chart column
#'
#' @inheritParams add_line
#'
#' @return The updated chart object.
#' @export
add_area <- function(chart, column = NULL, pane = "price", name = NULL, color = "#0f766e") {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)

  add_ta(
    chart = chart,
    values = context$data[, column, drop = FALSE],
    type = "area",
    pane = pane,
    name = name %||% column,
    color = color,
    overlay = identical(pane, "price")
  )
}

#' Add a histogram series from a chart column
#'
#' @inheritParams add_line
#' @param pane_height Relative pane height for the target pane.
#'
#' @return The updated chart object.
#' @export
add_histogram <- function(chart,
                          column = NULL,
                          pane = "histogram",
                          name = NULL,
                          color = "#7c3aed",
                          pane_height = 1) {
  chart <- ensure_widget(chart)
  context <- widget_context(chart)
  column <- ensure_series_column(chart, column)

  add_ta(
    chart = chart,
    values = context$data[, column, drop = FALSE],
    type = "histogram",
    pane = pane,
    name = name %||% column,
    color = color,
    pane_height = pane_height,
    overlay = FALSE
  )
}
