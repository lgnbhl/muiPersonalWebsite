# The applications band: a list of apps, and the screenshots of the selected one beside it.
# All of its state is MUI's own - a TabContext.static picks the app, a second one inside it
# picks the screenshot, and a Dialog.triggerId owns whether that screenshot is open full
# size. A .shinyInput here would never receive a value: there is no server behind the page.

# A screenshot is `list(src, caption)`. An app that names none falls back to the single
# `image` a card would have shown, flagged as a logo: blown up to fill a 16:10 frame a
# hexagon reads as a mistake rather than a mark.
shot_list <- function(item) {
  shots <- Filter(function(s) !is.null(s$src), item$shots %||% list())
  if (length(shots)) {
    shots
  } else if (!is.null(item$image)) {
    list(list(src = item$image, logo = TRUE))
  } else {
    list()
  }
}

# The tab's value, and the stem of every DOM id on its stage. It has to be there and has to
# be unique, so the title stands in when a content file names no slug.
showcase_key <- function(item) item$slug %||% item$title

# One app, as a row in the list. It is a Tab because a TabList clones its children to hand
# them the selection - a Box wrapped around one would never light up - so the row is drawn
# *as* the Tab. `component = "div"`, because the row holds the app's two links and an <a>
# inside a <button> nests interactive content.
showcase_card <- function(item) {
  Tab(
    key = showcase_key(item),
    value = showcase_key(item),
    component = "div",
    sx = list(
      p = 0,
      maxWidth = "none",
      textTransform = "none",
      textAlign = "left",
      alignItems = "stretch",
      opacity = 1,
      # A tab colours its own text to show the selection. A row does not: its words read the
      # same whichever row is open.
      color = "text.primary",
      borderLeft = "3px solid transparent",
      borderBottom = "1px solid",
      borderBottomColor = "divider",
      "&:first-of-type" = list(
        borderTop = "1px solid",
        borderTopColor = "divider"
      ),
      "&:hover" = list(backgroundColor = "action.hover"),
      "&.Mui-selected" = list(
        color = "text.primary",
        backgroundColor = "action.hover",
        borderLeftColor = "primary.main"
      )
    ),
    label = Box(
      sx = list(px = 2, py = 1.75, width = "100%"),
      Typography(
        variant = "h6",
        component = "h3",
        sx = list(fontSize = "1.05rem", mb = 0.5),
        item$title
      ),
      if (!is.null(item$description)) {
        Typography(
          variant = "body2",
          color = "text.secondary",
          sx = list(lineHeight = 1.55),
          item$description
        )
      },
      if (!is.null(item$primary) || !is.null(item$secondary)) {
        Stack(
          direction = "row",
          spacing = 0.5,
          useFlexGap = TRUE,
          sx = list(flexWrap = "wrap", mt = 1, ml = -1),
          item_actions(item, primary = "text", secondary = "text")
        )
      }
    )
  )
}

# One fixed shape for every app, so the band's height does not move as you click down the
# list. 16:10 is what a browser window is, which is what most of these are pictures of.
STAGE_RATIO <- "16 / 10"

# One screenshot: the frame, its caption, and the dialog that opens it full size. The
# dialog's trigger is the frame itself - .triggerId binds by DOM id, so any element will do.
shot_slide <- function(id, shot, alt) {
  tagList(
    Box(
      id = id,
      sx = list(
        aspectRatio = STAGE_RATIO,
        width = "100%",
        p = 1,
        display = "flex",
        alignItems = "center",
        justifyContent = "center",
        overflow = "hidden",
        cursor = "zoom-in",
        borderRadius = 1.5,
        border = "1px solid",
        borderColor = "divider",
        backgroundColor = "background.paper"
      ),
      # `contain` and not `cover`: a screenshot cropped to fit is one with its point cut off.
      CardMedia(
        component = "img",
        image = shot$src,
        alt = alt,
        loading = "lazy",
        sx = list(
          maxWidth = if (isTRUE(shot$logo)) "45%" else "100%",
          maxHeight = if (isTRUE(shot$logo)) "70%" else "100%",
          width = "auto",
          height = "auto",
          objectFit = "contain",
          display = "block",
          borderRadius = 1
        )
      )
    ),
    Typography(
      variant = "body2",
      color = "text.secondary",
      noWrap = TRUE,
      align = "center",
      sx = list(mt = 1, minHeight = 22),
      shot$caption %||% ""
    ),
    Dialog.triggerId(
      triggerId = id,
      maxWidth = "lg",
      DialogContent(
        sx = list(p = 0, lineHeight = 0),
        CardMedia(
          component = "img",
          image = shot$src,
          alt = alt,
          sx = list(width = "100%", height = "auto")
        )
      )
    )
  )
}

