HTMLWidgets.widget({
  name: "lightweightchartR",
  type: "output",

  factory: function(el, width, height) {
    var chartState = {
      chart: null,
      chartEl: null,
      legendEl: null,
      tooltipEl: null,
      isPointerOver: false,
      taTooltip: true,
      taTooltipThreshold: 14,
      paneUnits: [],
      panesMeta: [],
      primarySeries: null,
      primarySeriesSpec: null,
      legendName: "",
      paneTitles: [],
      paneTops: []
    };

    function normalizeTime(value) {
      if (typeof value === "number") {
        return value;
      }

      if (typeof value !== "string") {
        return value;
      }

      if (value.indexOf("T") >= 0) {
        return Math.floor(new Date(value).getTime() / 1000);
      }

      var parsed = new Date(value + "T00:00:00Z");
      if (!isNaN(parsed.getTime())) {
        return Math.floor(parsed.getTime() / 1000);
      }

      return value;
    }

    function seriesDefinition(seriesType) {
      if (seriesType === "candlestick") {
        return LightweightCharts.CandlestickSeries;
      }
      if (seriesType === "bar") {
        return LightweightCharts.BarSeries;
      }
      if (seriesType === "area") {
        return LightweightCharts.AreaSeries;
      }
      if (seriesType === "histogram") {
        return LightweightCharts.HistogramSeries;
      }
      return LightweightCharts.LineSeries;
    }

    function addSeries(chart, seriesSpec, paneIndex) {
      var options = seriesSpec.options || {};
      var series = chart.addSeries(seriesDefinition(seriesSpec.type), options, paneIndex);

      var data = (seriesSpec.data || []).map(function(row) {
        var out = Object.assign({}, row);
        out.time = normalizeTime(out.time);
        return out;
      });

      series.setData(data);

      if (seriesSpec.scaleMargins) {
        series.priceScale().applyOptions({ scaleMargins: seriesSpec.scaleMargins });
      }

      return series;
    }

    function seriesColor(spec) {
      var options = (spec && spec.options) || {};
      return (
        options.color ||
        options.lineColor ||
        options.topLineColor ||
        options.topColor ||
        options.upColor ||
        "#94a3b8"
      );
    }

    function formatLegendTime(value) {
      if (typeof value === "number") {
        var date = new Date(value * 1000);
        if (!isNaN(date.getTime())) {
          return date.toISOString().slice(0, 10);
        }
      }

      return value == null ? "" : String(value);
    }

    function formatTooltipValue(point) {
      if (!point) {
        return "";
      }

      if (typeof point.close === "number") {
        return point.close.toFixed(2);
      }

      if (typeof point.value === "number") {
        return point.value.toFixed(2);
      }

      return "";
    }

    function formatLegendValue(point) {
      if (!point) {
        return "";
      }

      if (typeof point.close === "number") {
        return point.close.toFixed(2);
      }

      if (typeof point.value === "number") {
        return point.value.toFixed(2);
      }

      return "";
    }

    function latestPoint(seriesSpec) {
      if (!seriesSpec || !seriesSpec.data || !seriesSpec.data.length) {
        return null;
      }

      return seriesSpec.data[seriesSpec.data.length - 1];
    }

    function pointFromCrosshair(param, series) {
      if (!param || !param.time || !series || !param.seriesData) {
        return null;
      }

      return param.seriesData.get(series) || null;
    }

    function pointValue(point) {
      if (!point) {
        return null;
      }

      if (typeof point.value === "number") {
        return point.value;
      }

      if (typeof point.close === "number") {
        return point.close;
      }

      return null;
    }

    function overlaySeriesEntries() {
      return (chartState.seriesEntries || []).filter(function(entry) {
        return (
          entry.paneIndex === 0 &&
          entry.series !== chartState.primarySeries &&
          entry.spec.id !== "volume"
        );
      });
    }

    function nearestOverlayAtPoint(param) {
      if (!param || !param.point) {
        return null;
      }

      var best = null;
      overlaySeriesEntries().forEach(function(entry) {
        var point = pointFromCrosshair(param, entry.series);
        var value = pointValue(point);
        if (value == null) {
          return;
        }

        var y = entry.series.priceToCoordinate(value);
        if (y == null || !isFinite(y)) {
          return;
        }

        var distance = Math.abs(param.point.y - y);
        if (!best || distance < best.distance) {
          best = {
            entry: entry,
            point: point,
            y: y,
            distance: distance
          };
        }
      });

      return best;
    }

    function updateLegendContent(legendEl, name, point) {
      if (!legendEl) {
        return;
      }

      var nameEl = legendEl.querySelector(".lightweightchartR-legend-name");
      var valueEl = legendEl.querySelector(".lightweightchartR-legend-value");
      var timeEl = legendEl.querySelector(".lightweightchartR-legend-time");

      if (nameEl) {
        nameEl.textContent = name || "";
      }

      if (valueEl) {
        valueEl.textContent = formatLegendValue(point);
      }

      if (timeEl) {
        timeEl.textContent = formatLegendTime(point && point.time);
      }
    }

    function buildLegend(name, point, theme) {
      var wrap = document.createElement("div");
      wrap.className = "lightweightchartR-legend";
      wrap.style.position = "absolute";
      wrap.style.top = "12px";
      wrap.style.left = "12px";
      wrap.style.zIndex = "1000";
      wrap.style.pointerEvents = "none";
      wrap.style.display = "flex";
      wrap.style.flexDirection = "column";
      wrap.style.gap = "2px";
      wrap.style.maxWidth = "45%";
      wrap.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
      wrap.style.color = theme === "dark" ? "#e2e8f0" : "#0f172a";
      wrap.style.textShadow = theme === "dark" ? "0 1px 2px rgba(0, 0, 0, 0.45)" : "none";

      var nameEl = document.createElement("div");
      nameEl.className = "lightweightchartR-legend-name";
      nameEl.textContent = name || "";
      nameEl.style.fontSize = "18px";
      nameEl.style.fontWeight = "500";
      nameEl.style.lineHeight = "1.05";
      wrap.appendChild(nameEl);

      var valueEl = document.createElement("div");
      valueEl.className = "lightweightchartR-legend-value";
      valueEl.textContent = formatLegendValue(point);
      valueEl.style.fontSize = "32px";
      valueEl.style.fontWeight = "500";
      valueEl.style.lineHeight = "1";
      wrap.appendChild(valueEl);

      var timeEl = document.createElement("div");
      timeEl.className = "lightweightchartR-legend-time";
      timeEl.textContent = formatLegendTime(point && point.time);
      timeEl.style.fontSize = "12px";
      timeEl.style.lineHeight = "1.1";
      timeEl.style.opacity = "0.8";
      wrap.appendChild(timeEl);

      return wrap;
    }

    function buildPaneTitle(label) {
      var el = document.createElement("div");
      el.className = "lightweightchartR-pane-title";
      el.style.position = "absolute";
      el.style.left = "12px";
      el.style.zIndex = "1000";
      el.style.pointerEvents = "none";
      el.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
      el.style.fontSize = "12px";
      el.style.fontWeight = "600";
      el.style.lineHeight = "1.2";
      el.style.letterSpacing = "0.02em";
      el.style.textShadow = "0 1px 2px rgba(0, 0, 0, 0.45)";
      el.style.opacity = "0.92";
      el.textContent = label || "";
      return el;
    }

    function buildTooltip() {
      var el = document.createElement("div");
      el.className = "lightweightchartR-tooltip";
      el.style.position = "absolute";
      el.style.zIndex = "1200";
      el.style.pointerEvents = "none";
      el.style.display = "none";
      el.style.minWidth = "120px";
      el.style.maxWidth = "220px";
      el.style.padding = "8px 10px";
      el.style.borderRadius = "8px";
      el.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
      el.style.fontSize = "12px";
      el.style.lineHeight = "1.25";
      el.style.boxShadow = "0 6px 18px rgba(0, 0, 0, 0.28)";
      el.style.backdropFilter = "blur(8px)";
      return el;
    }

    function updateTooltip(param) {
      if (!chartState.tooltipEl) {
        return;
      }

      if (!chartState.taTooltip) {
        chartState.tooltipEl.style.display = "none";
        return;
      }

      var hoveredOverlay = nearestOverlayAtPoint(param);

      if (
        !param ||
        !chartState.isPointerOver ||
        !hoveredOverlay ||
        !param.point ||
        !param.time ||
        param.point.x < 0 ||
        param.point.y < 0 ||
        hoveredOverlay.distance > chartState.taTooltipThreshold
      ) {
        chartState.tooltipEl.style.display = "none";
        return;
      }

      var row =
        '<div class="lightweightchartR-tooltip-row" style="display:flex;align-items:center;gap:8px;">' +
          '<span class="lightweightchartR-tooltip-swatch" style="background:' + seriesColor(hoveredOverlay.entry.spec) + ';width:8px;height:8px;border-radius:999px;flex:0 0 auto;"></span>' +
          '<span class="lightweightchartR-tooltip-label" style="flex:1 1 auto;opacity:0.84;">' + (hoveredOverlay.entry.spec.name || hoveredOverlay.entry.spec.id || "") + '</span>' +
          '<span class="lightweightchartR-tooltip-value" style="font-weight:700;flex:0 0 auto;">' + formatTooltipValue(hoveredOverlay.point) + '</span>' +
        '</div>';

      chartState.tooltipEl.innerHTML =
        '<div class="lightweightchartR-tooltip-time" style="margin-bottom:6px;font-size:11px;opacity:0.78;">' + formatLegendTime(param.time) + '</div>' +
        row;
      chartState.tooltipEl.style.display = "block";

      var containerRect = el.getBoundingClientRect();
      var tooltipRect = chartState.tooltipEl.getBoundingClientRect();
      var left = param.point.x + 16;
      var top = hoveredOverlay.y - tooltipRect.height / 2;

      if (left + tooltipRect.width > containerRect.width - 8) {
        left = Math.max(8, param.point.x - tooltipRect.width - 16);
      }

      top = Math.max(8, Math.min(containerRect.height - tooltipRect.height - 8, top));

      chartState.tooltipEl.style.left = left + "px";
      chartState.tooltipEl.style.top = top + "px";
    }

    function computeHeight(targetHeight) {
      if (targetHeight && targetHeight > 0) {
        return targetHeight;
      }

      var rectHeight = el.getBoundingClientRect().height;
      if (rectHeight && rectHeight > 0) {
        return rectHeight;
      }

      return 600;
    }

    function minimumPaneHeight(paneId, paneCount) {
      if (paneCount <= 1) {
        return 120;
      }

      if (paneId === "price") {
        return 80;
      }

      return 40;
    }

    function layoutChart(targetWidth, targetHeight, panes) {
      if (!chartState.chart) {
        return;
      }

      var widthPx = targetWidth || el.getBoundingClientRect().width || width || 800;
      var heightPx = computeHeight(targetHeight);
      chartState.chart.resize(widthPx, heightPx);

      if (chartState.chartEl) {
        chartState.chartEl.style.width = widthPx + "px";
        chartState.chartEl.style.height = heightPx + "px";
      }

      var totalUnits = chartState.paneUnits.reduce(function(total, value) { return total + value; }, 0) || 1;
      var paneApis = chartState.chart.panes();
      var assigned = 0;

      paneApis.forEach(function(paneApi, index) {
        var paneId = panes[index] && panes[index].id ? panes[index].id : "pane-" + index;
        var paneHeight;
        var minHeight = minimumPaneHeight(paneId, paneApis.length);

        if (index === paneApis.length - 1) {
          paneHeight = Math.max(minHeight, heightPx - assigned);
        } else {
          paneHeight = Math.max(minHeight, Math.floor(heightPx * (chartState.paneUnits[index] / totalUnits)));
        }

        assigned += paneHeight;
        chartState.paneTops[index] = assigned - paneHeight;
        paneApi.setHeight(paneHeight);
      });

      chartState.paneTitles.forEach(function(item) {
        var paneTop = chartState.paneTops[item.paneIndex] || 0;
        item.el.style.top = paneTop + 10 + "px";
      });
    }

    function removeChart() {
      if (chartState.chart) {
        chartState.chart.remove();
      }

      chartState.chart = null;
      chartState.chartEl = null;
      chartState.legendEl = null;
      chartState.tooltipEl = null;
      chartState.isPointerOver = false;
      chartState.taTooltip = true;
      chartState.taTooltipThreshold = 14;
      chartState.paneUnits = [];
      chartState.panesMeta = [];
      chartState.primarySeries = null;
      chartState.primarySeriesSpec = null;
      chartState.legendName = "";
      chartState.paneTitles = [];
      chartState.paneTops = [];
      chartState.seriesEntries = [];
    }

    return {
      renderValue: function(x) {
        el.innerHTML = "";
        var theme = (x.meta && x.meta.theme) || "light";
        var backgroundColor = theme === "dark" ? "#101418" : "#ffffff";
        el.className = "lightweightchartR lightweightchartR--" + theme;
        el.style.backgroundColor = backgroundColor;

        var panes = (x.spec && x.spec.panes) || [];
        removeChart();

        var chartEl = document.createElement("div");
        chartEl.className = "lightweightchartR-chart";
        chartEl.style.backgroundColor = backgroundColor;
        el.appendChild(chartEl);
        chartState.chartEl = chartEl;

        chartState.chart = LightweightCharts.createChart(
          chartEl,
          Object.assign(
            {
              width: chartEl.clientWidth || width || 800,
              height: computeHeight(height),
              rightPriceScale: { borderVisible: false },
              timeScale: { borderVisible: false },
              localization: { locale: "en-US" }
            },
            x.spec.options || {}
          )
        );

        chartState.paneUnits = panes.map(function(pane) {
          return pane.height || 1;
        });
        chartState.panesMeta = panes.map(function(pane) {
          return { id: pane.id || null, height: pane.height || 1 };
        });
        chartState.legendName = (x.meta && x.meta.name) || "";
        chartState.taTooltip = !(x.meta && x.meta.ta_tooltip === false);
        chartState.taTooltipThreshold = x.meta && typeof x.meta.ta_tooltip_threshold === "number"
          ? x.meta.ta_tooltip_threshold
          : 14;
        chartState.seriesEntries = [];

        panes.forEach(function(pane, paneIndex) {
          (pane.series || []).forEach(function(seriesSpec, seriesIndex) {
            var series = addSeries(chartState.chart, seriesSpec, paneIndex);
            chartState.seriesEntries.push({ series: series, spec: seriesSpec, paneIndex: paneIndex });
            if (paneIndex === 0 && seriesIndex === 0) {
              chartState.primarySeries = series;
              chartState.primarySeriesSpec = seriesSpec;
            }
          });
        });

        var pricePane = panes[0] || null;
        el.style.position = "relative";
        if (pricePane) {
          var point = latestPoint((pricePane.series || [])[0]);
          var legendEl = buildLegend(x.meta && x.meta.name, point, theme);
          el.appendChild(legendEl);
          chartState.legendEl = legendEl;
        }

        var tooltipEl = buildTooltip();
        tooltipEl.style.background = theme === "dark" ? "rgba(15, 23, 42, 0.92)" : "rgba(255, 255, 255, 0.96)";
        tooltipEl.style.color = theme === "dark" ? "#e2e8f0" : "#0f172a";
        tooltipEl.style.border = theme === "dark"
          ? "1px solid rgba(148, 163, 184, 0.22)"
          : "1px solid rgba(148, 163, 184, 0.3)";
        el.appendChild(tooltipEl);
        chartState.tooltipEl = tooltipEl;
        el.addEventListener("mouseenter", function() {
          chartState.isPointerOver = true;
        });
        el.addEventListener("mouseleave", function() {
          chartState.isPointerOver = false;
          if (chartState.tooltipEl) {
            chartState.tooltipEl.style.display = "none";
          }
        });

        panes.slice(1).forEach(function(pane, paneOffset) {
          var paneIndex = paneOffset + 1;
          var label = null;

          if (pane.id && pane.id !== "price") {
            label = pane.id.toUpperCase() === "RSI" ? "RSI" : pane.id.charAt(0).toUpperCase() + pane.id.slice(1);
          }

          if (!label && pane.series && pane.series.length) {
            label = pane.series[0].name || pane.series[0].id || null;
          }

          if (label) {
            var titleEl = buildPaneTitle(label);
            titleEl.style.color = theme === "dark" ? "#d7dde5" : "#0f172a";
            el.appendChild(titleEl);
            chartState.paneTitles.push({ el: titleEl, paneIndex: paneIndex });
          }
        });

        if (chartState.chart && chartState.primarySeries) {
          chartState.chart.subscribeCrosshairMove(function(param) {
            var point = pointFromCrosshair(param, chartState.primarySeries);
            if (!point) {
              point = latestPoint(chartState.primarySeriesSpec);
            }
            updateLegendContent(chartState.legendEl, chartState.legendName, point);
            updateTooltip(param);
          });
        }

        layoutChart(width, height, panes);
      },

      resize: function(newWidth, newHeight) {
        layoutChart(newWidth, newHeight, chartState.panesMeta);
      }
    };
  }
});
