# Per-page <head> metadata, the sitemap and robots.txt. These are written at build time as
# plain tags, so social card scrapers - which do not execute JavaScript - still see them.
# The site's identity is configuration, so all of it is read from `config`.

# A page's URL made absolute. Page URLs ("/", "/about.html") are relative to the site, so
# they go onto `url` whole - path and all, for a site served under one.
abs_url <- function(path, config = mui_config()) paste0(config$url, path)

# The path the site is served under, read off `url`: "" at a domain root, "/repo" for a
# GitHub Pages project site at https://<user>.github.io/repo. Every URL the build writes
# into the tree - its own /_mui/ files, the /assets/ an item names, the way home - is
# prefixed with it, which is what lets a site be served from somewhere other than a root.
site_base <- function(config = mui_config()) {
  sub("^[A-Za-z][A-Za-z0-9+.-]*://[^/]*", "", config$url %||% "")
}

# `{base}` in text the author writes, for a link that has to reach this site's root
# whether it is served at a domain or under /<repo> - the 404's way home, above all, which is
# served at every depth and so cannot be relative. A bare "/" is a path on the host and is
# left as written; see mui_asset_url().
expand_base <- function(x, config = mui_config()) {
  if (is.null(x)) {
    return(x)
  }
  gsub("{base}", site_base(config), x, fixed = TRUE)
}

# `url` without that path: the scheme and host a served path is resolved against.
site_origin <- function(config = mui_config()) {
  base <- site_base(config)
  substring(config$url, 1L, nchar(config$url) - nchar(base))
}

# An href as a scraper needs it, absolute. One this build resolved - or one a content file
# wrote starting with "/" - is a path on the host, so it goes onto the origin; a full or
# protocol-relative URL is somewhere else already and passes through.
abs_href <- function(href, config = mui_config()) {
  if (is.null(href) || !nzchar(href)) {
    return(NULL)
  }
  if (startsWith(href, "/") && !startsWith(href, "//")) {
    paste0(site_origin(config), href)
  } else {
    href
  }
}

# Where the 404 page is written. GitHub Pages serves it for every missing URL, so it is kept
# out of the sitemap and marked noindex.
NOT_FOUND_URL <- "/404.html"

# One <meta>. `name` or `property` is the only difference between a Twitter card tag and an
# Open Graph one. An absent value is omitted rather than emitted empty.
meta_tag <- function(key, content, attr = "name") {
  if (!length(content)) {
    return("")
  }
  # A list or a vector here is a configuration value written as a YAML sequence -
  # `twitter: [a, b]` - and one <meta> cannot carry two.
  if (length(content) != 1L || is.list(content)) {
    stop("site config: ", key, " has to be a single value", call. = FALSE)
  }
  if (is.na(content)) {
    return("")
  }
  sprintf('<meta %s="%s" content="%s">', attr, key, attr_esc(content))
}

prop_tag <- function(key, content) meta_tag(key, content, "property")

# The icons <head> advertises. Each is optional and each is named the way the assets
# directory holds it, so adding a favicon is a file plus one line of YAML. `rel` and `type`
# are the only per-icon knowledge here, which is why this is a table rather than five
# sprintf calls.
ICON_LINKS <- list(
  favicon = list(rel = "icon"),
  png_32 = list(rel = "icon", type = "image/png", sizes = "32x32"),
  png_16 = list(rel = "icon", type = "image/png", sizes = "16x16"),
  apple_touch = list(rel = "apple-touch-icon"),
  manifest = list(rel = "manifest")
)

icon_head <- function(config = mui_config()) {
  paste(
    vapply(
      names(ICON_LINKS),
      function(k) {
        href <- mui_asset_url(config$icons[[k]] %||% "", config)
        if (is.null(href)) {
          return("")
        }
        a <- ICON_LINKS[[k]]
        sprintf(
          '<link %shref="%s">',
          paste0(
            vapply(
              names(a),
              function(n) sprintf('%s="%s" ', n, a[[n]]),
              character(1)
            ),
            collapse = ""
          ),
          attr_esc(href)
        )
      },
      character(1)
    ),
    collapse = ""
  )
}

