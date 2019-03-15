tracePlotUI <- function(id){
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
        column(width = 4
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



tracePlot <- function(input, output, session){
    
  chain <- reactive(input$diagnostic_chain)
  param <- reactive(input$diagnostic_param)
  include <- reactive(input$report)
  
  output$diagnostic_chain_text <- renderText({
    if (chain() == 0)
      return("All chains")
    paste("Chain", chain())
  })
  
  plotOut <- function(parameters, chain) {
    color_scheme_set("mix-blue-pink")
    validate(
      need(length(parameters) > 0, "Select at least one parameter.")
    )
    if(shinystan:::.sso_env$.SHINYSTAN_OBJECT@misc$stan_method == "sampling"){
      mcmc_trace( if(chain != 0) {
        shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, chain, ]
      } else {
        shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, , ]
      }, pars = parameters,
      np = if(chain != 0){
        nuts_params(list(shinystan:::.sso_env$.SHINYSTAN_OBJECT@sampler_params[[chain]]) %>%
                      lapply(., as.data.frame) %>%
                      lapply(., filter, row_number() > shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) %>%
                      lapply(., as.matrix))
      } else {
        nuts_params(shinystan:::.sso_env$.SHINYSTAN_OBJECT@sampler_params %>%
                      lapply(., as.data.frame) %>%
                      lapply(., filter, row_number() > shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) %>%
                      lapply(., as.matrix))
      }
      )} else {
        mcmc_trace( if(chain != 0) {
          shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, chain, ]
        } else {
          shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, , ]
        }, pars = parameters) 
      }
    
  }
  
  output$plot1 <- renderPlot({
    plotOut(parameters = param(), chain = chain())
  })
  
  return(reactive({
    if(include() == TRUE){
      plotOut(chain = chain(), parameters = param())
    } else {
      NULL
    }
  }))
  
  
}