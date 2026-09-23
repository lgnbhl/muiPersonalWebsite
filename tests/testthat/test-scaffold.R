# The reuse path: what somebody else gets. There are two starters and they are checked for
# different things. `blank` is generated from the defaults, so what matters is that it
# stands up at all and that its words are placeholders rather than anybody's. `demo` is this
# package's own site, so what matters is that the tree really does work somewhere else: it
# builds away from this repository, it is not wired to this domain, and the one thing that
# would be actively wrong in a stranger's hands, the analytics id, is gone.

scaffold_dir <- function() file.path(tempdir(), "scaffold-verify")

# Built once per starter, on the first check that asks.
scaffolded <- local({
  out <- list()
  function(starter = "blank") {
    if (!is.null(out[[starter]])) return(out[[starter]])
    dir <- paste0(scaffold_dir(), "-", starter)
    unlink(dir, recursive = TRUE)
    suppressMessages(mui_create_site(dir, starter = starter))
    mui_build_site(out_dir = file.path(dir, "_out"), input = dir, quiet = TRUE)
    out[[starter]] <<- file.path(dir, "_out")
    out[[starter]]
  }
})

source_dir <- function(starter = "blank") paste0(scaffold_dir(), "-", starter)

test_that("either starter builds a whole site somewhere else entirely", {
  # A copy in tempdir(), with none of this repository around it: the check that a scaffold
  # is self-contained and is not quietly reading something at the repo root.
  expect_setequal(generated_pages(scaffolded("blank")), c("index.html", "404.html"))
  skip_without_content()
  expect_setequal(generated_pages(scaffolded("demo")), c("index.html", "404.html"))
})

test_that("the blank starter is nobody's site", {
  # The default, and the reason it is the default: the first thing it asks you to do is
  # write something rather than delete somebody else's name from three files.
  config <- readLines(file.path(source_dir("blank"), "mui.config.yml"), encoding = "UTF-8")
  page <- slurp(scaffolded("blank"), "index.html")
  for (trace in c("Luginb", "felixluginbuhl", "counterdev", "a716cbfd", "lgnbhl")) {
    expect_false(any(grepl(trace, config, fixed = TRUE)), info = trace)
  }
  # The page is held to the same standard bar one thing: the footer's default credit names
  # the tool the site is built with, the way a generator's footer always has. That is
  # attribution for muiMaterial, not the author's identity riding along - and `footer.credit`
  # is a documented key a site can rewrite or empty.
  for (trace in c("Luginb", "felixluginbuhl", "counterdev", "a716cbfd")) {
    expect_false(grepl(trace, page, fixed = TRUE), info = trace)
  }
  credit <- mui_default_config()$footer$credit
  expect_match(page, "muiMaterial", fixed = TRUE)
  expect_equal(lengths(regmatches(page, gregexpr("lgnbhl", page)))[[1]],
               lengths(regmatches(credit, gregexpr("lgnbhl", credit)))[[1]])

  expect_true(any(grepl("^title: Your Name", config)))


  # And it is a site, not a stub: one band per variant it names, each with an item in it.
  parsed <- mui_read_config(file.path(source_dir("blank"), "mui.config.yml"))
  expect_setequal(vapply(parsed$sections, function(s) s$variant, character(1)),
                  c("cards", "list", "prose"))
  for (s in parsed$sections) {
    expect_true(file.exists(file.path(source_dir("blank"), s$data)), info = s$id)
  }
})

test_that("the blank starter is generated from the defaults, not stored beside them", {
  # A second tree under inst/ would be a second site to keep in step with the code - and
  # nobody would build it either, so it would rot exactly the way a stored example does.
  expect_false(dir.exists(system.file("starter-blank", package = "muiPersonalWebsite")))
  # Every key it writes is one the defaults already know about, so an unknown key here is a
  # typo rather than a feature.
  config <- mui_read_config(file.path(source_dir("blank"), "mui.config.yml"))
  expect_no_error(mui_validate_config(config, strict = FALSE))
})

