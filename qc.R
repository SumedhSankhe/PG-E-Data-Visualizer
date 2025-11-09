
qcUI <- function(id, label = 'qc') {
  ns <- NS(id)
  h3('Data Quality Control')
  shinyjs::useShinyjs()
  fluidPage(
    # Date Range Filter
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'QC Filters', status = 'primary', solidHeader = TRUE,
        column(width = 4,
               uiOutput(outputId = ns('dateRange'))),
        column(width = 4,
               actionButton(inputId = ns('run_qc'),
                            label = 'Run QC Analysis',
                            icon = icon('play'),
                            class = 'btn-primary btn-lg')),
        column(width = 4,
               downloadButton(ns('download_qc_report'),
                              label = 'Download QC Report',
                              class = 'btn-success btn-lg'))
      )
    ),

    # QC Metrics Value Boxes
    fluidRow(
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('qc_total_records'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('qc_missing_values'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('qc_outliers'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('qc_data_quality'), width = 12))
    ),

    # QC Details Row
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'QC Summary Statistics',
               status = 'info',
               solidHeader = TRUE,
               DT::dataTableOutput(ns('qc_summary_table'))
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'QC Flags & Warnings',
               status = 'warning',
               solidHeader = TRUE,
               uiOutput(ns('qc_flags'))
             ))
    ),

    # QC Visualizations
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Data Completeness by Hour',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("qc_completeness_plot"))
               )
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Value Distribution with Outliers',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("qc_distribution_plot"))
               )
             ))
    ),

    # Time Series with Issues Highlighted
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Time Series with Data Quality Issues Highlighted',
        status = 'warning',
        solidHeader = TRUE,
        shinycssloaders::withSpinner(
          plotly::plotlyOutput(outputId = ns("qc_timeseries_plot"))
        )
      )
    )
  )
}


