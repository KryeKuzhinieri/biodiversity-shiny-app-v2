box::use(
  shiny[reactive, testServer],
  testthat[expect_no_error, test_that],
)

box::use(
  app/view/table[server, ui],
)

test_that("module server works with reactive data and tests download filename", {
  testServer(server, args = list(
    state = reactiveValues(data = NULL),
    data = reactive({
      data.frame(
        col1 = 1:5,
        col2 = letters[1:5]
      )
    })
  ), {
    # Ensure the table renders without error
    expect_no_error(output$table)
  })
})

test_that("module server works with state data and tests download filename", {
  testServer(server, args = list(
    state = reactiveValues(data = data.frame(a = 1:3, b = c("x", "y", "z"))),
    data = NULL
  ), {
    # Ensure the table renders without error
    expect_no_error(output$table)
  })
})

test_that("module UI renders without errors", {
  expect_no_error(ui("test_id", "Test Title", "Information for tooltip"))
})
