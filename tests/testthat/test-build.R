# What a real build of the real content produces. These are the checks that cannot be made
# against a function in isolation: they are about the tree on disk.

test_that("the build produces the landing page, the 404 and nothing else", {
  skip_without_content()
  out <- built_site()
  expect_setequal(generated_pages(out), c("404.html", "index.html"))
})

test_that("every page carries complete, non-empty metadata", {
  skip_without_content()
  out <- built_site()
  for (p in generated_pages(out)) {
    h <- slurp(out, p)
    for (tag in c("og:title", "og:image", "og:url", "twitter:card", 'rel="canonical"',
                  "<title>", 'name="description"')) {
      expect_true(grepl(tag, h, fixed = TRUE), info = paste(p, "is missing", tag))
    }
    # An empty value is worse than a missing tag: it looks present but says nothing.
    expect_false(grepl('property="og:title" content=""', h), info = p)
    expect_false(grepl('name="description" content=""', h), info = p)
    expect_false(grepl("<title>\\s*(\\|[^<]*)?</title>", h), info = p)
  }
})

test_that("the home page declares exactly one h1, and <head> says what it is", {
  skip_without_content()
  h <- slurp(built_site(), "index.html")
  # The page is React all the way down, so the heading is a Typography variant in the
  # react-data rather than an <h1> in the source. One of them, still: two h1s is a
  # document-outline bug whether or not a crawler can see it.
  expect_equal(
    lengths(regmatches(h, gregexpr('"variant":"h1"', h, fixed = TRUE))), 1L)
  # Which makes <head> the whole of what a crawler gets. It has to be complete.
  expect_match(h, "<title>[^<]+</title>")
  expect_false(grepl('property="og:title" content=""', h, fixed = TRUE))
})

test_that("the react runtime is shared, not copied next to every page", {
  skip_without_content()
  out <- built_site()
  expect_true(dir.exists(file.path(out, "_mui", "libs")))
  expect_length(list.files(out, pattern = "^mui-material[.]js$", recursive = TRUE), 1)
  # A pre-rendered artefact may legitimately ship its own widget libraries; what must not
  # happen is a second copy of the React/MUI runtime outside _mui/libs.
  dup <- Filter(function(f) !startsWith(f, "_mui/libs/"),
                list.files(out, recursive = TRUE,
                           pattern = "^(mui-material|shiny-react|react|react-dom)[.-].*[.]js$"))
  expect_length(dup, 0)
})

test_that("dependency hrefs are site-absolute", {
  skip_without_content()
  out <- built_site()
  # The tree is served, not opened off disk, so there is no per-page "../" to get wrong.
  for (p in generated_pages(out)) {
    h <- slurp(out, p)
    expect_true(grepl('src="/_mui/libs/', h, fixed = TRUE), info = p)
    expect_false(grepl('src="../', h, fixed = TRUE), info = p)
  }
})

test_that("every band the config declares is on the page, in order", {
  skip_without_content()
  h   <- slurp(built_site(), "index.html")
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  # The bands are rendered by React, so their ids live in the page's react-data rather
  # than in an id= attribute.
  at <- vapply(config$sections, function(s)
    regexpr(sprintf('"id":{"type":"raw","value":"%s"}', s$id), h, fixed = TRUE),
    integer(1))
  expect_false(any(at < 0), info = "a section declared in mui.config.yml has no band")
  expect_false(is.unsorted(at), info = "the bands are not in the configured order")
})

test_that("the published site draws only with variants it has", {
  skip_without_content()
  # Which bands the published site shows is an editorial choice, so it is not held to using
  # every shipped variant - test-variants.R draws each of those on its own. What is checked
  # is that every band names a variant that exists, shipped or the site's own.
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  used <- vapply(config$sections, function(s) s$variant, character(1))
  expect_true(all(used %in% names(site_variants(config))))

  # intro_cards is a band of prose over mui_card_grid(); a wrapper that stopped calling
  # what it wraps would quietly stop drawing the cards.
  site_r <- slurp(site_root(), "variants.R")
  expect_match(site_r, "mui_card_grid", fixed = TRUE)
  expect_match(site_r, "mui_prose", fixed = TRUE)
})

