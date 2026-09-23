# Removing what a previous build wrote and this one did not. The risk is the opposite of the
# obvious one: not that a stale page survives, but that a clean deletes something the build
# never owned - a slide deck, a pre-rendered widget, a copy_dirs tree. So every check here is
# as much about what is still standing afterwards.

# A minimal site, written fresh, with `pages` a test can add to and take away from.
clean_site <- function(name, pages = character()) {
  dir <- file.path(tempdir(), name)
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir))
  dir.create(file.path(dir, "pages"), showWarnings = FALSE, recursive = TRUE)
  for (p in pages) {
    writeLines(
      c("---", paste0("title: ", p), "---", "", "Some words."),
      file.path(dir, "pages", paste0(p, ".md"))
    )
  }
  dir
}

test_that("a renamed page does not stay live at its old url", {
  # The failure this exists for: nothing else reports it. The old page is still served, still
  # in nobody's sitemap, and still says whatever it said the day it was renamed.
  dir <- clean_site("clean-rename", "about")
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "about.html")))

  file.rename(
    file.path(dir, "pages", "about.md"),
    file.path(dir, "pages", "colophon.md")
  )
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "colophon.html")))
  expect_false(file.exists(file.path(out, "about.html")))
})

test_that("clean = FALSE leaves the stale page exactly where it was", {
  dir <- clean_site("clean-off", "about")
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  unlink(file.path(dir, "pages", "about.md"))
  mui_build_site(out_dir = out, input = dir, clean = FALSE, quiet = TRUE)
  expect_true(file.exists(file.path(out, "about.html")))
})

test_that("a clean only removes what the build itself wrote", {
  # Read from the manifest rather than by listing the tree, precisely so that an artefact
  # the build does not own is never a candidate. A slide deck copied out of the assets
  # directory is somebody's real page, not a leftover.
  dir <- clean_site("clean-artefacts", "about")
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)

  # Three files the build did not generate, of the three kinds it could mistake for its own.
  writeLines("<html>slides</html>", file.path(out, "slides.html"))
  dir.create(file.path(out, "assets"), showWarnings = FALSE)
  writeLines("<html>widget</html>", file.path(out, "assets", "widget.html"))
  writeLines("hand-written", file.path(out, "hand-written.html"))

  unlink(file.path(dir, "pages", "about.md"))
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)

  expect_false(file.exists(file.path(out, "about.html")))
  for (kept in c("slides.html", "assets/widget.html", "hand-written.html")) {
    expect_true(file.exists(file.path(out, kept)), info = kept)
  }
})

test_that("a manifest naming a path outside the tree deletes nothing", {
  # The manifest is a file on disk and this code deletes things, so it is checked rather
  # than trusted - an edited or hand-written one must not be able to reach out of out_dir.
  dir <- clean_site("clean-escape")
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)

  hostage <- file.path(dir, "do-not-delete.html")
  writeLines("still here", hostage)
  writeLines(
    c("index.html", "../do-not-delete.html"),
    file.path(out, "_mui", "manifest.txt")
  )

  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_true(file.exists(hostage))
})

test_that("the first build of a tree with no manifest cleans nothing", {
  dir <- clean_site("clean-first")
  out <- file.path(dir, "_out")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  writeLines("<html>was here first</html>", file.path(out, "prior.html"))
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "prior.html")))
})
