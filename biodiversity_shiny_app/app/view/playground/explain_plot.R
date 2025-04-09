box::use(
  ggplot2[ggsave, ],
  shiny[
    showModal, modalDialog, tags, tagAppendAttributes, observeEvent,
    getDefaultReactiveDomain, isolate,
  ],
  shinychat[chat_ui, chat_append, ],
  ellmer[content_image_file, ],
)

plot_to_img_content <- function(p) {
  # Create a temporary file
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp))

  ggsave(tmp, p, width = 800, height = 600, units = "px", dpi = 100)
  content_image_file(tmp, resize = "high")
}

#' @export
explain_plot <- function(chat, p, model, ..., .ctx = NULL, session = getDefaultReactiveDomain()) {
  chat_id <- paste0("explain_plot_", sample.int(1e9, 1))
  img_content <- plot_to_img_content(p())
  img_url <- paste0("data:", img_content@type, ";base64,", img_content@data)

  showModal(
    tagAppendAttributes(
      style = "--bs-modal-margin: 1.75rem;",
      modalDialog(
        tags$button(
          type = "button",
          class = "btn-close d-block ms-auto mb-3",
          `data-bs-dismiss` = "modal",
          aria_label = "Close",
        ),
        tags$img(
          src = img_url,
          style = "max-width: min(100%, 400px);",
          class = "d-block border mx-auto mb-3"
        ),
        chat_ui(session$ns(chat_id), fill = FALSE, height = "300px"),
        size = "l",
        easyClose = TRUE,
        title = NULL,
        footer = NULL,
      )
    )
  )

  session$onFlushed(function() {
    stream <- isolate(chat())$chat_async(
      "Interpret this plot, which is based on the current state of the data (i.e. with filtering applied, if any). Try to make specific observations if you can, but be conservative in drawing firm conclusions and express uncertainty if you can't be confident.",
      img_content
    )
    chat_append(session$ns(chat_id), stream)
  })

  observeEvent(session$input[[paste0(chat_id, "_user_input")]], {
    stream <- chat()$chat_async(session$input[[paste0(chat_id, "_user_input")]])
    chat_append(session$ns(chat_id), stream)
  })
}
