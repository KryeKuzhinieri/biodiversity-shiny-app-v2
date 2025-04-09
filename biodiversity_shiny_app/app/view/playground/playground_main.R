box::use(
  bsicons[bs_icon],
  bslib[
    as_fill_carrier,
    card,
    card_header,
    layout_sidebar,
    nav_panel,
    popover,
    sidebar,
    toggle_popover,
    tooltip
  ],
  DBI[dbGetQuery],
  ellmer[chat_openai, tool, type_string],
  ggplot2[...], # ... means import all functions - needed to allow the ai model to create any
  jsonlite[toJSON],
  promises[`%...>%`],
  shiny[
    actionButton,
    downloadButton,
    downloadHandler,
    isolate,
    moduleServer,
    NS,
    observe,
    observeEvent,
    plotOutput,
    reactive,
    reactiveVal,
    renderPlot,
    renderText,
    tagAppendAttributes,
    tags,
    textOutput,
    verbatimTextOutput
  ],
  shinychat[chat_append, chat_append_message, chat_ui],
  shinycssloaders[withSpinner],
)

box::use(
  app / logic / utils[show_no_data_plot],
  app / view / playground / explain_plot[explain_plot],
  app / view / playground / prompt_helper[df_to_html, system_prompt],
  app / view / table,
)

greeting <- paste(readLines("app/view/playground/greeting.md"), collapse = "\n")

openai_model <- "gpt-4o-mini" # gpt-4o



