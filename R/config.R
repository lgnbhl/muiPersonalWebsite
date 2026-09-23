# The site's configuration: everything about *this* site that the code around it does not
# need to know. The functions in this package build a site; mui.config.yml says which one.
#
# The active configuration lives in an internal environment rather than being threaded
# through every function, but every function that reads it still takes `config` explicitly,
# so a test can hand one in without touching global state.

the <- new.env(parent = emptyenv())

#' Default site configuration
#'
#' The values [mui_read_config()] falls back to for any key `mui.config.yml` does not name.
#' The palette and fonts live here because they are the site's design, not its content: a
#' colour is changed by naming it in `mui.config.yml`, not by editing R.
#'
#' @return A named list.
#' @export
mui_default_config <- function() {
  list(
    title = "A site",
    # The masthead, when it is written differently from the title - lowercase, say.
    wordmark = NULL,
    url = "https://example.com",
    description = "",
    twitter = NULL,
    locale = "en_US",
    # <html lang>. Left unset it follows the locale; name it only when that is wrong.
    lang = NULL,
    default_image = NULL,
    counterdev = NULL,
    # The feed <head> advertises. A URL points at one the site does not own - writing that
    # lives on Substack, say. `feed: true` builds one instead, at /feed.xml, from the dated
    # pages under `pages_dir`; see mui_feed_xml().
    feed = NULL,
    # Write a plain-HTML copy of the landing page's content into the document, ahead of the
    # React tree that replaces it on mount. Without this the <body> is a JSON blob and the
    # site's words reach nothing that does not run JavaScript. See R/fallback.R.
    prerender = TRUE,
    # Replace lodash inside the copied shiny.react bundle with the two functions the bundle
    # actually imports from it - about 470 KB of the 1.4 MB a reader downloads. Checked
    # against the bundle in front of it and skipped if anything does not match; see
    # R/payload.R.
    trim_payload = TRUE,

    # The Person block the landing page carries for search engines. `jsonld: false` drops it.
    jsonld = TRUE,
    # The site's own files - logos, screenshots, favicons, slide decks - copied verbatim into
    # <out>/assets and published at /assets/, so a content file names a file and nothing more.
    assets_dir = "content/assets",
    # The site's own markdown pages. Their URLs are relative to this directory rather than to
    # the site root, so pages/about.md is served at /about.html.
    pages_dir = "pages",
    # Directories copied into the output verbatim, keeping their own name at the site root: a
    # tree this build does not own that a clean rebuild would otherwise drop.
    copy_dirs = character(),
    # The bands the home page lays out, in order: one content file plus the words around it.
    # See mui_validate_config() for the keys and SECTION_VARIANTS in page-home.R for the
    # variants. This is the site's single source of truth for its sections - the band's id
    # and scroll anchor, the app bar's tab and the hero cue's target all come from here.
    sections = list(),
    # Off-site entries appended to the app bar after the section tabs.
    nav_links = list(),
    # Section variants of the site's own, taking precedence over the ones this package ships.
    # Each is function(items, section, config) returning a muiMaterial component. This is R
    # rather than YAML, so it is set on the configuration object rather than in the file.
    variants = list(),
    # Icons for <head>: favicon, apple_touch, png_32, png_16, manifest. Each optional, each
    # resolved against the assets tree, and only the ones named are emitted.
    icons = list(),
    # GitHub Pages plumbing. `cname` is the custom domain; without one the site is served
    # from <user>.github.io and needs no CNAME at all.
    pages = list(cname = NULL, nojekyll = TRUE),
    social = list(),
    # What a reader with JavaScript switched off is told. Only reached when
    # `prerender: false`, because a prerendered page needs no apology: its words are in the
    # document. One sentence, rendered from <head>; `noscript: ~` leaves it out.
    noscript = paste(
      "This site needs JavaScript to display.",
      "Please enable it, or read the source at the repository linked from the page title."
    ),
    # Which of `social` the hero shows, by name. The footer always shows all of them.
    hero_social = character(),
    # The hero's own words: greeting, name, role, lead.
    hero = list(),
    # Where the honeycomb's empty slot points - what it promises is more packages.
    github_href = NULL,
    # The line under the profiles. `copyright` is the name in the notice; `credit` is the
    # HTML sentence after it, written raw, and `credit: ~` leaves the notice standing alone.
    footer = list(
      copyright = NULL,
      credit = 'built with R and <a href="https://github.com/lgnbhl/muiMaterial">muiMaterial</a>'
    ),
    theme = list(
      # "auto" follows the reader's system setting, through `prefers-color-scheme` alone -
      # there is no toggle and so no script and no stored preference. "light" or "dark"
      # pins the site to one scheme and emits only that palette.
      mode = "auto",
      fonts = list(
        sans = "system-ui, -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif",
        serif = "Georgia, 'Times New Roman', serif",
        mono = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
      ),
      # Loaded in <head> before anything paints. Empty when the fonts above are all local.
      font_head = "",
      # The one definition of the site's colours: mui_theme() feeds the MUI half from it, and
      # mui_css_root_vars() emits the same values as custom properties for the CSS half. The
      # keys are roles, not colours - `primary` is whatever the site's interactive colour is,
      # not "indigo" - so a site can repoint them and every name here stays true.
      palette = list(
        background = "#FAF6F1",
        # The raised surface: cards, the app bar's ground, a logo's mat.
        paper = "#FFFFFF",
        ink_strong = "#1C1917",
        text_primary = "#3D3229",
        text_secondary = "#6B5D4D",
        text_on_dark = "#E8E2DC", # prose code blocks, the one dark surface
        # The code block's ground. `ink_strong` would do it in the light scheme and is
        # exactly wrong in the dark one, where the strongest ink is nearly white.
        code_bg = "#1C1917",
        # The hero's profile pills and scroll cue: a translucent mat over the ground.
        pill = "rgba(255,255,255,0.55)",

        # The interactive colour: buttons, links, focus rings, the card hover border.
        primary = "#4f46e5",
        primary_dark = "#3730a3",
        primary_light = "#818cf8",
        # The label colour: every kicker and dateline. Dark enough to be read as text on the
        # ground rather than seen as a tint.
        accent = "#8B5A2B",
        # `ink_strong` as rgb, for the hairlines and shadows that need an alpha channel.
        ink_rgb = "28,25,23"
      ),
      # Merged *over* `palette`, so a dark scheme only has to name what differs. The keys
      # are the same roles: `ink_rgb` is still "the colour hairlines are drawn in", which on
      # a dark ground is a light one - that is the whole reason the palette names roles
      # rather than hues.
      #
      # The two indigos are not the light scheme's: #4f46e5 on #14120F is under 3:1, so the
      # interactive colour lightens to keep its contrast rather than keeping its hue exact.
      palette_dark = list(
        background = "#14120F",
        paper = "#1C1917",
        ink_strong = "#F5F1EC",
        text_primary = "#E8E2DC",
        text_secondary = "#AFA294",
        primary = "#a5b4fc",
        primary_dark = "#818cf8",
        primary_light = "#c7d2fe",
        accent = "#D9B68C",
        code_bg = "#26221E",
        pill = "rgba(232,226,220,0.06)",
        ink_rgb = "232,226,220"
      )
    )
  )
}