test_that("the analytics id is not in the shipped tree, nor in a copy of it", {
  # Left in, a stranger's traffic - a demo starter's, or anybody building inst/site/ to
  # look at it - would report into this author's counter.dev account: wrong for both of
  # them, and invisible from the page. The id is added at publish time, in build-site.yaml.
  skip_without_content()
  shipped <- readLines(file.path(site_root(), "mui.config.yml"), encoding = "UTF-8")
  expect_false(any(grepl("^counterdev:", shipped)))
  expect_false(any(grepl("a716cbfd", shipped, fixed = TRUE)))
  expect_false(grepl("counter.dev", slurp(built_site(), "index.html"), fixed = TRUE))

  config <- readLines(file.path(source_dir("demo"), "mui.config.yml"), encoding = "UTF-8")
  expect_false(any(grepl("^counterdev:", config)))
  expect_false(grepl("counter.dev", slurp(scaffolded("demo"), "index.html"), fixed = TRUE))
})

test_that("drop_analytics() still takes a counterdev block out of a config", {
  # The safety net for a demo tree that carries one again.
  cfg <- c("title: x", "counterdev:", "  id: abc", "  utcoffset: 2", "", "url: https://x.org")
  out <- drop_analytics(cfg)
  expect_false(any(grepl("^counterdev:|abc", out)))
  expect_true(any(grepl("# counterdev:", out, fixed = TRUE)))
  expect_true("url: https://x.org" %in% out)
})


test_that("the starter is not wired to the domain it came from", {
  # mui_create_site(cname =) is what makes the copy somebody else's: the config it writes has
  # to name their domain, and the built tree has to publish it.
  dir <- file.path(tempdir(), "scaffold-cname")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  expect_equal(config$url, "https://www.example.org")
  expect_equal(config$pages$cname, "www.example.org")

  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_equal(slurp(out, "CNAME"), "www.example.org")
  # Every absolute URL the build writes is pasted onto config$url, so the sitemap is where a
  # domain left behind would show up first.
  expect_false(grepl("felixluginbuhl.com", slurp(out, "sitemap.xml"), fixed = TRUE))
})

test_that("the footer credit is the site's to write, or to leave out", {
  config <- mui_default_config()
  config$title <- "Site Of Someone"; config$url <- "https://x.example"

  config$footer <- list(copyright = "Someone Else", credit = 'made in <a href="https://bern.ch">Bern</a>')
  out <- as.character(mui_footer(config))
  expect_match(out, "&copy; ", fixed = TRUE)
  expect_match(out, "Someone Else", fixed = TRUE)
  expect_match(unescaped(out), '<a href="https://bern.ch">Bern</a>', fixed = TRUE)

  # No credit leaves the copyright notice standing alone, with no dangling separator.
  bare <- config; bare$footer$credit <- NULL
  expect_false(grepl("&middot;", as.character(mui_footer(bare)), fixed = TRUE))
  expect_match(as.character(mui_footer(bare)), "Someone Else", fixed = TRUE)

  # With no `copyright` the notice falls back to the site's own title.
  untitled <- config; untitled$footer$copyright <- NULL
  expect_match(as.character(mui_footer(untitled)), "Site Of Someone", fixed = TRUE)
})

test_that("a markdown page is served off the site root, not off the directory holding it", {
  # Written into the scaffold rather than shipped inside it: the starter is a real site
  # now, and a real site does not carry a page whose text is instructions for deleting it.
  dir <- file.path(tempdir(), "scaffold-pages")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))
  dir.create(file.path(dir, "pages"), showWarnings = FALSE)
  writeLines(c("---", "title: About", "---", "",
               "Hello, with a *word* and a [link](https://example.org)."),
             file.path(dir, "pages", "about.md"))

  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  h <- slurp(out, "about.html")
  # The heading is a Typography under the theme rather than an <h1> in the source.
  expect_match(h, '"variant":"h1"', fixed = TRUE)
  expect_match(h, '"children":"About"', fixed = TRUE)
  expect_match(h, '"class":{"type":"raw","value":"prose"}', fixed = TRUE)
  # A page body is the one place markdown is rendered, so this is where it is checked. It
  # reaches the page as an HTML string the bridge hands to React, not as MUI components.
  expect_match(unescaped(h), "<em>word</em>", fixed = TRUE)
  expect_match(unescaped(h), '<a href="https://example.org">link</a>', fixed = TRUE)
  # Its URL carries no trace of pages_dir, and the sitemap agrees.
  expect_match(slurp(out, "sitemap.xml"),
               "<loc>https://www.example.org/about.html</loc>", fixed = TRUE)
  expect_false(grepl("/pages/", slurp(out, "sitemap.xml"), fixed = TRUE))
})

