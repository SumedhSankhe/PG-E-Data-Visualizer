
anomalyUI <- function(id, label = 'anomaly') {
  ns <- NS(id)
  h3('Anomaly Detection')
  shinyjs::useShinyjs()
  fluidPage(
    # Help Box
    fluidRow(
      shinydashboard::box(
        width = 12,
        status = 'warning',
        solidHeader = FALSE,
        collapsible = TRUE,
        collapsed = FALSE,
        title = tags$span(icon('info-circle'), ' What does Anomaly Detection do?'),
        p(
          style = "font-size: 14px; line-height: 1.6;",
          "Anomaly Detection identifies unusual consumption patterns that deviate significantly from your normal usage. This can help spot appliance malfunctions, unusual events, or data quality issues."
        ),
        tags$ul(
          style = "font-size: 14px; line-height: 1.6;",
          tags$li(tags$strong("Detection Methods:"), " IQR (statistical), Z-Score (standard deviation), STL (seasonal), Moving Average (trend-based)."),
          tags$li(tags$strong("Sensitivity:"), " Lower values (1-3) = stricter detection, higher values (7-10) = more lenient. Start with 5."),
          tags$li(tags$strong("Interpreting Results:"), " Critical anomalies need immediate attention. Medium anomalies may indicate unusual but not problematic behavior.")
        )
      )
    ),

    # Control Panel
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Anomaly Detection Settings', status = 'primary', solidHeader = TRUE,
        column(width = 4,
               selectInput(
                 inputId = ns('detection_method'),
                 label = 'Detection Method',
                 choices = list(
                   'Statistical (IQR)' = 'iqr',
                   'Z-Score' = 'zscore',
                   'Seasonal Decomposition' = 'stl',
                   'Moving Average' = 'ma'
                 ),
                 selected = 'iqr'
               )),
        column(width = 4,
               numericInput(
                 inputId = ns('sensitivity'),
                 label = 'Sensitivity (1-10)',
                 value = 5,
                 min = 1,
                 max = 10,
                 step = 1
               )),
        column(width = 4,
               actionButton(inputId = ns('run_detection'),
                            label = 'Detect Anomalies',
                            icon = icon('search'),
                            class = 'btn-primary btn-lg',
                            style = 'margin-top: 25px;'))
      )
    ),

    # Anomaly Summary Metrics
    fluidRow(
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('anomaly_count'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('anomaly_percentage'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('highest_anomaly'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('anomaly_severity'), width = 12))
    ),

    # Main Visualization
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Time Series with Detected Anomalies',
        status = 'danger',
        solidHeader = TRUE,
        shinycssloaders::withSpinner(
          plotly::plotlyOutput(outputId = ns("anomaly_timeseries"), height = '400px')
        )
      )
    ),

    # Anomaly Details and Distribution
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Anomaly Distribution by Hour',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("anomaly_hourly_dist"))
               )
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Anomaly Severity Distribution',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("anomaly_severity_plot"))
               )
             ))
    ),

    # Detailed Anomaly Table
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Detected Anomalies - Detailed View',
        status = 'warning',
        solidHeader = TRUE,
        downloadButton(ns('download_anomalies'),
                       label = 'Download Anomaly Report',
                       class = 'btn-success',
                       style = 'margin-bottom: 10px;'),
        DT::dataTableOutput(ns('anomaly_table'))
      )
    )
  )
}


