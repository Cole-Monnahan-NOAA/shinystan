divergentScatterUI <- function(id){
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
                 selected = c(shinystan:::.sso_env$.SHINYSTAN_OBJECT@param_names[1],shinystan:::.sso_env$.SHINYSTAN_OBJECT@param_names[which(shinystan:::.sso_env$.SHINYSTAN_OBJECT@param_names == "log-posterior")]),
                 options = list(maxItems = 2)
               )
               )
        ),
        column(width = 4,
               tags$head(tags$style(HTML("
                                           .shiny-split-layout > div {
                                           overflow: visible;
                                           }
                                           "))), # overflow of splitlayout didn't work, so this is a fix. 
               splitLayout(
                 div(style = "width: 90%;",
                     selectInput(
                       inputId = ns("transformation"),
                       label = h5("Transform X"),
                       choices = transformation_choices,
                       selected = "identity"
                     )),
                 div(style = "width: 90%;",
                     selectInput(
                       inputId = ns("transformation2"),
                       label = h5("Transform Y") ,
                       choices = transformation_choices,
                       selected = "identity"
                     )
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


divergentScatter <- function(input, output, session){
 
  chain <- reactive(input$diagnostic_chain)
  param <- reactive(input$diagnostic_param)
  include <- reactive(input$report)
  
  transform1 <- reactive({input$transformation})
  transform2 <- reactive({input$transformation2})
  
  transform <- reactive({
    validate(
      need(is.null(transform1()) == FALSE, "")
    )
    out <- list(transform1(), transform2())
    names(out) <- c(param())
    out
  })
  
  
  output$diagnostic_chain_text <- renderText({
    if (chain() == 0)
      return("All chains")
    paste("Chain", chain())
  })
  
  
  plotOut <- function(parameters, chain, transformations){
    
    color_scheme_set("darkgray")
    validate(
      need(length(parameters) == 2, "Select two parameters.")
    )
    mcmc_scatter(
      if(chain != 0) {
        shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, chain, ]
      } else {
        shinystan:::.sso_env$.SHINYSTAN_OBJECT@posterior_sample[(1 + shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) : shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_iter, , ]
      },
      pars = parameters,
      transformations = transformations,
      np = if(chain != 0) {
        nuts_params(list(shinystan:::.sso_env$.SHINYSTAN_OBJECT@sampler_params[[chain]]) %>%
                      lapply(., as.data.frame) %>%
                      lapply(., filter, row_number() > shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) %>%
                      lapply(., as.matrix))
      } else {
        nuts_params(shinystan:::.sso_env$.SHINYSTAN_OBJECT@sampler_params %>%
                      lapply(., as.data.frame) %>%
                      lapply(., filter, row_number() > shinystan:::.sso_env$.SHINYSTAN_OBJECT@n_warmup) %>%
                      lapply(., as.matrix)) 
        
      },
      np_style = scatter_style_np(div_color = "green", div_alpha = 0.8)
    ) + labs(#title = "",
      #subtitle = "Generated via ShinyStan",
      caption = paste0("Scatter plot of ", parameters[1]," and ", parameters[2],
                       " with highlighted divergent transitions."))
    
    
  }
  
  output$plot1 <- renderPlot({
    plotOut(parameters = param(), chain = chain(),
            transformations = transform())
  })
  
  
  
  return(reactive({
    if(include() == TRUE){
    plotOut(parameters = param(), chain = chain(),
                           transformations = transform())
    } else {
    NULL
    }
  }))
  
}