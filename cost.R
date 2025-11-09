
costUI <- function(id, label = 'cost') {
  ns <- NS(id)
  h3('Cost Optimization')
  shinyjs::useShinyjs()
  fluidPage(
    # Control Panel
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Cost Analysis Settings', status = 'primary', solidHeader = TRUE,
        fluidRow(
          column(width = 4,
                 selectInput(
                   inputId = ns('rate_plan'),
                   label = 'Rate Plan',
                   choices = list(
                     'Time of Use (TOU)' = 'tou',
                     'Tiered Rate' = 'tiered',
                     'EV Rate' = 'ev',
                     'Custom Rate' = 'custom'
                   ),
                   selected = 'tou'
                 )),
          column(width = 4,
                 conditionalPanel(
                   condition = "input.rate_plan == 'tou' || input.rate_plan == 'ev'",
                   ns = ns,
                   numericInput(
                     inputId = ns('peak_rate'),
                     label = 'Peak Rate ($/kWh)',
                     value = 0.45,
                     min = 0,
                     max = 2,
                     step = 0.01
                   )
                 ),
                 conditionalPanel(
                   condition = "input.rate_plan == 'tiered'",
                   ns = ns,
                   numericInput(
                     inputId = ns('tier1_rate'),
                     label = 'Tier 1 Rate ($/kWh)',
                     value = 0.30,
                     min = 0,
                     max = 2,
                     step = 0.01
                   )
                 )),
          column(width = 4,
                 conditionalPanel(
                   condition = "input.rate_plan == 'tou' || input.rate_plan == 'ev'",
                   ns = ns,
                   numericInput(
                     inputId = ns('offpeak_rate'),
                     label = 'Off-Peak Rate ($/kWh)',
                     value = 0.25,
                     min = 0,
                     max = 2,
                     step = 0.01
                   )
                 ),
                 conditionalPanel(
                   condition = "input.rate_plan == 'tiered'",
                   ns = ns,
                   numericInput(
                     inputId = ns('tier2_rate'),
                     label = 'Tier 2 Rate ($/kWh)',
                     value = 0.40,
                     min = 0,
                     max = 2,
                     step = 0.01
                   )
                 ))
        ),
        fluidRow(
          column(width = 3,
                 conditionalPanel(
                   condition = "input.rate_plan == 'tou' || input.rate_plan == 'ev'",
                   ns = ns,
                   numericInput(
                     inputId = ns('peak_start'),
                     label = 'Peak Start Hour',
                     value = 16,
                     min = 0,
                     max = 23,
                     step = 1
                   )
                 ),
                 conditionalPanel(
                   condition = "input.rate_plan == 'tiered'",
                   ns = ns,
                   numericInput(
                     inputId = ns('tier1_limit'),
                     label = 'Tier 1 Limit (kWh/day)',
                     value = 30,
                     min = 0,
                     max = 1000,
                     step = 5
                   )
                 )),
          column(width = 3,
                 conditionalPanel(
                   condition = "input.rate_plan == 'tou' || input.rate_plan == 'ev'",
                   ns = ns,
                   numericInput(
                     inputId = ns('peak_end'),
                     label = 'Peak End Hour',
                     value = 21,
                     min = 0,
                     max = 23,
                     step = 1
                   )
                 )),
          column(width = 4,
                 actionButton(inputId = ns('calculate_cost'),
                              label = 'Calculate Costs',
                              icon = icon('calculator'),
                              class = 'btn-primary btn-lg',
                              style = 'margin-top: 25px; width: 100%;'))
        )
      )
    ),

    # Cost Summary Metrics
    fluidRow(
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('total_cost'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('avg_daily_cost'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('peak_cost_pct'), width = 12)),
      column(width = 3,
             shinydashboard::valueBoxOutput(ns('potential_savings'), width = 12))
    ),

    # Cost Breakdown Charts
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Daily Cost Trend',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("daily_cost_plot"))
               )
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Cost by Time Period',
               status = 'info',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("cost_breakdown_plot"))
               )
             ))
    ),

    # Hourly Analysis
    fluidRow(
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Hourly Cost Distribution',
               status = 'warning',
               solidHeader = TRUE,
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("hourly_cost_plot"))
               )
             )),
      column(width = 6,
             shinydashboard::box(
               width = 12,
               title = 'Cost Optimization Recommendations',
               status = 'success',
               solidHeader = TRUE,
               uiOutput(ns('recommendations'))
             ))
    ),

    # Comparison & Download
    fluidRow(
      shinydashboard::box(
        width = 12,
        title = 'Rate Plan Comparison',
        status = 'primary',
        solidHeader = TRUE,
        fluidRow(
          column(width = 8,
                 shinycssloaders::withSpinner(
                   plotly::plotlyOutput(outputId = ns("plan_comparison_plot"))
                 )),
          column(width = 4,
                 h4('Cost Summary Table'),
                 DT::dataTableOutput(ns('cost_summary_table')),
                 br(),
                 downloadButton(ns('download_cost_report'),
                                label = 'Download Cost Report',
                                class = 'btn-success btn-lg',
                                style = 'width: 100%;'))
        )
      )
    )
  )
}