anomalyServer <- function(id, dt) {
  moduleServer(
    id,
    function(input, output, session) {

      # Anomaly Detection Reactive ----
      anomaly_results <- reactive({
        input$run_detection
        req(dt())
        req(input$detection_method)
        req(input$sensitivity)

        logger::log_info("Running anomaly detection with method: {input$detection_method}, sensitivity: {input$sensitivity}")

        df <- copy(dt())
        method <- input$detection_method
        sensitivity <- input$sensitivity

        # Remove NA values for analysis
        df_clean <- df[!is.na(value)]

        # Initialize anomaly column
        df_clean[, is_anomaly := FALSE]
        df_clean[, anomaly_score := 0]
        df_clean[, expected_range_lower := NA_real_]
        df_clean[, expected_range_upper := NA_real_]

        # Apply detection method
        if (method == 'iqr') {
          # IQR-based detection
          Q1 <- quantile(df_clean$value, 0.25, na.rm = TRUE)
          Q3 <- quantile(df_clean$value, 0.75, na.rm = TRUE)
          IQR_val <- Q3 - Q1

          # Adjust multiplier based on sensitivity (lower sensitivity = stricter)
          multiplier <- 1.5 + (10 - sensitivity) * 0.3

          lower_bound <- Q1 - multiplier * IQR_val
          upper_bound <- Q3 + multiplier * IQR_val

          df_clean[, is_anomaly := (value < lower_bound | value > upper_bound)]
          df_clean[, anomaly_score := pmax(
            abs(value - lower_bound) / IQR_val,
            abs(value - upper_bound) / IQR_val
          )]
          df_clean[, expected_range_lower := lower_bound]
          df_clean[, expected_range_upper := upper_bound]

        } else if (method == 'zscore') {
          # Z-score based detection
          mean_val <- mean(df_clean$value, na.rm = TRUE)
          sd_val <- sd(df_clean$value, na.rm = TRUE)

          # Adjust threshold based on sensitivity
          threshold <- 3 - (sensitivity - 5) * 0.2

          df_clean[, z_score := abs((value - mean_val) / sd_val)]
          df_clean[, is_anomaly := z_score > threshold]
          df_clean[, anomaly_score := z_score / threshold]
          df_clean[, expected_range_lower := mean_val - threshold * sd_val]
          df_clean[, expected_range_upper := mean_val + threshold * sd_val]

        } else if (method == 'stl') {
          # STL decomposition for seasonal anomalies
          if (nrow(df_clean) >= 24) {  # Need at least 24 hours
            tryCatch({
              ts_data <- ts(df_clean$value, frequency = 24)
              stl_result <- stl(ts_data, s.window = "periodic", robust = TRUE)

              # Calculate residuals
              residuals <- as.numeric(stl_result$time.series[, "remainder"])

              # Detect anomalies in residuals
              res_sd <- sd(residuals, na.rm = TRUE)
              threshold <- 2.5 - (sensitivity - 5) * 0.15

              df_clean[, is_anomaly := abs(residuals) > threshold * res_sd]
              df_clean[, anomaly_score := abs(residuals) / (threshold * res_sd)]

              # Expected value from trend + seasonal
              expected <- as.numeric(stl_result$time.series[, "trend"] +
                                    stl_result$time.series[, "seasonal"])
              df_clean[, expected_range_lower := expected - threshold * res_sd]
              df_clean[, expected_range_upper := expected + threshold * res_sd]
            }, error = function(e) {
              logger::log_warn("STL decomposition failed: {e$message}")
              # Fallback to IQR
              Q1 <- quantile(df_clean$value, 0.25, na.rm = TRUE)
              Q3 <- quantile(df_clean$value, 0.75, na.rm = TRUE)
              IQR_val <- Q3 - Q1
              multiplier <- 1.5 + (10 - sensitivity) * 0.3
              lower_bound <- Q1 - multiplier * IQR_val
              upper_bound <- Q3 + multiplier * IQR_val
              df_clean[, is_anomaly := (value < lower_bound | value > upper_bound)]
            })
          } else {
            logger::log_warn("Insufficient data for STL, using IQR method")
            # Fallback to IQR for small datasets
            Q1 <- quantile(df_clean$value, 0.25, na.rm = TRUE)
            Q3 <- quantile(df_clean$value, 0.75, na.rm = TRUE)
            IQR_val <- Q3 - Q1
            multiplier <- 1.5 + (10 - sensitivity) * 0.3
            lower_bound <- Q1 - multiplier * IQR_val
            upper_bound <- Q3 + multiplier * IQR_val
            df_clean[, is_anomaly := (value < lower_bound | value > upper_bound)]
          }

        } else if (method == 'ma') {
          # Moving average based detection
          window_size <- max(3, round(24 / sensitivity))  # Adaptive window

          # Calculate moving average and standard deviation
          df_clean <- df_clean[order(dttm_start)]
          df_clean[, ma := frollmean(value, n = window_size, align = "center")]
          df_clean[, ma_sd := frollapply(value, n = window_size, FUN = sd, align = "center")]

          # Detect anomalies
          threshold <- 2.5 - (sensitivity - 5) * 0.15
          df_clean[, deviation := abs(value - ma)]
          df_clean[, is_anomaly := deviation > threshold * ma_sd]
          df_clean[, anomaly_score := deviation / (threshold * ma_sd)]
          df_clean[, expected_range_lower := ma - threshold * ma_sd]
          df_clean[, expected_range_upper := ma + threshold * ma_sd]
        }

        # Calculate severity levels
        df_clean[, severity := ifelse(
          !is_anomaly, "Normal",
          ifelse(anomaly_score > 2, "Critical",
                 ifelse(anomaly_score > 1.5, "High", "Medium"))
        )]

        # Summary statistics
        results <- list()
        results$data <- df_clean
        results$total_records <- nrow(df_clean)
        results$anomaly_count <- sum(df_clean$is_anomaly, na.rm = TRUE)
        results$anomaly_pct <- round((results$anomaly_count / results$total_records) * 100, 2)
        results$method <- method
        results$sensitivity <- sensitivity

        # Highest anomaly
        if (results$anomaly_count > 0) {
          max_anomaly <- df_clean[is_anomaly == TRUE][which.max(anomaly_score)]
          results$highest_anomaly_value <- max_anomaly$value
          results$highest_anomaly_time <- max_anomaly$dttm_start
          results$highest_anomaly_score <- round(max_anomaly$anomaly_score, 2)
        } else {
          results$highest_anomaly_value <- NA
          results$highest_anomaly_time <- NA
          results$highest_anomaly_score <- 0
        }

        # Severity distribution
        results$severity_counts <- df_clean[is_anomaly == TRUE, .N, by = severity]

        # Hourly distribution
        if ("hour" %in% names(df_clean)) {
          results$hourly_anomalies <- df_clean[, .(
            total = .N,
            anomalies = sum(is_anomaly, na.rm = TRUE),
            anomaly_rate = round(sum(is_anomaly, na.rm = TRUE) / .N * 100, 1)
          ), by = hour][order(hour)]
        }

        logger::log_info("Anomaly detection completed: {results$anomaly_count} anomalies found ({results$anomaly_pct}%)")
        return(results)
      })

      # Value Boxes ----
      output$anomaly_count <- shinydashboard::renderValueBox({
        results <- anomaly_results()
        shinydashboard::valueBox(
          value = format(results$anomaly_count, big.mark = ","),
          subtitle = "Anomalies Detected",
          icon = icon("exclamation-triangle"),
          color = if (results$anomaly_pct > 10) "red" else if (results$anomaly_pct > 5) "yellow" else "green"
        )
      })

      output$anomaly_percentage <- shinydashboard::renderValueBox({
        results <- anomaly_results()
        shinydashboard::valueBox(
          value = paste0(results$anomaly_pct, "%"),
          subtitle = "Anomaly Rate",
          icon = icon("percent"),
          color = if (results$anomaly_pct > 10) "red" else if (results$anomaly_pct > 5) "yellow" else "green"
        )
      })

      output$highest_anomaly <- shinydashboard::renderValueBox({
        results <- anomaly_results()
        val <- if (is.na(results$highest_anomaly_value)) {
          "None"
        } else {
          paste0(round(results$highest_anomaly_value, 2), " kWh")
        }
        shinydashboard::valueBox(
          value = val,
          subtitle = "Highest Anomaly",
          icon = icon("arrow-up"),
          color = "red"
        )
      })

      output$anomaly_severity <- shinydashboard::renderValueBox({
        results <- anomaly_results()
        critical_count <- if (nrow(results$severity_counts) > 0) {
          sum(results$severity_counts[severity == "Critical"]$N, na.rm = TRUE)
        } else {
          0
        }
        shinydashboard::valueBox(
          value = critical_count,
          subtitle = "Critical Anomalies",
          icon = icon("radiation"),
          color = if (critical_count > 0) "red" else "green"
        )
      })

      # Time Series Plot ----
      output$anomaly_timeseries <- plotly::renderPlotly({
        results <- anomaly_results()
        df <- results$data

        validate(
          need(nrow(df) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        # Normal data
        p <- plotly::plot_ly()

        # Add expected range as shaded area if available
        if (!all(is.na(df$expected_range_lower))) {
          p <- p |> plotly::add_ribbons(
            data = df,
            x = ~dttm_start,
            ymin = ~expected_range_lower,
            ymax = ~expected_range_upper,
            name = "Expected Range",
            line = list(color = 'transparent'),
            fillcolor = 'rgba(135, 206, 250, 0.3)',
            hoverinfo = 'skip'
          )
        }

        # Normal points
        p <- p |> plotly::add_trace(
          data = df[is_anomaly == FALSE],
          x = ~dttm_start, y = ~value,
          type = 'scatter', mode = 'lines+markers',
          name = 'Normal Data',
          line = list(color = '#4CAF50'),
          marker = list(size = 4, color = '#4CAF50'),
          text = ~paste0("Time: ", dttm_start, "<br>",
                        "Value: ", round(value, 2), " kWh<br>",
                        "Status: Normal"),
          hoverinfo = 'text'
        )

        # Anomalies by severity
        if (sum(df$severity == "Medium", na.rm = TRUE) > 0) {
          p <- p |> plotly::add_trace(
            data = df[severity == "Medium"],
            x = ~dttm_start, y = ~value,
            type = 'scatter', mode = 'markers',
            name = 'Medium Severity',
            marker = list(size = 10, color = '#FFA500', symbol = 'circle'),
            text = ~paste0("Time: ", dttm_start, "<br>",
                          "Value: ", round(value, 2), " kWh<br>",
                          "Severity: Medium<br>",
                          "Anomaly Score: ", round(anomaly_score, 2)),
            hoverinfo = 'text'
          )
        }

        if (sum(df$severity == "High", na.rm = TRUE) > 0) {
          p <- p |> plotly::add_trace(
            data = df[severity == "High"],
            x = ~dttm_start, y = ~value,
            type = 'scatter', mode = 'markers',
            name = 'High Severity',
            marker = list(size = 12, color = '#FF4500', symbol = 'diamond'),
            text = ~paste0("Time: ", dttm_start, "<br>",
                          "Value: ", round(value, 2), " kWh<br>",
                          "Severity: High<br>",
                          "Anomaly Score: ", round(anomaly_score, 2)),
            hoverinfo = 'text'
          )
        }

        if (sum(df$severity == "Critical", na.rm = TRUE) > 0) {
          p <- p |> plotly::add_trace(
            data = df[severity == "Critical"],
            x = ~dttm_start, y = ~value,
            type = 'scatter', mode = 'markers',
            name = 'Critical Severity',
            marker = list(size = 14, color = '#DC143C', symbol = 'x'),
            text = ~paste0("Time: ", dttm_start, "<br>",
                          "Value: ", round(value, 2), " kWh<br>",
                          "Severity: Critical<br>",
                          "Anomaly Score: ", round(anomaly_score, 2)),
            hoverinfo = 'text'
          )
        }

        p |> plotly::layout(
          xaxis = list(title = "Timestamp"),
          yaxis = list(title = "Consumption (kWh)"),
          hovermode = 'closest',
          legend = list(x = 0.01, y = 0.99)
        ) |>
          plotly::config(
            modeBarButtonsToRemove = list(
              'pan2d', 'select2d', 'lasso2d',
              'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
            ),
            doubleClick = 'reset',
            displaylogo = FALSE
          )
      })

      # Hourly Distribution Plot ----
      output$anomaly_hourly_dist <- plotly::renderPlotly({
        results <- anomaly_results()
        req(results$hourly_anomalies)

        validate(
          need(nrow(results$hourly_anomalies) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        plotly::plot_ly(
          data = results$hourly_anomalies,
          x = ~hour,
          y = ~anomaly_rate,
          type = 'bar',
          marker = list(
            color = ~anomaly_rate,
            colorscale = list(c(0, '#4CAF50'), c(0.5, '#FFA500'), c(1, '#DC143C')),
            colorbar = list(title = "Anomaly Rate %")
          ),
          text = ~paste0("Hour: ", hour, "<br>",
                         "Anomalies: ", anomalies, "/", total, "<br>",
                         "Rate: ", anomaly_rate, "%"),
          hoverinfo = 'text'
        ) |>
          plotly::layout(
            xaxis = list(title = "Hour of Day", dtick = 1),
            yaxis = list(title = "Anomaly Rate (%)"),
            hovermode = 'closest'
          ) |>
          plotly::config(
            modeBarButtonsToRemove = list(
              'pan2d', 'select2d', 'lasso2d',
              'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
            ),
            doubleClick = 'reset',
            displaylogo = FALSE
          )
      })

      # Severity Distribution Plot ----
      output$anomaly_severity_plot <- plotly::renderPlotly({
        results <- anomaly_results()

        if (nrow(results$severity_counts) == 0) {
          # No anomalies found
          plotly::plot_ly() |>
            plotly::layout(
              title = "No anomalies detected",
              xaxis = list(visible = FALSE),
              yaxis = list(visible = FALSE)
            )
        } else {
          severity_colors <- c(
            "Medium" = "#FFA500",
            "High" = "#FF4500",
            "Critical" = "#DC143C"
          )

          plotly::plot_ly(
            data = results$severity_counts,
            labels = ~severity,
            values = ~N,
            type = 'pie',
            marker = list(colors = ~severity_colors[severity]),
            text = ~paste0(severity, ": ", N),
            hoverinfo = 'text'
          ) |>
            plotly::layout(
              showlegend = TRUE
            ) |>
            plotly::config(
              modeBarButtonsToRemove = list(
                'pan2d', 'select2d', 'lasso2d',
                'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
              ),
              doubleClick = 'reset',
              displaylogo = FALSE
            )
        }
      })

      # Anomaly Table ----
      output$anomaly_table <- DT::renderDataTable({
        results <- anomaly_results()
        df <- results$data[is_anomaly == TRUE]

        if (nrow(df) == 0) {
          # Return empty table with message
          data.frame(Message = "No anomalies detected in the selected date range")
        } else {
          table_data <- df[, .(
            Timestamp = format(dttm_start, "%Y-%m-%d %H:%M:%S"),
            Value = round(value, 3),
            Expected_Min = round(expected_range_lower, 3),
            Expected_Max = round(expected_range_upper, 3),
            Anomaly_Score = round(anomaly_score, 3),
            Severity = severity
          )][order(-Anomaly_Score)]

          DT::datatable(
            table_data,
            options = list(
              pageLength = 10,
              order = list(list(4, 'desc')),  # Sort by Anomaly_Score descending
              columnDefs = list(
                list(className = 'dt-center', targets = '_all')
              )
            ),
            rownames = FALSE
          ) |>
            DT::formatStyle(
              'Severity',
              backgroundColor = DT::styleEqual(
                c('Medium', 'High', 'Critical'),
                c('#FFF4E6', '#FFE6E6', '#FFD6D6')
              )
            )
        }
      })

      # Download Handler ----
      output$download_anomalies <- downloadHandler(
        filename = function() {
          paste0("Anomaly_Report_", input$detection_method, "_", Sys.Date(), ".csv")
        },
        content = function(file) {
          results <- anomaly_results()

          report_data <- results$data[is_anomaly == TRUE, .(
            Timestamp = dttm_start,
            Value = value,
            Expected_Range_Lower = expected_range_lower,
            Expected_Range_Upper = expected_range_upper,
            Anomaly_Score = anomaly_score,
            Severity = severity,
            Detection_Method = results$method,
            Sensitivity = results$sensitivity
          )][order(-Anomaly_Score)]

          write.csv(report_data, file, row.names = FALSE)
          logger::log_info("Anomaly report downloaded: {results$method} method, {nrow(report_data)} anomalies")
        }
      )

    }
  )
}
