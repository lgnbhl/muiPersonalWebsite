# The three variants that know nothing about packages, talks or apps. What matters about
# them is exactly that: any content file has to feed any of them, because the moment one
# needs a field of its own it stops being a general variant and becomes a fourth version of
# this author's own site.

sparse_items <- list(
  list(title = "Only a title"),
  list(title = "With words", description = "A sentence."),
  list(
    title = "With everything",
    description = "A sentence.",
    date = "2024-05-01",
    event = "Somewhere",
    location = "Bern",
    primary = list(label = "Read", href = "/read/"),
    secondary = list(label = "Source", href = "https://example.com"),
    links = list(list(name = "Slides", url = "/slides.html"))
  )
)

test_that("every general variant renders an item that carries almost nothing", {
  # A content file written for `cards` has an image and two buttons; one written for a
  # reading list has a title and nothing else. Both have to go through all three.
  for (draw in list(mui_list, mui_timeline, mui_prose)) {
    expect_no_error(as.character(draw(sparse_items)))
    # And an empty section is a band with nothing in it, not an error: a site adds the
    # section before it has anything to put there.
    expect_no_error(as.character(draw(list())))
  }
})

test_that("a row shows what an item has and skips what it does not", {
  out <- as.character(mui_list(sparse_items))
  expect_match(out, "Only a title", fixed = TRUE)
  expect_match(out, "A sentence.", fixed = TRUE)
  # The links out, from both the primary/secondary pair and the `links` list.
  for (href in c("/read/", "https://example.com", "/slides.html")) {
    expect_match(out, href, fixed = TRUE)
  }
  # The dateline parts an item happens to carry.
  expect_match(out, "Somewhere", fixed = TRUE)
  expect_match(out, "Bern", fixed = TRUE)
})

test_that("the timeline pulls the year out and the list does not", {
  # The one difference between the two: a column of years and a rail to hang them on. A
  # column of "01 May 2024" would be a column of noise.
  timeline <- as.character(mui_timeline(sparse_items))
  expect_match(timeline, "2024", fixed = TRUE)
  expect_match(timeline, "timeline-rail", fixed = TRUE)
  expect_false(grepl("timeline-rail", as.character(mui_list(sparse_items)), fixed = TRUE))
})

test_that("prose renders markdown and nothing else", {
  out <- as.character(mui_prose(list(
    list(body = "A **word** and a [link](https://example.org).")
  )))
  expect_match(unescaped(out), "<strong>word</strong>", fixed = TRUE)
  expect_match(unescaped(out), '<a href="https://example.org">link</a>', fixed = TRUE)
  # Inside `.prose`, so a link in a band reads exactly as one in an article page does -
  # and so the stylesheet's anchor rules stay scoped to the one class that may carry them.
  expect_match(out, "prose", fixed = TRUE)

  # An item with only a description is the paragraph it is.
  expect_match(
    unescaped(as.character(mui_prose(list(list(description = "Just words."))))),
    "Just words.",
    fixed = TRUE
  )
})

test_that("a general variant builds a whole band, end to end", {
  # The variants are reachable from YAML alone, which is the claim that matters: a site adds
  # a timeline by naming it, with no R anywhere.
  dir <- file.path(tempdir(), "variant-site")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))

  writeLines(
    c("items:",
      "  - title: A job",
      "    description: What it was.",
      "    date: '2023-04-01'"),
    file.path(dir, "content", "work.yml")
  )
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  config$sections <- c(config$sections, list(list(
    id = "work", kicker = "Where", title = "Work",
    nav = "work", variant = "timeline", data = "content/work.yml"
  )))

  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, config = config, quiet = TRUE)
  h <- slurp(out, "index.html")
  expect_match(h, "A job", fixed = TRUE)
  expect_match(h, "timeline-rail", fixed = TRUE)
  # And the band reaches the prerendered copy too, so a crawler sees it as well.
  expect_match(h, "<h2>Work</h2>", fixed = TRUE)
})

test_that("a site adds a variant by shipping variants.R beside its configuration", {
  # The other half of the extension point: a variant is R, so it cannot be written in YAML -
  # but it can live in the site's own tree rather than in a build script, which is what lets
  # `mui_build_site(input = <site>)` build a site whose sections name it. A variant defined
  # in a build.R nobody ran is a variant the section naming it cannot reach.
  dir <- file.path(tempdir(), "own-variant-site")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))

  writeLines(
    c("items:", "  - title: A thing", "    description: What it is."),
    file.path(dir, "content", "notes.yml")
  )
  writeLines(
    c("variants <- list(",
      "  shouty = function(items, section, config) {",
      "    muiMaterial::Box(",
      "      muiMaterial::Typography(variant = 'body1', toupper(section$intro %||% '')),",
      "      mui_list(items)",
      "    )",
      "  }",
      ")"),
    file.path(dir, "variants.R")
  )

  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  # Read off the configuration's own directory, so the variant is known before the section
  # naming it is validated - which is the only reason this config parses at all.
  expect_true("shouty" %in% names(site_variants(config)))

  config$sections <- c(config$sections, list(list(
    id = "notes", kicker = "Aside", title = "Notes",
    nav = "notes", variant = "shouty", intro = "read this first",
    data = "content/notes.yml"
  )))

  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, config = config, quiet = TRUE)
  h <- slurp(out, "index.html")
  expect_match(h, "READ THIS FIRST", fixed = TRUE)
  expect_match(h, "A thing", fixed = TRUE)
  # `intro` is a key no shipped variant reads, and the fallback carries it for every section
  # regardless - the invariant there is about the words, not about the arrangement.
  expect_match(h, "<h2>Notes</h2><p>read this first</p>", fixed = TRUE)
})

test_that("a site with no variants.R is unchanged, and a malformed one is refused", {
  dir <- file.path(tempdir(), "no-variant-site")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))
  # The blank starter ships none: a site that has not needed a variant of its own should not
  # have to read one to find that out.
  expect_false(file.exists(file.path(dir, "variants.R")))
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  expect_setequal(names(site_variants(config)), names(SECTION_VARIANTS))

  # A file that leaves something other than a list behind is a typo, not a variant, and
  # saying so here beats failing when a band tries to call it.
  writeLines("variants <- 'cards'", file.path(dir, "variants.R"))
  expect_error(
    mui_read_config(file.path(dir, "mui.config.yml")),
    "named list called `variants`",
    fixed = TRUE
  )
})