costServer <- function(id, dt) {
  moduleServer(
    id,
    function(input, output, session) {

      # Cost Calculation Reactive ----
      cost_results <- reactive({
        input$calculate_cost
        req(dt())
        req(input$rate_plan)

        logger::log_info("Calculating costs with rate plan: {input$rate_plan}")

        df <- copy(dt())
        df[, start_date := as.Date(dttm_start)]

        validate(
          need(nrow(df) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        results <- list()
        results$rate_plan <- input$rate_plan
        results$data <- df

        # Calculate costs based on rate plan
        if (input$rate_plan == 'tou' || input$rate_plan == 'ev') {
          # Time of Use pricing
          peak_start <- input$peak_start
          peak_end <- input$peak_end
          peak_rate <- input$peak_rate
          offpeak_rate <- input$offpeak_rate

          df[, is_peak := hour >= peak_start & hour <= peak_end]
          df[, rate := ifelse(is_peak, peak_rate, offpeak_rate)]
          df[, cost := value * rate]

          results$peak_start <- peak_start
          results$peak_end <- peak_end
          results$peak_rate <- peak_rate
          results$offpeak_rate <- offpeak_rate

          # Cost breakdown
          results$peak_cost <- sum(df[is_peak == TRUE]$cost, na.rm = TRUE)
          results$offpeak_cost <- sum(df[is_peak == FALSE]$cost, na.rm = TRUE)
          results$peak_consumption <- sum(df[is_peak == TRUE]$value, na.rm = TRUE)
          results$offpeak_consumption <- sum(df[is_peak == FALSE]$value, na.rm = TRUE)

        } else if (input$rate_plan == 'tiered') {
          # Tiered pricing
          tier1_rate <- input$tier1_rate
          tier2_rate <- input$tier2_rate
          tier1_limit <- input$tier1_limit

          # Calculate daily totals and apply tiers
          daily_totals <- df[, .(daily_total = sum(value, na.rm = TRUE)), by = start_date]
          daily_totals[, tier1_usage := pmin(daily_total, tier1_limit)]
          daily_totals[, tier2_usage := pmax(0, daily_total - tier1_limit)]
          daily_totals[, daily_cost := tier1_usage * tier1_rate + tier2_usage * tier2_rate]

          # Join back to main data
          df <- merge(df, daily_totals[, .(start_date, daily_cost, daily_total)], by = "start_date")
          df[, cost := (value / daily_total) * daily_cost]

          results$tier1_rate <- tier1_rate
          results$tier2_rate <- tier2_rate
          results$tier1_limit <- tier1_limit
          results$tier1_cost <- sum(daily_totals$tier1_usage * tier1_rate, na.rm = TRUE)
          results$tier2_cost <- sum(daily_totals$tier2_usage * tier2_rate, na.rm = TRUE)

        } else {
          # Custom or default flat rate
          flat_rate <- 0.35
          df[, cost := value * flat_rate]
          results$flat_rate <- flat_rate
        }

        # Overall statistics
        results$total_cost <- sum(df$cost, na.rm = TRUE)
        results$total_days <- length(unique(df$start_date))
        results$avg_daily_cost <- results$total_cost / results$total_days
        results$total_consumption <- sum(df$value, na.rm = TRUE)
        results$avg_rate <- results$total_cost / results$total_consumption

        # Hourly cost analysis
        results$hourly_costs <- df[, .(
          total_cost = sum(cost, na.rm = TRUE),
          avg_cost = mean(cost, na.rm = TRUE),
          consumption = sum(value, na.rm = TRUE),
          count = .N
        ), by = hour][order(hour)]

        # Daily cost trend
        results$daily_costs <- df[, .(
          total_cost = sum(cost, na.rm = TRUE),
          consumption = sum(value, na.rm = TRUE)
        ), by = start_date][order(start_date)]

        # Peak cost percentage (for TOU plans)
        if (input$rate_plan == 'tou' || input$rate_plan == 'ev') {
          results$peak_cost_pct <- round((results$peak_cost / results$total_cost) * 100, 1)
        } else {
          results$peak_cost_pct <- NA
        }

        # Calculate potential savings
        results$potential_savings <- calculate_savings(df, input$rate_plan, results)

        # Rate plan comparisons
        results$plan_comparisons <- compare_rate_plans(df)

        results$data_with_cost <- df

        logger::log_info("Cost calculation completed: Total = ${round(results$total_cost, 2)}")
        return(results)
      })

      # Helper function to calculate potential savings
      calculate_savings <- function(df, current_plan, results) {
        # Simple savings estimation based on peak shifting
        if (current_plan == 'tou' || current_plan == 'ev') {
          # Estimate 10-15% savings if top 20% peak usage shifted to off-peak
          peak_usage <- df[is_peak == TRUE, .(value, cost)]
          if (nrow(peak_usage) > 0) {
            top_20_pct <- peak_usage[order(-value)][1:ceiling(nrow(peak_usage) * 0.2)]
            current_peak_cost <- sum(top_20_pct$cost, na.rm = TRUE)
            potential_offpeak_cost <- sum(top_20_pct$value * results$offpeak_rate, na.rm = TRUE)
            savings <- current_peak_cost - potential_offpeak_cost
            return(round(savings, 2))
          }
        }
        return(0)
      }

      # Helper function to compare different rate plans
      compare_rate_plans <- function(df) {
        comparisons <- list()

        # TOU Plan
        tou_df <- copy(df)
        tou_df[, is_peak := hour >= 16 & hour <= 21]
        tou_cost <- sum(tou_df[is_peak == TRUE]$value * 0.45, na.rm = TRUE) +
          sum(tou_df[is_peak == FALSE]$value * 0.25, na.rm = TRUE)
        comparisons$TOU <- tou_cost

        # Tiered Plan
        daily_totals <- df[, .(daily_total = sum(value, na.rm = TRUE)), by = start_date]
        tier_cost <- sum(pmin(daily_totals$daily_total, 30) * 0.30, na.rm = TRUE) +
          sum(pmax(0, daily_totals$daily_total - 30) * 0.40, na.rm = TRUE)
        comparisons$Tiered <- tier_cost

        # Flat Rate
        flat_cost <- sum(df$value * 0.35, na.rm = TRUE)
        comparisons$Flat <- flat_cost

        # EV Plan (super off-peak midnight to 6am)
        ev_df <- copy(df)
        ev_df[, period := ifelse(hour >= 0 & hour < 6, "super_offpeak",
                                   ifelse(hour >= 16 & hour <= 21, "peak", "offpeak"))]
        ev_cost <- sum(ev_df[period == "peak"]$value * 0.50, na.rm = TRUE) +
          sum(ev_df[period == "offpeak"]$value * 0.28, na.rm = TRUE) +
          sum(ev_df[period == "super_offpeak"]$value * 0.15, na.rm = TRUE)
        comparisons$EV <- ev_cost

        return(data.table(
          Plan = names(comparisons),
          Total_Cost = unlist(comparisons),
          Avg_Daily = unlist(comparisons) / length(unique(df$start_date))
        ))
      }

      # Value Boxes ----
      output$total_cost <- shinydashboard::renderValueBox({
        results <- cost_results()
        shinydashboard::valueBox(
          value = paste0("$", format(round(results$total_cost, 2), nsmall = 2, big.mark = ",")),
          subtitle = "Total Cost",
          icon = icon("dollar-sign"),
          color = "blue"
        )
      })

      output$avg_daily_cost <- shinydashboard::renderValueBox({
        results <- cost_results()
        shinydashboard::valueBox(
          value = paste0("$", format(round(results$avg_daily_cost, 2), nsmall = 2)),
          subtitle = "Average Daily Cost",
          icon = icon("calendar-day"),
          color = "green"
        )
      })

      output$peak_cost_pct <- shinydashboard::renderValueBox({
        results <- cost_results()
        if (!is.na(results$peak_cost_pct)) {
          color_val <- if (results$peak_cost_pct > 60) "red" else if (results$peak_cost_pct > 40) "yellow" else "green"
          shinydashboard::valueBox(
            value = paste0(results$peak_cost_pct, "%"),
            subtitle = "Peak Period Cost",
            icon = icon("clock"),
            color = color_val
          )
        } else {
          shinydashboard::valueBox(
            value = "N/A",
            subtitle = "Peak Period Cost",
            icon = icon("clock"),
            color = "light-blue"
          )
        }
      })

      output$potential_savings <- shinydashboard::renderValueBox({
        results <- cost_results()
        savings <- results$potential_savings
        color_val <- if (savings > 50) "green" else if (savings > 20) "yellow" else "light-blue"
        shinydashboard::valueBox(
          value = paste0("$", format(round(savings, 2), nsmall = 2)),
          subtitle = "Potential Savings",
          icon = icon("piggy-bank"),
          color = color_val
        )
      })

      # Daily Cost Trend Plot ----
      output$daily_cost_plot <- plotly::renderPlotly({
        results <- cost_results()
        data <- results$daily_costs

        validate(
          need(nrow(data) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        plotly::plot_ly(data, x = ~start_date, y = ~total_cost,
                       type = 'scatter', mode = 'lines+markers',
                       name = 'Daily Cost',
                       line = list(color = '#4682B4', width = 2),
                       marker = list(size = 6, color = '#4682B4'),
                       text = ~paste0("Date: ", start_date, "<br>",
                                     "Cost: $", round(total_cost, 2), "<br>",
                                     "Consumption: ", round(consumption, 2), " kWh"),
                       hoverinfo = 'text') |>
          plotly::layout(
            xaxis = list(title = "Date"),
            yaxis = list(title = "Cost ($)"),
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

      # Cost Breakdown Plot ----
      output$cost_breakdown_plot <- plotly::renderPlotly({
        results <- cost_results()

        if (results$rate_plan == 'tou' || results$rate_plan == 'ev') {
          data <- data.table(
            Period = c("Peak", "Off-Peak"),
            Cost = c(results$peak_cost, results$offpeak_cost),
            Consumption = c(results$peak_consumption, results$offpeak_consumption)
          )

          plotly::plot_ly(data, labels = ~Period, values = ~Cost,
                         type = 'pie',
                         marker = list(colors = c('#FF6B6B', '#4ECDC4')),
                         text = ~paste0(Period, "<br>",
                                       "$", round(Cost, 2), "<br>",
                                       round(Consumption, 2), " kWh"),
                         hoverinfo = 'text') |>
            plotly::layout(showlegend = TRUE) |>
            plotly::config(
            modeBarButtonsToRemove = list(
              'pan2d', 'select2d', 'lasso2d',
              'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
            ),
            doubleClick = 'reset',
            displaylogo = FALSE
          )

        } else if (results$rate_plan == 'tiered') {
          data <- data.table(
            Tier = c("Tier 1", "Tier 2"),
            Cost = c(results$tier1_cost, results$tier2_cost)
          )

          plotly::plot_ly(data, labels = ~Tier, values = ~Cost,
                         type = 'pie',
                         marker = list(colors = c('#95E1D3', '#F38181')),
                         text = ~paste0(Tier, ": $", round(Cost, 2)),
                         hoverinfo = 'text') |>
            plotly::layout(showlegend = TRUE) |>
            plotly::config(
            modeBarButtonsToRemove = list(
              'pan2d', 'select2d', 'lasso2d',
              'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
            ),
            doubleClick = 'reset',
            displaylogo = FALSE
          )
        } else {
          plotly::plot_ly() |>
            plotly::layout(
              annotations = list(
                text = "Cost breakdown not available for this rate plan",
                xref = "paper", yref = "paper",
                x = 0.5, y = 0.5,
                showarrow = FALSE,
                font = list(size = 14)
              ),
              xaxis = list(visible = FALSE),
              yaxis = list(visible = FALSE)
            )
        }
      })

      # Hourly Cost Distribution Plot ----
      output$hourly_cost_plot <- plotly::renderPlotly({
        results <- cost_results()
        data <- results$hourly_costs

        validate(
          need(nrow(data) > 0, 'No data available for the selected date range. Please select a valid date range with data.')
        )

        plotly::plot_ly(data, x = ~hour, y = ~total_cost,
                       type = 'bar',
                       marker = list(
                         color = ~total_cost,
                         colorscale = 'Viridis',
                         colorbar = list(title = "Cost ($)")
                       ),
                       text = ~paste0("Hour: ", hour, ":00<br>",
                                     "Total Cost: $", round(total_cost, 2), "<br>",
                                     "Avg Cost: $", round(avg_cost, 3), "<br>",
                                     "Consumption: ", round(consumption, 2), " kWh"),
                       hoverinfo = 'text') |>
          plotly::layout(
            xaxis = list(title = "Hour of Day", dtick = 2),
            yaxis = list(title = "Total Cost ($)"),
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

      # Recommendations ----
      output$recommendations <- renderUI({
        results <- cost_results()

        recs <- list()

        # High cost hours
        top_cost_hours <- results$hourly_costs[order(-total_cost)][1:3]
        recs <- c(recs, list(tags$div(
          class = "alert alert-warning",
          icon("lightbulb"),
          strong(" Highest Cost Hours: "),
          paste(paste0(top_cost_hours$hour, ":00"), collapse = ", "),
          br(),
          "Consider reducing usage during these times."
        )))

        # Peak usage recommendation
        if (results$rate_plan == 'tou' || results$rate_plan == 'ev') {
          if (results$peak_cost_pct > 50) {
            recs <- c(recs, list(tags$div(
              class = "alert alert-danger",
              icon("exclamation-triangle"),
              strong(" High Peak Usage: "),
              paste0(results$peak_cost_pct, "% of costs during peak hours."),
              br(),
              "Shift usage to off-peak hours (", results$peak_end + 1, ":00 - ",
              results$peak_start - 1, ":00) to save money."
            )))
          }
        }

        # Savings opportunity
        if (results$potential_savings > 20) {
          recs <- c(recs, list(tags$div(
            class = "alert alert-success",
            icon("piggy-bank"),
            strong(" Savings Opportunity: "),
            paste0("You could save approximately $", round(results$potential_savings, 2),
                   " by shifting high-usage activities to off-peak hours.")
          )))
        }

        # Best rate plan
        best_plan <- results$plan_comparisons[which.min(Total_Cost)]
        current_cost <- results$total_cost
        best_cost <- best_plan$Total_Cost
        if (best_cost < current_cost * 0.95) {
          recs <- c(recs, list(tags$div(
            class = "alert alert-info",
            icon("info-circle"),
            strong(" Rate Plan Recommendation: "),
            paste0("The ", best_plan$Plan, " plan could save you $",
                   round(current_cost - best_cost, 2), " for this period.")
          )))
        }

        do.call(tagList, recs)
      })

      # Rate Plan Comparison Plot ----
      output$plan_comparison_plot <- plotly::renderPlotly({
        results <- cost_results()
        data <- results$plan_comparisons

        plotly::plot_ly(data, x = ~Plan, y = ~Total_Cost,
                       type = 'bar',
                       marker = list(
                         color = c('#4ECDC4', '#FF6B6B', '#95E1D3', '#F38181'),
                         line = list(color = 'rgb(8,48,107)', width = 1.5)
                       ),
                       text = ~paste0("Plan: ", Plan, "<br>",
                                     "Total Cost: $", round(Total_Cost, 2), "<br>",
                                     "Daily Avg: $", round(Avg_Daily, 2)),
                       hoverinfo = 'text') |>
          plotly::layout(
            xaxis = list(title = "Rate Plan"),
            yaxis = list(title = "Total Cost ($)"),
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

      # Cost Summary Table ----
      output$cost_summary_table <- DT::renderDataTable({
        results <- cost_results()
        data <- results$plan_comparisons

        data[, Savings := Total_Cost[Plan == results$rate_plan] - Total_Cost]
        data[, Savings_Pct := round((Savings / Total_Cost[Plan == results$rate_plan]) * 100, 1)]

        display_data <- data[, .(
          Plan = Plan,
          Total = paste0("$", round(Total_Cost, 2)),
          Daily = paste0("$", round(Avg_Daily, 2)),
          Savings = paste0("$", round(Savings, 2)),
          `Savings %` = paste0(Savings_Pct, "%")
        )]

        DT::datatable(
          display_data,
          options = list(
            pageLength = 10,
            dom = 't',
            ordering = TRUE
          ),
          rownames = FALSE
        ) |>
          DT::formatStyle(
            'Savings',
            backgroundColor = DT::styleInterval(c(0), c('#FFE6E6', '#E6FFE6'))
          )
      })

      # Download Handler ----
      output$download_cost_report <- downloadHandler(
        filename = function() {
          paste0("Cost_Analysis_", input$rate_plan, "_", Sys.Date(), ".csv")
        },
        content = function(file) {
          results <- cost_results()

          # Create comprehensive report
          report <- results$data_with_cost[, .(
            Timestamp = dttm_start,
            Hour = hour,
            Consumption_kWh = value,
            Rate_Applied = rate,
            Cost = cost,
            Date = start_date
          )][order(Timestamp)]

          write.csv(report, file, row.names = FALSE)
          logger::log_info("Cost report downloaded: {input$rate_plan} plan")
        }
      )

    }
  )
}
