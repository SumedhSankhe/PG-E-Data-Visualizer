
patternUI <- function(id, label = 'pattern') {
  ns <- NS(id)
  h3('Pattern Recognition')
  shinyjs::useShinyjs()
  fluidPage(
    # Control Panel
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Pattern Analysis Settings', status = 'primary', solidHeader = TRUE,
        column(width = 3,
               uiOutput(outputId = ns('dateRange'))),
        column(width = 3,
               selectInput(
                 inputId = ns('pattern_type'),
                 label = 'Pattern Type',
                 choices = list(
                   'Daily Patterns' = 'daily',
                   'Weekly Patterns' = 'weekly',
                   'Day Type Comparison' = 'daytype',
                   'Load Curve Clustering' = 'clustering'
                 ),
                 selected = 'daily'
               )),
        column(width = 3,
               numericInput(
                 inputId = ns('num_clusters'),
                 label = 'Number of Clusters',
                 value = 3,
                 min = 2,
                 max = 7,
                 step = 1
               )),
        column(width = 3,
               actionButton(inputId = ns('run_analysis'),
                            label = 'Analyze Patterns',
                            icon = icon('chart-line'),
                            class = 'btn-primary btn-lg',
                            style = 'margin-top: 25px;'))
      )
    ),

    # Summary Metrics
    fluidRow(
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('peak_hour'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('avg_daily'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('pattern_consistency'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('weekend_vs_weekday'), width = 12))
    ),

    # Main Pattern Visualization
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Pattern Visualization',
        status = 'info',
        solidHeader = TRUE,
        shinycssloaders::withSpinner(
          plotly::plotlyOutput(outputId = ns("pattern_main_plot"), height = '450px')
        )
      )
    ),

    # Secondary Visualizations
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Hourly Consumption Heatmap',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("heatmap_plot"))
               )
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Pattern Statistics',
               status = 'info',
               solidHeader = TRUE,
               uiOutput(ns('pattern_stats'))
             ))
    ),

    # Clustering Results (conditional - single box)
    uiOutput(ns('clustering_box')),

    # Download Section
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Pattern Analysis Report',
        status = 'success',
        solidHeader = TRUE,
        downloadButton(ns('download_report'),
                       label = 'Download Pattern Report',
                       class = 'btn-success btn-lg')
      )
    )
  )
}


