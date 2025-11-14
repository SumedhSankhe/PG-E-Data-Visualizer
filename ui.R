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
          downloadButton(
            outputId = 'download_complete_report',
            label = 'Download All Reports',
            class = 'btn-success btn-block',
            style = 'margin-top: 10px; font-size: 13px;',
            icon = icon('file-excel')
          ),
          tags$small(
            style = "display: block; margin-top: 5px; color: #6c757d; text-align: center;",
            "Excel workbook with all analyses"
          )
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