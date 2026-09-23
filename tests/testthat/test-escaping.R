# Every value the site puts in the page comes out of YAML somebody wrote by hand, and a
# double quote in one of them is not exotic — a title with a quoted phrase, a URL with a
# query string, an ampersand in a company name. The markup has to survive the value rather
# than be broken by it.
#
# What that means changed when the pages became muiMaterial. These values are no longer
# written into HTML attributes; they cross the React bridge as props, JSON-encoded into a
# `<script type="application/json">` block. So the escape that matters is no longer the
# quote that would close an attribute but the `</script>` that would close the block — and
# `shiny.react` writes it `<\/script>` for exactly that reason. These check that it holds
# for every value this package puts on a page, because a break there is script injection
# rather than a cosmetic fault.

# A value carrying every character that has to be escaped somewhere.
NASTY <- 'A "quoted" & <angled> name'
NASTY_URL <- 'https://example.com/a?x=1&y="2"'
# The one that would end the react-data block and start writing markup of its own.
BREAKOUT <- '</script><img src=x onerror="alert(1)">'

# Assigned key by key rather than through modifyList(): modifyList() walks names(), so an
# unnamed list like `social` is silently left at its default. merge_lists() in this package
# guards against exactly that, and is what mui_read_config() uses.
config_with <- function(...) {
  config <- merge_lists(mui_default_config(), list(title = "S", url = "https://s.example"))
  for (k in names(list(...))) config[[k]] <- list(...)[[k]]
  mui_validate_config(config)
}

# The guarantee, stated once: a value that tries to close the block does not close it, and
# is still carried intact as data rather than dropped or mangled.
expect_carries_safely <- function(html, value) {
  expect_false(grepl("</script><img", html, fixed = TRUE))
  expect_match(html, "<\\/script>", fixed = TRUE)
  expect_match(unescaped(html), value, fixed = TRUE)
}

test_that("a social profile's href and name cannot break out of the react data", {
  config <- config_with(
    social = list(list(name = BREAKOUT, href = NASTY_URL)),
    hero_social = BREAKOUT,
    sections = list(list(id = "x", title = "X", variant = "cards", data = "x.yml")),
    hero = list(name = "N")
  )
  # The hero shows the profiles hero_social names; the footer shows every one of them.
  for (html in c(as.character(mui_hero(list(), config)),
                 as.character(mui_footer(config)))) {
    expect_carries_safely(html, BREAKOUT)
    expect_match(unescaped(html), NASTY_URL, fixed = TRUE)
  }
})

test_that("a mui_page_head link's url and a date survive as data, not as markup", {
  html <- as.character(mui_page_head(list(
    title = NASTY, date = '2025-01-01" onload="x',
    links = list(list(name = BREAKOUT, url = NASTY_URL))
  )))
  expect_carries_safely(html, BREAKOUT)
  expect_match(unescaped(html), NASTY_URL, fixed = TRUE)
  # The injected quote stays inside a JSON string; it cannot become an attribute of its own.
  expect_false(grepl('onload="x"', html, fixed = TRUE))
  # A title's angle brackets are data too, and stay readable rather than entity-ised.
  expect_match(html, "<angled> name", fixed = TRUE)
})

test_that("a honeycomb cell's href, src and label cannot break out either", {
  config <- config_with(github_href = BREAKOUT)
  html <- as.character(mui_hex_grid(list(list(
    image = NASTY_URL, slug = NASTY, description = BREAKOUT,
    primary = list(href = NASTY_URL)
  )), config, label = BREAKOUT))
  # aria-label is the one that used to be escaped without attribute = TRUE, so a
  # description carrying a quote closed it and everything after was parsed as markup. It is
  # built from the slug and the description together, which is why both are in it.
  expect_carries_safely(html, paste0(NASTY, ": ", BREAKOUT))
  expect_match(unescaped(html), NASTY_URL, fixed = TRUE)
  # The empty slot's href comes from the configuration and crosses the bridge too.
  expect_match(html, '"hex hex-empty"', fixed = TRUE)
})