#' Read a site configuration
#'
#' Reads `mui.config.yml` and merges it over [mui_default_config()]. Keys the file does not
#' name keep their default, so a configuration only has to say what is particular to it.
#'
#' The file is `mui.config.yml` and not `_site.yml`, because rmarkdown defines a directory
#' holding `_site.yml` to be an R Markdown website and would try to render this one.
#'
#' `url` is the address the site is served at, and its path is the site's base path: a
#' site served at the root of a domain names the domain alone, and a GitHub Pages project
#' site names `https://<user>.github.io/<repo>`, which prefixes every URL the build writes
#' with `/<repo>`. An href a content file writes starting with `/` is a path on the host and
#' is not prefixed; name an asset by its filename to have it resolved under the base path.
#'
#' # Security
#'
#' If a `variants.R` file sits beside the configuration, reading it **runs that file**: it
#' is `source()`d so the section variants it defines can be named in the YAML. Read and
#' build only sites whose files you trust, exactly as you would only `source()` a script you
#' trust. [mui_build_site()] reads the configuration the same way.
#'
#' @param path Path to the YAML configuration file. A missing file is not an error: the
#'   defaults alone are a valid configuration.
#' @return A named list, validated by [mui_validate_config()].
#' @export
#' @examples
#' config <- mui_read_config(system.file("site", "mui.config.yml", package = "muiPersonalWebsite"))
#' config$title
mui_read_config <- function(path = "mui.config.yml") {
  over <- if (file.exists(path)) {
    yaml::yaml.load_file(path) %||% list()
  } else {
    list()
  }
  config <- merge_lists(mui_default_config(), over)
  # Before validating, because validation is where a section's `variant` is checked against
  # the variants there are - and a variant the site defines beside this file is one of them.
  # Read from the configuration's own directory rather than the working one, so
  # mui_read_config("<site>/mui.config.yml") sees the same variants a build of <site> does.
  config$variants <- modifyList(
    site_own_variants(file.path(dirname(path), SITE_VARIANTS_FILE)),
    config$variants %||% list()
  )
  mui_validate_config(config)
}

