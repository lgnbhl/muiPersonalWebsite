# The page's words, as plain HTML, for everything that does not run JavaScript.
#
# Every element of every page is a muiMaterial component, which means the document React is
# handed is a JSON blob: the site's <body> carries no sentence a crawler, a reader mode, a
# text browser or a social unfurler can read. That is defensible for a dashboard and wrong
# for a personal site, whose whole job is to be read and to be found.
#
# So the landing page's content is written twice. Once as the React tree, which is what a
# browser ends up showing, and once - here - as a small tree of <section>, <article>, <h2>
# and <a>, placed in the document ahead of it. Both are generated from the same `items`, so
# they cannot disagree about what the site says.
#
# It is markup rather than a <noscript> block on purpose: text inside <noscript> is inert to
# a lot of what this is for, and putting it in the document proper also means the first paint
# has words in it instead of an empty ground. React does not hydrate this - it mounts
# alongside - so the fallback is removed on mount; see R/boot.R.

# The one thing a fallback item always has. A card, a talk and a showcase row are different
# components and the same handful of facts, so this flattens all three rather than mirroring
# the variants - a variant is about arrangement, and arrangement is exactly what a plain
# document does not need.
fallback_links <- function(it) {
  c(
    list(it$primary, it$secondary),
    if (!is.null(it$event_url)) {
      list(list(label = it$event %||% "Event", href = it$event_url))
    },
    lapply(it$links %||% list(), function(l) {
      list(label = l$name, href = l$url)
    })
  )
}

# The dateline, spelled the way the accordion spells it: an item that carries an event and a
# place says so here too, since that is most of what a talk *is*.
#
# `meta` wins over the date where an item carries one, exactly as it does in a list or
# timeline row: an item saying "2023 - present" means the span, and a fallback answering
# "01 January 2023" would be the two copies of the page disagreeing about a fact.
fallback_meta <- function(it) {
  parts <- c(
    if (nzchar(trimws(it$meta %||% ""))) {
      trimws(it$meta)
    } else if (!is.null(it$date)) {
      format(as.Date(it$date), "%d %B %Y")
    },
    it$event,
    it$location
  )
  parts[nzchar(parts %||% "")]
}

fallback_item <- function(it) {
  links <- Filter(
    function(l) !is.null(l) && nzchar(l$href %||% ""),
    fallback_links(it)
  )
  meta <- fallback_meta(it)
  head <- it$title %||% it$slug %||% ""
  paste0(
    "<article>",
    # A `prose` item is a body and nothing else, so an empty <h3> here would be the whole
    # band to a reader without JavaScript. Skipped rather than emitted blank.
    if (nzchar(head)) sprintf("<h3>%s</h3>", text_esc(head)) else "",
    if (length(meta)) sprintf("<p>%s</p>", text_esc(paste(meta, collapse = " \u00b7 "))) else "",
    if (nzchar(trimws(it$description %||% ""))) {
      sprintf("<p>%s</p>", text_esc(trimws(it$description)))
    } else {
      ""
    },
    # The words of a band that is words, through the same `mui_md_to_html()` an article
    # page's markdown goes through. That is not an escape: CommonMark passes raw HTML
    # through, and `tagfilter` disarms only <script>, <iframe>, <style> and the like - an
    # attribute such as `onerror` survives. The markdown is the site author's own, and is
    # trusted exactly as far as the rest of their content is.
    if (nzchar(trimws(it$body %||% ""))) {
      mui_md_to_html(trimws(it$body))
    } else {
      ""
    },
    if (length(links)) {
      paste0(
        "<p>",
        paste0(
          vapply(
            links,
            function(l) {
              sprintf(
                '<a href="%s">%s</a>',
                attr_esc(l$href),
                text_esc(l$label %||% l$href)
              )
            },
            character(1)
          ),
          collapse = " "
        ),
        "</p>"
      )
    } else {
      ""
    },
    "</article>"
  )
}

