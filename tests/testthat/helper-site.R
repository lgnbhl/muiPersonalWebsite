# One real build, shared by every check in test-build.R. Building the site is the only way
# to test what the build actually produces, and it is far too slow to repeat per check.
#
# The site is inst/site/ - the tree the package ships and mui_create_site() copies - so
# system.file() finds it under devtools::test() and under R CMD check alike, and these
# checks are the same checks in both. The one thing that does not ship is the slide decks
# under content/assets/talks/ (they are .Rbuildignore'd for size), so a check that reaches
# for a deck asks for it by name rather than assuming it is there.

site_root <- function() system.file("site", package = "muiPersonalWebsite")

has_site_content <- function() {
  root <- site_root()
  nzchar(root) &&
    all(file.exists(file.path(root, c("mui.config.yml", "content", "content/assets"))))
}

# The decks are the part of the site that is left out of the built package.
has_talk_assets <- function() dir.exists(file.path(site_root(), "content/assets/talks"))

skip_without_content <- function() {
  skip_if_not(has_site_content(), "site content is not present")
}

# Built at most once per test run, on the first check that asks for it.
built_site <- local({
  out <- NULL
  function() {
    if (!is.null(out)) return(out)
    dir <- file.path(tempdir(), "site-verify")
    unlink(dir, recursive = TRUE)
    mui_build_site(out_dir = dir, input = site_root(), quiet = TRUE)
    out <<- dir
    dir
  }
})

slurp <- function(...) paste(readLines(file.path(...), warn = FALSE, encoding = "UTF-8"),
                             collapse = "\n")

# The pages this build generated. Copied artefacts — slide decks, pre-rendered widgets —
# are passed through verbatim and are not expected to carry site metadata.
generated_pages <- function(out) readLines(file.path(out, "_mui", "manifest.txt"), warn = FALSE)

# Every value a page carries now crosses the React bridge JSON-encoded into the react-data
# block, so markup inside one reaches the file with its slashes and quotes escaped:
# `</em>` is written `<\/em>`, and an attribute's quotes `\"`. That escaping is what stops a
# value closing the block it sits in — test-escaping.R is about exactly that — but it is not
# a difference the rest of the suite is asking about, so these checks read the page back the
# way a browser will.
unescaped <- function(x) {
  gsub('\\"', '"', gsub("<\\/", "</", x, fixed = TRUE), fixed = TRUE)
}
