test_that("front matter is split from the body", {
  fm <- mui_split_front_matter(test_path("fixtures/page.md"))
  expect_equal(fm$front$title, "A Talk")
  expect_equal(fm$front$location, "Geneva")
  expect_true(grepl("The body, with a *word* in it.", fm$body, fixed = TRUE))
  # The fence itself never reaches the body.
  expect_false(startsWith(trimws(fm$body), "---"))
})

test_that("a file with no front matter is all body", {
  fm <- mui_split_front_matter(test_path("fixtures/bare.md"))
  expect_equal(fm$front, list())
  expect_equal(trimws(fm$body), "No front matter here.")
})

test_that("an unterminated fence is an error, not a silent half-read", {
  expect_error(mui_split_front_matter(test_path("fixtures/unterminated.md")),
               "Unterminated YAML front matter")
})

test_that("source paths map to output paths and URLs", {
  # An index becomes its folder's URL; anything else keeps its own name.
  expect_equal(page_paths("talks/adminr-zurich/index.md"),
               list(out = "talks/adminr-zurich/index.html", url = "/talks/adminr-zurich/"))
  expect_equal(page_paths("index.qmd"), list(out = "index.html", url = "/"))
  expect_equal(page_paths("404.qmd"), list(out = "404.html", url = "/404.html"))
  # Windows separators resolve to the same URL as POSIX ones.
  win <- paste("talks", "adminr-zurich", "index.md", sep = "\\")
  expect_equal(page_paths(win)$url, "/talks/adminr-zurich/")
})

test_that("a page carries where it came from and where it is going", {
  p <- mui_read_page(test_path("fixtures/page.md"), root = test_path("fixtures"))
  expect_equal(p$rel, "page.md")
  expect_equal(p$out, "page.html")
  expect_equal(p$title, "A Talk")
  expect_equal(p$links[[1]]$name, "Slides")
})

test_that("a section's defaults are merged under every item", {
  items <- mui_read_items(test_path("fixtures/content/work.yml"))
  # Named on the item, so it wins; not named, so the default reaches it.
  expect_equal(items[[1]]$secondary$label, "Elsewhere")
  expect_equal(items[[2]]$secondary$label, "Source")
  expect_equal(items[[1]]$fit, "contain")
})

test_that("{slug} is expanded throughout an item, not just at the top level", {
  items <- mui_read_items(test_path("fixtures/content/work.yml"))
  beta <- items[[1]]
  # This is what lets a section state "docs at /<slug>/, source at github/<me>/<slug>"
  # once instead of writing two URLs per project.
  expect_equal(beta$primary$href, "/beta/")
  expect_equal(items[[2]]$secondary$href, "https://github.com/example/alpha")
})

test_that("items come back newest first", {
  items <- mui_read_items(test_path("fixtures/content/work.yml"))
  expect_equal(vapply(items, function(i) i$title, character(1)), c("Beta", "Alpha"))
})

test_that("a content file may be a bare list of items", {
  # A section with no conventions to state needs no `defaults:` block, and so needs no
  # `items:` key to hang them off either.
  items <- mui_read_items(test_path("fixtures/content/bare.yml"))
  expect_length(items, 1)
  expect_equal(items[[1]]$slug, "solo")
})

test_that("a missing content file is an error, not an empty section", {
  # A typo in `data:` would otherwise build a band with nothing in it and say nothing.
  expect_error(mui_read_items(test_path("fixtures/content/nope.yml")), "content file not found")
})

test_that("an item's hrefs are resolved against the assets tree", {
  items <- mui_read_items(test_path("fixtures/content/talks.yml"))
  expect_equal(items[[1]]$links[[1]]$url, "/assets/talks/a-talk/slides.html")
  # A link that pointed nowhere is dropped rather than rendered as a dead button.
  expect_length(items[[1]]$links, 1)
})

