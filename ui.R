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
        shinydashboard::menuItem(text = 'Analyse', tabName = 'analyse',
                                 icon = icon('project-diagram'))
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
          tabName = 'analyse', analyseUI('analyse')
        )
      )
    )
  )
)