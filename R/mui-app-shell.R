# The page chrome, in muiMaterial: the sticky app bar, the mobile drawer, and the shell
# every page is assembled into. The nav entries and the profiles are content, so they live
# in mui.config.yml; what is here is how they are laid out.

# Where a nav entry points: an off-site href as given, or a bare fragment. Bare rather than
# "/#packages", so the browser treats it as a same-document jump and scrolls smoothly
# instead of reloading. <html> carries scroll-behavior: smooth, so there is no script here.
nav_href <- function(n, config = mui_config()) {
  if (!is.null(n$href)) expand_base(n$href, config) else paste0("#", n$anchor)
}

# The section tabs, in the order the page lays the bands out. Nothing here names a section:
# rename one in mui.config.yml and the band, the tab, its anchor and the hero's scroll cue
# all move together, because all four read the same `id`.
section_nav <- function(config = mui_config()) {
  lapply(Filter(function(s) !is.null(s$nav), config$sections), function(s) {
    list(text = s$nav, anchor = s$id)
  })
}

# What the bar shows on a given page. The section tabs appear only where the sections do:
# the bands are rendered by React, so their ids do not exist while the browser is resolving
# the fragment it was loaded with, and a cold "/#packages" would land at the top and stay
# there. Off the landing page the wordmark is the way back.
nav_items <- function(home, config = mui_config()) {
  if (home) c(section_nav(config), config$nav_links) else config$nav_links
}

# Read off the href rather than declared per entry, so a nav item cannot disagree with
# where it points.
nav_link_props <- function(n) {
  if (grepl("^https?://", nav_href(n))) {
    list(target = "_blank", rel = "noopener")
  } else {
    list()
  }
}

#' The site's app bar and mobile drawer
#'
#' A sticky bar carrying the wordmark, the section tabs, the profile icons and - on a
#' phone, where the bar has room for nothing else - a hamburger opening the drawer.
#'
#' @inheritParams mui_app_shell
#' @return A `muiMaterial` component.
#' @family shell
#' @keywords internal
mui_app_bar <- function(home = FALSE, config = mui_config()) {
  AppBar(
    position = "sticky",
    Toolbar(
      sx = list(
        gap = 0.5,
        maxWidth = 1100,
        width = "100%",
        mx = "auto",
        px = list(xs = 2, md = 3)
      ),
      # The masthead is also the way back to the top, which is why no nav entry has to be.
      Link(
        href = if (home) "#top" else paste0(site_base(config), "/"),
        underline = "none",
        color = "inherit",
        sx = list(
          fontFamily = font("serif", config),
          fontWeight = 600,
          fontSize = "1.05rem",
          mr = "auto"
        ),
        config$wordmark %||% config$title
      ),
      Box(
        sx = list(display = list(xs = "none", sm = "flex"), gap = 0.25),
        lapply(nav_items(home, config), function(n) {
          do.call(
            Button,
            c(
              list(
                key = n$text,
                href = nav_href(n, config),
                size = "small",
                color = "inherit",
                # `data-nav` is what the scroll spy matches a band's id against; an off-site
                # entry has no band and so carries none. The `.is-current` rule that lights
                # the tab up lives in site.css, next to the spy that sets it.
                `data-nav` = n$anchor,
                className = "nav-tab",
                sx = list(
                  fontWeight = 400,
                  opacity = 0.75,
                  "&:hover" = list(
                    backgroundColor = "background.paper",
                    opacity = 1
                  )
                )
              ),
              nav_link_props(n),
              list(n$text)
            )
          )
        })
      ),
      Box(
        sx = list(
          display = list(xs = "none", sm = "flex"),
          gap = 0.25,
          ml = 0.5
        ),
        lapply(social_icon_names(config), social_icon_button, config = config)
      ),
      IconButton(
        id = "nav-trigger",
        color = "inherit",
        `aria-label` = "Open navigation",
        sx = list(display = list(xs = "inline-flex", sm = "none"), mr = -1),
        menu_icon()
      )
    )
  )
}