test_that("asset hrefs resolve against the assets tree", {
  expect_equal(mui_asset_url("BFS-logo.png"), "/assets/BFS-logo.png")
  expect_equal(mui_asset_url("talks/x/slides.html"), "/assets/talks/x/slides.html")
  # Absolute and protocol-relative hrefs are somewhere else entirely.
  expect_equal(mui_asset_url("/pkg/index.html"), "/pkg/index.html")
  expect_equal(mui_asset_url("https://example.com/x"), "https://example.com/x")
  expect_equal(mui_asset_url("//cdn.example.com/x"), "//cdn.example.com/x")
  expect_null(mui_asset_url(""))
  expect_null(mui_asset_url(NULL))
})

test_that("an absolute image is left alone while a bare filename is resolved", {
  items <- mui_read_items(test_path("fixtures/content/work.yml"))
  expect_equal(items[[1]]$image, "https://cdn.example.com/beta.png")
  expect_equal(items[[2]]$image, "/assets/alpha-logo.png")
})

test_that("a showcase item's screenshots resolve against the assets tree", {
  items <- mui_read_items(test_path("fixtures/content/work.yml"))
  alpha <- Filter(function(it) identical(it$slug, "alpha"), items)[[1]]
  # {slug} expands inside a shot path the way it does in every other string, so a whole
  # app's screenshots can be named once as a folder.
  expect_equal(alpha$shots[[1]]$src, "/assets/apps/alpha/one.png")
  expect_equal(alpha$shots[[1]]$caption, "The first")
  # Somewhere else entirely, left alone.
  expect_equal(alpha$shots[[2]]$src, "https://cdn.example.com/two.png")
  # A shot that names no file points nowhere and is dropped, the way an empty link url is.
  expect_length(alpha$shots, 2)
})

test_that("every card in a grid has a key, and no two share one", {
  items <- list(
    list(title = "No links"),
    list(title = "Same link", primary = list(label = "Go", href = "/x/")),
    list(title = "Same link", primary = list(label = "Go", href = "/x/"))
  )
  html <- as.character(mui_card_grid(items))
  # The grid cells are the siblings React compares; each card inside one is an only child.
  cell <- '"key":\\{"type":"raw","value":"([0-9]+-[^"]*)"\\},"size"'
  keys <- sub(cell, "\\1", regmatches(html, gregexpr(cell, html))[[1]])
  expect_length(keys, 3)
  expect_false(anyDuplicated(keys) > 0)
  expect_true(all(nzchar(keys)))
})

test_that("a date that is not a whole YYYY-MM-DD is refused, naming where it is", {
  items_file <- function(date_line) {
    f <- tempfile(fileext = ".yml")
    writeLines(c("items:", "  - title: A talk", paste0("    ", date_line)), f)
    f
  }
  # YAML reads a bare year as an integer, which as.Date() would turn into 1975.
  f <- items_file("date: 2023")
  expect_error(mui_read_items(f, mui_default_config()), "A talk.*'2023-01-01'")
  expect_error(mui_read_items(f, mui_default_config()), basename(f), fixed = TRUE)
  expect_error(mui_read_items(items_file("date: '2024-03'"), mui_default_config()),
               "YYYY-MM-DD")
  expect_error(mui_read_items(items_file("date: '2024-02-30'"), mui_default_config()),
               "YYYY-MM-DD")

  expect_equal(mui_read_items(items_file("date: 2024-03-01"), mui_default_config())[[1]]$date,
               "2024-03-01")
  expect_equal(iso_date(as.Date("2024-03-01"), "x"), "2024-03-01")
  expect_null(iso_date(NULL, "x"))
})

test_that("a page's front-matter date is checked the same way", {
  f <- tempfile(fileext = ".md")
  writeLines(c("---", "title: T", "date: 2023", "---", "Body."), f)
  expect_error(mui_read_page(f, root = dirname(f)), "YYYY-MM-DD")
  expect_equal(mui_read_page(test_path("fixtures/page.md"), root = test_path("fixtures"))$date,
               "2025-04-01")
})

test_that("a showcase item with neither slug nor title is refused", {
  expect_error(mui_showcase(list(list(description = "x"))), "`slug` or a `title`")
  expect_no_error(mui_showcase(list(list(title = "An app"))))
})