#' @rdname mui_read_config
#' @param config A configuration list.
#' @param strict Also make the checks only a build can make: that there is at least one
#'   section, and that every section's content file exists. Off by default, because
#'   [mui_default_config()] alone is a valid configuration but is not yet a site.
#' @export
mui_validate_config <- function(config, strict = FALSE) {
  for (k in c("title", "url")) {
    if (!nzchar(config[[k]] %||% "")) {
      stop("site config: `", k, "` is required", call. = FALSE)
    }
  }
  # Every URL the build writes pastes a site-absolute path onto this, so a trailing slash
  # would double the one the path already carries.
  config$url <- sub("/$", "", config$url)
  # The site's base path is read off `url` (see site_base()), so a url without a scheme
  # would have its host taken for a path and every asset and script prefixed with it.
  if (!grepl("^https?://[^/?#]+(/[^?#]*)?$", config$url)) {
    stop(
      "site config: `url` is ",
      config$url,
      "; it has to be the address the site is served at, such as https://example.com or ",
      "https://user.github.io/repo",
      call. = FALSE
    )
  }

  # An error rather than a silent ignore: a config written for the old schema would
  # otherwise build a site with an empty app bar and no complaint. [[ ]] rather than $,
  # because $ on a list partial-matches and config$nav would resolve to config$nav_links.
  if (!is.null(config[["nav"]])) {
    stop(
      "site config: `nav` is gone. Give each section a `nav:` label for its tab, and ",
      "put off-site entries under `nav_links:`.",
      call. = FALSE
    )
  }

  # Mistyping this would not fail anywhere: mui_theme() would fall through to a light
  # palette and the site would simply never go dark, with nothing said.
  mode <- config$theme$mode %||% "auto"
  if (!identical(length(mode), 1L) || !mode %in% c("auto", "light", "dark")) {
    stop(
      "site config: `theme.mode` is ",
      paste(mode, collapse = ", "),
      "; it has to be auto, light or dark",
      call. = FALSE
    )
  }

  # A variant is R, so it cannot come from YAML - and a string written there would only
  # fail much later, when the band tried to call it.

  for (nm in names(config$variants %||% list())) {
    if (!is.function(config$variants[[nm]])) {
      stop(
        "site config: variant `",
        nm,
        "` must be a function(items, section, config). ",
        "Variants are R, so they are set on the configuration object rather than in ",
        "mui.config.yml.",
        call. = FALSE
      )
    }
  }

  ids <- character()
  for (s in config$sections) {
    where <- s$id %||% s$title %||% "?"
    for (k in c("id", "data", "variant")) {
      if (!nzchar(s[[k]] %||% "")) {
        stop(
          "site config: section `",
          where,
          "` needs a `",
          k,
          "`",
          call. = FALSE
        )
      }
    }
    # The id is written into href="#<id>" three times over - the tab, the scroll cue, the
    # spy - and a space or a `#` in it breaks all three without a word.
    if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", s$id)) {
      stop(
        "site config: section id `",
        s$id,
        "` has to start with a letter and hold only letters, digits, - and _, ",
        "since it is the band's anchor",
        call. = FALSE
      )
    }
    known <- names(site_variants(config))
    if (!s$variant %in% known) {
      stop(
        "site config: section `",
        where,
        "` names variant `",
        s$variant,
        "`; the variants ",
        "are ",
        paste(known, collapse = ", "),
        call. = FALSE
      )
    }
    # mui_card_grid() turns `columns` into a Grid span by dividing twelve; a number that
    # does not divide twelve would floor to a span laying out a different number of cards.
    if (!is.null(s$columns) && !s$columns %in% c(2L, 3L, 4L, 6L)) {
      stop(
        "site config: section `",
        where,
        "` sets `columns: ",
        s$columns,
        "`; it has to divide 12 - 2, 3, 4 or 6",
        call. = FALSE
      )
    }
    ids <- c(ids, s$id)
  }
  # Two bands with one id would make the anchor - and so the tab and the cue - ambiguous.
  if (anyDuplicated(ids)) {
    stop(
      "site config: duplicate section id `",
      ids[anyDuplicated(ids)],
      "`",
      call. = FALSE
    )
  }
  if (
    sum(vapply(config$sections, function(s) isTRUE(s$hero), logical(1))) > 1L
  ) {
    stop("site config: only one section can set `hero: true`", call. = FALSE)
  }
  if (!is.null(config$hero$scroll_to) && !config$hero$scroll_to %in% ids) {
    stop(
      "site config: `hero.scroll_to` names no section: ",
      config$hero$scroll_to,
      call. = FALSE
    )
  }

  # A profile the hero is told to show but that `social` never names would simply be missing
  # from the page with nothing said - the same class of mistake as a `scroll_to` pointing
  # nowhere, so it is caught the same way.
  known <- vapply(config$social, function(s) s$name %||% "", character(1))
  unknown <- setdiff(config$hero_social %||% character(), known)
  if (length(unknown)) {
    stop(
      "site config: `hero_social` names no profile in `social`: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  for (n in config$nav_links) {
    if (!nzchar(n$text %||% "")) {
      stop(
        "site config: nav_links entry `",
        n$href %||% "?",
        "` needs a `text` - it is the tab's label",
        call. = FALSE
      )
    }
    if (!nzchar(n$href %||% "")) {
      stop(
        "site config: nav_links entry `",
        n$text %||% "?",
        "` needs an href",
        call. = FALSE
      )
    }
  }

  # The build writes its own files under `_mui/`, and Jekyll drops every path beginning with
  # an underscore - which would take the stylesheet and the whole React bundle with it. The
  # site would publish looking unstyled and half-empty, so refuse the combination outright.
  if (identical(config$pages$nojekyll, FALSE)) {
    stop(
      "site config: `pages.nojekyll: false` cannot work - the build writes to `_mui/`, ",
      "and Jekyll drops every path beginning with an underscore, which would take the ",
      "stylesheet and the React bundle with it.",
      call. = FALSE
    )
  }

  # Checks only a build can make. The defaults alone are a valid configuration - that is
  # what lets mui_config() fall back to them outside a build - but they are not a site.
  if (strict) {
    if (!length(config$sections)) {
      stop(
        "site config: `sections` needs at least one entry - the landing page is its ",
        "bands, and a site with none is a hero over nothing",
        call. = FALSE
      )
    }
    for (s in config$sections) {
      if (!file.exists(s$data)) {
        stop(
          "site config: section `",
          s$id,
          "` names a content file that is not there: ",
          s$data,
          call. = FALSE
        )
      }
    }
  }
  config
}

