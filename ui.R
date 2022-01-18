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
        shinydashboard::menuItem(text = 'Analyse', tabName = 'analyse',
                                 icon = icon('project-diagram'))
      )
    ),
    body = shinydashboard::dashboardBody(
      shinyjs::useShinyjs(),
      shinydashboard::tabItems(
        shinydashboard::tabItem(
          tabName = 'home', homeUI('home')
        ),
        shinydashboard::tabItem(
          tabName = 'loadData', loadUI('loadData')
        ),
        shinydashboard::tabItem(
          tabName = 'analyse', analyseUI('analyse')
        )
      )
    )
  )
)


css <<- "
.chart-wrapper {
  overflow-x: scroll;
}
.shiny-progress .progress-text{
background-color: #FF0000;
}
"