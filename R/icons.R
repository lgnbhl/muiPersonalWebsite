# The site's icons, all drawn inline as SVG rather than pulled from an icon font: a handful
# of paths are not worth a webfont, and an inline path paints with the first frame.

# A profile from `social`, by name.
social_entry <- function(name, config = mui_config()) {
  hit <- Filter(function(s) identical(s$name, name), config$social)
  if (length(hit)) hit[[1]] else NULL
}

# The glyph for a profile: the one its `social` entry carries, or this package's own. The
# configuration is consulted first, so a site can add a brand this package has never heard
# of - or replace one it draws badly - with an `icon: {box, d}` block and no R at all.
social_glyph <- function(name, config = mui_config()) {
  social_entry(name, config)$icon %||% SOCIAL_ICONS[[name]]
}

# The profiles the bar shows a mark for, in the order `social` lists them, minus any there
# is no glyph for. A profile with no icon is not lost - the footer names every one in words.
social_icon_names <- function(config = mui_config()) {
  Filter(
    function(n) !is.null(social_glyph(n, config)),
    vapply(config$social, function(s) s$name %||% "", character(1))
  )
}

# The profile links in words: the hero's row, and the footer's. One helper for both, since
# the two rows differ only in how they are styled - `sx` is the caller's business.
#
# Nothing is escaped here. These cross the React bridge as props, which are JSON-encoded;
# the hand-rolled escaping this replaced was what plain HTML needed.
social_links <- function(entries, sx = NULL) {
  lapply(entries, function(s) {
    Link(
      key = s$name,
      href = s$href,
      rel = "me noopener",
      target = "_blank",
      underline = "none",
      color = "inherit",
      sx = sx,
      s$name
    )
  })
}

# The brands this package can draw. Filled shapes, so they take `fill: currentColor` and
# inherit the button's colour. The table is deliberately short and is not the limit: a
# `social` entry can carry its own `icon: {box, d}` - see social_glyph().
SOCIAL_ICONS <- list(
  LinkedIn = list(
    box = "0 0 24 24",
    d = paste0(
      "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445",
      "-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 ",
      "4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064",
      " 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774",
      " 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24",
      " .774 23.2 0 22.222 0h.003z"
    )
  ),
  GitHub = list(
    box = "0 0 16 16",
    d = paste0(
      "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82",
      "-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53",
      ".63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64",
      "-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64",
      "-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12",
      ".51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 ",
      "1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"
    )
  ),
  # Not a brand mark: a plain envelope, for the `mailto:` most people want in this row.
  Email = list(
    box = "0 0 24 24",
    d = paste0(
      "M2 5.5A2.5 2.5 0 0 1 4.5 3h15A2.5 2.5 0 0 1 22 5.5v13a2.5 2.5 0 0 1-2.5 2.5h-15A2.5 ",
      "2.5 0 0 1 2 18.5v-13zm2.2-.3 7.8 5.7 7.8-5.7a.5.5 0 0 0-.3-.1h-15a.5.5 0 0 0-.3.1zM20",
      " 7.4l-7.4 5.4a1 1 0 0 1-1.2 0L4 7.4v11.1c0 .3.2.5.5.5h15c.3 0 .5-.2.5-.5V7.4z"
    )
  ),
  YouTube = list(
    box = "0 0 24 24",
    d = paste0(
      "M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0",
      "-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 ",
      "3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015",
      " 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818",
      " 12l-6.273 3.568z"
    )
  )
)

# Built from tags rather than HTML() so the glyph crosses the React bridge as an element.
social_icon <- function(name, size = 19, config = mui_config()) {
  ic <- social_glyph(name, config)
  tags$svg(
    viewBox = ic$box %||% "0 0 24 24",
    width = size,
    height = size,
    fill = "currentColor",
    `aria-hidden` = "true",
    tags$path(d = ic$d)
  )
}

# One icon button: a real <a> with the same off-site treatment the nav links get.
social_icon_button <- function(name, config = mui_config()) {
  IconButton(
    key = name,
    component = "a",
    href = social_entry(name, config)$href,
    target = "_blank",
    rel = "me noopener",
    size = "small",
    color = "inherit",
    `aria-label` = name,
    sx = list(
      opacity = 0.7,
      "&:hover" = list(opacity = 1, backgroundColor = "background.paper")
    ),
    social_icon(name, config = config)
  )
}

# Built from tags rather than HTML(), for the same reason chevron_icon() is: it crosses the
# React bridge into an IconButton, and an element survives that trip intact.
menu_icon <- function() {
  tags$svg(
    width = 22,
    height = 22,
    viewBox = "0 0 24 24",
    fill = "none",
    stroke = "currentColor",
    `stroke-width` = "1.8",
    `stroke-linecap` = "round",
    `aria-hidden` = "true",
    tags$path(d = "M4 7h16M4 12h16M4 17h16")
  )
}

# The one chevron on the site: the hero's scroll cue and the talk accordion's expand icon.
# Built from tags rather than HTML() so it crosses the React bridge as an element - MUI
# rotates it by styling the wrapper it puts around it.
chevron_icon <- function(size = 20) {
  tags$svg(
    viewBox = "0 0 24 24",
    width = size,
    height = size,
    fill = "none",
    stroke = "currentColor",
    `stroke-width` = "2",
    `stroke-linecap` = "round",
    `stroke-linejoin` = "round",
    `aria-hidden` = "true",
    tags$path(d = "M6 9l6 6 6-6")
  )
}
