# The pieces of the page that exist only for a reader who is not using a mouse, plus the one
# refusal the build makes about Quarto. Small checks, but each is for something that fails
# silently: nothing about a missing skip link or an unrendered code chunk looks wrong on the
# page.

test_that("the page opens with a skip link that points at a real element", {
  skip_without_content()
  # Read the way a browser will: every prop crosses the React bridge JSON-encoded, so a
  # plain attribute arrives as {"type":"raw","value":...} with its quotes escaped.
  h <- unescaped(slurp(built_site(), "index.html"))
  expect_match(h, "skip-link", fixed = TRUE)
  expect_match(h, '"href":"#main"', fixed = TRUE)
  # A link to an id nothing carries is a link that does nothing, and a keyboard reader is
  # the only person who would ever find out.
  expect_match(h, '"id":{"type":"raw","value":"main"}', fixed = TRUE)
  # <main> has to be focusable or the jump leaves focus on the link and the next Tab goes
  # back into the app bar.
  expect_match(h, '"tabIndex":{"type":"raw","value":-1}', fixed = TRUE)
})

test_that("the skip link is off the canvas rather than out of the tab order", {
  css <- slurp(built_site(), "_mui/site.css")
  rule <- regmatches(css, regexpr("\\.skip-link\\s*\\{[^}]*\\}", css))
  expect_length(rule, 1)
  # display:none would take it out of the tab order and leave the link there in name only.
  expect_false(grepl("display:\\s*none", rule))
  expect_match(rule, "position: absolute", fixed = TRUE)
  expect_match(css, ".skip-link:focus", fixed = TRUE)
})

test_that("every section tab carries the band id the scroll spy matches it against", {
  skip_without_content()
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  h <- unescaped(slurp(built_site(), "index.html"))
  for (s in Filter(function(s) !is.null(s$nav), config$sections)) {
    expect_match(h, paste0('"data-nav":"', s$id, '"'), fixed = TRUE, info = s$id)
  }
  # An off-site entry has no band to be current in, so it carries no id to match - and a
  # null prop is how React is told the attribute is simply not there.
  expect_equal(
    lengths(regmatches(h, gregexpr('"data-nav":null', h, fixed = TRUE)))[[1]],
    length(config$nav_links)
  )
})


test_that("a .qmd in the pages directory is refused rather than published as source", {
  # It used to be read as markdown, which is right up to the first code chunk and then
  # publishes the chunk's source instead of its output - a page that looks fine in the build
  # log and is wrong on the site.
  dir <- file.path(tempdir(), "qmd-refused")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir))
  dir.create(file.path(dir, "pages"), showWarnings = FALSE, recursive = TRUE)
  writeLines(
    c("---", "title: A notebook", "---", "", "```{r}", "1 + 1", "```"),
    file.path(dir, "pages", "notebook.qmd")
  )
  expect_error(
    mui_build_site(out_dir = file.path(dir, "_out"), input = dir, quiet = TRUE),
    "renders markdown, not Quarto"
  )
})
