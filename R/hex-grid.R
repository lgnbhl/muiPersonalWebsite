# The honeycomb of package stickers in the hero: layout algebra, then markup.
#
# Rows alternate between a long row of `per_row` cells and a short one of `per_row - 1`, the
# short rows inset by half a cell so the points nest - a real comb, rather than uniform rows
# shifted sideways. The comb holds the packages plus exactly one empty slot.
#
# Adding a package re-proportions the comb and shrinks the stickers a step; it never grows
# the hero, so the scroll cue stays at the fold however long the list gets. The stylesheet
# is handed the answers rather than the algebra - see hex_shape().

HEX_ASPECT <- 1.05 # Target width:height. Square, give or take: paving, not a banner.
HEX_MAX_H <- 340 # px. The comb's height budget - what the hero can give it on a laptop.
HEX_MAX_W <- 400 # px. Its width budget.
HEX_MIN_CELL <- 40 # px. Below this a sticker stops being recognisable at a glance.
HEX_GAP_R <- 0.10 # The gap between cells, as a fraction of a cell's width.

# Row lengths when m cells are dealt into alternating long and short rows.
hex_rows <- function(m, per_row) {
  lens <- integer(0)
  while (m > 0) {
    take <- if (length(lens) %% 2 == 0) per_row else per_row - 1L
    lens <- c(lens, min(take, m))
    m <- m - take
  }
  lens
}

# One candidate comb: n packages plus the empty slot, at `per_row` cells to a long row. NULL
# if the cells do not even fill one row. `across` and `down` are in units of a cell's width,
# so dividing them cancels the unit and leaves the shape.
hex_shape <- function(n, per_row) {
  lens <- hex_rows(n + 1L, per_row)
  if (lens[1] < per_row) {
    return(NULL)
  }
  across <- per_row + (per_row - 1) * HEX_GAP_R
  down <- 1.1547 + (length(lens) - 1) * (0.866 + 0.5 * HEX_GAP_R)
  aspect <- across / down
  box <- floor(min(HEX_MAX_W, HEX_MAX_H * aspect)) # whichever budget binds first
  list(
    per_row = per_row,
    rows = length(lens),
    lens = lens,
    box = box,
    aspect = round(aspect, 3),
    cell_px = box / across,
    # Cell and gap as fractions of the comb's width: all the stylesheet needs to size
    # everything, without repeating this arithmetic or being able to disagree with it.
    cell_f = round(1 / across, 5),
    gap_f = round(HEX_GAP_R / across, 5)
  )
}

#' Choose the honeycomb's shape
#'
#' What is decided per build is the comb's *shape* - cells to a row, and the rows that
#' follow from it. Its proportions depend on those two counts alone, since scaling the
#' cells scales both sides of the block, so the shape is chosen against a target aspect
#' ratio and the size follows from whichever budget binds.
#'
#' Choosing by cell size instead - the fewest cells per row that fits a height cap - always
#' lands on the widest, shortest comb that will fit, which reads as a banner rather than as
#' paving.
#'
#' @param n Number of cells: the packages, plus the one empty slot.
#' @return A list: `rows` (cells per row), `box` (px), `aspect`, `cell_px`, `cell_f`,
#'   `gap_f`.
#' @family home
#' @keywords internal
mui_hex_layout <- function(n) {
  shapes <- Filter(Negate(is.null), lapply(2:12, hex_shape, n = n))
  legible <- Filter(function(s) s$cell_px >= HEX_MIN_CELL, shapes)
  # Nothing is legible only once there are so many packages that every shape has tiny
  # stickers. Until someone caps the hero, show the largest cells there are.
  if (!length(legible)) {
    return(shapes[[which.max(vapply(shapes, function(s) s$cell_px, 0))]])
  }
  score <- vapply(
    legible,
    function(s) {
      # A last row holding nothing but the empty slot leaves it stranded under the block.
      # Nudge away from that, but only enough to decide between shapes already close.
      abs(s$aspect - HEX_ASPECT) + if (s$lens[s$rows] == 1) 0.06 else 0
    },
    numeric(1)
  )
  legible[[which.min(score)]]
}

# Deal the packages into that comb in order: a package index per cell, NA for the single
# empty slot at the end, 0 for a blank that holds a lattice position and draws nothing.
hex_split <- function(n, lay) {
  i <- 0L
  rows <- lapply(lay$lens, function(len) {
    idx <- i + seq_len(len)
    i <<- i + len
    replace(idx, idx > n, NA_integer_)
  })
  last <- length(rows)
  # When the packages fill their rows exactly, the empty slot opens a row of its own, and at
  # the far left it reads as a cell that fell off the block. Blanks centre it instead.
  if (last > 1 && lay$lens[last] == 1L) {
    width <- if (last %% 2 == 1) lay$per_row else lay$per_row - 1L
    rows[[last]] <- c(rep(0L, (width - 1L) %/% 2L), rows[[last]])
  }
  rows
}