test_that("a section's intro reaches both copies of the page", {
  skip_without_content()
  # The band that has one: words under the heading and above the items, which no shipped
  # variant draws. It has to be in the prerendered copy as well as in the react-data -
  # R/fallback.R's whole claim is that the two cannot disagree about what the site says.
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  intro <- Filter(function(s) !is.null(s$intro), config$sections)
  skip_if(length(intro) == 0, "no section carries an intro")

  h <- slurp(built_site(), "index.html")
  split <- regexpr("react-data", h, fixed = TRUE)
  words <- trimws(strsplit(intro[[1]]$intro, "[[:space:]]+")[[1]])
  phrase <- paste(utils::head(words, 5), collapse = " ")
  expect_match(substr(h, 1, split), phrase, fixed = TRUE)
  expect_match(unescaped(substr(h, split, nchar(h))), phrase, fixed = TRUE)
})

test_that("every nav anchor names a band that exists on the page", {
  skip_without_content()
  # The thing that used to break silently: an anchor pointing at a band that is not there
  # scrolls nowhere and nothing else complains. The tabs are built from the sections now,
  # so this asserts that derivation actually holds in the built page.
  h    <- slurp(built_site(), "index.html")
  config  <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  want <- Filter(Negate(is.null), lapply(nav_items(TRUE, config), function(n) n$anchor))
  expect_gt(length(want), 0)
  for (a in want) {
    expect_true(grepl(sprintf('"id":{"type":"raw","value":"%s"}', a), h, fixed = TRUE),
                info = paste("no band for nav anchor", a))
  }
  # The wordmark's target is a real element on this page.
  expect_match(h, '"id":{"type":"raw","value":"top"}', fixed = TRUE)
})

test_that("the hero's scroll cue lands on a band that exists", {
  skip_without_content()
  # The cue is a real link rather than a script, so a stale target is a click that goes
  # nowhere. It follows the first section, which is what makes a rename safe.
  h   <- slurp(built_site(), "index.html")
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  # The cue is the one element on the page whose label starts "Scroll to"; its href sits
  # immediately before that label in the react-data.
  cue <- regmatches(h, regexpr(
    '"href":[{]"type":"raw","value":"#[^"]+"[}],"aria-label":[{]"type":"raw","value":"Scroll to',
    h))
  expect_length(cue, 1)
  id <- sub('.*"#([^"]+)".*', "\\1", cue)
  expect_equal(id, scroll_cue_section(config)$id)
  expect_true(grepl(sprintf('"id":{"type":"raw","value":"%s"}', id), h, fixed = TRUE))
})

test_that("the chrome every page carries is there", {
  skip_without_content()
  h   <- slurp(built_site(), "index.html")
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  expect_match(h, '"triggerId":{"type":"raw","value":"nav-trigger"}', fixed = TRUE)
  # Counted from the footer on: the hero carries the same profiles above it, and a count
  # over the whole document would see both sets. The footer is the last thing in the shell,
  # so everything after its marker is the footer.
  foot <- substring(h, regexpr('"component":{"type":"raw","value":"footer"}', h,
                               fixed = TRUE))
  expect_equal(lengths(regmatches(foot, gregexpr('"rel":"me noopener"', foot,
                                                 fixed = TRUE))),
               length(config$social))
})

test_that("the honeycomb links every package from the page source", {
  skip_without_content()
  out <- built_site()
  h   <- slurp(out, "index.html")
  expect_match(h, '"className":{"type":"raw","value":"hexgrid"}', fixed = TRUE)
  # One hex per item of the hero section, each pointing at its own pkgdown site. The blanks
  # and the empty slot carry no --i, which is what keeps them out of this count.
  config  <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  hero <- Filter(function(s) identical(s$id, hero_section_id(config)), config$sections)[[1]]
  n    <- length(mui_read_items(file.path(site_root(), hero$data), config))
  cells <- gregexpr(
    paste0('"className":[{]"type":"raw","value":"hex"[}],',
           '"style":[{]"type":"raw","value":[{]"--i":[0-9]+,"--d":[0-9]+[}][}],',
           '"href":[{]"type":"raw","value":"/'),
    h)
  expect_equal(lengths(regmatches(h, cells)), n)
})