# `counterdev: <id>`, or `counterdev: {id: ..., utcoffset: 2}` when the site wants its
# visits bucketed by its own timezone rather than by UTC.
analytics_head <- function(config = mui_config()) {
  cd <- config$counterdev
  if (is.null(cd)) {
    return("")
  }
  id <- if (is.list(cd)) cd$id %||% "" else cd
  offset <- if (is.list(cd)) cd$utcoffset %||% 0 else 0
  if (!nzchar(id)) {
    return("")
  }
  sprintf(
    paste0(
      '<script defer src="https://cdn.counter.dev/script.js" data-id="%s" ',
      'data-utcoffset="%s"></script>'
    ),
    attr_esc(id),
    attr_esc(offset)
  )
}

# Minimal JSON string escaping. jsonlite would do this, but one <script> block is not worth
# a dependency - and the escape that matters most here is one jsonlite does not make either:
# "<" is escaped too, so a value carrying "</script>" cannot close the block it sits in.
#
# JSON forbids every raw control character inside a string, not just the newline, so a tab
# pasted into a description would otherwise make the whole block unparseable. The three
# common ones get their short escapes; the rest get \u00XX.
json_str <- function(x) {
  x <- gsub("\\", "\\\\", enc2utf8(as.character(x)), fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  for (code in setdiff(1:31, c(9L, 10L, 13L))) {
    x <- gsub(intToUtf8(code), sprintf("\\u%04x", code), x, fixed = TRUE)
  }
  x <- gsub("<", "\\u003c", x, fixed = TRUE)
  paste0('"', x, '"')
}

# The landing page's Person block. Its name, role, url and profiles are all already in the
# configuration, so this restates nothing and cannot drift from what the page says.
person_jsonld <- function(config = mui_config()) {
  if (identical(config$jsonld, FALSE)) {
    return("")
  }
  name <- trimws(config$hero$name %||% config$title %||% "")
  if (!nzchar(name)) {
    return("")
  }
  role <- trimws(config$hero$role %||% "")
  desc <- trimws(config$description %||% "")
  same <- vapply(config$social, function(s) s$href %||% "", character(1))
  same <- same[nzchar(same)]
  fields <- c(
    '"@context":"https://schema.org"',
    '"@type":"Person"',
    paste0('"name":', json_str(name)),
    paste0('"url":', json_str(paste0(config$url, "/"))),
    if (nzchar(role)) paste0('"jobTitle":', json_str(role)),
    if (nzchar(desc)) paste0('"description":', json_str(desc)),
    if (length(same)) {
      paste0(
        '"sameAs":[',
        paste(
          vapply(same, json_str, character(1), USE.NAMES = FALSE),
          collapse = ","
        ),
        "]"
      )
    }
  )
  paste0(
    '<script type="application/ld+json">{',
    paste(fields, collapse = ","),
    "}</script>"
  )
}

# The colour the browser paints its own chrome with. Two of them where the site follows the
# reader's setting: one unqualified tag would have a phone draw a cream address bar over a
# dark page.
theme_color_head <- function(config = mui_config()) {
  schemes <- site_schemes(config)
  if (length(schemes) == 1L) {
    return(meta_tag("theme-color", site_palette(config, schemes)$background))
  }
  paste0(
    sprintf(
      '<meta name="theme-color" media="(prefers-color-scheme: light)" content="%s">',
      attr_esc(site_palette(config, "light")$background)
    ),
    sprintf(
      '<meta name="theme-color" media="(prefers-color-scheme: dark)" content="%s">',
      attr_esc(site_palette(config, "dark")$background)
    )
  )
}

# `feed: true` is the feed this build writes; a string is one somewhere else. Both are
# advertised the same way, which is the point - a reader cannot tell, and should not have to.
feed_head <- function(config = mui_config()) {
  href <- if (isTRUE(config$feed)) {
    abs_url("/feed.xml", config)
  } else if (is.character(config$feed) && nzchar(config$feed)) {
    config$feed
  } else {
    return("")
  }
  sprintf(
    '<link rel="alternate" type="application/rss+xml" title="%s" href="%s">',
    attr_esc(config$title),
    attr_esc(href)
  )
}

# Every page is drawn by React, so a reader with JavaScript switched off gets a blank one.
# A line of text is what stands between that and a page that merely looks broken, and it
# goes in <head> because that is the half of the document that exists before React runs.
# `noscript: ~` in the configuration leaves it out.
noscript_notice <- function(config = mui_config()) {
  # A prerendered page has its words in the document and needs no apology - the reader is
  # reading it. Only an unprerendered one is blank without JavaScript.
  if (isTRUE(config$prerender %||% TRUE)) {
    return("")
  }
  text <- trimws(config$noscript %||% "")
  if (!nzchar(text)) {
    return("")
  }
  # The text becomes a CSS string, so the escape that matters is the quote that would end
  # it - and a newline inside one is a parse error rather than a line break.
  quoted <- gsub("[\r\n]+", " ", gsub('["\\\\<]', "", text))
  sprintf(
    paste0(
      '<noscript><style>body::before{content:"%s";display:block;',
      "padding:28px 20px;text-align:center;",
      "font:16px/1.6 system-ui,-apple-system,sans-serif}</style></noscript>"
    ),
    quoted
  )
}

# Title, description, canonical, Open Graph, Twitter card, icons, the palette, the
# stylesheet and the analytics tag. Every URL here is either absolute - canonical and `og:`,
# which scrapers need that way - or site-absolute: the built tree is meant to be served, not
# opened off disk.
mui_head_meta <- function(page, config = mui_config()) {
  title <- page$pagetitle %||% page$title %||% config$title
  if (!nzchar(trimws(title))) {
    title <- config$title
  } # front matter may carry title: ""
  full <- if (identical(page$url, "/") || identical(title, config$title)) {
    config$title
  } else {
    paste0(title, " | ", config$title)
  }
  desc <- trimws(page$description %||% config$description)
  # NULL when neither the page nor the site names an image, so the image tags are omitted:
  # an og:image pointing at the site's own URL would be an HTML page posing as a picture.
  img <- abs_href(
    mui_asset_url(page$image %||% "", config) %||%
      mui_asset_url(config$default_image %||% "", config),
    config
  )
  can <- abs_url(page$url, config)
  type <- if (!is.null(page$date)) "article" else "website"

  paste0(
    sprintf("<title>%s</title>", text_esc(full)),
    meta_tag("description", desc),
    if (identical(page$url, NOT_FOUND_URL)) meta_tag("robots", "noindex") else "",
    sprintf('<link rel="canonical" href="%s">', attr_esc(can)),
    prop_tag("og:type", type),
    prop_tag("og:site_name", config$title),
    prop_tag("og:locale", config$locale),
    prop_tag("og:title", title),
    prop_tag("og:description", desc),
    prop_tag("og:url", can),
    prop_tag("og:image", img),
    # The large card is a picture with words under it; with no picture it is an empty frame.
    meta_tag("twitter:card", if (is.null(img)) "summary" else "summary_large_image"),
    meta_tag("twitter:site", config$twitter),
    meta_tag("twitter:creator", config$twitter),
    meta_tag("twitter:title", title),
    meta_tag("twitter:description", desc),
    meta_tag("twitter:image", img),
    if (!is.null(page$date)) {
      prop_tag("article:published_time", as.character(page$date))
    } else {
      ""
    },
    icon_head(config),
    theme_color_head(config),
    config$theme$font_head,
    mui_css_root_vars(config),
    sprintf(
      '<link rel="stylesheet" href="%s/_mui/site.css">',
      attr_esc(site_base(config))
    ),
    feed_head(config),
    # The landing page alone: a Person block on every page would claim the 404 is a person.
    if (identical(page$url, "/")) person_jsonld(config) else "",
    noscript_notice(config),
    analytics_head(config)
  )
}

# The sitemap, from the URLs this build generated and their publication dates.
mui_sitemap_xml <- function(urls, dates = NULL, config = mui_config()) {
  entries <- vapply(
    seq_along(urls),
    function(i) {
      # Escaped: a URL is text in XML, and a bare `&` in one makes the whole sitemap
      # malformed - which a crawler answers by reading none of it.
      sprintf(
        "  <url><loc>%s</loc>%s</url>",
        xml_esc(abs_url(urls[i], config)),
        if (!is.null(dates) && !is.na(dates[i]) && nzchar(dates[i])) {
          sprintf("<lastmod>%s</lastmod>", xml_esc(dates[i]))
        } else {
          ""
        }
      )
    },
    character(1)
  )
  paste0(
    '<?xml version="1.0" encoding="UTF-8"?>\n',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n',
    paste(entries, collapse = "\n"),
    "\n</urlset>\n"
  )
}

mui_robots_txt <- function(config = mui_config()) {
  paste0(
    "User-agent: *\nAllow: /\n\nSitemap: ",
    abs_url("/sitemap.xml", config),
    "\n"
  )
}
