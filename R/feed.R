# The site's own feed.
#
# `feed:` in the configuration is two things wearing one name, on purpose. A URL points at a
# feed somewhere else - writing that lives on Substack, say - and is only advertised in
# <head>. `feed: true` says the writing is here, and this builds one from it.
#
# Only the dated pages go in. An undated page is a colophon or an about page, not a post,
# and a reader that was pushed one every time it was edited would be right to unsubscribe.

# RFC 822, which is what RSS wants and is not what anything else on the site uses. The build
# pins LC_TIME to C before it gets here, so the day and month names are the English ones the
# format requires rather than the build machine's.
rfc822 <- function(date) {
  format(as.Date(date), "%a, %d %b %Y 00:00:00 +0000")
}

# Not CDATA. A description is a single escaped string here, which is the one encoding every
# reader agrees on - CDATA buys the ability to send HTML and costs a correctness argument
# this feed has no use for.
xml_esc <- function(x) {
  x <- gsub("&", "&amp;", as.character(x %||% ""), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

feed_item <- function(p, config) {
  url <- abs_url(p$url, config)
  paste0(
    "  <item>\n",
    sprintf("    <title>%s</title>\n", xml_esc(p$title %||% config$title)),
    sprintf("    <link>%s</link>\n", xml_esc(url)),
    # The URL is the identity: these pages have no id of their own, and a title can be
    # edited without the post becoming a different post.
    sprintf('    <guid isPermaLink="true">%s</guid>\n', xml_esc(url)),
    sprintf("    <pubDate>%s</pubDate>\n", rfc822(p$date)),
    if (nzchar(trimws(p$description %||% ""))) {
      sprintf(
        "    <description>%s</description>\n",
        xml_esc(trimws(p$description))
      )
    } else {
      ""
    },
    "  </item>"
  )
}

#' The site's RSS feed
#'
#' An RSS 2.0 document over the dated pages of the site, newest first. Built only when the
#' configuration says `feed: true`; a `feed:` naming a URL is a feed the site does not own
#' and is advertised in `<head>` without being generated.
#'
#' @param pages Built pages carrying a `date`; see [mui_build_site()].
#' @inheritParams mui_theme
#' @return The feed document, as a string.
#' @family render
#' @keywords internal
mui_feed_xml <- function(pages, config = mui_config()) {
  dated <- Filter(function(p) !is.null(p$date), pages)
  ord <- order(
    vapply(dated, function(p) as.character(p$date), character(1)),
    decreasing = TRUE
  )
  dated <- dated[ord]
  paste0(
    '<?xml version="1.0" encoding="UTF-8"?>\n',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n',
    "<channel>\n",
    sprintf("  <title>%s</title>\n", xml_esc(config$title)),
    sprintf("  <link>%s</link>\n", xml_esc(abs_url("/", config))),
    sprintf("  <description>%s</description>\n", xml_esc(config$description)),
    sprintf("  <language>%s</language>\n", xml_esc(site_lang(config))),
    # Required by the spec's own validator and by several readers: a feed has to say where
    # it lives, or a copy of it cannot be told from the original.
    sprintf(
      '  <atom:link href="%s" rel="self" type="application/rss+xml"/>\n',
      xml_esc(abs_url("/feed.xml", config))
    ),
    if (length(dated)) {
      paste0(
        paste0(
          vapply(dated, feed_item, character(1), config = config),
          collapse = "\n"
        ),
        "\n"
      )
    } else {
      ""
    },
    "</channel>\n</rss>\n"
  )
}
