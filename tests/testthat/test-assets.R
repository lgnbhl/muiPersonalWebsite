# A content file naming a file that is not in the assets tree builds a page with a button
# that 404s, and every other check passes on the way: the YAML is valid, the URL is well
# formed, and the file is simply not there. This is the one thing that says so.

test_that("a build warns, by name, about an asset the tree does not have", {
  items <- list(work = list(
    list(image = "/assets/there.png",
         primary = list(href = "/assets/gone.pdf"),
         links = list(list(url = "/assets/also-gone.html")))
  ))
  out <- file.path(tempdir(), "assets-verify")
  unlink(out, recursive = TRUE)
  dir.create(file.path(out, "assets"), recursive = TRUE)
  file.create(file.path(out, "assets/there.png"))

  expect_warning(missing <- warn_missing_assets(items, out), "not in the built tree")
  expect_setequal(missing, c("/assets/gone.pdf", "/assets/also-gone.html"))
  # The one that is there is not reported.
  expect_false("/assets/there.png" %in% missing)
})

test_that("a build whose assets are all present warns about nothing", {
  out <- file.path(tempdir(), "assets-ok")
  unlink(out, recursive = TRUE)
  dir.create(file.path(out, "assets"), recursive = TRUE)
  file.create(file.path(out, "assets/there.png"))
  items <- list(work = list(list(image = "/assets/there.png")))
  expect_silent(expect_length(warn_missing_assets(items, out), 0))
})

test_that("only /assets/ is checked - an href elsewhere on the domain is not", {
  # An https:// link is somebody else's server. A protocol-relative "//cdn..." is too,
  # despite starting with a slash. And a site-absolute "/BFS/" is a part of this domain
  # that this build legitimately does not generate - a package's own pkgdown site, say -
  # which mui_asset_url() passes through untouched. Checking those would make the warning
  # fire on every correct site.
  out <- file.path(tempdir(), "assets-offsite")
  unlink(out, recursive = TRUE)
  dir.create(out, recursive = TRUE)
  items <- list(work = list(list(
    image = "https://cdn.example.com/x.png",
    primary = list(href = "//cdn.example.com/y.pdf"),
    secondary = list(href = "/BFS/"),
    links = list(list(url = "/pkg/reference/index.html"))
  )))
  expect_silent(expect_length(warn_missing_assets(items, out), 0))
})