# A dot under the stage, one per screenshot. The mark is a child rather than the tab
# itself, so the tab keeps a finger-sized hit area around an eight-pixel dot.
shot_dot <- function(i) {
  Tab(
    key = i,
    value = as.character(i),
    `aria-label` = paste("Screenshot", i),
    sx = list(
      minWidth = 0,
      minHeight = 0,
      p = 1,
      opacity = 1,
      "&.Mui-selected .shot-mark" = list(backgroundColor = "primary.main"),
      "&:hover .shot-mark" = list(backgroundColor = "primary.light")
    ),
    label = Box(
      className = "shot-mark",
      sx = list(
        width = 8,
        height = 8,
        borderRadius = "50%",
        backgroundColor = "divider"
      )
    )
  )
}

# The screenshots of one app: a panel each, and a row of dots to switch between them. A
# strip of links would put a hash in the address bar and the browser would scroll the page
# to answer it, so this is a TabContext.static of its own instead.
shot_stage <- function(item) {
  shots <- shot_list(item)
  if (!length(shots)) {
    return(NULL)
  }
  key <- showcase_key(item)

  panels <- lapply(seq_along(shots), function(i) {
    TabPanel(
      key = i,
      value = as.character(i),
      sx = list(p = 0),
      shot_slide(
        paste0("shot-", key, "-", i),
        shots[[i]],
        shots[[i]]$caption %||% item$title %||% ""
      )
    )
  })

  TabContext.static(
    defaultValue = "1",
    Box(sx = list(width = "100%", minWidth = 0), panels),
    if (length(shots) > 1L) {
      TabList.static(
        `aria-label` = "Screenshots",
        sx = list(
          minHeight = 0,
          mt = 1,
          # The indicator is a rule under the selected tab, which is not what a dot looks like.
          "& .MuiTabs-indicator" = list(display = "none"),
          "& .MuiTabs-flexContainer" = list(justifyContent = "center")
        ),
        lapply(seq_along(shots), shot_dot)
      )
    }
  )
}

#' The applications band
#'
#' A list of applications, and the screenshots of the selected one on a stage beside it. An
#' application is worth looking at for what it looks like, and a card in a grid shows one
#' strip of it.
#'
#' Which app is showing is MUI's own state - `TabContext.static`, the way the talks accordion
#' and the mobile drawer are - so the band needs no server and no script. So is which
#' screenshot: each one is a `TabPanel` of a second `TabContext.static`, switched by the dots
#' under the stage. The stage is one fixed 16:10 shape for every app, so the band's height
#' does not move as you click down the list, and each screenshot is fitted into it rather
#' than cropped to it. Clicking a screenshot opens it full size in a `Dialog.triggerId`.
#'
#' @param items Application items: `slug`, `title`, `description`, `primary`, `secondary`,
#'   and a `shots` list of `src` and optional `caption`. An item with no `shots` falls back
#'   to its `image`.
#' @return A `muiMaterial` component.
#' @family home
#' @export
#' @examples
#' mui_showcase(list(list(slug = "app", title = "An app",
#'                        shots = list(list(src = "/assets/app.png")))))
mui_showcase <- function(items) {
  if (!length(items)) {
    return(NULL)
  }
  # The key is the tab's value: without one the row can never be selected, and the band
  # would render as a list that does nothing when clicked.
  if (any(vapply(items, function(it) is.null(showcase_key(it)), logical(1)))) {
    stop(
      "site: every showcase item needs a `slug` or a `title` - it is what selects the app",
      call. = FALSE
    )
  }
  TabContext.static(
    # defaultValue, not value: `value` is MUI's controlled mode, and without an onChange to
    # write the new tab back it would render the first app and then refuse to move.
    defaultValue = showcase_key(items[[1]]),
    Grid(
      container = TRUE,
      spacing = list(xs = 3, md = 4),
      Grid(
        size = list(xs = 12, md = 5),
        # Not `variant = "scrollable"`: it hangs a chevron button above and below the list
        # whether or not there is anything to scroll to.
        TabList.static(
          orientation = "vertical",
          sx = list(
            # A tab list's own furniture, taken off: the rows show the selection themselves,
            # and they are divided by their own hairline rather than by air.
            "& .MuiTabs-indicator" = list(display = "none"),
            "& .MuiTabs-flexContainer" = list(gap = 0)
          ),
          lapply(items, showcase_card)
        )
      ),
      # minWidth = 0, or the Grid column is as wide as its widest content rather than seven
      # twelfths. The stage carries no words of its own - the row that selected it, beside
      # it, is where the app is named. `p = 0`, because TabPanel's own padding is MUI's
      # dialog-sized 24px and the stage sits beside a list, not in a box.
      Grid(
        size = list(xs = 12, md = 7),
        sx = list(minWidth = 0),
        lapply(items, function(item) {
          TabPanel(
            key = showcase_key(item),
            value = showcase_key(item),
            sx = list(p = 0),
            shot_stage(item)
          )
        })
      )
    )
  )
}