# The section a predicate picks, falling back to the first one - so a configuration that
# says nothing still works, and an empty `sections` gives NULL rather than a subscript error.
pick_section <- function(pred, config = mui_config()) {
  hit <- Filter(pred, config$sections)
  if (length(hit)) {
    hit[[1]]
  } else if (length(config$sections)) {
    config$sections[[1]]
  } else {
    NULL
  }
}

# The section whose items fill the honeycomb, and the band the hero's scroll cue points at.
hero_section_id <- function(config = mui_config()) {
  pick_section(function(s) isTRUE(s$hero), config)$id
}

scroll_cue_section <- function(config = mui_config()) {
  pick_section(
    function(s) identical(s$id, config$hero$scroll_to %||% ""),
    config
  )
}

#' The active site configuration
#'
#' The configuration [mui_build_site()] is currently building with. Every function that needs
#' configuration defaults its `config` argument to this, so that callers do not have to pass
#' one and tests can.
#'
#' @param config A configuration list to make active.
#' @return `mui_config()` returns the active configuration, falling back to
#'   [mui_default_config()] outside a build. `mui_set_config()` returns the previous one,
#'   invisibly, so a caller can restore it.
#' @export
mui_config <- function() the$config %||% mui_default_config()

#' @rdname mui_config
#' @export
mui_set_config <- function(config) {
  old <- the$config
  the$config <- mui_validate_config(config)
  invisible(old)
}

# Palette and font accessors, short enough to read inline at the call sites in theme.R.
pal <- function(key, config = mui_config()) site_palette(config)[[key]]
font <- function(key, config = mui_config()) config$theme$fonts[[key]]

# One scheme's colours, complete. `palette` is the site's light scheme; `palette_dark` names
# only what differs, so the dark one is the merge of the two. Every reader of a colour goes
# through here, which is what stops the dark scheme from quietly missing a key.
site_palette <- function(config = mui_config(), scheme = "light") {
  p <- config$theme$palette
  if (identical(scheme, "dark")) {
    merge_lists(p, config$theme$palette_dark %||% list())
  } else {
    p
  }
}

# The schemes this site emits, in the order they are declared. One for a pinned mode, both
# for "auto" - and the first is the one that paints before any media query is consulted.
site_schemes <- function(config = mui_config()) {
  switch(
    config$theme$mode %||% "auto",
    light = "light",
    dark = "dark",
    c("light", "dark")
  )
}


# The document language: what the site names, or the locale re-punctuated as the BCP 47 tag
# <html lang> wants ("de_CH" -> "de-CH").
site_lang <- function(config = mui_config()) {
  config$lang %||% gsub("_", "-", config$locale %||% "en_US")
}