# `.triggerId`, not `.shinyInput`: the open state stays inside React, which is what makes
# it work on a static page with no Shiny server behind it.
#' @rdname mui_app_bar
#' @keywords internal
mui_nav_drawer <- function(home = FALSE, config = mui_config()) {
  Drawer.triggerId(
    triggerId = "nav-trigger",
    anchor = "right",
    width = 240,
    Box(
      sx = list(pt = 1),
      List(
        lapply(nav_items(home, config), function(n) {
          do.call(
            ListItemButton,
            c(
              list(key = n$text, component = "a", href = nav_href(n, config)),
              nav_link_props(n),
              list(ListItemText(
                primary = n$text,
                slotProps = list(primary = list(sx = list(fontSize = "1rem")))
              ))
            )
          )
        })
      ),
      # The same profiles the bar shows on a wider screen, as a row under the links.
      Box(
        sx = list(display = "flex", gap = 0.5, px = 2, pt = 1),
        lapply(social_icon_names(config), social_icon_button, config = config)
      )
    )
  )
}

themed <- function(..., config = mui_config()) {
  ThemeProvider(theme = mui_theme(config), ...)
}

#' The page shell
#'
#' Everything every page has: the app bar, the mobile drawer, `<main>`, and the footer - all
#' of it inside one `ThemeProvider`, so every element on the page is a `muiMaterial`
#' component rendering under the site's theme.
#'
#' One themed block rather than two: the chrome used to sit inside it and `<main>` and the
#' footer outside, because plain HTML was what put the page's words in the source. Nothing
#' is outside it now - see the design notes on what `R/seo.R` carries instead.
#'
#' No `useMaterialIconsOutlined`: the site draws its icons as inline SVG precisely so it
#' does not load an icon font.
#'
#' @param body The page's content.
#' @param home Whether this page carries the bands the app bar's anchors point at. Only the
#'   landing page does, and the anchor tabs are hidden everywhere else - a fragment cannot
#'   reach a band that React has not rendered yet.
#' @param bare Drop the width cap from `<main>`, for the home page whose bands run edge to
#'   edge and set their own inner width. Every other page keeps the cap.
#' @inheritParams mui_theme
#' @return A `muiMaterial` page.
#' @family shell
#' @export
mui_app_shell <- function(
  body,
  home = FALSE,
  bare = FALSE,
  config = mui_config()
) {
  # Every muiMaterialPage() flag is left at FALSE, and each for its own reason rather than
  # by default: the site's faces are `theme.fonts`, so Roboto would be a webfont nothing on
  # the page asks for, and the icon flags fetch an icon font this site has no use
  # for - Material Icons has no LinkedIn, GitHub or YouTube mark, and the hamburger and the
  # chevron are one path each (see R/icons.R). What is *not* overridden is `styleBody`: its
  # default is the body margin, which is exactly what the page wants and is why
  # inst/assets/site.css no longer sets one.
  muiMaterialPage(
    useFontRoboto = FALSE,
    themed(
      CssBaseline(),
      # First in the tree, so it is the first thing a keyboard reaches. It is a real link to
      # a real element rather than a scripted focus move; `.skip-link` in site.css is what
      # keeps it off the page until it is focused.
      Link(className = "skip-link", href = "#main", "Skip to content"),
      mui_app_bar(home, config),
      mui_nav_drawer(home, config),
      # `.wrap` is a width cap and nothing else, so it stays in the stylesheet rather than
      # becoming a Container: the home page opts out of it entirely.
      Box(
        id = "main",
        component = "main",
        className = if (bare) NULL else "wrap",
        # A jumped-to <main> has to be focusable or the focus stays on the skip link and the
        # next Tab goes back into the bar.
        tabIndex = -1,
        body
      ),
      mui_footer(config),
      config = config
    )
  )
}
