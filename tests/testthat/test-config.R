test_that("a configuration file is merged over the defaults", {
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  expect_equal(config$title, "A Test Site")
  # Named, so it wins.
  expect_equal(config$theme$palette$primary, "#000fff")
  # Not named, so the default survives the merge rather than being dropped with its
  # siblings — this is the whole point of merging rather than replacing.
  expect_equal(config$theme$palette$background, mui_default_config()$theme$palette$background)
  expect_equal(config$theme$fonts$mono, mui_default_config()$theme$fonts$mono)
})

test_that("a missing configuration file is not an error", {
  # The defaults alone are a valid configuration.
  expect_equal(mui_read_config(tempfile())$title, mui_default_config()$title)
})

test_that("a configuration without a title or a url is refused", {
  expect_error(mui_validate_config(modifyList(mui_default_config(), list(title = ""))),
               "`title` is required")
  expect_error(mui_validate_config(modifyList(mui_default_config(), list(url = ""))),
               "`url` is required")
})

test_that("a trailing slash is trimmed off the site url", {
  # Every URL the build writes pastes a site-absolute path onto this, and that path
  # carries its own leading slash.
  config <- mui_validate_config(modifyList(mui_default_config(), list(url = "https://example.com/")))
  expect_equal(config$url, "https://example.com")
  expect_equal(abs_url("/talks/", config), "https://example.com/talks/")
})

test_that("a nav_links entry that points nowhere is refused", {
  bad <- mui_default_config()
  bad$nav_links <- list(list(text = "orphan"))
  expect_error(mui_validate_config(bad), "needs an href")
})

test_that("a configuration written for the old nav schema is refused, not ignored", {
  # Silently dropping it would build a site with an empty app bar and no complaint.
  bad <- mui_default_config()
  bad[["nav"]] <- list(list(text = "apps", anchor = "applications"))
  expect_error(mui_validate_config(bad), "`nav` is gone")
})

test_that("a section without an id, a data file or a variant is refused", {
  base <- mui_read_config(test_path("fixtures/mui.config.yml"))
  for (k in c("id", "data", "variant")) {
    bad <- base
    bad$sections[[1]][[k]] <- NULL
    expect_error(mui_validate_config(bad), paste0("needs a `", k, "`"))
  }
})

test_that("`columns` has to divide twelve", {
  base <- mui_read_config(test_path("fixtures/mui.config.yml"))
  # mui_card_grid() turns the count into a Grid span by dividing twelve, so a number that
  # does not divide it would floor to a span laying out a different number of cards than
  # the key asked for - silently, and only visible in a browser.
  for (n in c(5, 7, 8)) {
    bad <- base
    bad$sections[[1]]$columns <- n
    expect_error(mui_validate_config(bad), "divide 12")
  }
  for (n in c(2, 3, 4, 6)) {
    ok <- base
    ok$sections[[1]]$columns <- n
    expect_silent(mui_validate_config(ok))
  }
  # The key is optional; a section that says nothing gets mui_card_grid()'s own default.
  expect_silent(mui_validate_config(base))
})

test_that("`pages.nojekyll: false` is refused", {
  # The build writes the stylesheet and the whole React bundle under `_mui/`, and Jekyll
  # drops every underscore path. The combination publishes an unstyled, half-empty site
  # with nothing said, so it is refused rather than left to a deploy to discover.
  bad <- mui_read_config(test_path("fixtures/mui.config.yml"))
  bad$pages$nojekyll <- FALSE
  expect_error(mui_validate_config(bad), "nojekyll")
})

test_that("a section naming a variant that does not exist is refused", {
  bad <- mui_read_config(test_path("fixtures/mui.config.yml"))
  bad$sections[[1]]$variant <- "carousel"
  # The message names the variants there are, so the typo is fixable from the error alone.
  expect_error(mui_validate_config(bad), "cards")
})

