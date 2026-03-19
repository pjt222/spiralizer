test_that("spiralizer_app() returns a shiny.appobj", {
  app <- spiralizer_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("app_ui() returns a valid UI tag", {
  ui <- app_ui()
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
})

test_that("run_spiralizer() accepts valid arguments", {
  # Verify the function exists and accepts port/host args without launching
  expect_true(is.function(run_spiralizer))
  fmls <- formals(run_spiralizer)
  expect_true("port" %in% names(fmls) || "..." %in% names(fmls))
})
