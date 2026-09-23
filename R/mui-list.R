# Three bands that are not this site's own three.
#
# `cards`, `accordion` and `showcase` were written for a portfolio of packages, talks and
# apps, and they carry that shape: a card wants a logo, the accordion wants an abstract, the
# showcase wants screenshots. A site whose sections are publications, or jobs, or a reading
# list, fits none of them and had to drop into R to add a variant.
#
# These three do not know what an item is. A `list` is titles and links, a `timeline` is
# those with a year down the left, and `prose` is a band of words with no items at all. Any
# content file feeds any of them.

# The two destinations, as text rather than as buttons: a column of filled rectangles down a
# list is what the eye runs down instead of the titles. Same pair mui_card() draws, and the
# same fields in the content file.
row_links <- function(item) {
  links <- Filter(
    function(l) !is.null(l) && nzchar(l$href %||% ""),
    c(
      list(item$primary, item$secondary),
      lapply(item$links %||% list(), function(l) {
        list(label = l$name, href = l$url)
      })
    )
  )
  if (!length(links)) {
    return(NULL)
  }
  Stack(
    direction = "row",
    spacing = 2,
    useFlexGap = TRUE,
    flexWrap = "wrap",
    sx = list(mt = 1),
    lapply(links, function(l) {
      Link(
        key = l$href,
        href = l$href,
        sx = list(fontSize = "0.85rem", color = "primary.main"),
        l$label %||% l$href
      )
    })
  )
}

# The year, for the timeline's left column. Not the full date: a column of "14 March 2023"
# is a column of noise, and the exact day is in the dateline under the title.
row_year <- function(item) {
  if (is.null(item$date)) "" else format(as.Date(item$date), "%Y")
}

# One row, in both variants. `rail` is what makes it a timeline rather than a list - the year
# column and the hairline the markers sit on - and is the only difference between the two.
list_row <- function(item, rail = FALSE) {
  body <- Box(
    sx = list(minWidth = 0, flexGrow = 1, pb = 3),
    Typography(variant = "h5", component = "h3", item$title %||% item$slug),
    if (!is.null(item$meta) || !is.null(item$location) || !is.null(item$event)) {
      Typography(
        variant = "body2",
        sx = list(color = "kicker", mt = 0.25),
        paste(
          Filter(
            nzchar,
            c(item$meta %||% "", item$event %||% "", item$location %||% "")
          ),
          collapse = " \u00b7 "
        )
      )
    },
    if (!is.null(item$description)) {
      Typography(
        variant = "body1",
        color = "text.secondary",
        sx = list(mt = 0.75, maxWidth = 640),
        item$description
      )
    },
    # A `body` is the description with links in the sentence: markdown, inside `.prose` as in
    # mui_prose(), at the description's size. The last paragraph drops the prose margin, which
    # would otherwise double the row's own padding.
    if (!is.null(item$body)) {
      Typography(
        variant = "body1",
        component = "div",
        color = "text.secondary",
        className = "prose",
        sx = list(mt = 0.75, maxWidth = 640, "& p:last-child" = list(mb = 0)),
        HTML(mui_md_to_html(trimws(item$body)))
      )
    },
    row_links(item)
  )
  if (!rail) {
    return(Box(
      key = item$slug %||% item$title,
      sx = list(
        borderBottom = "1px solid",
        borderColor = "divider",
        pt = 3,
        "&:first-of-type" = list(pt = 0)
      ),
      body
    ))
  }
  Stack(
    key = item$slug %||% item$title,
    direction = "row",
    spacing = 3,
    sx = list(alignItems = "stretch"),
    Typography(
      variant = "mono",
      sx = list(color = "kicker", pt = 0.5, width = 52, flexShrink = 0),
      row_year(item)
    ),
    # The rail is a left border on a spacer rather than an absolutely positioned line, so it
    # is exactly as tall as the rows are and needs no arithmetic to stay that way. The marker
    # is the spacer's own `:before`, sitting on the border.
    Box(
      className = "timeline-rail",
      sx = list(
        flexShrink = 0,
        width = "1px",
        backgroundColor = "divider",
        position = "relative"
      )
    ),
    body
  )
}

#' A band of rows
#'
#' Titles, a line of context and the links out, one under the other. The variant for a
#' section whose items are neither pictures nor talks - publications, posts, a reading list -
#' where a grid of cards would be a grid of mostly-empty boxes.
#'
#' `timeline` is the same rows with the year pulled into a column of its own and a rule down
#' the side, for items whose order is the point.
#'
#' Neither knows what an item is. `title`, `description`, `body`, `date`, `primary`,
#' `secondary` and `links` are read where they are there and skipped where they are not, so
#' any content file feeds either. `body` is markdown, for a description whose links belong in
#' the sentence rather than under it.
#'
#' @param items Items from a section's content file.
#' @return A `muiMaterial` component.
#' @family home
#' @export
#' @examples
#' mui_list(list(list(title = "A paper", description = "In a journal.")))
mui_list <- function(items) {
  Box(lapply(items, list_row, rail = FALSE))
}

#' @rdname mui_list
#' @export
mui_timeline <- function(items) {
  Box(lapply(items, list_row, rail = TRUE))
}

#' A band of prose
#'
#' Words, centred at a reading measure - an "about" band, or a note introducing the ones
#' below it. Each item's `body` is markdown; an item with only a `description` is rendered as
#' the paragraph it is.
#'
#' This is the one variant with no links, no dates and no pictures: a band that is a piece of
#' writing rather than a list of things.
#'
#' @param items Items carrying a `body` or a `description`.
#' @return A `muiMaterial` component.
#' @family home
#' @export
#' @examples
#' mui_prose(list(list(body = "Some **markdown**.")))
mui_prose <- function(items) {
  Box(
    sx = list(maxWidth = 680, mx = "auto"),
    lapply(items, function(it) {
      md <- trimws(it$body %||% it$description %||% "")
      Box(
        key = it$slug %||% it$title %||% substr(md, 1, 24),
        if (!is.null(it$title)) {
          Typography(variant = "h5", component = "h3", sx = list(mb = 1), it$title)
        },
        # Rendered as markdown and handed over as HTML, inside the same `.prose` the article
        # pages use - so a link or a list in a band reads exactly as one in a page does.
        tags$div(class = "prose", HTML(mui_md_to_html(md)))
      )
    })
  )
}