test_that("two sections cannot share an id", {
  # The id is the band's anchor, its tab's target and the hero cue's destination at once,
  # so a duplicate would make all three ambiguous.
  bad <- mui_read_config(test_path("fixtures/mui.config.yml"))
  bad$sections[[2]]$id <- bad$sections[[1]]$id
  expect_error(mui_validate_config(bad), "duplicate section id")
})

test_that("only one section can fill the honeycomb", {
  bad <- mui_read_config(test_path("fixtures/mui.config.yml"))
  bad$sections[[2]]$hero <- TRUE
  expect_error(mui_validate_config(bad), "only one section")
})

test_that("a scroll cue pointing at no section is refused", {
  bad <- mui_read_config(test_path("fixtures/mui.config.yml"))
  bad$hero$scroll_to <- "nowhere"
  expect_error(mui_validate_config(bad), "names no section")
})

test_that("the hero section and the scroll cue default to the first section", {
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  # `work` is the one that sets hero: true; it is also first, so both agree here.
  expect_equal(hero_section_id(config), "work")
  expect_equal(scroll_cue_section(config)$id, "work")
  # With no hero: true at all, the first section fills the comb.
  plain <- config
  plain$sections[[1]]$hero <- NULL
  expect_equal(hero_section_id(plain), "work")
  # And the cue follows scroll_to when it is set.
  aimed <- config
  aimed$hero$scroll_to <- "talks"
  expect_equal(scroll_cue_section(mui_validate_config(aimed))$id, "talks")
})

test_that("the app bar is built from the sections, in the order they are laid out", {
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  items <- nav_items(home = TRUE, config)
  # `work` asked for a tab and `talks` did not; the off-site link comes last.
  expect_equal(vapply(items, function(n) n$text, character(1)), c("work", "blog"))
  expect_equal(items[[1]]$anchor, "work")
  # Renaming the section moves its tab with it — nothing else to keep in sync.
  config$sections[[1]]$id <- "projects"
  expect_equal(nav_items(home = TRUE, config)[[1]]$anchor, "projects")
})

test_that("off the landing page the bar drops the section tabs", {
  # A fragment cannot reach a band React has not rendered, so 404 shows the off-site
  # links and the wordmark alone.
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  items <- nav_items(home = FALSE, config)
  expect_equal(vapply(items, function(n) n$text, character(1)), "blog")
})

test_that("an unnamed list in the configuration replaces rather than merging", {
  # nav_links and social are lists of entries, not named settings: naming two entries in
  # mui.config.yml has to give a two-entry bar, not the first two of the default's entries
  # overwritten in place. utils::modifyList() gets this wrong, which is why merge_lists()
  # only recurses into a list that has names.
  base <- list(nav_links = list(list(text = "a"), list(text = "b")))
  out  <- merge_lists(base, list(nav_links = list(list(text = "c"))))
  expect_length(out$nav_links, 1)
  expect_equal(out$nav_links[[1]]$text, "c")
})

test_that("the active configuration is restored after it is swapped", {
  before <- mui_config()
  old <- mui_set_config(modifyList(mui_default_config(), list(title = "Temporary")))
  expect_equal(mui_config()$title, "Temporary")
  mui_set_config(old %||% mui_default_config())
  expect_equal(mui_config()$title, before$title)
})

# A valid minimum, to build the awkward cases out of. Unnamed lists — `sections`, `social`,
# `variants` — are assigned rather than passed through modifyList(), which recurses into a
# list and so quietly leaves an unnamed one alone.
minimal_config <- function(...) {
  config <- modifyList(mui_default_config(), list(title = "X", url = "https://x.example"))
  over <- list(...)
  for (k in names(over)) config[[k]] <- over[[k]]
  config
}

test_that("a site with no sections is refused, but only when one is being built", {
  # The defaults alone stay a valid configuration — that is what lets mui_config() fall back
  # to them outside a build — so this is a strict check rather than a general one.
  config <- minimal_config()
  expect_no_error(mui_validate_config(config))
  expect_error(mui_validate_config(config, strict = TRUE), "`sections` needs at least one entry")
})