test_that("the assets tree is published whole, under one prefix", {
  skip_without_content()
  out <- built_site()
  expect_true(file.exists(file.path(out, "assets/logo-sgtourism.png")))
  # The package's own stylesheet stays out of that prefix, so a site file cannot shadow it.
  expect_true(file.exists(file.path(out, "_mui/site.css")))
  expect_false(file.exists(file.path(out, "assets/site.css")))
})

test_that("a slide deck is copied with the sibling directory it needs", {
  skip_without_content()
  # The decks are the one part of the site left out of the built package - 17MB of
  # reveal.js output that nobody scaffolding a site wants - so this runs at the repo root
  # and skips on a tarball. What it guards is real: presentation_files/ is what a copy
  # that flattened the deck would lose, and the deck would render unstyled without it.
  skip_if_not(has_talk_assets(), "the slide decks are not in this tree")
  out <- built_site()
  expect_true(file.exists(file.path(out, "assets/talks/adminr-zurich/slides.html")))
  expect_true(dir.exists(file.path(out,
    "assets/talks/geneva-r-lunches/presentation_files")))
})

test_that("no page is generated per item", {
  skip_without_content()
  # The home page lists every app, package and talk itself; a page of chrome around one
  # paragraph was more navigation than content.
  expect_setequal(generated_pages(built_site()), c("404.html", "index.html"))
})

test_that("every href an item carries is resolved before it reaches the page", {
  skip_without_content()
  h <- slurp(built_site(), "index.html")
  # A content file names a deck as `talks/<slug>/slides.html`; what ships is the URL the
  # built tree actually serves it at.
  expect_match(h, "/assets/talks/adminr-zurich/slides.html", fixed = TRUE)
  expect_false(grepl('"value":"talks/adminr-zurich/slides.html"', h, fixed = TRUE))
  expect_false(grepl('"value":"slides.html"', h, fixed = TRUE))
})

test_that("the talks band ships as an accordion carrying its abstracts", {
  skip_without_content()
  h <- slurp(built_site(), "index.html")
  expect_match(h, '"name":"Accordion"', fixed = TRUE)
  expect_match(h, '"name":"AccordionDetails"', fixed = TRUE)
})

test_that("the site hand-writes the boot script and the js flag, and no more", {
  skip_without_content()
  # The drawer, the accordion, the tabs and the smooth scroll are React and CSS, with no
  # script of ours behind any of them. What is left is R/boot.R, which does the two things
  # that need the page to already exist: take the prerendered fallback back out, and mark
  # the band the reader is in. Both are in one script, and this is the check that a third
  # thing does not quietly join them.
  #
  # The ld+json block is not an exception. It carries a `script` tag because that is how
  # structured data is embedded, but it is data a crawler reads, never code a browser runs.
  h <- slurp(built_site(), "index.html")
  inline <- regmatches(h, gregexpr("<script(?![^>]*src=)[^>]*>(.*?)</script>", h,
                                   perl = TRUE))[[1]]
  handwritten <- Filter(
    function(s) !grepl("react-data|findAndRenderReactData|application/ld", s),
    inline)
  expect_length(handwritten, 2)
  # The flag first: it sits in <head> because it has to be on <html> before anything
  # paints, which is what keeps the prerendered fallback off the screen. Its partner is
  # the `.js #site-fallback` rule in site.css - the two fail silently in opposite
  # directions on their own, so both are checked.
  expect_match(handwritten[[1]], "documentElement.className", fixed = TRUE)
  expect_match(slurp(built_site(), file.path("_mui", "site.css")),
               ".js #site-fallback", fixed = TRUE)
  expect_match(handwritten[[2]], "site-fallback", fixed = TRUE)
  expect_match(handwritten[[2]], "IntersectionObserver", fixed = TRUE)

  # An article page has no bands, so it carries the fallback half and not the spy.
  a <- slurp(built_site(), "404.html")
  expect_match(a, "site-fallback", fixed = TRUE)
  expect_match(a, "documentElement.className", fixed = TRUE)
  expect_false(grepl("IntersectionObserver", a, fixed = TRUE))
})

