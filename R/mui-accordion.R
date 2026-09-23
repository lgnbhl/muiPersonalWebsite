# The talks band: a tour-dates accordion rather than a third grid of cards.

# The panel's detail line. The row above gives the year and, on anything wider than a
# phone, the location; this spells both out, so the exact day is there and the location is
# not lost on the narrow screens that drop it from the row.
talk_meta <- function(page) {
  parts <- c(
    if (!is.null(page$date)) format(as.Date(page$date), "%d %B %Y"),
    page$location
  )
  if (!length(parts)) NULL else paste(parts, collapse = " \u00b7 ")
}

# The abstract, split into paragraphs. An abstract is plain text - markdown belongs in a
# .md page, not in a YAML string - so there is nothing to strip, only blank lines to split
# on. A URL an abstract wants to point at goes under the talk's `links:` instead, where it
# becomes a button rather than a link buried in a paragraph.
talk_paragraphs <- function(body) {
  txt <- trimws(body %||% "")
  if (!nzchar(txt)) {
    return(character(0))
  }
  paras <- strsplit(txt, "\n[[:space:]]*\n")[[1]]
  # Soft-wrapped lines are one paragraph; the sources hard-wrap some and not others.
  paras <- trimws(gsub("[[:space:]]+", " ", paras))
  paras[nzchar(paras)]
}

# The event's page, then the slides, posters and anything else the talk links to. The event
# leads the row rather than being a link on the event name above it: that row is a
# ButtonBase, and an <a> inside a role="button" nests interactive content.
talk_links <- function(page) {
  event <- if (!is.null(page$event_url) && nzchar(page$event_url)) {
    list(list(name = page$event %||% "Event", href = page$event_url))
  }
  rest <- lapply(page$links %||% list(), function(l) {
    list(name = trimws(l$name), href = l$url)
  })
  # A talk that names its event page and then lists it again under `links` gets one button.
  c(event, Filter(function(l) !identical(l$href, page$event_url), rest))
}

# A line length for the panel's prose, in px. Not `ch`: this serif's zero is wide enough
# that 68ch measures past the width the panel even has, so the cap would never bind.
MEASURE <- 620

talk_row <- function(p) {
  links <- talk_links(p)
  paras <- talk_paragraphs(p$abstract)
  Accordion(
    # A talk has no URL of its own - no page is generated for it - so the key is its title.
    key = p$slug %||% p$title,
    AccordionSummary(
      expandIcon = chevron_icon(),
      # Children land in .MuiAccordionSummary-content, which is the flex row to style - the
      # root also holds the expand icon, and laying that out here would fight MUI.
      sx = list(
        "& .MuiAccordionSummary-content" = list(
          gap = 2.5,
          alignItems = "flex-start",
          margin = 0,
          marginRight = 1
        )
      ),
      Typography(
        variant = "mono",
        sx = list(color = "kicker", pt = 0.25, flexShrink = 0),
        if (is.null(p$date)) "" else format(as.Date(p$date), "%Y")
      ),
      Box(
        sx = list(minWidth = 0, flexGrow = 1),
        Typography(
          variant = "body1",
          sx = list(fontWeight = 600),
          p$event %||% p$title
        ),
        # Talk titles run to ninety characters; two lines is enough to recognise one while
        # the row is shut, and the whole thing is in the panel below anyway.
        Typography(
          variant = "body2",
          color = "text.secondary",
          sx = list(
            display = "-webkit-box",
            WebkitLineClamp = 2,
            WebkitBoxOrient = "vertical",
            overflow = "hidden",
            mt = 0.25
          ),
          p$title
        )
      ),
      if (!is.null(p$location)) {
        Typography(
          variant = "body2",
          color = "text.secondary",
          sx = list(
            flexShrink = 0,
            pt = 0.25,
            display = list(xs = "none", sm = "block")
          ),
          p$location
        )
      }
    ),
    AccordionDetails(
      # Indented past the year column so the abstract starts under the title it belongs to.
      # On a phone the year column is the whole left margin there is, so the panel gives it
      # up and runs full width.
      sx = list(
        pl = list(xs = 0, sm = 7),
        pr = list(xs = 0, sm = 7),
        pt = 1,
        maxWidth = 780
      ),
      # The event's one-liner, and only where there is no abstract to open on: where an
      # abstract does exist the description mostly restates the title.
      if (
        !length(paras) &&
          !is.null(p$description) &&
          nzchar(trimws(p$description))
      ) {
        Typography(
          variant = "body1",
          color = "text.secondary",
          sx = list(maxWidth = MEASURE),
          trimws(p$description)
        )
      },
      if (!is.null(talk_meta(p))) {
        Typography(
          variant = "body2",
          color = "text.secondary",
          sx = list(opacity = 0.75, mt = 0.5, mb = 2.5),
          talk_meta(p)
        )
      },
      lapply(seq_along(paras), function(i) {
        Typography(
          key = i,
          variant = "body1",
          sx = list(maxWidth = MEASURE, mb = 1.5),
          paras[[i]]
        )
      }),
      if (length(links)) {
        Stack(
          direction = "row",
          spacing = 1,
          useFlexGap = TRUE,
          sx = list(flexWrap = "wrap", mt = 2),
          lapply(links, function(l) {
            Button(
              key = l$href,
              href = l$href,
              variant = "outlined",
              size = "small",
              color = "inherit",
              l$name
            )
          })
        )
      }
    )
  )
}

#' The talks band
#'
#' A tour-dates list rather than a grid of cards: a talk carries an event, a location and a
#' date, and a card shows almost none of it. Each row is an uncontrolled Accordion, so React
#' owns which row is open - the same way the mobile drawer does, with no server and no
#' script of our own.
#'
#' @param talks Talk items: `title`, `event`, `date`, `location`, `abstract`, `description`
#'   and `links`.
#' @return A `muiMaterial` component.
#' @family home
#' @export
#' @examples
#' mui_accordion(list(list(title = "A talk", event = "A meetup", date = "2025-03-01",
#'                         location = "Zurich", abstract = "What it was about.")))
mui_accordion <- function(talks) Box(lapply(talks, talk_row))