test_that("a section naming a content file that is not there is refused before the build", {
  config <- minimal_config(
    sections = list(list(id = "a", title = "A", variant = "cards", data = "nope.yml")))
  expect_error(mui_validate_config(config, strict = TRUE), "content file that is not there")
})

test_that("a hero_social name with no profile behind it is refused", {
  # It used to vanish silently, which left a link simply missing from the hero.
  config <- minimal_config(
    social = list(list(name = "GitHub", href = "https://github.com/x")),
    hero_social = c("GitHub", "Mastodon"))
  expect_error(mui_validate_config(config), "names no profile in `social`: Mastodon")
})

test_that("a variant the configuration adds is a variant a section may name", {
  # The shipped table is a locked namespace binding once the package is installed, so this
  # is the only way a site can add a band of its own.
  # A name the shipped table does not hold, so the check is about `variants` and not about
  # whichever variants this package happens to ship today.
  config <- minimal_config(
    variants = list(gallery = function(items, s, config) NULL),
    sections = list(list(id = "p", title = "P", variant = "gallery", data = "p.yml")))
  expect_no_error(mui_validate_config(config))
  without <- config; without$variants <- list()
  expect_error(mui_validate_config(without), "names variant `gallery`")

  # A variant written into mui.config.yml arrives as a string and would only fail much later,
  # when the band tried to call it.
  as_yaml <- config; as_yaml$variants <- list(gallery = "draw_a_gallery")
  expect_error(mui_validate_config(as_yaml), "must be a function")
})

test_that("the variants that know nothing about this site's sections are shipped", {
  # cards, accordion and showcase were written for packages, talks and apps and carry that
  # shape. These three do not, which is what makes the package a generator rather than one
  # site with a configuration file.
  for (v in c("list", "timeline", "prose")) {
    expect_no_error(mui_validate_config(minimal_config(
      sections = list(list(id = "s", title = "S", variant = v, data = "s.yml")))))
  }
})

test_that("theme.mode is checked, because nothing downstream would notice", {
  # A typo here does not fail anywhere: the site simply never goes dark, silently.
  expect_error(mui_validate_config(minimal_config(
    theme = modifyList(mui_default_config()$theme, list(mode = "system")))),
    "theme.mode")
  for (m in c("auto", "light", "dark")) {
    expect_no_error(mui_validate_config(minimal_config(
      theme = modifyList(mui_default_config()$theme, list(mode = m)))))
  }
})


test_that("the document language follows the locale unless it is named", {
  expect_equal(site_lang(modifyList(mui_default_config(), list(locale = "de_CH"))), "de-CH")
  expect_equal(site_lang(modifyList(mui_default_config(), list(lang = "rm"))), "rm")
})

test_that("showcase is a variant a section may name", {
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  config$sections[[1]]$variant <- "showcase"
  expect_silent(mui_validate_config(config))
})

test_that("a section id has to be usable as an anchor", {
  section <- function(id) list(sections = list(list(id = id, data = "x.yml", variant = "cards")))
  expect_error(mui_validate_config(merge_lists(mui_default_config(), section("my projects"))),
               "section id `my projects`")
  expect_error(mui_validate_config(merge_lists(mui_default_config(), section("1st"))),
               "start with a letter")
  expect_no_error(mui_validate_config(merge_lists(mui_default_config(), section("r-pkgs_2"))))
})

test_that("a nav_links entry needs its label", {
  expect_error(
    mui_validate_config(merge_lists(mui_default_config(),
                                    list(nav_links = list(list(href = "https://a.org"))))),
    "needs a `text`"
  )
})

test_that("a head value written as a YAML sequence is refused rather than crashing", {
  expect_error(meta_tag("twitter:site", c("@a", "@b")), "twitter:site")
  expect_equal(meta_tag("x", NULL), "")
})
