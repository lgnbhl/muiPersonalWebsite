# The card behind every `variant: cards` band, and the item-to-buttons mapping the showcase
# band shares with it.

# The two destinations an item carries. The card grid draws them solid; the showcase list
# draws them as text, because a column of blue rectangles down a list is what the eye would
# run down instead of the app names.
item_actions <- function(item, primary = "contained", secondary = "outlined") {
  Filter(
    Negate(is.null),
    list(
      if (!is.null(item$primary)) {
        Button(
          href = item$primary$href,
          variant = primary,
          size = "small",
          item$primary$label
        )
      },
      if (!is.null(item$secondary)) {
        Button(
          href = item$secondary$href,
          variant = secondary,
          size = "small",
          color = "inherit",
          item$secondary$label
        )
      }
    )
  )
}

# A card's React key. The slug is the item's identity where it has one; the link is not,
# since an item may have no `primary` at all, and a NULL key is no key.
card_key <- function(item) {
  item$slug %||% item$title %||% item$primary$href %||% ""
}

#' The shared card
#'
#' Apps and packages are the same kind of thing: a picture, a sentence, somewhere to try it
#' and somewhere to read the code. They resolve to one shape and render through one card,
#' rather than two components that would drift apart.
#'
#' The card is deliberately not wrapped in a `CardActionArea`: two destinations means two
#' links, and a Button inside a CardActionArea is an `<a>` inside an `<a>`.
#'
#' @param item A card: `list(image, fit, title, description, primary = list(label, href),
#'   secondary = ...)` - which is exactly what an item in a `variant: cards` content file
#'   says, so a content file feeds this directly with nothing in between.
#' @param items Cards, for the grid.
#' @param columns How many cards stand across a medium screen.
#' @return A `muiMaterial` component.
#' @family home
#' @export
#' @examples
#' mui_card(list(title = "aniview", description = "Animate on scroll.",
#'                primary = list(label = "Docs", href = "/aniview/")))
mui_card <- function(item) {
  # A screenshot fills the band; a logo is shown whole, since cropping a hexagon to a 16:9
  # strip loses the thing that makes it recognisable.
  logo <- identical(item$fit, "contain")
  Card(
    key = card_key(item),
    if (!is.null(item$image)) {
      CardMedia(
        component = "img",
        image = item$image,
        alt = "",
        loading = "lazy",
        sx = list(
          height = 168,
          objectFit = if (logo) "contain" else "cover",
          p = if (logo) 2.5 else 0,
          backgroundColor = if (logo) "background.paper" else NULL,
          borderBottom = "1px solid rgba(var(--site-ink-rgb),0.11)"
        )
      )
    },
    CardContent(
      sx = list(p = 2.25, pb = 1, flexGrow = 1),
      Typography(
        variant = "h5",
        component = "h3",
        sx = list(mb = 0.75),
        item$title
      ),
      if (!is.null(item$description)) {
        Typography(
          variant = "body2",
          color = "text.secondary",
          sx = list(lineHeight = 1.55),
          item$description
        )
      }
    ),
    CardActions(
      sx = list(px = 2.25, pb = 2, pt = 0, gap = 1),
      item_actions(item)
    )
  )
}

# `columns` counts cards across, because "three across" is what a person means and `md: 4`
# is only how MUI spells it. Grid v2 divides twelve, so the span is the reciprocal;
# mui_validate_config() holds `columns` to a divisor of twelve so the division is exact.
#' @rdname mui_card
#' @export
mui_card_grid <- function(items, columns = 3) {
  Grid(
    container = TRUE,
    spacing = 2.5,
    # The position goes into the key as well: two items may share a slug-less title or a
    # link, and React needs sibling keys to be unique, not merely present.
    lapply(seq_along(items), function(i) {
      item <- items[[i]]
      Grid(
        key = paste0(i, "-", card_key(item)),
        size = list(xs = 12, sm = 6, md = 12 %/% columns),
        mui_card(item)
      )
    })
  )
}