# No ids anywhere in here. The React tree gives every band the id its app bar tab points at,
# and a document holding the same id twice is one where the anchor is ambiguous and the
# fallback is what the browser would find.
#
# `intro` is carried for every section and not only for the variants that draw one, because
# the invariant is about the words: a sentence the React page says under the heading is a
# sentence this copy has to say too, whatever arrangement chose to say it.
fallback_section <- function(s, items) {
  paste0(
    "<section>",
    sprintf("<h2>%s</h2>", text_esc(s$title %||% s$id)),
    if (nzchar(trimws(s$intro %||% ""))) mui_md_to_html(s$intro) else "",
    paste0(vapply(items, fallback_item, character(1)), collapse = ""),
    "</section>"
  )
}

# The hero's own words, and the profile links under them. <h1> rather than <h2>: this is the
# page's heading, and a document whose only heading level is 2 reads as a fragment.
fallback_hero <- function(config) {
  h <- config$hero
  shown <- Filter(
    function(s) s$name %in% (config$hero_social %||% character()),
    config$social
  )
  # In the order the hero says them: the greeting introduces the name, so it comes before
  # it here exactly as it does on the page.
  para <- function(x) {
    if (!nzchar(trimws(x %||% ""))) "" else sprintf("<p>%s</p>", text_esc(trimws(x)))
  }
  paste0(
    "<header>",
    para(h$greeting),
    sprintf("<h1>%s</h1>", text_esc(h$name %||% config$title)),
    para(h$role),
    para(h$lead),
    if (length(shown)) {
      paste0(
        "<p>",
        paste0(
          vapply(
            shown,
            function(s) {
              sprintf(
                '<a href="%s" rel="me noopener">%s</a>',
                attr_esc(s$href),
                text_esc(s$name)
              )
            },
            character(1)
          ),
          collapse = " "
        ),
        "</p>"
      )
    } else {
      ""
    },
    "</header>"
  )
}

#' The landing page in plain HTML
#'
#' The same hero and the same items the React tree renders, as a document a crawler, a reader
#' mode or a text browser can read. Written into the page ahead of the React container and
#' removed when React mounts, so it costs a reader with JavaScript nothing but is the whole
#' page to a reader without it.
#'
#' It mirrors the *content*, not the layout: one `<section>` per band and one `<article>` per
#' item, whatever variant the band is drawn with. Arrangement is what a plain document does
#' not need.
#'
#' @param items Items by section id, exactly as [mui_build_site()] assembles them.
#' @inheritParams mui_theme
#' @return A `<div>`, as a string, or `""` when `prerender` is off.
#' @family render
#' @keywords internal
mui_prerender_html <- function(items, config = mui_config()) {
  if (!isTRUE(config$prerender %||% TRUE)) {
    return("")
  }
  paste0(
    '<div id="site-fallback">',
    fallback_hero(config),
    paste0(
      vapply(
        config$sections,
        function(s) fallback_section(s, items[[s$id]] %||% list()),
        character(1)
      ),
      collapse = ""
    ),
    "</div>"
  )
}

# The article shell's own fallback: a markdown page already renders its body as plain HTML
# inside the React tree, but the tree is still JSON, so the body has to be written out here
# too. The title block is escaped here; the body is markdown rendered by `mui_md_to_html()`,
# which passes the author's raw HTML through - see fallback_item().
mui_prerender_page <- function(page, config = mui_config()) {
  if (!isTRUE(config$prerender %||% TRUE)) {
    return("")
  }
  title <- trimws(page$title %||% "")
  paste0(
    '<div id="site-fallback">',
    if (nzchar(title)) sprintf("<h1>%s</h1>", text_esc(title)) else "",
    if (nzchar(trimws(page$description %||% ""))) {
      sprintf("<p>%s</p>", text_esc(trimws(page$description)))
    } else {
      ""
    },
    mui_md_to_html(page$body),
    "</div>"
  )
}