qcServer <- function(id, dt) {
  moduleServer(
    id,
    function(input, output, session) {

      # Date Range UI ----
      observe({
        output$dateRange <- renderUI({
          req(dt())
          ns <- session$ns
          logger::log_debug("Rendering QC date range selector")

          # Get min and max dates from data
          data_min_date <- as.Date(min(dt()$dttm_start))
          data_max_date <- as.Date(max(dt()$dttm_start))

          # Default to first available day (1 day range)
          default_start <- data_min_date
          default_end <- data_min_date

          logger::log_info("QC date range: data available from {data_min_date} to {data_max_date}, defaulting to {default_start}")

          dateRangeInput(
            inputId = ns('dates'),
            label = 'Date Range for QC Analysis',
            start = default_start,
            end = default_end,
            min = data_min_date,
            max = data_max_date
          )
        })
      })

      # Filtered Data Reactive ----
      filtered_data <- reactive({
        req(dt())
        req(input$dates)

        validate(
          need(!is.na(input$dates[1]), 'Select a start date'),
          need(!is.na(input$dates[2]), 'Select an end date')
        )

        df <- copy(dt())
        df[, start_date := as.Date(dttm_start)]
        df_filtered <- df[start_date >= input$dates[1] & start_date <= input$dates[2]]

        logger::log_info("QC data filtered: {nrow(df_filtered)} records from {input$dates[1]} to {input$dates[2]}")
        return(df_filtered)
      })

      # QC Analysis Reactive ----
      qc_results <- reactive({
        # Trigger on button click OR when filtered data changes
        input$run_qc
        req(filtered_data())
        logger::log_info("Running QC analysis on filtered data")

        df <- filtered_data()

        # Initialize QC results list
        qc <- list()

        # Total records
        qc$total_records <- nrow(df)
        qc$date_range <- paste(input$dates[1], "to", input$dates[2])

        # Missing values check
        qc$missing_values <- sum(is.na(df$value))
        qc$missing_pct <- round((qc$missing_values / qc$total_records) * 100, 2)

        # Negative values (impossible for consumption)
        qc$negative_values <- sum(df$value < 0, na.rm = TRUE)

        # Zero values (potential meter issue)
        qc$zero_values <- sum(df$value == 0, na.rm = TRUE)
        qc$zero_pct <- round((qc$zero_values / qc$total_records) * 100, 2)

        # Outlier detection using IQR method
        Q1 <- quantile(df$value, 0.25, na.rm = TRUE)
        Q3 <- quantile(df$value, 0.75, na.rm = TRUE)
        IQR_val <- Q3 - Q1
        lower_bound <- Q1 - 1.5 * IQR_val
        upper_bound <- Q3 + 1.5 * IQR_val

        qc$outliers <- sum(df$value < lower_bound | df$value > upper_bound, na.rm = TRUE)
        qc$outlier_pct <- round((qc$outliers / qc$total_records) * 100, 2)
        qc$outlier_lower <- lower_bound
        qc$outlier_upper <- upper_bound

        # Duplicate timestamps
        qc$duplicate_timestamps <- sum(duplicated(df$dttm_start))

        # Time gaps detection (expecting hourly data)
        if ("dttm_start" %in% names(df)) {
          df_sorted <- df[order(dttm_start)]
          time_diffs <- as.numeric(diff(df_sorted$dttm_start), units = "hours")
          qc$time_gaps <- sum(time_diffs > 1.5, na.rm = TRUE)  # gaps > 1.5 hours
        } else {
          qc$time_gaps <- NA
        }

        # Summary statistics
        qc$mean_value <- round(mean(df$value, na.rm = TRUE), 3)
        qc$median_value <- round(median(df$value, na.rm = TRUE), 3)
        qc$min_value <- round(min(df$value, na.rm = TRUE), 3)
        qc$max_value <- round(max(df$value, na.rm = TRUE), 3)
        qc$sd_value <- round(sd(df$value, na.rm = TRUE), 3)

        # Data quality score (0-100)
        issues <- qc$missing_pct + qc$outlier_pct +
                  (qc$negative_values / qc$total_records * 100)
        qc$quality_score <- max(0, 100 - issues)

        # Completeness by hour
        if ("hour" %in% names(df)) {
          qc$completeness_by_hour <- df[, .(
            total = .N,
            missing = sum(is.na(value)),
            valid = sum(!is.na(value)),
            completeness_pct = round((1 - sum(is.na(value)) / .N) * 100, 1)
          ), by = hour][order(hour)]
        }

        # Flag problematic records for visualization
        df[, is_outlier := (value < lower_bound | value > upper_bound)]
        df[, is_missing := is.na(value)]
        df[, is_negative := value < 0]
        df[, has_issue := is_outlier | is_missing | is_negative]
        qc$data_with_flags <- df

        logger::log_info("QC analysis completed. Quality score: {qc$quality_score}%")
        return(qc)
      })

      # QC Value Boxes ----
      output$qc_total_records <- shinydashboard::renderValueBox({
        qc <- qc_results()
        shinydashboard::valueBox(
          value = format(qc$total_records, big.mark = ","),
          subtitle = "Total Records",
          icon = icon("database"),
          color = "blue"
        )
      })

      output$qc_missing_values <- shinydashboard::renderValueBox({
        qc <- qc_results()
        color_val <- if (qc$missing_pct > 5) "red" else if (qc$missing_pct > 1) "yellow" else "green"
        shinydashboard::valueBox(
          value = paste0(qc$missing_values, " (", qc$missing_pct, "%)"),
          subtitle = "Missing Values",
          icon = icon("exclamation-triangle"),
          color = color_val
        )
      })

      output$qc_outliers <- shinydashboard::renderValueBox({
        qc <- qc_results()
        color_val <- if (qc$outlier_pct > 10) "red" else if (qc$outlier_pct > 5) "yellow" else "green"
        shinydashboard::valueBox(
          value = paste0(qc$outliers, " (", qc$outlier_pct, "%)"),
          subtitle = "Outliers Detected",
          icon = icon("chart-line"),
          color = color_val
        )
      })

      output$qc_data_quality <- shinydashboard::renderValueBox({
        qc <- qc_results()
        score <- round(qc$quality_score, 1)
        color_val <- if (score >= 90) "green" else if (score >= 70) "yellow" else "red"
        shinydashboard::valueBox(
          value = paste0(score, "%"),
          subtitle = "Data Quality Score",
          icon = icon("check-circle"),
          color = color_val
        )
      })

      # QC Summary Table ----
      output$qc_summary_table <- DT::renderDataTable({
        qc <- qc_results()

        summary_df <- data.frame(
          Metric = c("Date Range", "Mean (kWh)", "Median (kWh)", "Min (kWh)", "Max (kWh)",
                     "Std Dev", "Negative Values", "Zero Values",
                     "Duplicate Timestamps", "Time Gaps"),
          Value = c(
            qc$date_range,
            qc$mean_value,
            qc$median_value,
            qc$min_value,
            qc$max_value,
            qc$sd_value,
            qc$negative_values,
            paste0(qc$zero_values, " (", qc$zero_pct, "%)"),
            qc$duplicate_timestamps,
            if (is.na(qc$time_gaps)) "N/A" else qc$time_gaps
          ),
          stringsAsFactors = FALSE
        )

        DT::datatable(
          summary_df,
          options = list(
            pageLength = 15,
            dom = 't',
            ordering = FALSE
          ),
          rownames = FALSE
        )
      })

      # QC Flags ----
      output$qc_flags <- renderUI({
        qc <- qc_results()

        flags <- list()

        if (qc$missing_pct > 5) {
          flags <- c(flags, list(tags$div(
            class = "alert alert-danger",
            icon("exclamation-circle"),
            strong(" High Missing Values: "),
            paste0(qc$missing_pct, "% of data is missing")
          )))
        }

        if (qc$outlier_pct > 10) {
          flags <- c(flags, list(tags$div(
            class = "alert alert-warning",
            icon("chart-line"),
            strong(" High Outlier Rate: "),
            paste0(qc$outlier_pct, "% outliers detected (outside ",
                   round(qc$outlier_lower, 2), " - ", round(qc$outlier_upper, 2), " kWh)")
          )))
        }

        if (qc$negative_values > 0) {
          flags <- c(flags, list(tags$div(
            class = "alert alert-danger",
            icon("times-circle"),
            strong(" Invalid Negative Values: "),
            paste0(qc$negative_values, " records with negative consumption")
          )))
        }

        if (qc$duplicate_timestamps > 0) {
          flags <- c(flags, list(tags$div(
            class = "alert alert-warning",
            icon("copy"),
            strong(" Duplicate Timestamps: "),
            paste0(qc$duplicate_timestamps, " duplicate timestamp(s) found")
          )))
        }

        if (!is.na(qc$time_gaps) && qc$time_gaps > 0) {
          flags <- c(flags, list(tags$div(
            class = "alert alert-info",
            icon("clock"),
            strong(" Time Gaps: "),
            paste0(qc$time_gaps, " gap(s) in hourly sequence detected")
          )))
        }

        if (length(flags) == 0) {
          flags <- list(tags$div(
            class = "alert alert-success",
            icon("check-circle"),
            strong(" Data Quality Excellent: "),
            "No major issues detected in selected date range"
          ))
        }

        do.call(tagList, flags)
      })

      # QC Completeness Plot ----
      output$qc_completeness_plot <- plotly::renderPlotly({
        qc <- qc_results()
        req(qc$completeness_by_hour)

        validate(
          need(nrow(qc$completeness_by_hour) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        plotly::plot_ly(
          data = qc$completeness_by_hour,
          x = ~hour,
          y = ~completeness_pct,
          type = 'bar',
          marker = list(
            color = ~completeness_pct,
            colorscale = list(c(0, 'red'), c(0.5, 'yellow'), c(1, 'green')),
            cmin = 0,
            cmax = 100,
            colorbar = list(title = "Completeness %")
          ),
          text = ~paste0("Hour: ", hour, "<br>",
                         "Valid: ", valid, "/", total, "<br>",
                         "Completeness: ", completeness_pct, "%"),
          hoverinfo = 'text'
        ) |>
          plotly::layout(
            xaxis = list(title = "Hour of Day", dtick = 1),
            yaxis = list(title = "Data Completeness (%)", range = c(0, 105)),
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

      # QC Distribution Plot ----
      output$qc_distribution_plot <- plotly::renderPlotly({
        qc <- qc_results()
        df <- qc$data_with_flags

        validate(
          need(nrow(df) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        # Create separate boxplots for normal data and outliers
        plotly::plot_ly() |>
          plotly::add_trace(
            data = df[is_outlier == FALSE & !is.na(value)],
            y = ~value,
            x = rep("Normal Range", sum(df$is_outlier == FALSE & !is.na(df$value))),
            type = "box",
            name = "Normal Range",
            marker = list(color = '#90C695'),
            line = list(color = '#7FB685'),
            boxpoints = FALSE
          ) |>
          plotly::add_trace(
            data = df[is_outlier == TRUE],
            y = ~value,
            x = rep("Outliers", sum(df$is_outlier == TRUE)),
            type = "box",
            name = "Outliers",
            marker = list(color = '#FFB3BA'),
            line = list(color = '#FF8A94'),
            boxpoints = 'all',
            jitter = 0.3,
            pointpos = 0
          ) |>
          plotly::layout(
            title = paste0("Normal Range: ", round(qc$outlier_lower, 2),
                           " - ", round(qc$outlier_upper, 2), " kWh"),
            yaxis = list(title = "Consumption (kWh)"),
            xaxis = list(title = ""),
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
      })

      # QC Time Series Plot ----
      output$qc_timeseries_plot <- plotly::renderPlotly({
        qc <- qc_results()
        df <- qc$data_with_flags

        validate(
          need(nrow(df) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        # Normal data points
        p <- plotly::plot_ly(df[has_issue == FALSE], x = ~dttm_start, y = ~value,
                             type = 'scatter', mode = 'lines+markers',
                             name = 'Valid Data',
                             line = list(color = 'steelblue'),
                             marker = list(size = 4, color = 'steelblue'))

        # Outliers
        if (sum(df$is_outlier, na.rm = TRUE) > 0) {
          p <- p |> plotly::add_trace(
            data = df[is_outlier == TRUE],
            x = ~dttm_start, y = ~value,
            type = 'scatter', mode = 'markers',
            name = 'Outliers',
            marker = list(size = 10, color = 'red', symbol = 'x')
          )
        }

        # Negative values
        if (sum(df$is_negative, na.rm = TRUE) > 0) {
          p <- p |> plotly::add_trace(
            data = df[is_negative == TRUE],
            x = ~dttm_start, y = ~value,
            type = 'scatter', mode = 'markers',
            name = 'Negative Values',
            marker = list(size = 10, color = 'purple', symbol = 'diamond')
          )
        }

        p |> plotly::layout(
          xaxis = list(title = "Timestamp"),
          yaxis = list(title = "Consumption (kWh)"),
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

      # Download QC Report ----
      output$download_qc_report <- downloadHandler(
        filename = function() {
          paste0("QC_Report_", Sys.Date(), ".csv")
        },
        content = function(file) {
          qc <- qc_results()

          report <- data.frame(
            Section = c(rep("Overview", 2), rep("Statistics", 5), rep("Quality Checks", 5)),
            Metric = c("Date Range", "Total Records",
                       "Mean (kWh)", "Median (kWh)", "Min (kWh)", "Max (kWh)", "Std Dev",
                       "Missing Values", "Outliers", "Negative Values", "Zero Values",
                       "Data Quality Score (%)"),
            Value = c(
              qc$date_range,
              qc$total_records,
              qc$mean_value,
              qc$median_value,
              qc$min_value,
              qc$max_value,
              qc$sd_value,
              paste0(qc$missing_values, " (", qc$missing_pct, "%)"),
              paste0(qc$outliers, " (", qc$outlier_pct, "%)"),
              qc$negative_values,
              paste0(qc$zero_values, " (", qc$zero_pct, "%)"),
              round(qc$quality_score, 1)
            )
          )

          write.csv(report, file, row.names = FALSE)
          logger::log_info("QC report downloaded")
        }
      )

    }
  )
}