# One cell. `slot` is a package index, NA for the empty slot, or 0 for a blank; `d` is its
# distance from the middle of the comb, in cell widths, which the bloom-in fans out along.
#
# The cells keep their classes: the comb's geometry and its animations stay in the
# stylesheet (see mui_hex_grid), and `style` rather than `sx` carries the per-cell custom
# properties - `sx` would mint an emotion class per distinct value, and a comb is dozens of
# cells each with its own pair.
#
# `Box(component = "a")` rather than `Link`, for the same reason: a Box with no `sx` emits
# no styles of its own, where a Link brings MUI's colour and underline. Emotion injects its
# styles after site.css, so on a tie MUI wins - a Link here would repaint the empty slot's
# `+` in the primary and underline it on hover, over the top of .hex-empty.
hex_cell <- function(slot, key, d, items, config = mui_config()) {
  # The empty slot is a real link: an invitation rather than a placeholder. Without a
  # `github_href` there is nowhere to invite anyone to, so it is drawn as the same dashed hex
  # but as decoration - an <a> with no href, labelled as a link, would be announced as one
  # and then do nothing.
  if (is.na(slot) && !nzchar(config$github_href %||% "")) {
    return(Box(
      key = key,
      component = "span",
      className = "hex hex-empty",
      style = list(`--d` = d),
      `aria-hidden` = "true"
    ))
  }
  if (is.na(slot)) {
    return(Box(
      key = key,
      component = "a",
      className = "hex hex-empty",
      style = list(`--d` = d),
      href = config$github_href,
      `aria-label` = "More on GitHub"
    ))
  }
  if (slot == 0L) {
    return(Box(
      key = key,
      component = "span",
      className = "hex",
      `aria-hidden` = "true"
    ))
  }
  it <- items[[slot]]
  desc <- trimws(it$desc %||% "")
  # The caption positions itself against the whole grid (see .hex-caption), so every cell
  # writes into the same strip under the comb. No `title`: the native tooltip would cover it.
  # --i phases the idle shimmer; stepping by 7 scatters the highlight rather than sweeping
  # it across in reading order.
  Box(
    key = key,
    component = "a",
    className = "hex",
    style = list(
      `--i` = ((slot - 1L) * 7L) %% length(items),
      `--d` = d
    ),
    href = it$href,
    `aria-label` = if (nzchar(desc)) paste0(it$slug, ": ", desc) else it$slug,
    Box(
      component = "img",
      src = it$img,
      alt = it$slug,
      decoding = "async",
      width = 104,
      height = 120
    ),
    Box(
      component = "span",
      className = "hex-caption",
      `aria-hidden` = "true",
      tags$b(it$slug),
      if (nzchar(desc)) paste0(" \u2014 ", desc) else ""
    )
  )
}

#' The package honeycomb
#'
#' A comb of package stickers, plus exactly one empty slot: a dashed hex linking to GitHub,
#' saying the next package goes here.
#'
#' The components are handed the answers rather than the algebra - [mui_hex_layout()] decides
#' the shape and the stylesheet sizes the cells from the fractions it is given. The comb is
#' the one part of the site that keeps its stylesheet: clip-path cells, rows nested by
#' negative margins, a bloom-in fanned out along `--d` and an idle shimmer phased by `--i`
#' are what CSS is for, and restating them as `sx` would buy nothing. What is muiMaterial
#' here is the markup.
#'
#' Which items these are is configuration: the comb is filled by the section that sets
#' `hero: true` in `mui.config.yml`, and an item with no image is skipped, since a sticker is
#' the one thing a cell cannot do without.
#'
#' @param items Items of the hero section.
#' @param label What the comb is a comb of, for its `aria-label`.
#' @inheritParams mui_theme
#' @return A `muiMaterial` component, or `NULL` when there is nothing to draw.
#' @family home
#' @keywords internal
mui_hex_grid <- function(items, config = mui_config(), label = "Projects") {
  items <- Filter(
    Negate(is.null),
    lapply(items, function(it) {
      if (is.null(it$image)) {
        return(NULL)
      }
      list(
        img = it$image,
        slug = it$slug %||% it$title,
        href = it$primary$href %||% "#",
        desc = it$description
      )
    })
  )
  if (!length(items)) {
    return(NULL)
  }
  lay <- mui_hex_layout(length(items))
  rows <- hex_split(length(items), lay)

  mid_row <- (length(rows) - 1) / 2
  row_boxes <- lapply(seq_along(rows), function(r) {
    slots <- rows[[r]]
    mid_col <- (length(slots) - 1) / 2
    Box(
      key = r,
      className = "hexrow",
      lapply(seq_along(slots), function(c) {
        # 0.87 puts a row step into the same unit as a column step.
        d <- round(sqrt((c - 1 - mid_col)^2 + ((r - 1 - mid_row) * 0.87)^2))
        # Keyed by position rather than by package: a blank and the empty slot have no
        # identity of their own, and the lattice position is what React is diffing.
        hex_cell(slots[c], paste(r, c, sep = "-"), d, items, config)
      })
    )
  })

  # --hex-box is the width the shape would like, which .hexgrid takes as a ceiling; the
  # fractions size cells and gaps from whatever width it settles on; --hex-aspect lets the
  # stacked phone layout turn the height it can spare back into a width.
  Box(
    component = "nav",
    className = "hexgrid",
    `aria-label` = label,
    style = list(
      `--hex-n` = length(items),
      `--hex-box` = paste0(lay$box, "px"),
      `--hex-aspect` = format(lay$aspect),
      `--hex-cell-f` = format(lay$cell_f),
      `--hex-gap-f` = format(lay$gap_f)
    ),
    row_boxes
  )
}