#' @export
ui <- function(id) {
  ns <- NS(id)
  nav_panel(
    "AI Playground",
    layout_sidebar(
      fill = TRUE,
      sidebar = sidebar(
        width = 450,
        chat_ui(ns("chat"), fill = FALSE, height = "750px")
      ),
      # Headers
      tagAppendAttributes(
        style = "margin-top: -15px;",
        textOutput(ns("show_title"), container = tags$h5)
      ),
      tagAppendAttributes(
        style = "max-height: 100px; overflow: auto; margin-top: -15px;",
        verbatimTextOutput(ns("show_query"))
      ),

      # Plot
      card(
        full_screen = TRUE,
        max_height = 350,
        card_header(
          class = "d-flex justify-content-between align-items-center",
          tags$span(
            "Plot",
            tooltip(
              bs_icon("info-circle"),
              "This plot was generated using AI! Try giving the AI model a prompt ",
              "like `Create a bar chart showing species scientificNames by sex` to see ",
              "what it can do. Feel free to experiment with different queries to ",
              "explore its full capabilities.",
              placement = "bottom"
            )
          ),
          popover(
            id = ns("plot-popover"),
            trigger = bs_icon("gear"),
            title = "Options",
            tagAppendAttributes(
              style = "margin-bottom: 10px;",
              downloadButton(ns("download_graph"), label = "Download Graph")
            ),
            actionButton(
              inputId = ns("interpret_plot"),
              label = tags$div(bs_icon("stars"), "Explain Plot"),
            ),
          ),
        ),
        as_fill_carrier(
          withSpinner(
            plotOutput(ns("plot")),
            color = "#25443B"
          )
        )
      ),

      # Table
      table$ui(
        id = ns("table"),
        card_title = "Current Data",
        tooltip_info = "Data filtered and managed by AI."
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    default_query <- sprintf("SELECT * FROM '%s';", isolate(state$table_name))
    current_title <- reactiveVal("All data")
    current_query <- reactiveVal(default_query)
    current_plot <- reactiveVal(show_no_data_plot(label = "Ask AI for a plot!"))
    system_prompt_str <- system_prompt(
      dbGetQuery(isolate(state$conn), default_query),
      isolate(state$table_name)
    )

    # This object must always be passed as the `.ctx` argument to query(), so that
    # tool functions can access the context they need to do their jobs; in this
    # case, the database connection that query() needs.
    ctx <- reactiveVal(list(conn = isolate(state$conn)))

    chat <- chat_openai(model = openai_model, system_prompt = system_prompt_str)

    # The reactive data frame. Either returns the entire dataset, or filtered by
    # whatever Sidebot decided.
    db_data <- reactive({
      sql <- current_query()
      if (is.null(sql) || sql == "") {
        sql <- default_query
      }
      dbGetQuery(state$conn, sql)
    })

    output$show_title <- renderText({
      current_title()
    })

    output$show_query <- renderText({
      current_query()
    })

    output$plot <- renderPlot(current_plot())

    observeEvent(input$interpret_plot, {
      toggle_popover(id = "plot-popover")
      explain_plot(chat, current_plot, model = openai_model, .ctx = ctx)
    })

    append_output <- function(...) {
      txt <- paste0(...)
      chat_append_message(
        ns("chat"),
        list(role = "assistant", content = txt),
        chunk = TRUE,
        operation = "append",
        session = session
      )
    }

    #' Modifies the data presented in the data dashboard, based on the given SQL
    #' query, and also updates the title.
    #' @param query A DuckDB SQL query; must be a SELECT statement.
    #' @param title A title to display at the top of the data dashboard,
    #'   summarizing the intent of the SQL query.
    update_dashboard <- function(query, title) {
      if (is.null(query) || query == "") {
        print("No query available. Using default query.")
        sql <- default_query
      }
      append_output("\n```sql\n", query, "\n```\n\n")

      tryCatch(
        {
          # Try it to see if it errors; if so, the LLM will see the error
          dbGetQuery(isolate(state$conn), query)
        },
        error = function(err) {
          append_output("> Error: ", conditionMessage(err), "\n\n")
          stop(err)
        }
      )

      if (!is.null(query)) {
        current_query(query)
      }
      if (!is.null(title)) {
        current_title(title)
      }
    }

    #' Perform a SQL query on the data, and return the results as JSON.
    #' @param query A DuckDB SQL query; must be a SELECT statement.
    #' @return The results of the query as a JSON string.
    query <- function(query) {
      # Do this before query, in case it errors
      append_output("\n```sql\n", query, "\n```\n\n")

      tryCatch(
        {
          df <- dbGetQuery(isolate(state$conn), query)
        },
        error = function(e) {
          append_output("> Error: ", conditionMessage(e), "\n\n")
          stop(e)
        }
      )

      tbl_html <- df_to_html(df, maxrows = 5)
      append_output(tbl_html, "\n\n")

      df |> toJSON(auto_unbox = TRUE)
    }

    #' Create a ggplot2 plot on the data.
    #' @param code A string of code showing how to create the plot given instructions.
    #' @return The ggplot2 object.
    plot_data <- function(code) {
      # Do this before query, in case it errors
      append_output("\n```sql\n", code, "\n```\n\n")

      tryCatch(
        {
          p <- eval(parse(text = code))
        },
        error = function(e) {
          append_output("> Error: ", conditionMessage(e), "\n\n")
          stop(e)
        }
      )

      print(p)

      current_plot(p)
    }

    observe({
      # Preload the conversation with the system prompt. These are instructions for
      # the chat model, and must not be shown to the end user.
      chat$register_tool(tool(
        update_dashboard,
        paste0(
          "Modifies the data presented in the data dashboard, based on the given ",
          "SQL query, and also updates the title."
        ),
        query = type_string("A DuckDB SQL query; must be a SELECT statement."),
        title = type_string(
          paste0(
            "A title to display at the top of the data dashboard, ",
            "summarizing the intent of the SQL query."
          )
        )
      ))
      chat$register_tool(tool(
        query,
        "Perform a SQL query on the data, and return the results as JSON.",
        query = type_string("A DuckDB SQL query; must be a SELECT statement.")
      ))
      chat$register_tool(
        tool(
          plot_data,
          "Modifies the plot present in the dashboard, based on the given plot code.",
          code = type_string(
            paste0(
              "An R code command as string to be evaluated ",
              "with eval(parse(text = 'code here'))."
            )
          )
        )
      )
    })


    # Prepopulate the chat UI with a welcome message that appears to be from the
    # chat model (but is actually hard-coded). This is just for the user, not for
    # the chat model to see.
    chat_append(ns("chat"), greeting)

    # Handle user input
    observeEvent(input$chat_user_input, {
      # Add user message to the chat history
      chat_append(ns("chat"), chat$chat_async(input$chat_user_input)) %...>% {
        # print(chat())  # nolint
      }
    })

    table$server(id = "table", data = db_data())
    output$download_graph <- downloadHandler(
      filename = function() {
        "plot.png"
      },
      content = function(file) {
        ggsave(file, current_plot(), bg = "white", width = 10, height = 6)
      }
    )
  })
}
