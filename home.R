
homeUI <- function(id, label = 'home'){
  ns <- NS(id)
  tagList(
    fluidPage(
      style = "padding: 20px;",

      # Header
      div(
        style = "text-align: center; margin-bottom: 30px;",
        h1("PG&E Data Visualizer", style = "color: #2c3e50; font-weight: bold;"),
        p(
          style = "font-size: 18px; color: #7f8c8d;",
          "An interactive tool for exploring and analyzing Pacific Gas & Electric smart meter consumption data"
        )
      ),

      hr(),

      # Overview Section
      div(
        style = "margin-bottom: 30px;",
        h2("Overview", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),
        p(
          style = "font-size: 16px; line-height: 1.6;",
          "The PG&E Data Visualizer helps utilities, energy customers, and analysts understand energy consumption patterns
          through interactive visualizations. Analyze time series data, examine hourly distributions, and compare usage
          across different rate plans—all through a web-based interface."
        )
      ),

      # Key Features Section
      div(
        style = "margin-bottom: 30px;",
        h2("Key Features", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),
        fluidRow(
          column(
            6,
            tags$ul(
              style = "font-size: 15px; line-height: 1.8;",
              tags$li(tags$strong("Time Series Analysis:"), " Visualize consumption patterns by hour of day with overlaid daily lines and smooth trend curves"),
              tags$li(tags$strong("Distribution Analysis:"), " Understand variability with box plots showing quartiles and outliers for each hour"),
              tags$li(tags$strong("Rate Plan Comparison:"), " Evaluate different PG&E pricing structures including Time of Use, Tiered, and Electric Vehicle plans")
            )
          ),
          column(
            6,
            tags$ul(
              style = "font-size: 15px; line-height: 1.8;",
              tags$li(tags$strong("Interactive Visualizations:"), " Zoom, pan, and hover for detailed insights using plotly-powered charts"),
              tags$li(tags$strong("Flexible Data Loading:"), " Upload your own CSV/TSV files or use the bundled sample dataset"),
              tags$li(tags$strong("Comprehensive Logging:"), " Track application operations with daily log files")
            )
          )
        )
      ),

      # Quick Start Guide - Compact version
      div(
        style = "margin-bottom: 20px; background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); padding: 20px; border-radius: 4px; border: 1px solid #dee2e6;",
        h2("Quick Start Guide", style = "color: #212529; margin-top: 0; font-size: 22px; font-weight: 600;"),
        fluidRow(
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #ffffff; border-radius: 4px; border: 2px solid #3b82f6; box-shadow: 0 1px 3px rgba(0,0,0,0.1);",
              tags$div(style = "font-size: 36px; color: #3b82f6; font-weight: 600;", "1"),
              h5("Load Data", style = "margin: 5px 0; color: #374151;"),
              p(style = "font-size: 12px; margin: 0; color: #6b7280;", "Data tab → Upload CSV/TSV")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #ffffff; border-radius: 4px; border: 2px solid #10b981; box-shadow: 0 1px 3px rgba(0,0,0,0.1);",
              tags$div(style = "font-size: 36px; color: #10b981; font-weight: 600;", "2"),
              h5("Quality Check", style = "margin: 5px 0; color: #374151;"),
              p(style = "font-size: 12px; margin: 0; color: #6b7280;", "QC tab → Run QC Analysis")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #ffffff; border-radius: 4px; border: 2px solid #f59e0b; box-shadow: 0 1px 3px rgba(0,0,0,0.1);",
              tags$div(style = "font-size: 36px; color: #f59e0b; font-weight: 600;", "3"),
              h5("Analyze", style = "margin: 5px 0; color: #374151;"),
              p(style = "font-size: 12px; margin: 0; color: #6b7280;", "Explore patterns & anomalies")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #ffffff; border-radius: 4px; border: 2px solid #ef4444; box-shadow: 0 1px 3px rgba(0,0,0,0.1);",
              tags$div(style = "font-size: 36px; color: #ef4444; font-weight: 600;", "4"),
              h5("Optimize", style = "margin: 5px 0; color: #374151;"),
              p(style = "font-size: 12px; margin: 0; color: #6b7280;", "Compare rate plans & save")
            )
          )
        ),
        tags$p(
          style = "margin-top: 15px; text-align: center; font-size: 14px; color: #495057;",
          icon("info-circle"), " Use the ", tags$strong("sidebar date filter"), " to select your analysis period."
        )
      ),

      # Analysis Features Explained - Collapsible
      div(
        style = "margin-bottom: 20px; border: 1px solid #e5e7eb; border-radius: 4px; background-color: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);",
        div(
          style = "padding: 12px 20px; background: linear-gradient(135deg, #f9fafb 0%, #ffffff 100%); border-bottom: 1px solid #e5e7eb; cursor: pointer; border-radius: 4px 4px 0 0;",
          onclick = "$(this).next().slideToggle(200);",
          tags$span(
            style = "font-size: 15px; font-weight: 500; color: #3b82f6;",
            icon('book'), ' Analysis Features Guide ',
            tags$span(style = "color: #6b7280; font-size: 13px; font-weight: normal;", "(click to expand)")
          )
        ),
        div(
          style = "display: none; padding: 20px;",
        fluidRow(
          column(
            6,
            # Quality Control
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #f0fdf4; border-left: 3px solid #10b981; border-radius: 4px;",
              h5(icon("check-circle", style = "color: #10b981;"), " Quality Control", style = "color: #374151; margin-top: 0; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Validates data quality (missing values, outliers, gaps)"),
                tags$li(tags$strong("When:"), " Run first after loading data"),
                tags$li(tags$strong("Key metric:"), " Quality Score 90%+ is excellent")
              )
            ),
            # Pattern Recognition
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #ecfeff; border-left: 3px solid #06b6d4; border-radius: 4px;",
              h5(icon("chart-line", style = "color: #06b6d4;"), " Pattern Recognition", style = "color: #374151; margin-top: 0; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Discovers daily, weekly, and seasonal patterns"),
                tags$li(tags$strong("When:"), " To understand usage habits and peak hours"),
                tags$li(tags$strong("Types:"), " Daily, Weekly, Day Type, Clustering")
              )
            )
          ),
          column(
            6,
            # Anomaly Detection
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #fffbeb; border-left: 3px solid #f59e0b; border-radius: 4px;",
              h5(icon("exclamation-triangle", style = "color: #f59e0b;"), " Anomaly Detection", style = "color: #374151; margin-top: 0; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Finds unusual consumption spikes/drops"),
                tags$li(tags$strong("When:"), " To spot malfunctions or unusual events"),
                tags$li(tags$strong("Tip:"), " Sensitivity 1-3 = strict, 7-10 = lenient")
              )
            ),
            # Cost Optimization
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #fef2f2; border-left: 3px solid #ef4444; border-radius: 4px;",
              h5(icon("dollar-sign", style = "color: #ef4444;"), " Cost Optimization", style = "color: #374151; margin-top: 0; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Calculates costs under different rate plans"),
                tags$li(tags$strong("When:"), " To choose optimal plan and reduce bills"),
                tags$li(tags$strong("Plans:"), " TOU, Tiered, EV, Custom rates")
              )
            )
          )
        )
        )
      ),

      # Data Format Requirements - Collapsible
      div(
        style = "margin-bottom: 20px; border: 1px solid #e5e7eb; border-radius: 4px; background-color: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);",
        div(
          style = "padding: 12px 20px; background: linear-gradient(135deg, #f9fafb 0%, #ffffff 100%); border-bottom: 1px solid #e5e7eb; cursor: pointer; border-radius: 4px 4px 0 0;",
          onclick = "$(this).next().slideToggle(200);",
          tags$span(
            style = "font-size: 15px; font-weight: 500; color: #6366f1;",
            icon('file-alt'), ' Data Format Requirements ',
            tags$span(style = "color: #6b7280; font-size: 13px; font-weight: normal;", "(click to expand)")
          )
        ),
        div(
          style = "display: none; padding: 20px;",
        tags$table(
          class = "table table-striped table-bordered",
          style = "margin-top: 10px; font-size: 13px;",
          tags$thead(
            tags$tr(
              tags$th("Column"),
              tags$th("Type"),
              tags$th("Description")
            )
          ),
          tags$tbody(
            tags$tr(
              tags$td(tags$code("dttm_start")),
              tags$td("DateTime"),
              tags$td("Timestamp (YYYY-MM-DD HH:MM:SS)")
            ),
            tags$tr(
              tags$td(tags$code("hour")),
              tags$td("Numeric"),
              tags$td("Hour of day (0-23)")
            ),
            tags$tr(
              tags$td(tags$code("value")),
              tags$td("Numeric"),
              tags$td("Energy consumption (kWh)")
            ),
            tags$tr(
              tags$td(tags$code("day")),
              tags$td("Numeric"),
              tags$td("Day identifier")
            ),
            tags$tr(
              tags$td(tags$code("day2")),
              tags$td("Numeric"),
              tags$td("Secondary day identifier")
            )
          )
        ),
        tags$p(
          style = "font-size: 13px; margin-top: 10px;",
          tags$strong("Supported Formats:"), " CSV, TSV"
        )
        )
      ),

      # Rate Plans Section - Collapsible
      div(
        style = "margin-bottom: 20px; border: 1px solid #e5e7eb; border-radius: 4px; background-color: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);",
        div(
          style = "padding: 12px 20px; background: linear-gradient(135deg, #f9fafb 0%, #ffffff 100%); border-bottom: 1px solid #e5e7eb; cursor: pointer; border-radius: 4px 4px 0 0;",
          onclick = "$(this).next().slideToggle(200);",
          tags$span(
            style = "font-size: 15px; font-weight: 500; color: #8b5cf6;",
            icon('bolt'), ' Understanding PG&E Rate Plans ',
            tags$span(style = "color: #6b7280; font-size: 13px; font-weight: normal;", "(click to expand)")
          )
        ),
        div(
          style = "display: none; padding: 20px;",
        fluidRow(
          column(
            6,
            div(
              style = "background-color: #dbeafe; padding: 12px; border-left: 3px solid #3b82f6; margin-bottom: 12px; border-radius: 4px;",
              h5("Time of Use (TOU)", style = "margin-top: 0; color: #1e3a8a; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0; color: #1e40af;",
                tags$li(tags$strong("E-TOU-C:"), " Peak 4-9 PM"),
                tags$li(tags$strong("E-TOU-D:"), " Peak 5-8 PM")
              )
            ),
            div(
              style = "background-color: #f0fdf4; padding: 12px; border-left: 3px solid #10b981; border-radius: 4px;",
              h5("Tiered Rates", style = "margin-top: 0; color: #065f46; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0; color: #047857;",
                tags$li("T1: 100% baseline"),
                tags$li("T2: 101-400% baseline"),
                tags$li("T3: >400% baseline")
              )
            )
          ),
          column(
            6,
            div(
              style = "background-color: #fef3c7; padding: 12px; border-left: 3px solid #f59e0b; margin-bottom: 12px; border-radius: 4px;",
              h5("EV Plans", style = "margin-top: 0; color: #92400e; font-weight: 600;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0; color: #b45309;",
                tags$li("EV2-A: Standard EV rate"),
                tags$li("EV-B: Alternative EV rate")
              )
            ),
            div(
              style = "background-color: #fae8ff; padding: 12px; border-left: 3px solid #a855f7; border-radius: 4px;",
              h5("Solar & Renewable", style = "margin-top: 0; color: #581c87; font-weight: 600;"),
              p(
                style = "font-size: 13px; margin-bottom: 0; color: #6b21a8;",
                tags$em("Coming soon")
              )
            )
          )
        )
        )
      ),

      # About Smart Meter Data - Collapsible
      div(
        style = "margin-bottom: 20px; border: 1px solid #e5e7eb; border-radius: 4px; background-color: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);",
        div(
          style = "padding: 12px 20px; background: linear-gradient(135deg, #f9fafb 0%, #ffffff 100%); border-bottom: 1px solid #e5e7eb; cursor: pointer; border-radius: 4px 4px 0 0;",
          onclick = "$(this).next().slideToggle(200);",
          tags$span(
            style = "font-size: 15px; font-weight: 500; color: #eab308;",
            icon('lightbulb'), ' About Smart Meter Data ',
            tags$span(style = "color: #6b7280; font-size: 13px; font-weight: normal;", "(click to expand)")
          )
        ),
        div(
          style = "display: none; padding: 20px;",
          p(
            style = "font-size: 14px; line-height: 1.6;",
            "Smart meters record your energy consumption at regular intervals (typically hourly). This granular data enables pattern recognition, cost optimization, anomaly detection, and informed decision-making for choosing the most cost-effective rate plan."
          )
        )
      ),

      # Footer / Call to Action
      div(
        style = "background: linear-gradient(135deg, #dbeafe 0%, #eff6ff 100%); color: #1e40af; padding: 20px; border-radius: 4px; text-align: center; border: 1px solid #3b82f6;",
        h3("Ready to Get Started?", style = "margin-top: 0; color: #1e3a8a; font-weight: 600;"),
        p(
          style = "font-size: 16px; color: #1e40af;",
          "Head to the ", tags$strong("Data tab"), " to load your energy consumption data and begin exploring!"
        )
      )
    )
  )
}


homeServer <- function(id){
  moduleServer(
    id,
    function(input, output, session){
      # Home UI is static, no server-side rendering needed
    }
  )
}