test_that("the page's words are in the document, not only in the react blob", {
  skip_without_content()
  # The failure this exists for: every element of every page is a muiMaterial component, so
  # without a prerendered copy the <body> is a JSON blob and the site's words reach nothing
  # that does not run JavaScript - no crawler that skips JS, no reader mode, no text browser.
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  h <- slurp(built_site(), "index.html")
  fallback <- sub(".*<div id=\"site-fallback\">", "", sub("</div>\n<div class=\"react-container\".*", "", h))

  expect_match(fallback, config$hero$name, fixed = TRUE)
  expect_match(fallback, config$hero$lead, fixed = TRUE)
  # One <section> per band, one <article> per item, and every band's heading present.
  for (s in config$sections) expect_match(fallback, paste0("<h2>", s$title, "</h2>"), fixed = TRUE)
  expect_gt(lengths(regmatches(fallback, gregexpr("<article>", fallback)))[[1]], 5)

  # And it carries no ids: the React tree gives every band the id its app bar tab points at,
  # and a document holding each of those twice is one where the anchor is ambiguous.
  expect_false(grepl("id=", fallback, fixed = TRUE))
})

test_that("a band that is words reaches the reader without JavaScript too", {
  skip_without_content()
  # The gap this closes: a `prose` item carries a body and no title, no date and no links -
  # none of the fields a fallback article was built from - so the band whose whole content is
  # words used to reach a crawler as an empty <h3> and nothing else. The <h2> was there, so
  # the check above passed while the words were missing.
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  prose <- Filter(function(s) identical(s$variant, "prose"), config$sections)
  if (!length(prose)) skip("the site has no prose band")
  h <- slurp(built_site(), "index.html")
  fallback <- sub(".*<div id=\"site-fallback\">", "",
                  sub("</div>\n<div class=\"react-container\".*", "", h))
  items <- mui_read_items(file.path(site_root(), prose[[1]]$data))
  first <- strsplit(trimws(items[[1]]$body), "\n")[[1]][1]

  expect_match(fallback, substr(first, 1, 40), fixed = TRUE)
  expect_false(grepl("<h3></h3>", fallback, fixed = TRUE))
  # The markdown is rendered rather than dumped: a body reaches the document as HTML.
  expect_match(fallback, "<p>", fixed = TRUE)
})

test_that("the timeline band is drawn with its rail", {
  skip_without_content()
  # The one thing that tells a timeline from a list on the built page. Asserted against the
  # real site rather than a fixture, since the point is that the site exercises the variant.
  expect_match(slurp(built_site(), "index.html"), "timeline-rail", fixed = TRUE)
})

test_that("prerender: false is the old page, apology and all", {
  skip_without_content()
  out <- file.path(tempdir(), "no-prerender")
  unlink(out, recursive = TRUE)
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  config$prerender <- FALSE
  mui_build_site(out_dir = out, input = site_root(), config = config, quiet = TRUE)

  h <- slurp(out, "index.html")
  expect_false(grepl("site-fallback", h, fixed = TRUE))
  # The noscript notice is the apology for a blank page, so it belongs exactly here and
  # nowhere else - a prerendered page has its words in it and the reader is reading them.
  expect_match(h, "<noscript>", fixed = TRUE)
  expect_false(grepl("<noscript>", slurp(built_site(), "index.html"), fixed = TRUE))
})


test_that("prose typography cannot cascade into the React subtree", {
  skip_without_content()
  # Prose rules that reach MUI's own components repaint them: blue card text, invisible
  # contained-button labels. Anchor rules are the ones that have done it, so every anchor
  # selector has to be scoped to a class that only ever wraps server-rendered HTML.
  # `.wrap` is not one of them: it is the <main> container and holds the React subtree too.
  # The list is short now, and that is the point: everything the theme draws is styled
  # through `sx`, so the only anchors the stylesheet may still reach are the markdown body
  # and the honeycomb, whose geometry stays in CSS.
  # The fallback and the skip link join them: both are plain HTML React never touches, and
  # the fallback is removed the moment it mounts.
  safe <- c("prose", "hexgrid", "hex", "hex-empty", "skip-link", "site-fallback")
  css <- gsub("/\\*.*?\\*/", "", slurp(built_site(), "_mui/site.css"))
  selectors <- trimws(regmatches(css, gregexpr("[^{}]+(?=\\{)", css, perl = TRUE))[[1]])
  targets_a <- grepl("(^|[\\s>+~,])a([\\s:.\\[,]|$)", selectors, perl = TRUE)
  leaky <- Filter(function(s) {
    named <- sub("^[.#]", "",
                 regmatches(s, gregexpr("[.#][A-Za-z][A-Za-z0-9_-]*", s))[[1]])
    !length(named) || !any(named %in% safe)

  }, selectors[targets_a])
  expect_length(leaky, 0)
})

