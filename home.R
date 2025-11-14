
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

      # Quick Start Guide
      div(
        style = "margin-bottom: 30px; background-color: #ecf0f1; padding: 20px; border-radius: 5px;",
        h2("Quick Start Guide", style = "color: #34495e; margin-top: 0;"),

        div(
          style = "margin-bottom: 15px;",
          h4("Step 1: Load Your Data", style = "color: #2980b9;"),
          p(
            style = "font-size: 15px; margin-left: 20px;",
            "Navigate to the", tags$strong("Data"), "tab and either:"
          ),
          tags$ul(
            style = "font-size: 15px; margin-left: 40px;",
            tags$li("Upload a CSV or TSV file with your smart meter data, OR"),
            tags$li("Use the pre-loaded sample dataset (loads automatically)")
          )
        ),

        div(
          style = "margin-bottom: 15px;",
          h4("Step 2: Check Data Quality (Recommended)", style = "color: #2980b9;"),
          p(
            style = "font-size: 15px; margin-left: 20px;",
            "Go to the", tags$strong("Quality Control"), "tab to verify your data:"
          ),
          tags$ul(
            style = "font-size: 15px; margin-left: 40px;",
            tags$li("Click", tags$strong("'Run QC Analysis'"), "to check for missing values, outliers, and data quality issues"),
            tags$li("Review the quality score and fix any flagged issues if needed")
          )
        ),

        div(
          style = "margin-bottom: 15px;",
          h4("Step 3: Analyze Your Data", style = "color: #2980b9;"),
          p(
            style = "font-size: 15px; margin-left: 20px;",
            "Use the sidebar date filter and explore different analysis tabs:"
          ),
          tags$ul(
            style = "font-size: 15px; margin-left: 40px;",
            tags$li(tags$strong("Anomaly Detection:"), " Find unusual consumption spikes or drops"),
            tags$li(tags$strong("Pattern Recognition:"), " Discover daily, weekly, or seasonal usage patterns"),
            tags$li(tags$strong("Cost Optimization:"), " Compare rate plans and identify savings opportunities")
          )
        ),

        div(
          h4("Step 4: Take Action", style = "color: #2980b9;"),
          tags$ul(
            style = "font-size: 15px; margin-left: 40px;",
            tags$li("Download reports for detailed analysis"),
            tags$li("Use insights to shift usage to off-peak hours"),
            tags$li("Choose the most cost-effective rate plan for your consumption pattern")
          )
        )
      ),

      # Workflow Guide
      div(
        style = "margin-bottom: 30px;",
        h2("Recommended Workflow", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),
        fluidRow(
          column(
            3,
            div(
              style = "text-align: center; padding: 20px; background-color: #e8f4f8; border-radius: 10px; height: 100%;",
              tags$div(style = "font-size: 50px; color: #3498db;", "1"),
              h4("Load Data"),
              p(style = "font-size: 13px;", "Upload your energy consumption data or use sample data")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 20px; background-color: #e8f8f5; border-radius: 10px; height: 100%;",
              tags$div(style = "font-size: 50px; color: #27ae60;", "2"),
              h4("Quality Check"),
              p(style = "font-size: 13px;", "Verify data completeness and identify quality issues")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 20px; background-color: #fef5e7; border-radius: 10px; height: 100%;",
              tags$div(style = "font-size: 50px; color: #f39c12;", "3"),
              h4("Discover Patterns"),
              p(style = "font-size: 13px;", "Detect anomalies and recognize usage patterns")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 20px; background-color: #fdeef4; border-radius: 10px; height: 100%;",
              tags$div(style = "font-size: 50px; color: #e74c3c;", "4"),
              h4("Optimize Costs"),
              p(style = "font-size: 13px;", "Compare rate plans and find savings opportunities")
            )
          )
        )
      ),

      # Analysis Features Explained
      div(
        style = "margin-bottom: 30px;",
        h2("Analysis Features Explained", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),

        # Quality Control
        div(
          style = "margin-bottom: 20px; padding: 15px; background-color: #e8f8f5; border-left: 5px solid #27ae60; border-radius: 5px;",
          h4(icon("check-circle"), " Quality Control", style = "color: #27ae60; margin-top: 0;"),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("What it does:"), " Validates your data quality by checking for missing values, outliers, negative consumption, and time gaps in your hourly data."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("When to use:"), " Always run this first after loading data to ensure your analysis is based on reliable data."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("Key metrics:"), " Data Quality Score (0-100%), missing values count, outliers detected, data completeness by hour."
          )
        ),

        # Anomaly Detection
        div(
          style = "margin-bottom: 20px; padding: 15px; background-color: #fef5e7; border-left: 5px solid #f39c12; border-radius: 5px;",
          h4(icon("exclamation-triangle"), " Anomaly Detection", style = "color: #f39c12; margin-top: 0;"),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("What it does:"), " Identifies unusual consumption patterns using statistical methods (IQR, Z-Score, Seasonal Decomposition, or Moving Average)."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("When to use:"), " To find unexpected spikes (appliance malfunctions, unusual events) or drops (missed readings) in your energy usage."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("Tip:"), " Adjust sensitivity (1-10) to control detection strictness. Lower values = more strict."
          )
        ),

        # Pattern Recognition
        div(
          style = "margin-bottom: 20px; padding: 15px; background-color: #e8f4f8; border-left: 5px solid #3498db; border-radius: 5px;",
          h4(icon("chart-line"), " Pattern Recognition", style = "color: #3498db; margin-top: 0;"),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("What it does:"), " Discovers consumption patterns across daily, weekly, or seasonal cycles. Uses clustering to group similar usage days together."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("When to use:"), " To understand your typical usage habits, identify peak hours, and compare weekday vs weekend consumption."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("Pattern types:"), " Daily (average hourly pattern), Weekly (by day of week), Day Type (weekday vs weekend), Clustering (groups similar days)."
          )
        ),

        # Cost Optimization
        div(
          style = "margin-bottom: 20px; padding: 15px; background-color: #fdeef4; border-left: 5px solid #e74c3c; border-radius: 5px;",
          h4(icon("dollar-sign"), " Cost Optimization", style = "color: #e74c3c; margin-top: 0;"),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("What it does:"), " Calculates your energy costs under different PG&E rate plans and identifies potential savings by shifting usage to off-peak hours."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("When to use:"), " When choosing a rate plan or optimizing your consumption schedule to reduce electricity bills."
          ),
          p(
            style = "font-size: 15px; line-height: 1.6;",
            tags$strong("Supported plans:"), " Time of Use (TOU), Tiered rates, EV charging plans, and custom flat rates. Compare all plans side-by-side."
          )
        )
      ),

      # Data Format Requirements
      div(
        style = "margin-bottom: 30px;",
        h2("Data Format Requirements", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),
        p(
          style = "font-size: 15px;",
          "Your uploaded file must include these columns:"
        ),
        tags$table(
          class = "table table-striped table-bordered",
          style = "margin-top: 15px; font-size: 14px;",
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
              tags$td("Timestamp of meter reading (YYYY-MM-DD HH:MM:SS)")
            ),
            tags$tr(
              tags$td(tags$code("hour")),
              tags$td("Numeric"),
              tags$td("Hour of day (0-23)")
            ),
            tags$tr(
              tags$td(tags$code("value")),
              tags$td("Numeric"),
              tags$td("Energy consumption in kilowatt-hours (kWh)")
            ),
            tags$tr(
              tags$td(tags$code("day")),
              tags$td("Numeric"),
              tags$td("Day identifier for grouping")
            ),
            tags$tr(
              tags$td(tags$code("day2")),
              tags$td("Numeric"),
              tags$td("Secondary day identifier")
            )
          )
        ),
        p(
          style = "font-size: 15px; margin-top: 10px;",
          tags$strong("Supported Formats:"), " CSV, TSV"
        )
      ),

      # Rate Plans Section
      div(
        style = "margin-bottom: 30px;",
        h2("Understanding PG&E Rate Plans", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),

        fluidRow(
          column(
            6,
            div(
              style = "background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin-bottom: 15px;",
              h4("Time of Use (TOU)", style = "margin-top: 0; color: #856404;"),
              p(
                style = "font-size: 14px;",
                "Different electricity prices for peak and off-peak hours:"
              ),
              tags$ul(
                style = "font-size: 14px;",
                tags$li(tags$strong("E-TOU-C:"), " Peak hours 4 PM - 9 PM (16:00-21:00)"),
                tags$li(tags$strong("E-TOU-D:"), " Peak hours 5 PM - 8 PM (17:00-20:00)")
              ),
              p(
                style = "font-size: 13px; margin-bottom: 0;",
                "Higher rates during peak demand periods encourage shifting usage to off-peak times."
              )
            ),

            div(
              style = "background-color: #d1ecf1; padding: 15px; border-left: 4px solid #17a2b8;",
              h4("Tiered Rate Plans", style = "margin-top: 0; color: #0c5460;"),
              p(
                style = "font-size: 14px;",
                "Usage-based pricing tiers:"
              ),
              tags$ul(
                style = "font-size: 14px;",
                tags$li(tags$strong("T1:"), " 100% of baseline allowance"),
                tags$li(tags$strong("T2:"), " 101%-400% of baseline allowance"),
                tags$li(tags$strong("T3:"), " Above 400% of baseline allowance")
              ),
              p(
                style = "font-size: 13px; margin-bottom: 0;",
                "Higher consumption moves you into higher-priced tiers."
              )
            )
          ),

          column(
            6,
            div(
              style = "background-color: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin-bottom: 15px;",
              h4("Electric Vehicle Plans", style = "margin-top: 0; color: #155724;"),
              p(
                style = "font-size: 14px;",
                "Optimized for EV charging:"
              ),
              tags$ul(
                style = "font-size: 14px;",
                tags$li(tags$strong("EV2-A:"), " Standard EV rate plan"),
                tags$li(tags$strong("EV-B:"), " Alternative EV pricing structure")
              ),
              p(
                style = "font-size: 13px; margin-bottom: 0;",
                "Designed to encourage off-peak charging when grid demand is lower."
              )
            ),

            div(
              style = "background-color: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;",
              h4("Solar & Renewable Energy", style = "margin-top: 0; color: #721c24;"),
              p(
                style = "font-size: 14px; margin-bottom: 0;",
                tags$em("Coming soon:"), " Net metering and renewable energy integration options."
              )
            )
          )
        )
      ),

      # About Smart Meter Data
      div(
        style = "margin-bottom: 30px;",
        h2("About Smart Meter Data", style = "color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px;"),
        p(
          style = "font-size: 15px; line-height: 1.6;",
          "Smart meters record your energy consumption at regular intervals (typically hourly). This granular data enables:"
        ),
        fluidRow(
          column(
            3,
            div(
              style = "text-align: center; padding: 15px;",
              tags$div(style = "font-size: 40px; color: #3498db;", "📊"),
              h5("Pattern Recognition"),
              p(style = "font-size: 13px;", "Identify when you use the most energy")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px;",
              tags$div(style = "font-size: 40px; color: #2ecc71;", "💰"),
              h5("Cost Optimization"),
              p(style = "font-size: 13px;", "Shift usage to lower-price periods")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px;",
              tags$div(style = "font-size: 40px; color: #e74c3c;", "🔍"),
              h5("Anomaly Detection"),
              p(style = "font-size: 13px;", "Spot unusual consumption patterns")
            )
          ),
          column(
            3,
            div(
              style = "text-align: center; padding: 15px;",
              tags$div(style = "font-size: 40px; color: #9b59b6;", "📈"),
              h5("Informed Decisions"),
              p(style = "font-size: 13px;", "Choose the most cost-effective rate plan")
            )
          )
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