test_that("the document language follows the configuration into the built page", {
  expect_match(slurp(scaffolded(), "index.html"), '<html lang="en-US">', fixed = TRUE)
})

test_that("the default configuration is read from the site, not from the caller", {
  # mui_build_site(config = NULL) reads `input`'s own mui.config.yml, which is what makes
  # mui_build_site("docs", input = <site>) build that site rather than whatever configuration
  # happens to sit next to the caller. This used to rest on the argument's lazy default being
  # forced after the setwd; it is an explicit read now, and this is what holds it there.
  dir <- file.path(tempdir(), "config-not-the-callers")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.net"))

  wd <- file.path(tempdir(), "a-different-place")
  dir.create(wd, showWarnings = FALSE)
  # A configuration in the caller's directory that names a different site entirely.
  writeLines(c("title: The Caller's Site", "url: https://caller.example"),
             file.path(wd, "mui.config.yml"))
  old <- setwd(wd)
  on.exit(setwd(old), add = TRUE)

  out <- file.path(dir, "_out2")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_match(slurp(out, "sitemap.xml"), "www.example.net", fixed = TRUE)
  expect_false(grepl("caller.example", slurp(out, "sitemap.xml"), fixed = TRUE))
})


test_that("a page that would claim the landing page's URL is refused", {
  # It would be written and then overwritten a moment later: a page that silently is not
  # there. The landing page is assembled from the content files and has no source.
  dir <- file.path(tempdir(), "scaffold-index-clash")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir))
  dir.create(file.path(dir, "pages"), showWarnings = FALSE)
  writeLines(c("---", "title: Home", "---", "", "Hi."), file.path(dir, "pages", "index.md"))
  expect_error(mui_build_site(out_dir = file.path(dir, "_out"), input = dir, quiet = TRUE),
               "would take the landing page's URL")
})

test_that("the default configuration is the site's own, not the caller's", {
  # mui_build_site()'s `config = mui_read_config()` default is forced only after it has moved into
  # `input`, which is what makes `mui_build_site("docs", input = <site>)` read that site's
  # mui.config.yml rather than whatever is next to the caller. Nothing else asserts it, and a
  # `force(config)` added anywhere above that line would break it silently.
  skip_without_content()
  wd <- file.path(tempdir(), "elsewhere")
  dir.create(wd, showWarnings = FALSE)
  old <- setwd(wd)
  on.exit(setwd(old), add = TRUE)

  out <- file.path(tempdir(), "config-origin")
  unlink(out, recursive = TRUE)
  mui_build_site(out_dir = out, input = site_root(), quiet = TRUE)

  want <- mui_read_config(file.path(site_root(), "mui.config.yml"))$title
  expect_match(slurp(out, "index.html"), want, fixed = TRUE)
})

test_that("the demo starter does not credit its cards to the author's handle", {
  skip_without_content()
  config <- readLines(file.path(source_dir("demo"), "mui.config.yml"), encoding = "UTF-8")
  expect_false(any(grepl("^twitter:", config)))
  expect_false(any(grepl("@FelixLuginbuhl", config, fixed = TRUE)))
  expect_true(any(grepl("# twitter:", config, fixed = TRUE)))
  expect_false(grepl("twitter:site", slurp(scaffolded("demo"), "index.html"), fixed = TRUE))
})

test_that("the demo starter given no domain takes the placeholder, not the author's", {
  skip_without_content()
  config <- mui_read_config(file.path(source_dir("demo"), "mui.config.yml"))
  expect_equal(config$url, mui_default_config()$url)
  expect_false(grepl("felixluginbuhl.com", slurp(scaffolded("demo"), "sitemap.xml"),
                     fixed = TRUE))
})
