autoCorrelationUI <- function(id){
  # for internal namespace structure
  ns <- NS(id)
  tagList(
    wellPanel(
      fluidRow(
        column(width = 4, 
               verticalLayout(
                 selectizeInput(
                   inputId = ns("diagnostic_param"),
                   label = h5("Parameter"),
                   multiple = TRUE,
                   choices = shinystan:::.sso_env$.SHINYSTAN_OBJECT@param_names,
                   selected = shinystan:::.sso_env$.SHINYSTAN_OBJECT@param_names[1]
                 )
               )
        ),
        column(width = 4,
               div(style = "width: 100px;",
                   numericInput(
                     ns("diagnostic_lags"),
                     label = h5("Lags"),
                     value = 20,
                     min = 1,
                     max = (shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter - shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup - 2),
                     step = 1
                   )
               )
        ),
        column(width = 4, align = "right",
                 div(style = "width: 100px;",
                     numericInput(
                       ns("diagnostic_chain"),
                       label = h5(textOutput(ns("diagnostic_chain_text"))),
                       value = 0,
                       min = 0,
                       # don't allow changing chains if only 1 chain
                       max = ifelse(shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_chain == 1, 0, shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_chain)
                     )
                 )
        )
      )
    ),
    plotOutput(ns("plot1")),
    hr(), 
    checkboxInput(ns("report"), "Include in report?")
  )
}


autoCorrelation <- function(input, output, session){

  chain <- reactive(input$diagnostic_chain)
  param <- reactive(input$diagnostic_param)
  lags <- reactive(input$diagnostic_lags)
  include <- reactive(input$report)
  
  output$diagnostic_chain_text <- renderText({
    validate(
      need(is.na(chain()) == FALSE, "Select chains")
    )
    if (chain() == 0)
      return("All chains")
    paste("Chain", chain())
  })
  
  # create function to make the plot and call in renderplot and return
  # needed to return plots from module so that we can use them in report.
  plotOut <- function(chain, lags, parameters) {
    color_scheme_set("blue")
    validate(
      need(length(parameters) > 0, "Select at least one parameter."),
      need(is.na(chain) == FALSE, "Select chains"),
      need(is.null(lags) == FALSE & is.na(lags) == FALSE, "Select lags"),
      need(lags > 0 & lags < (shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter - shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup - 1), "Number of lags is inappropriate.")
    )
    mcmc_acf_bar( if(chain != 0) {
      shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, chain, ]
    } else {
      shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, , ]
    }, pars = parameters,
    lags = lags
    )
  }
  
  output$plot1 <- renderPlot({
    plotOut(chain = chain(), lags = lags(), parameters = param())
  })
  
  return(reactive({
    if(include() == TRUE){
      plotOut(chain = chain(), lags = lags(), parameters = param())
    } else {
      NULL
    }
  }))
  
  
}