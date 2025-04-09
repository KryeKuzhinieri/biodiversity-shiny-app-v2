box::use(
  shiny[
    NS, moduleServer, verbatimTextOutput, tagAppendAttributes, actionButton,
    plotOutput, onStop, reactiveVal, textOutput, reactive, renderText,
    renderPlot, observeEvent, tags, isolate, observe, downloadButton,
    downloadHandler,
  ],
  shinychat[chat_ui, chat_append, chat_append_message, ],
  bslib[
    card, card_header, layout_sidebar, sidebar, nav_panel,
    as_fill_carrier, popover, tooltip, toggle_popover,
  ],
  bsicons[bs_icon, ],
  DBI[dbConnect, dbDisconnect, dbGetQuery, ],
  duckdb[duckdb, ],
  DT[DTOutput, renderDT, ],
  # ... means import all functions - needed to allow the ai model to create any
  # type of graph using ggplot2.
  ggplot2[...],
  jsonlite[toJSON, ],
  ellmer[chat_openai, tool, type_string, ],
  promises[`%...>%`, ],
  shinycssloaders[withSpinner, ],
  shinyWidgets[pickerInput, ],
  utils[write.csv2, ],
)

box::use(
  app / view / playground / prompt_helper[system_prompt, df_to_html, ],
  app / view / playground / explain_plot[explain_plot, ],
  app / logic / data_transformation[DB_CHOICES, DB_PATH, ],
  app / logic / utils[show_no_data_plot, ],
)

greeting <- paste(readLines("app/view/playground/greeting.md"), collapse = "\n")

openai_model <- "gpt-4o-mini" # gpt-4o

default_query <- sprintf("SELECT * FROM %s;", "animal_ez")


#' @export
ui <- function(id) {
  ns <- NS(id)
  nav_panel(
    "AI Playground",
    layout_sidebar(
      fill = TRUE,
      sidebar = sidebar(
        width = 450,
        pickerInput(
          inputId = ns("selected_db"),
          label = "Select the database to use",
          choices = DB_CHOICES,
          selected = "animal_ez.duckdb",
          multiple = FALSE,
          options = list("size" = 4)
        ),
        chat_ui(ns("chat"), fill = FALSE, height = "650px")
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
              "like `Create a bar chart showing animals by sex` to see what it can do. ",
              "Feel free to experiment with different queries to explore its full capabilities.",
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
      card(
        full_screen = TRUE,
        max_height = 350,
        card_header(
          class = "d-flex justify-content-between align-items-center",
          tags$span(
            "Data",
            tooltip(
              bs_icon("info-circle"),
              "The dataset below represents the full data used. To filter it using ",
              "the AI model, try queries like `Show only Bovine and Porcine species.`",
              "Feel free to experiment with different queries to explore its full capabilities!",
              placement = "bottom"
            )
          ),
          popover(
            id = ns("data-popover"),
            trigger = bs_icon("gear"),
            title = "Options",
            downloadButton(ns("download_data"), label = "Download Data"),
          ),
        ),
        as_fill_carrier(
          withSpinner(
            DTOutput(ns("table")),
            color = "#25443B"
          )
        )
      ),
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    current_title <- reactiveVal("All data")
    current_query <- reactiveVal(default_query)
    current_plot <- reactiveVal(show_no_data_plot(label = "Ask AI for a plot!"))
    # connect to the database.
    conn <- reactiveVal(
      dbConnect(
        duckdb(),
        dbdir = file.path(DB_PATH, "animal_ez.duckdb"),
        read_only = TRUE
      )
    )
    system_prompt_str <- reactiveVal(
      system_prompt(dbGetQuery(isolate(conn()), default_query), "animal_ez")
    )

    onStop(function() {
      cat("Doing application cleanup!")
      dbDisconnect(isolate(conn()))
    })

    # This object must always be passed as the `.ctx` argument to query(), so that
    # tool functions can access the context they need to do their jobs; in this
    # case, the database connection that query() needs.
    ctx <- reactiveVal(list(conn = isolate(conn())))

    chat <- reactiveVal(
      chat_openai(model = openai_model, system_prompt = isolate(system_prompt_str()))
    )

    # The reactive data frame. Either returns the entire dataset, or filtered by
    # whatever Sidebot decided.
    db_data <- reactive({
      sql <- current_query()
      if (is.null(sql) || sql == "") {
        sql <- default_query
      }
      dbGetQuery(conn(), sql)
    })

    output$show_title <- renderText({
      current_title()
    })

    output$show_query <- renderText({
      current_query()
    })

    output$table <- renderDT(db_data(), fillContainer = TRUE)

    output$plot <- renderPlot(current_plot())

    observeEvent(input$interpret_plot, {
      toggle_popover(id = "plot-popover")
      explain_plot(chat, current_plot, model = openai_model, .ctx = ctx)
    })

    observeEvent(input$selected_db,
      {
        default_query <- sprintf(
          "SELECT * FROM %s;",
          strsplit(input$selected_db, ".", fixed = TRUE)[[1]][1]
        )
        print(default_query)
        dbDisconnect(conn())
        conn(
          dbConnect(
            duckdb(),
            dbdir = file.path(DB_PATH, input$selected_db),
            read_only = TRUE
          )
        )
        system_prompt_str(
          system_prompt(dbGetQuery(conn(), default_query), input$selected_db)
        )
        ctx(list(conn = conn()))
        current_query(default_query)
        current_title(sprintf("All %s data", input$selected_db))
        chat(chat_openai(model = openai_model, system_prompt = system_prompt_str()))
      },
      ignoreInit = TRUE
    )

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
          dbGetQuery(conn(), query)
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
          df <- dbGetQuery(conn(), query)
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
      chat()$register_tool(tool(
        update_dashboard,
        "Modifies the data presented in the data dashboard, based on the given SQL query, and also updates the title.",
        query = type_string("A DuckDB SQL query; must be a SELECT statement."),
        title = type_string("A title to display at the top of the data dashboard, summarizing the intent of the SQL query.")
      ))
      chat()$register_tool(tool(
        query,
        "Perform a SQL query on the data, and return the results as JSON.",
        query = type_string("A DuckDB SQL query; must be a SELECT statement.")
      ))
      chat()$register_tool(
        tool(
          plot_data,
          "Modifies the plot present in the dashboard, based on the given plot code.",
          code = type_string("An R code command as string to be evaluated with eval(parse(text = 'code here')).")
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
      chat_append(ns("chat"), chat()$chat_async(input$chat_user_input)) %...>% {
        # print(chat())
      }
    })

    output$download_graph <- downloadHandler(
      filename = function() {
        "plot.png"
      },
      content = function(file) {
        ggsave(file, current_plot(), bg = "white", width = 10, height = 6)
      }
    )

    output$download_data <- downloadHandler(
      filename = function() {
        "data.csv"
      },
      content = function(file) {
        write.csv2(db_data(), file, row.names = FALSE)
      }
    )
  })
}