patternServer <- function(id, dt) {
  moduleServer(
    id,
    function(input, output, session) {

      # Date Range UI ----
      observe({
        output$dateRange <- renderUI({
          req(dt())
          ns <- session$ns
          logger::log_debug("Rendering Pattern Recognition date range selector")

          # Get min and max dates from data
          data_min_date <- as.Date(min(dt()$dttm_start))
          data_max_date <- as.Date(max(dt()$dttm_start))

          # Default to all available data or last 30 days
          default_end <- data_max_date
          default_start <- max(data_min_date, data_max_date - 29)

          logger::log_info("Pattern date range: data available from {data_min_date} to {data_max_date}")

          dateRangeInput(
            inputId = ns('dates'),
            label = 'Date Range for Analysis',
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

        # Add day of week and weekend flag
        df_filtered[, weekday := weekdays(start_date)]
        df_filtered[, is_weekend := weekday %in% c("Saturday", "Sunday")]
        df_filtered[, day_type := ifelse(is_weekend, "Weekend", "Weekday")]

        logger::log_info("Pattern data filtered: {nrow(df_filtered)} records from {input$dates[1]} to {input$dates[2]}")
        return(df_filtered)
      })

      # Pattern Analysis Reactive ----
      pattern_results <- reactive({
        input$run_analysis
        req(filtered_data())
        req(input$pattern_type)

        logger::log_info("Running pattern analysis: {input$pattern_type}")

        df <- filtered_data()
        pattern_type <- input$pattern_type

        results <- list()
        results$type <- pattern_type
        results$data <- df

        # Common statistics
        results$total_days <- length(unique(df$start_date))
        results$avg_daily_consumption <- round(sum(df$value, na.rm = TRUE) / results$total_days, 2)

        # Peak hour analysis
        hourly_avg <- df[, .(avg_value = mean(value, na.rm = TRUE)), by = hour][order(-avg_value)]
        results$peak_hour <- hourly_avg[1, hour]
        results$peak_value <- round(hourly_avg[1, avg_value], 2)

        # Pattern consistency (coefficient of variation)
        daily_totals <- df[, .(daily_total = sum(value, na.rm = TRUE)), by = start_date]
        results$cv <- round(sd(daily_totals$daily_total, na.rm = TRUE) / mean(daily_totals$daily_total, na.rm = TRUE) * 100, 1)
        results$consistency_score <- max(0, 100 - results$cv)

        # Weekend vs Weekday comparison
        daytype_avg <- df[, .(avg_consumption = mean(value, na.rm = TRUE)), by = day_type]
        if (nrow(daytype_avg) == 2) {
          weekday_avg <- daytype_avg[day_type == "Weekday", avg_consumption]
          weekend_avg <- daytype_avg[day_type == "Weekend", avg_consumption]
          results$weekend_diff_pct <- round((weekend_avg - weekday_avg) / weekday_avg * 100, 1)
        } else {
          results$weekend_diff_pct <- 0
        }

        # Pattern-specific analysis
        if (pattern_type == 'daily') {
          # Average hourly pattern across all days
          results$hourly_pattern <- df[, .(
            mean_value = mean(value, na.rm = TRUE),
            sd_value = sd(value, na.rm = TRUE),
            min_value = min(value, na.rm = TRUE),
            max_value = max(value, na.rm = TRUE),
            count = .N
          ), by = hour][order(hour)]

        } else if (pattern_type == 'weekly') {
          # Pattern by day of week
          df[, weekday_ordered := factor(weekday,
                                         levels = c("Monday", "Tuesday", "Wednesday",
                                                   "Thursday", "Friday", "Saturday", "Sunday"))]
          results$weekly_pattern <- df[, .(
            mean_value = mean(value, na.rm = TRUE),
            total_consumption = sum(value, na.rm = TRUE),
            count = .N
          ), by = .(weekday_ordered, hour)][order(weekday_ordered, hour)]

          results$daily_totals <- df[, .(
            total = sum(value, na.rm = TRUE),
            avg = mean(value, na.rm = TRUE)
          ), by = weekday_ordered][order(weekday_ordered)]

        } else if (pattern_type == 'daytype') {
          # Weekday vs Weekend patterns
          results$daytype_pattern <- df[, .(
            mean_value = mean(value, na.rm = TRUE),
            sd_value = sd(value, na.rm = TRUE),
            count = .N
          ), by = .(day_type, hour)][order(day_type, hour)]

          results$daytype_summary <- df[, .(
            avg_hourly = mean(value, na.rm = TRUE),
            total_daily = sum(value, na.rm = TRUE) / length(unique(start_date)),
            peak_hour = hour[which.max(value)]
          ), by = day_type]

        } else if (pattern_type == 'clustering') {
          # K-means clustering of daily load curves
          num_clusters <- input$num_clusters

          # Pivot data to wide format (days x hours)
          df_wide <- dcast(df, start_date ~ hour, value.var = "value", fun.aggregate = mean)

          # Remove date column and handle NAs
          cluster_data <- as.matrix(df_wide[, -1])
          cluster_data[is.na(cluster_data)] <- 0

          if (nrow(cluster_data) >= num_clusters) {
            # Perform k-means clustering
            set.seed(123)
            km <- kmeans(cluster_data, centers = num_clusters, nstart = 25)

            # Add cluster assignment back to data
            df_wide[, cluster := km$cluster]
            results$cluster_centers <- data.table(
              cluster = 1:num_clusters,
              as.data.table(km$centers)
            )

            # Melt centers for plotting
            results$cluster_centers_long <- melt(
              results$cluster_centers,
              id.vars = "cluster",
              variable.name = "hour",
              value.name = "value"
            )
            results$cluster_centers_long[, hour := as.numeric(as.character(hour))]

            # Cluster sizes and characteristics
            results$cluster_info <- data.table(
              cluster = 1:num_clusters,
              size = as.numeric(table(km$cluster)),
              avg_consumption = sapply(1:num_clusters, function(i) {
                mean(rowSums(cluster_data[km$cluster == i, , drop = FALSE]))
              }),
              peak_hour = sapply(1:num_clusters, function(i) {
                which.max(km$centers[i, ]) - 1
              })
            )
            results$cluster_info[, percentage := round(size / sum(size) * 100, 1)]

            # Add cluster info back to original data
            df_with_clusters <- merge(df, df_wide[, .(start_date, cluster)], by = "start_date")
            results$data_with_clusters <- df_with_clusters

          } else {
            logger::log_warn("Insufficient data for clustering: {nrow(cluster_data)} days < {num_clusters} clusters")
            results$clustering_error <- "Insufficient data for clustering"
          }
        }

        logger::log_info("Pattern analysis completed: {pattern_type}")
        return(results)
      })

      # Value Boxes ----
      output$peak_hour <- shinydashboard::renderValueBox({
        results <- pattern_results()
        shinydashboard::valueBox(
          value = paste0(results$peak_hour, ":00"),
          subtitle = paste0("Peak Hour (", results$peak_value, " kWh)"),
          icon = icon("clock"),
          color = "yellow"
        )
      })

      output$avg_daily <- shinydashboard::renderValueBox({
        results <- pattern_results()
        shinydashboard::valueBox(
          value = paste0(results$avg_daily_consumption, " kWh"),
          subtitle = "Avg Daily Consumption",
          icon = icon("chart-bar"),
          color = "blue"
        )
      })

      output$pattern_consistency <- shinydashboard::renderValueBox({
        results <- pattern_results()
        color_val <- if (results$consistency_score >= 70) "green" else if (results$consistency_score >= 50) "yellow" else "red"
        shinydashboard::valueBox(
          value = paste0(round(results$consistency_score, 0), "%"),
          subtitle = "Pattern Consistency",
          icon = icon("sync"),
          color = color_val
        )
      })

      output$weekend_vs_weekday <- shinydashboard::renderValueBox({
        results <- pattern_results()
        diff_pct <- results$weekend_diff_pct
        color_val <- if (abs(diff_pct) < 10) "green" else if (abs(diff_pct) < 25) "yellow" else "red"
        sign_char <- ifelse(diff_pct > 0, "+", "")
        shinydashboard::valueBox(
          value = paste0(sign_char, diff_pct, "%"),
          subtitle = "Weekend vs Weekday",
          icon = icon("calendar"),
          color = color_val
        )
      })

      # Main Pattern Plot ----
      output$pattern_main_plot <- plotly::renderPlotly({
        results <- pattern_results()

        validate(
          need(nrow(results$data) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        pattern_type <- results$type

        if (pattern_type == 'daily') {
          # Daily average pattern with confidence band
          data <- results$hourly_pattern

          validate(
            need(nrow(data) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
          )

          plotly::plot_ly(data, x = ~hour) |>
            plotly::add_ribbons(
              ymin = ~pmax(0, mean_value - sd_value),
              ymax = ~mean_value + sd_value,
              name = "± 1 SD",
              line = list(color = 'transparent'),
              fillcolor = 'rgba(70, 130, 180, 0.3)',
              hoverinfo = 'skip'
            ) |>
            plotly::add_trace(
              y = ~mean_value,
              type = 'scatter',
              mode = 'lines+markers',
              name = 'Average Pattern',
              line = list(color = '#4682B4', width = 3),
              marker = list(size = 8, color = '#4682B4'),
              text = ~paste0("Hour: ", hour, ":00<br>",
                            "Avg: ", round(mean_value, 2), " kWh<br>",
                            "Min: ", round(min_value, 2), " kWh<br>",
                            "Max: ", round(max_value, 2), " kWh"),
              hoverinfo = 'text'
            ) |>
            plotly::layout(
              title = "Average Daily Consumption Pattern",
              xaxis = list(title = "Hour of Day", dtick = 2),
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

        } else if (pattern_type == 'weekly') {
          # Weekly pattern by day
          data <- results$weekly_pattern

          plotly::plot_ly(data, x = ~hour, y = ~mean_value,
                         color = ~weekday_ordered, colors = 'Set2',
                         type = 'scatter', mode = 'lines+markers',
                         line = list(width = 2),
                         marker = list(size = 4)) |>
            plotly::layout(
              title = "Weekly Consumption Pattern by Day of Week",
              xaxis = list(title = "Hour of Day", dtick = 2),
              yaxis = list(title = "Average Consumption (kWh)"),
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

        } else if (pattern_type == 'daytype') {
          # Weekday vs Weekend comparison
          data <- results$daytype_pattern

          plotly::plot_ly(data, x = ~hour, y = ~mean_value,
                         color = ~day_type,
                         colors = c('Weekday' = '#2E86AB', 'Weekend' = '#A23B72'),
                         type = 'scatter', mode = 'lines+markers',
                         line = list(width = 3),
                         marker = list(size = 6)) |>
            plotly::layout(
              title = "Weekday vs Weekend Consumption Pattern",
              xaxis = list(title = "Hour of Day", dtick = 2),
              yaxis = list(title = "Average Consumption (kWh)"),
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

        } else if (pattern_type == 'clustering') {
          if (!is.null(results$clustering_error)) {
            plotly::plot_ly() |>
              plotly::layout(
                title = results$clustering_error,
                xaxis = list(visible = FALSE),
                yaxis = list(visible = FALSE)
              )
          } else {
            # Plot cluster centers
            data <- results$cluster_centers_long

            plotly::plot_ly(data, x = ~hour, y = ~value,
                           color = ~factor(cluster),
                           colors = 'Set1',
                           type = 'scatter', mode = 'lines+markers',
                           line = list(width = 3),
                           marker = list(size = 6)) |>
              plotly::layout(
                title = "Load Curve Clusters (Typical Daily Patterns)",
                xaxis = list(title = "Hour of Day", dtick = 2),
                yaxis = list(title = "Average Consumption (kWh)"),
                hovermode = 'closest',
                legend = list(title = list(text = 'Cluster'))
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
        }
      })

      # Heatmap Plot ----
      output$heatmap_plot <- plotly::renderPlotly({
        results <- pattern_results()
        df <- results$data

        validate(
          need(nrow(df) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        # Create hourly x day heatmap
        df[, date_label := format(start_date, "%Y-%m-%d")]
        heatmap_data <- df[, .(avg_value = mean(value, na.rm = TRUE)),
                           by = .(date_label, hour)]

        # Convert to wide format for heatmap
        heatmap_wide <- dcast(heatmap_data, date_label ~ hour, value.var = "avg_value")

        # Convert to matrix (excluding date column)
        z_matrix <- as.matrix(heatmap_wide[, -1])

        plotly::plot_ly(
          x = colnames(z_matrix),
          y = heatmap_wide$date_label,
          z = z_matrix,
          type = "heatmap",
          colorscale = "RdYlBu",
          reversescale = TRUE,
          colorbar = list(title = "kWh")
        ) |>
          plotly::layout(
            title = "Consumption Heatmap (Hour x Day)",
            xaxis = list(title = "Hour of Day"),
            yaxis = list(title = "Date")
          ) |>
          plotly::config(displaylogo = FALSE)
      })

      # Pattern Statistics ----
      output$pattern_stats <- renderUI({
        results <- pattern_results()

        stats_list <- tagList(
          tags$div(
            style = "padding: 10px;",
            tags$h4("Pattern Analysis Summary"),
            tags$hr(),
            tags$p(strong("Analysis Period: "),
                   paste(input$dates[1], "to", input$dates[2])),
            tags$p(strong("Total Days Analyzed: "), results$total_days),
            tags$p(strong("Average Daily Consumption: "),
                   paste(results$avg_daily_consumption, "kWh")),
            tags$p(strong("Peak Hour: "),
                   paste0(results$peak_hour, ":00 (", results$peak_value, " kWh)")),
            tags$p(strong("Consistency Score: "),
                   paste0(round(results$consistency_score, 0), "%")),
            tags$p(strong("Coefficient of Variation: "),
                   paste0(results$cv, "%"))
          )
        )

        # Add pattern-specific stats
        if (results$type == 'daytype' && !is.null(results$daytype_summary)) {
          stats_list <- tagList(
            stats_list,
            tags$hr(),
            tags$h5("Day Type Comparison"),
            tags$table(
              class = "table table-condensed",
              tags$thead(tags$tr(tags$th(""), tags$th("Weekday"), tags$th("Weekend"))),
              tags$tbody(
                tags$tr(
                  tags$td("Avg Hourly"),
                  tags$td(paste0(round(results$daytype_summary[day_type == "Weekday", avg_hourly], 2), " kWh")),
                  tags$td(paste0(round(results$daytype_summary[day_type == "Weekend", avg_hourly], 2), " kWh"))
                ),
                tags$tr(
                  tags$td("Avg Daily"),
                  tags$td(paste0(round(results$daytype_summary[day_type == "Weekday", total_daily], 2), " kWh")),
                  tags$td(paste0(round(results$daytype_summary[day_type == "Weekend", total_daily], 2), " kWh"))
                )
              )
            )
          )
        }

        stats_list
      })

      # Clustering Box (conditional rendering) ----
      output$clustering_box <- renderUI({
        req(input$pattern_type)

        if (input$pattern_type == 'clustering') {
          fluidRow(
            shinydashboard::box(
              width = 12,
              title = 'Clustering Analysis',
              status = 'warning',
              solidHeader = TRUE,
              fluidRow(
                column(width = 8,
                       h4('Cluster Profiles'),
                       shinycssloaders::withSpinner(
                         plotly::plotlyOutput(outputId = session$ns("cluster_profiles"))
                       )),
                column(width = 4,
                       h4('Cluster Distribution'),
                       DT::dataTableOutput(session$ns('cluster_table'))
                )
              )
            )
          )
        } else {
          NULL
        }
      })

      # Cluster Profiles Plot ----
      output$cluster_profiles <- plotly::renderPlotly({
        results <- pattern_results()
        req(results$type == 'clustering')
        req(!is.null(results$cluster_centers_long))

        data <- results$cluster_centers_long

        plotly::plot_ly(data, x = ~hour, y = ~value,
                       color = ~factor(cluster),
                       colors = 'Set1',
                       type = 'scatter', mode = 'lines+markers',
                       line = list(width = 2),
                       marker = list(size = 5),
                       fill = 'tozeroy',
                       fillcolor = 'rgba(0,0,0,0.1)') |>
          plotly::layout(
            title = "Cluster Profiles",
            xaxis = list(title = "Hour of Day", dtick = 2),
            yaxis = list(title = "Average Consumption (kWh)"),
            legend = list(title = list(text = 'Cluster'))
          ) |>
          plotly::config(displaylogo = FALSE)
      })

      # Cluster Table ----
      output$cluster_table <- DT::renderDataTable({
        results <- pattern_results()
        req(results$type == 'clustering')
        req(!is.null(results$cluster_info))

        cluster_data <- results$cluster_info[, .(
          Cluster = cluster,
          Days = size,
          Percentage = paste0(percentage, "%"),
          Avg_Daily_kWh = round(avg_consumption, 2),
          Peak_Hour = paste0(peak_hour, ":00")
        )]

        DT::datatable(
          cluster_data,
          options = list(
            pageLength = 10,
            dom = 't',
            ordering = FALSE
          ),
          rownames = FALSE
        ) |>
          DT::formatStyle(
            'Cluster',
            backgroundColor = DT::styleEqual(
              1:nrow(cluster_data),
              RColorBrewer::brewer.pal(max(3, nrow(cluster_data)), "Set1")[1:nrow(cluster_data)]
            )
          )
      })

      # Download Handler ----
      output$download_report <- downloadHandler(
        filename = function() {
          paste0("Pattern_Report_", input$pattern_type, "_", Sys.Date(), ".csv")
        },
        content = function(file) {
          results <- pattern_results()

          if (results$type == 'daily') {
            report_data <- results$hourly_pattern
          } else if (results$type == 'weekly') {
            report_data <- results$weekly_pattern
          } else if (results$type == 'daytype') {
            report_data <- results$daytype_pattern
          } else if (results$type == 'clustering' && !is.null(results$cluster_info)) {
            report_data <- results$cluster_info
          } else {
            report_data <- data.frame(Message = "No pattern data available")
          }

          write.csv(report_data, file, row.names = FALSE)
          logger::log_info("Pattern report downloaded: {results$type}")
        }
      )

    }
  )
}
