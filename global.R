
library(shiny)
library(data.table)
library(ggplot2)
# library(shinydashboard)
# library(plotly)
# library(DT)
# library(shinycssloaders)
# library(shinyjs)

source('home.R')
source('loadData.R')
source('analyse.R')


PLANS <- c("Time of Use", "Tiered Rate Plan", "Solar & Renewable Energy Plan",
           "Electric Vehicle Base Plan", "SmartRate Add-on")

TIER <- list(
  "Time of Use" = c("E-TOU-C", "E-TOU-D"),
  "Tiered Rate Plan" = c("T1 (100% baseline)", "T2 (101%-400% baseline)",
                         "T3 (> 400% baseline)"),
  "Electric Vehicle Base Plan" = c('EV2-A', 'EV-B'),
  "Solar & Renewable Energy Plan" = c("COMING-SOON"),
  "SmartRate Add-on" = c("COMING-SOON")
)

HOUR <- list(
  "E-TOU-C" = c(16,21),
  "E-TOU-D" = c(17,20)
)


AGGCHOICE <- c('Day', 'Week','Month', 'Year')