test_that("the static trees, the sitemap and robots are written", {
  skip_without_content()
  out <- built_site()
  for (f in c("sitemap.xml", "robots.txt", "_mui/site.css", "assets/favicon.ico")) {
    expect_true(file.exists(file.path(out, f)), info = f)
  }
  expect_match(slurp(out, "robots.txt"), "Sitemap: https://", fixed = TRUE)
  # The 404 is built, but it is not a page to be indexed.
  expect_false(grepl("404.html", slurp(out, "sitemap.xml"), fixed = TRUE))
})

test_that("a build that still carries the placeholder url says so", {
  dir <- file.path(tempdir(), "placeholder-url")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir))
  expect_warning(
    suppressMessages(mui_build_site(file.path(dir, "docs"), input = dir)),
    "`url` is still https://example.com"
  )
})

test_that("the GitHub Pages files are written from the configuration", {
  skip_without_content()
  out <- built_site()
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  # .nojekyll is not decoration: without it Pages runs the built tree through Jekyll, which
  # drops every path beginning with an underscore or a dot and rewrites the rendered HTML.
  expect_true(file.exists(file.path(out, ".nojekyll")))
  expect_equal(readLines(file.path(out, "CNAME"), warn = FALSE), config$pages$cname)
})

test_that("every icon the configuration names is emitted and present", {
  skip_without_content()
  out <- built_site()
  config <- mui_read_config(file.path(site_root(), "mui.config.yml"))
  h   <- slurp(out, "index.html")
  expect_gt(length(config$icons), 0)
  for (k in names(config$icons)) {
    href <- mui_asset_url(config$icons[[k]], config)
    expect_match(h, sprintf('href="%s"', href), fixed = TRUE)
    expect_true(file.exists(file.path(out, sub("^/", "", href))), info = href)
  }
})

test_that("the applications band ships as a tab list over its screenshots", {
  skip_without_content()
  h <- slurp(built_site(), "index.html")
  # TabContext.static owns which app is showing, so the band needs no server and no script
  # of ours — the claim the "no javascript" check above holds the whole page to.
  expect_match(h, '"name":"MuiStaticTabContext"', fixed = TRUE)
  expect_match(h, '"name":"MuiStaticTabList"', fixed = TRUE)
  expect_match(h, '"name":"TabPanel"', fixed = TRUE)
  # Every app in the content file is a tab, addressed by its slug.
  apps <- mui_read_items(file.path(site_root(), "content/applications.yml"))
  for (app in apps) expect_match(h, paste0('"value":"', app$slug, '"'), fixed = TRUE)
})

test_that("a build copies each dependency once, not once per page", {
  dir <- file.path(tempdir(), "deps-once")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir))
  dir.create(file.path(dir, "pages"))
  for (p in c("one", "two", "three")) {
    writeLines(c("---", paste0("title: ", p), "---", "", "Words."),
               file.path(dir, "pages", paste0(p, ".md")))
  }
  copies <- 0L
  copy <- htmltools::copyDependencyToDir
  local_mocked_bindings(
    copyDependencyToDir = function(...) {
      copies <<- copies + 1L
      copy(...)
    },
    .package = "htmltools"
  )
  suppressWarnings(mui_build_site(out_dir = file.path(dir, "_out"), input = dir, quiet = TRUE))
  deps <- htmltools::renderTags(mui_app_shell(NULL))$dependencies
  # Five pages - the landing page, the 404 and three articles - and one copy per dependency.
  expect_equal(copies, length(deps))
  # Nothing is remembered once the build is over.
  expect_null(muiPersonalWebsite:::the$deps_done)
})
