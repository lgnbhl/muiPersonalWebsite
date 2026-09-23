# The two pieces of page chrome that are not a band: the footer and the article title block.
# Both are muiMaterial, and both render inside the one ThemeProvider mui_app_shell() opens.

#' The site footer
#'
#' The bar above carries the sections; this carries the profiles, and `sitemap.xml` carries
#' the full page list to crawlers.
#'
#' Its rule, its width and its type all come from the theme rather than from the stylesheet:
#' `divider` is the same hairline the app bar and the first band use, and `Container` is the
#' same `lg` cap the bands sit in, so the footer lines up with them without repeating a
#' number.
#'
#' @inheritParams mui_theme
#' @return A `muiMaterial` component.
#' @family shell
#' @keywords internal
mui_footer <- function(config = mui_config()) {
  # The credit is written raw: it is HTML, so a site can point it wherever it likes. Same
  # reason theme$font_head goes into <head> unescaped - see mui_head_meta() in seo.R.
  credit <- trimws(config$footer$credit %||% "")

  Box(
    component = "footer",
    sx = list(
      borderTop = "1px solid",
      borderColor = "divider",
      mt = 5,
      pt = 5,
      pb = 7
    ),
    Container(
      maxWidth = "lg",
      Stack(
        component = "nav",
        `aria-label` = "Elsewhere",
        direction = "row",
        useFlexGap = TRUE,
        flexWrap = "wrap",
        spacing = 2.25,
        social_links(
          config$social,
          sx = list(
            fontSize = "0.85rem",
            color = "text.secondary",
            "&:hover" = list(color = "primary.main", textDecoration = "underline")
          )
        )
      ),
      Typography(
        variant = "body2",
        color = "text.secondary",
        sx = list(fontSize = "0.8rem", mt = 2.5),
        HTML(paste0(
          "&copy; ",
          format(Sys.Date(), "%Y"),
          " ",
          text_esc(config$footer$copyright %||% config$title),
          if (nzchar(credit)) paste0(" &middot; ", credit) else ""
        ))
      )
    )
  )
}

#' A page's title block
#'
#' One header for every page type. `hide_title: true` in front matter suppresses it for a
#' page that opens with its own heading, without losing the `<title>` and `og:title`
#' metadata.
#'
#' The action links are `Button`s rather than the hand-rolled pill the stylesheet used to
#' draw: an outlined and a contained Button under this theme is what that pill was imitating,
#' and it is the same pair a card in any band shows.
#'
#' @param page A page read from a markdown file.
#' @return A `muiMaterial` component, or `NULL` when the page has no title to show.
#' @family shell
#' @keywords internal
mui_page_head <- function(page) {
  title <- trimws(page$title %||% "")
  if (isTRUE(page$`hide_title`) || !nzchar(title)) {
    return(NULL)
  }

  # Assembled as elements rather than as a string: the date has to stay a <time>, which a
  # paste() of escaped text could not carry.
  meta <- Filter(
    Negate(is.null),
    list(
      if (!is.null(page$date)) {
        Box(
          component = "time",
          dateTime = page$date,
          format(as.Date(page$date), "%d %B %Y")
        )
      },
      if (!is.null(page$event)) page$event,
      if (!is.null(page$location)) page$location
    )
  )
  # The separator goes between the parts and never at an end, so it is prepended to every
  # part but the first rather than appended to each.
  meta <- unlist(
    lapply(seq_along(meta), function(i) {
      if (i == 1L) meta[i] else list(HTML(" &middot; "), meta[[i]])
    }),
    recursive = FALSE
  )

  Stack(
    component = "header",
    sx = list(position = "relative", textAlign = "center", pt = 3, pb = 5),
    Typography(
      variant = "h1",
      sx = list(
        fontSize = "clamp(2.1rem, 1.4rem + 2.6vw, 3.2rem)",
        lineHeight = 1.06,
        letterSpacing = "-0.03em",
        maxWidth = "20ch",
        mx = "auto",
        mb = 2
      ),
      title
    ),
    if (!is.null(page$description)) {
      Typography(
        color = "text.secondary",
        sx = list(
          fontSize = "clamp(1.05rem, 1rem + 0.35vw, 1.22rem)",
          lineHeight = 1.6,
          maxWidth = "40em",
          mx = "auto",
          mb = 1.75
        ),
        trimws(page$description)
      )
    },
    if (length(meta)) {
      Typography(
        variant = "body2",
        color = "text.secondary",
        sx = list(
          fontSize = "0.78rem",
          letterSpacing = "0.08em",
          textTransform = "uppercase"
        ),
        meta
      )
    },
    if (length(page$links %||% list())) {
      Stack(
        direction = "row",
        useFlexGap = TRUE,
        flexWrap = "wrap",
        spacing = 1,
        sx = list(justifyContent = "center", mt = 3),
        lapply(page$links, function(l) {
          Button(
            key = l$url,
            href = l$url,
            variant = "contained",
            size = "small",
            l$name
          )
        })
      )
    }
  )
}
