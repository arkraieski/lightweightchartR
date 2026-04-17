#' @keywords internal
empty_null <- function(x) {
  is.null(x) || length(x) == 0L
}

#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' @keywords internal
ensure_xts <- function(data) {
  if (xts::is.xts(data)) {
    return(data)
  }

  if (inherits(data, "zoo")) {
    return(xts::as.xts(data))
  }

  if (is.data.frame(data) && "time" %in% names(data)) {
    idx <- as.POSIXct(data$time, tz = "UTC")
    core <- data[setdiff(names(data), "time")]
    return(xts::xts(core, order.by = idx, tzone = "UTC"))
  }

  stop("`data` must be an xts/zoo object or a data frame with a `time` column.", call. = FALSE)
}

#' @keywords internal
apply_subset <- function(data, subset = NULL) {
  if (is.null(subset)) {
    return(data)
  }

  if (!is.character(subset) || length(subset) != 1L) {
    stop("`subset` must be a single character string understood by xts.", call. = FALSE)
  }

  data[subset]
}

#' @keywords internal
guess_column <- function(data, candidates, required = TRUE) {
  nms <- colnames(data)
  lower <- tolower(nms)

  for (candidate in candidates) {
    hit <- which(lower == tolower(candidate))
    if (length(hit)) {
      return(nms[hit[[1L]]])
    }
  }

  for (candidate in candidates) {
    hit <- which(grepl(candidate, lower, fixed = TRUE))
    if (length(hit)) {
      return(nms[hit[[1L]]])
    }
  }

  if (required) {
    stop(
      sprintf("Could not detect a required column from: %s.", paste(candidates, collapse = ", ")),
      call. = FALSE
    )
  }

  NULL
}

#' @keywords internal
detect_mapping <- function(data) {
  mapping <- list(
    open = if (quantmod::has.Op(data)) colnames(quantmod::Op(data))[1] else guess_column(data, c("open", "op"), required = FALSE),
    high = if (quantmod::has.Hi(data)) colnames(quantmod::Hi(data))[1] else guess_column(data, c("high", "hi"), required = FALSE),
    low = if (quantmod::has.Lo(data)) colnames(quantmod::Lo(data))[1] else guess_column(data, c("low", "lo"), required = FALSE),
    close = if (quantmod::has.Cl(data)) colnames(quantmod::Cl(data))[1] else guess_column(data, c("close", "cl", "adjusted", "adj"), required = FALSE),
    volume = if (quantmod::has.Vo(data)) colnames(quantmod::Vo(data))[1] else guess_column(data, c("volume", "vol"), required = FALSE)
  )

  if (all(vapply(mapping[c("open", "high", "low", "close")], is.null, logical(1)))) {
    mapping$close <- guess_column(data, c("close", "value", "price", "y"), required = TRUE)
  }

  mapping
}

#' @keywords internal
infer_base_type <- function(mapping, type = "auto") {
  if (!identical(type, "auto")) {
    return(match.arg(type, c("candles", "bars", "line", "area")))
  }

  if (all(!vapply(mapping[c("open", "high", "low", "close")], is.null, logical(1)))) {
    return("candles")
  }

  "line"
}

#' @keywords internal
format_time_index <- function(index) {
  if (inherits(index, "Date")) {
    return(as.numeric(as.POSIXct(index, tz = "UTC")))
  }

  if (inherits(index, "POSIXt")) {
    idx <- as.POSIXct(index, tz = "UTC")
    return(as.numeric(idx))
  }

  as.numeric(index)
}

#' @keywords internal
columns_to_records <- function(columns, n = NULL) {
  if (is.null(n)) {
    n <- if (length(columns)) length(columns[[1L]]) else 0L
  }

  if (n == 0L) {
    return(list())
  }

  if (!length(columns)) {
    records <- vector("list", n)

    for (i in seq_len(n)) {
      records[[i]] <- list()
    }

    return(records)
  }

  do.call(Map, c(f = list(function(...) list(...)), columns))
}

#' @keywords internal
data_frame_to_records <- function(frame) {
  columns <- unclass(frame)
  names(columns) <- names(frame)
  columns_to_records(columns, n = nrow(frame))
}

#' @keywords internal
xts_to_records <- function(data, fields, keep_na = FALSE) {
  columns <- list(time = format_time_index(zoo::index(data)))
  present_fields <- names(fields)[!vapply(fields, is.null, logical(1))]

  for (field in present_fields) {
    columns[[field]] <- as.numeric(data[, fields[[field]], drop = TRUE])
  }

  if (!keep_na && length(present_fields)) {
    keep <- stats::complete.cases(as.data.frame(columns[present_fields], check.names = FALSE))

    if (!all(keep)) {
      columns <- lapply(columns, `[`, keep)
    }
  }

  columns_to_records(columns)
}

#' @keywords internal
make_series <- function(id, type, data, pane = "price", name = NULL, options = list(), scale = "right", overlay = TRUE, scale_margins = NULL) {
  list(
    id = id,
    type = type,
    pane = pane,
    name = name %||% id,
    data = data,
    options = options,
    scale = scale,
    overlay = overlay,
    scaleMargins = scale_margins
  )
}

#' @keywords internal
widget_context <- function(widget) {
  attr(widget, "lwc_context", exact = TRUE)
}

