# The home page: a muiMaterial hero over one muiMaterial band per section. Which bands there
# are is mui.config.yml's business rather than this file's.

# One band per section. Full-bleed comes free from Box being full width, which is why the
# home page's <main> carries no .wrap - see mui_app_shell(bare = TRUE). Every band sits on
# the same ground; `rule = TRUE` is for the first alone, where the hairline closes the hero.
section_band <- function(id, ..., rule = FALSE) {
  Box(
    id = id,
    className = "scroll-anchor",
    sx = list(
      backgroundColor = "background.default",
      borderTop = if (rule) "1px solid" else NULL,
      borderColor = if (rule) "divider" else NULL,
      py = list(xs = 6, md = 9)
    ),
    Container(maxWidth = "lg", ...)
  )
}

# A kicker over the title: two or three words naming the medium, where a sentence of prose
# under the title only restated what the cards already show.
home_section_head <- function(kicker, title) {
  Stack(
    sx = list(mb = 4, alignItems = "center", textAlign = "center"),
    Typography(variant = "kicker", sx = list(color = "kicker", mb = 1), kicker),
    Typography(
      variant = "h2",
      sx = list(fontSize = list(xs = "1.75rem", md = "2.25rem")),
      title
    )
  )
}

# What a section can be rendered as. A band names one of these by key in mui.config.yml,
# which is what keeps the page's shape out of R: the words, the order and the widths are all
# configuration, and only the *kinds* of band live here.
SECTION_VARIANTS <- list(
  # `columns` is the section's own: how wide its cards run is a property of how many it has.
  cards = function(items, s, config) {
    mui_card_grid(items, columns = s$columns %||% 3)
  },
  accordion = function(items, s, config) mui_accordion(items),
  showcase = function(items, s, config) mui_showcase(items),
  # The three that know nothing about packages, talks or apps - see R/mui-list.R.
  list = function(items, s, config) mui_list(items),
  timeline = function(items, s, config) mui_timeline(items),
  prose = function(items, s, config) mui_prose(items)
)


# The variants this site can draw with: the ones above, plus any the configuration adds.
# Config wins on a collision. A site adds one through `variants` rather than by reaching
# into the list above - a namespace is locked once the package is installed.
site_variants <- function(config = mui_config()) {
  modifyList(SECTION_VARIANTS, config$variants %||% list())
}

# A variant of the site's own, read off the site's own tree. mui_read_config() sources
# `variants.R` from beside the configuration it is reading and merges whatever `variants` the
# file leaves behind under the configuration's own - before validating, since validation is
# where a section's `variant` is checked against the variants there are.
#
# A file rather than a line in build.R: `mui_build_site(input = <site>)` has to build *that*
# site, and a variant defined in a build script nobody ran is a variant the section naming it
# cannot reach. The site directory carries everything the section names - which is what lets
# the test suite, a scaffolded copy and `Rscript build.R` all build the same page.
#
# Sourced into an environment of its own, with the package attached behind it, so the file
# may call mui_card_grid() and friends without a library() line and without writing into the
# caller's globals.
SITE_VARIANTS_FILE <- "variants.R"

site_own_variants <- function(path = SITE_VARIANTS_FILE) {
  if (!file.exists(path)) {
    return(list())
  }
  env <- new.env(parent = parent.env(environment()))
  source(path, local = env)
  found <- env$variants %||% list()
  if (!is.list(found)) {
    stop(
      "site: ", path, " must leave a named list called `variants` behind - ",
      "one function(items, section, config) per variant it adds",
      call. = FALSE
    )
  }
  found
}

#' The home page
#'
#' The whole site, bar the 404: a `muiMaterial` hero over one `muiMaterial` band per section.
#'
#' The bands are not named here. Each one is a `sections` entry in `mui.config.yml` - its id,
#' its kicker and title, and the `SECTION_VARIANTS` key that says how to draw it - so the
#' page's shape, order and words are configuration. The id it carries is the same one the
#' app bar anchors at and the hero's scroll cue points to, which is what lets a section be
#' renamed or added without touching R.
#'
#' There is no `ThemeProvider` here: [mui_app_shell()] wraps the whole page in one, so the
#' hero and the bands render under the same theme as the chrome around them.
#'
#' @param items Items by section id.
#' @inheritParams mui_theme
#' @return A tag list.
#' @family home
#' @keywords internal
mui_home_page <- function(items, config = mui_config()) {
  draw <- site_variants(config)
  bands <- lapply(seq_along(config$sections), function(i) {
    s <- config$sections[[i]]
    section_band(
      s$id,
      rule = i == 1L,
      home_section_head(s$kicker, s$title),
      draw[[s$variant]](items[[s$id]] %||% list(), s, config)
    )
  })
  tagList(
    # Not a Container: `.hero-wrap` is a width cap of its own, wider than `.wrap` and
    # narrower than the full-bleed bands. id="top" is the wordmark's target.
    Box(
      id = "top",
      className = "hero-wrap",
      mui_hero(items[[hero_section_id(config)]] %||% list(), config)
    ),
    bands
  )
}
