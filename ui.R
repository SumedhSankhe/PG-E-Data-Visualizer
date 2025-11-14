shinyUI(
  shinydashboard::dashboardPage(
    title = 'PG&E Analytics',
    skin = 'black',
    header = shinydashboard::dashboardHeader(
      title = 'Analytics', titleWidth = 200
    ),
    sidebar = shinydashboard::dashboardSidebar(
      width = 200,
      shinydashboard::sidebarMenu(
        shinydashboard::menuItem(text = 'Home', tabName = 'home',
                                 icon = icon('home')),
        shinydashboard::menuItem(text = 'Data', tabName = 'loadData',
                                 icon = icon('file-import')),
        shinydashboard::menuItem(text = 'Quality Control', tabName = 'qc',
                                 icon = icon('check-circle')),
        shinydashboard::menuItem(text = 'Anomaly Detection', tabName = 'anomaly',
                                 icon = icon('exclamation-triangle')),
        shinydashboard::menuItem(text = 'Pattern Recognition', tabName = 'pattern',
                                 icon = icon('chart-line')),
        shinydashboard::menuItem(text = 'Cost Optimization', tabName = 'cost',
                                 icon = icon('dollar-sign'))
      ),
      hr(),
      div(style = "padding: 10px;",
          uiOutput('global_date_range'),
          br(),
          div(
            style = "text-align: center;",
            downloadButton(
              outputId = 'download_complete_report',
              label = 'Download All Reports',
              icon = icon('file-excel')
            ),
            tags$small(
              style = "display: block; margin-top: 8px; color: #9ca3af; font-size: 11px;",
              "Excel with all analyses"
            )
          )
      ),
      # Custom CSS for download button
      tags$head(
        tags$style(HTML("
          #download_complete_report {
            width: 100%;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            border: none;
            color: white;
            font-weight: 600;
            font-size: 13px;
            padding: 10px 15px;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
            transition: all 0.2s ease;
            margin-top: 10px;
          }
          #download_complete_report:hover:enabled {
            background: linear-gradient(135deg, #059669 0%, #047857 100%);
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            transform: translateY(-1px);
          }
          #download_complete_report:disabled {
            background: #4b5563;
            opacity: 0.6;
            cursor: not-allowed;
            box-shadow: none;
          }
          #download_complete_report i {
            margin-right: 6px;
          }
        "))
      )
    ),
    body = shinydashboard::dashboardBody(
      shinyjs::useShinyjs(),
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
      ),
      shinydashboard::tabItems(
        shinydashboard::tabItem(
          tabName = 'home', homeUI('home')
        ),
        shinydashboard::tabItem(
          tabName = 'loadData', loadUI('loadData')
        ),
        shinydashboard::tabItem(
          tabName = 'qc', qcUI('qc')
        ),
        shinydashboard::tabItem(
          tabName = 'anomaly', anomalyUI('anomaly')
        ),
        shinydashboard::tabItem(
          tabName = 'pattern', patternUI('pattern')
        ),
        shinydashboard::tabItem(
          tabName = 'cost', costUI('cost')
        )
      )
    )
  )
)