#' @keywords internal
set_widget_context <- function(widget, context) {
  attr(widget, "lwc_context") <- context
  widget
}

#' @keywords internal
ensure_widget <- function(widget) {
  if (!inherits(widget, "lightweightchartR")) {
    stop("Expected a `lightweightchartR` chart object on the left-hand side of the pipe.", call. = FALSE)
  }

  widget
}

#' @keywords internal
update_spec <- function(widget, spec) {
  widget$x$spec <- spec
  widget
}

#' @keywords internal
build_main_series <- function(data, mapping, type, up_col, down_col) {
  if (identical(type, "candles")) {
    records <- xts_to_records(
      data,
      list(
        open = mapping$open,
        high = mapping$high,
        low = mapping$low,
        close = mapping$close
      )
    )

    return(make_series(
      id = "price",
      type = "candlestick",
      data = records,
      pane = "price",
      name = "Price",
      options = list(upColor = up_col, downColor = down_col, borderVisible = FALSE, wickUpColor = up_col, wickDownColor = down_col),
      overlay = TRUE
    ))
  }

  if (identical(type, "bars")) {
    records <- xts_to_records(
      data,
      list(
        open = mapping$open,
        high = mapping$high,
        low = mapping$low,
        close = mapping$close
      )
    )

    return(make_series(
      id = "price",
      type = "bar",
      data = records,
      pane = "price",
      name = "Price",
      options = list(upColor = up_col, downColor = down_col),
      overlay = TRUE
    ))
  }

  records <- xts_to_records(data, list(value = mapping$close))
  series_type <- if (identical(type, "area")) "area" else "line"
  options <- if (identical(series_type, "area")) {
    list(lineColor = up_col, topColor = paste0(up_col, "66"), bottomColor = paste0(up_col, "08"))
  } else {
    list(color = up_col, lineWidth = 2)
  }

  make_series(
    id = "price",
    type = series_type,
    data = records,
    pane = "price",
    name = "Price",
    options = options,
    overlay = TRUE
  )
}

#' @keywords internal
theme_defaults <- function(theme) {
  theme <- match.arg(theme, c("light", "dark"))

  if (identical(theme, "dark")) {
    return(list(
      layout = list(background = list(color = "#101418"), textColor = "#d7dde5"),
      grid = list(vertLines = list(color = "#1f2933"), horzLines = list(color = "#1f2933")),
      crosshair = list(mode = 0L),
      timeScale = list(
        minBarSpacing = 0.1,
        fixLeftEdge = FALSE,
        fixRightEdge = FALSE
      )
    ))
  }

  list(
    layout = list(background = list(color = "#ffffff"), textColor = "#334155"),
    grid = list(vertLines = list(color = "#e2e8f0"), horzLines = list(color = "#e2e8f0")),
    crosshair = list(mode = 0L),
    timeScale = list(
      minBarSpacing = 0.1,
      fixLeftEdge = FALSE,
      fixRightEdge = FALSE
    )
  )
}

#' @keywords internal
normalize_indicator_xts <- function(values, default_name = "Indicator") {
  values <- ensure_xts(values)
  columns <- colnames(values)

  lapply(seq_along(columns), function(i) {
    column <- columns[[i]]
    list(
      name = column %||% sprintf("%s %s", default_name, i),
      data = xts_to_records(values[, i, drop = FALSE], list(value = column))
    )
  })
}

#' @keywords internal
ensure_series_column <- function(chart, column = NULL) {
  context <- widget_context(chart)
  mapping <- context$mapping

  if (!is.null(column)) {
    return(column)
  }

  mapping$close %||% stop("No close/value column available for this chart.", call. = FALSE)
}

#' @keywords internal
parse_ta_call <- function(call_text) {
  cleaned <- gsub("\\s+", "", call_text)

  if (grepl("^addVo\\(", cleaned)) {
    return(list(fn = "add_volume", args = list()))
  }

  if (grepl("^addSMA\\(", cleaned)) {
    n <- sub(".*n=([0-9]+).*", "\\1", cleaned)
    if (identical(n, cleaned)) n <- "20"
    return(list(fn = "add_sma", args = list(n = as.integer(n))))
  }

  if (grepl("^addEMA\\(", cleaned)) {
    n <- sub(".*n=([0-9]+).*", "\\1", cleaned)
    if (identical(n, cleaned)) n <- "20"
    return(list(fn = "add_ema", args = list(n = as.integer(n))))
  }

  if (grepl("^addBBands\\(", cleaned)) {
    n <- sub(".*n=([0-9]+).*", "\\1", cleaned)
    if (identical(n, cleaned)) n <- "20"
    return(list(fn = "add_bbands", args = list(n = as.integer(n))))
  }

  if (grepl("^addRSI\\(", cleaned)) {
    n <- sub(".*n=([0-9]+).*", "\\1", cleaned)
    if (identical(n, cleaned)) n <- "14"
    return(list(fn = "add_rsi", args = list(n = as.integer(n))))
  }

  if (grepl("^addMACD\\(", cleaned)) {
    return(list(fn = "add_macd", args = list()))
  }

  stop(sprintf("Unsupported TA expression: %s", call_text), call. = FALSE)
}
