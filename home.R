
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
        style = "margin-bottom: 20px; background-color: #ecf0f1; padding: 20px; border-radius: 5px;",
        h2("Quick Start Guide", style = "color: #34495e; margin-top: 0;"),
        fluidRow(
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #e8f4f8; border-radius: 8px;",
              tags$div(style = "font-size: 36px; color: #3498db;", "1"),
              h5("Load Data", style = "margin: 5px 0;"),
              p(style = "font-size: 12px; margin: 0;", "Data tab → Upload CSV/TSV")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #e8f8f5; border-radius: 8px;",
              tags$div(style = "font-size: 36px; color: #27ae60;", "2"),
              h5("Quality Check", style = "margin: 5px 0;"),
              p(style = "font-size: 12px; margin: 0;", "QC tab → Run QC Analysis")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #fef5e7; border-radius: 8px;",
              tags$div(style = "font-size: 36px; color: #f39c12;", "3"),
              h5("Analyze", style = "margin: 5px 0;"),
              p(style = "font-size: 12px; margin: 0;", "Explore patterns & anomalies")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px; background-color: #fdeef4; border-radius: 8px;",
              tags$div(style = "font-size: 36px; color: #e74c3c;", "4"),
              h5("Optimize", style = "margin: 5px 0;"),
              p(style = "font-size: 12px; margin: 0;", "Compare rate plans & save")
            )
          )
        ),
        tags$p(
          style = "margin-top: 15px; text-align: center; font-size: 14px;",
          icon("info-circle"), " Use the ", tags$strong("sidebar date filter"), " to select your analysis period."
        )
      ),

      # Analysis Features Explained - Collapsible
      shinydashboard::box(
        width = 12,
        status = 'info',
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        title = tags$span(icon('book'), ' Analysis Features Guide (click to expand)'),
        fluidRow(
          column(
            6,
            # Quality Control
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #e8f8f5; border-left: 4px solid #27ae60; border-radius: 4px;",
              h5(icon("check-circle"), " Quality Control", style = "color: #27ae60; margin-top: 0;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Validates data quality (missing values, outliers, gaps)"),
                tags$li(tags$strong("When:"), " Run first after loading data"),
                tags$li(tags$strong("Key metric:"), " Quality Score 90%+ is excellent")
              )
            ),
            # Pattern Recognition
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #e8f4f8; border-left: 4px solid #3498db; border-radius: 4px;",
              h5(icon("chart-line"), " Pattern Recognition", style = "color: #3498db; margin-top: 0;"),
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
              style = "margin-bottom: 15px; padding: 12px; background-color: #fef5e7; border-left: 4px solid #f39c12; border-radius: 4px;",
              h5(icon("exclamation-triangle"), " Anomaly Detection", style = "color: #f39c12; margin-top: 0;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Finds unusual consumption spikes/drops"),
                tags$li(tags$strong("When:"), " To spot malfunctions or unusual events"),
                tags$li(tags$strong("Tip:"), " Sensitivity 1-3 = strict, 7-10 = lenient")
              )
            ),
            # Cost Optimization
            div(
              style = "margin-bottom: 15px; padding: 12px; background-color: #fdeef4; border-left: 4px solid #e74c3c; border-radius: 4px;",
              h5(icon("dollar-sign"), " Cost Optimization", style = "color: #e74c3c; margin-top: 0;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("What:"), " Calculates costs under different rate plans"),
                tags$li(tags$strong("When:"), " To choose optimal plan and reduce bills"),
                tags$li(tags$strong("Plans:"), " TOU, Tiered, EV, Custom rates")
              )
            )
          )
        )
      ),

      # Data Format Requirements - Collapsible
      shinydashboard::box(
        width = 12,
        status = 'primary',
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        title = tags$span(icon('file-alt'), ' Data Format Requirements (click to expand)'),
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
      ),

      # Rate Plans Section - Collapsible
      shinydashboard::box(
        width = 12,
        status = 'warning',
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        title = tags$span(icon('bolt'), ' Understanding PG&E Rate Plans (click to expand)'),
        fluidRow(
          column(
            6,
            div(
              style = "background-color: #fff3cd; padding: 12px; border-left: 4px solid #ffc107; margin-bottom: 12px; border-radius: 4px;",
              h5("Time of Use (TOU)", style = "margin-top: 0; color: #856404;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li(tags$strong("E-TOU-C:"), " Peak 4-9 PM"),
                tags$li(tags$strong("E-TOU-D:"), " Peak 5-8 PM")
              )
            ),
            div(
              style = "background-color: #d1ecf1; padding: 12px; border-left: 4px solid #17a2b8; border-radius: 4px;",
              h5("Tiered Rates", style = "margin-top: 0; color: #0c5460;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li("T1: 100% baseline"),
                tags$li("T2: 101-400% baseline"),
                tags$li("T3: >400% baseline")
              )
            )
          ),
          column(
            6,
            div(
              style = "background-color: #d4edda; padding: 12px; border-left: 4px solid #28a745; margin-bottom: 12px; border-radius: 4px;",
              h5("EV Plans", style = "margin-top: 0; color: #155724;"),
              tags$ul(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$li("EV2-A: Standard EV rate"),
                tags$li("EV-B: Alternative EV rate")
              )
            ),
            div(
              style = "background-color: #f8d7da; padding: 12px; border-left: 4px solid #dc3545; border-radius: 4px;",
              h5("Solar & Renewable", style = "margin-top: 0; color: #721c24;"),
              p(
                style = "font-size: 13px; margin-bottom: 0;",
                tags$em("Coming soon")
              )
            )
          )
        )
      ),

      # About Smart Meter Data - Collapsible
      shinydashboard::box(
        width = 12,
        status = 'success',
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        title = tags$span(icon('lightbulb'), ' About Smart Meter Data (click to expand)'),
        p(
          style = "font-size: 14px; line-height: 1.6;",
          "Smart meters record your energy consumption at regular intervals (typically hourly). This granular data enables pattern recognition, cost optimization, anomaly detection, and informed decision-making for choosing the most cost-effective rate plan."
        )
      ),

      # Footer / Call to Action
      div(
        style = "background-color: #3498db; color: white; padding: 20px; border-radius: 5px; text-align: center;",
        h3("Ready to Get Started?", style = "margin-top: 0;"),
        p(
          style = "font-size: 16px;",
          "Head to the Data tab to load your energy consumption data and begin exploring!"
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