# The single MUI theme for the whole site, and the single reading of its palette. The site
# renders in two halves - the MUI components, and the CSS that styles the markdown body and
# the honeycomb - and both need the same colours. Neither declares them: the palette lives
# in the configuration (see R/config.R), mui_theme() feeds the MUI half from it, and
# mui_css_root_vars() emits the same values as custom properties for the CSS half.

#' The palette as CSS custom properties
#'
#' The same colours [mui_theme()] gives the MUI half of the site, emitted as `:root`
#' custom properties for the half the stylesheet still draws - the markdown body and the
#' honeycomb. Written into `<head>` at build time so those paint in the right colours on the
#' first frame rather than after a stylesheet round-trip.
#'
#' Both halves name colours by role (`--site-ink`, `--site-bg`, `--site-primary`) rather
#' than by hue, so a colour can be repointed in the configuration without touching CSS. The
#' `--site-` prefix keeps these clear of `--mui-palette-*`, which MUI owns in its
#' CSS-variables mode, and of whatever a site adds in its own stylesheet.
#'
#' @inheritParams mui_theme
#' @return A `<style>` element, as a string.
#' @family theme
#' @keywords internal
mui_css_root_vars <- function(config = mui_config()) {
  schemes <- site_schemes(config)
  # The fonts are not a scheme's business, so they are written once with the first one.
  blocks <- vapply(
    seq_along(schemes),
    function(i) {
      body <- scheme_css_vars(config, schemes[i], fonts = i == 1L)
      # The first scheme is the ground: it paints before any media query is consulted, so
      # it goes on a bare :root. A second can only be the dark one, and it arrives behind
      # the query that asks for it.
      if (i == 1L) {
        sprintf(":root{%s}", body)
      } else {
        sprintf("@media (prefers-color-scheme:dark){:root{%s}}", body)
      }
    },
    character(1)
  )
  paste0("<style>", paste0(blocks, collapse = ""), "</style>")
}

# One scheme's custom properties. `color-scheme` is in here rather than in the stylesheet
# because it is the one declaration that changes what the *browser* draws - form controls,
# scrollbars and the canvas behind the page - and getting that wrong is a white flash on a
# dark page before the first paint.
scheme_css_vars <- function(config, scheme = "light", fonts = TRUE) {
  p <- site_palette(config, scheme)
  f <- config$theme$fonts
  vars <- c(
    "color-scheme" = scheme,
    bg = p$background,
    paper = p$paper,
    ink = p$text_primary,
    muted = p$text_secondary,
    "ink-strong" = p$ink_strong,
    "ink-rgb" = p$ink_rgb,
    line = rgba(p$ink_rgb, 0.12),
    "text-on-dark" = p$text_on_dark,
    "code-bg" = p$code_bg,
    pill = p$pill,

    primary = p$primary,
    "primary-dark" = p$primary_dark,
    accent = p$accent,
    # The primary as bare channels, for the one rule that puts its own alpha on it (the
    # hero wash). Without this the stylesheet would have to hard-code the brand colour.
    "primary-rgb" = hex_channels(p$primary),
    # The ground as bare channels, for the app bar's translucent wash.
    "bg-rgb" = hex_channels(p$background),
    if (fonts) c(sans = f$sans, serif = f$serif, mono = f$mono)
  )
  # `color-scheme` is a real CSS property, not one of ours, so it alone loses the prefix.
  names <- ifelse(
    names(vars) == "color-scheme",
    "color-scheme",
    paste0("--site-", names(vars))
  )
  paste0(sprintf("%s:%s", names, vars), collapse = ";")
}


#' The site's MUI theme
#'
#' The single theme every MUI component on the site renders under: palette, shape,
#' typography, and the component overrides that make a Card, an Accordion and an AppBar
#' look like this site rather than like stock Material Design.
#'
#' Its colours are read from `config`, not declared here, because the half of the site that
#' MUI does not render needs the same ones - see [mui_css_root_vars()].
#'
#' `theme.mode: auto` emits *both* schemes, as MUI `colorSchemes` under
#' `cssVariables$colorSchemeSelector = "media"`: MUI then writes one set of CSS variables per
#' scheme and switches them on `prefers-color-scheme`, with no toggle, no stored preference
#' and no script. The component overrides below name `var(--site-*)` rather than a colour for
#' the same reason - a hex baked into a `styleOverride` would stay light in the dark scheme.
#'
#' @param config The site configuration; see [mui_read_config()].
#' @return A theme list, ready for `muiMaterial::ThemeProvider()`.
#' @family theme
#' @export
#' @examples
#' theme <- mui_theme()
#' theme$colorSchemes$light$palette$primary$main
#' theme$typography$kicker
mui_theme <- function(config = mui_config()) {
  f <- config$theme$fonts
  schemes <- list()
  for (s in site_schemes(config)) {
    schemes[[s]] <- list(palette = mui_palette(config, s))
  }
  c(
    list(
      # Both schemes, always under the same key, so nothing downstream has to ask which
      # shape the theme came out in. A pinned mode simply emits one of them.
      colorSchemes = schemes,

      # "media" is what makes the switch happen in CSS rather than in JavaScript: MUI writes
      # the dark variables behind a `prefers-color-scheme` query instead of behind a class it
      # would have to set on mount.
      cssVariables = list(colorSchemeSelector = "media"),
      shape = list(borderRadius = 14)
    ),
    mui_theme_rest(f)
  )
}

# One scheme's MUI palette node.
mui_palette <- function(config, scheme = "light") {
  p <- site_palette(config, scheme)
  list(
    mode = scheme,
    primary = list(
      main = p$primary,
      dark = p$primary_dark,
      light = p$primary_light
    ),
    background = list(default = p$background, paper = p$paper),
    text = list(primary = p$text_primary, secondary = p$text_secondary),
    divider = rgba(p$ink_rgb, 0.12),
    # A custom palette node. MUI resolves palette paths in `sx`, so the label colour is
    # reachable as color = "kicker" without any of it reaching the stylesheet. One accent
    # for every kicker on the site, whatever band it sits in.
    kicker = p$accent
  )
}

# Everything in the theme that is not a colour: the type, and the component overrides. Split
# out because the palette above is per-scheme and this is not - and because a `styleOverride`
# that did depend on the scheme would be a bug, not a case to handle.
mui_theme_rest <- function(f) {
  list(
    typography = list(
      fontFamily = f$sans,
      h1 = list(
        fontFamily = f$serif,
        fontWeight = 600,
        letterSpacing = "-0.02em"
      ),
      h2 = list(
        fontFamily = f$serif,
        fontWeight = 600,
        letterSpacing = "-0.015em"
      ),
      h3 = list(fontFamily = f$serif, fontWeight = 600),
      h5 = list(
        fontWeight = 600,
        fontSize = "1.05rem",
        letterSpacing = "-0.01em"
      ),
      h6 = list(fontFamily = f$serif, fontWeight = 600),
      button = list(textTransform = "none", fontWeight = 500),
      # Two variants of our own. Declaring them here is what lets a component ask for
      # Typography(variant = "kicker") and inherit the whole definition.
      kicker = list(
        fontFamily = f$mono,
        fontSize = "0.72rem",
        fontWeight = 600,
        letterSpacing = "0.14em",
        textTransform = "uppercase"
      ),
      mono = list(fontFamily = f$mono, fontSize = "0.85rem", lineHeight = 1.6)
    ),
    components = list(
      # An unmapped variant would render as <span>; these keep the markup meaningful.
      MuiTypography = list(
        defaultProps = list(
          variantMapping = list(
            kicker = "p",
            mono = "span"
          )
        )
      ),
      MuiCard = list(
        styleOverrides = list(
          root = list(
            border = "1px solid rgba(var(--site-ink-rgb),0.11)",
            boxShadow = "none",
            transition = "border-color .18s ease, transform .18s ease, box-shadow .18s ease",
            height = "100%",
            display = "flex",
            flexDirection = "column",
            # The primary on every card, in every band: hover is the site's one interactive
            # colour, the same one the buttons and links use.
            "&:hover" = list(
              borderColor = "var(--site-primary)",
              transform = "translateY(-3px)",
              boxShadow = "0 12px 28px -14px rgba(var(--site-ink-rgb),0.3)"
            )
          )
        )
      ),
      # Outlined by default, so a Paper never arrives with a shadow the page does not use.
      MuiPaper = list(defaultProps = list(elevation = 0)),
      MuiButton = list(defaultProps = list(disableElevation = TRUE)),
      MuiDivider = list(
        styleOverrides = list(
          root = list(borderColor = "rgba(var(--site-ink-rgb),0.1)")
        )
      ),
      MuiLink = list(defaultProps = list(underline = "hover")),
      MuiListItemButton = list(
        styleOverrides = list(
          root = list(
            borderRadius = 10,
            paddingTop = 14,
            paddingBottom = 14,
            "&:hover" = list(
              backgroundColor = "rgba(var(--site-ink-rgb),0.035)"
            )
          )
        )
      ),
      # MUI draws an Accordion as a stack of cards: a shadow, corners that square up when it
      # opens, a top margin that appears on expand, and a `:before` standing in for the
      # divider. All of that is switched off here, leaving a real borderBottom, so an
      # expanding row does not rearrange the rows around it.
      MuiAccordion = list(
        defaultProps = list(disableGutters = TRUE, square = TRUE),
        styleOverrides = list(
          root = list(
            backgroundColor = "transparent",
            boxShadow = "none",
            borderBottom = "1px solid rgba(var(--site-ink-rgb),0.12)",
            "&:before" = list(display = "none"),
            "&:last-of-type" = list(borderBottom = "none")
          )
        )
      ),
      # The chevron is nudged up so it sits on the first line of a title that wraps to two,
      # rather than floating in the middle of the row.
      MuiAccordionSummary = list(
        styleOverrides = list(
          root = list(
            paddingLeft = 8,
            paddingRight = 8,
            borderRadius = 10,
            "&:hover" = list(
              backgroundColor = "rgba(var(--site-ink-rgb),0.035)"
            )
          ),
          content = list(marginTop = 14, marginBottom = 14),
          expandIconWrapper = list(
            alignSelf = "flex-start",
            marginTop = 10,
            opacity = 0.55
          )
        )
      ),
      MuiAccordionDetails = list(
        styleOverrides = list(
          root = list(
            paddingLeft = 8,
            paddingRight = 8,
            paddingTop = 0,
            paddingBottom = 24
          )
        )
      ),
      MuiAppBar = list(
        styleOverrides = list(
          root = list(
            backgroundColor = "rgba(var(--site-bg-rgb),0.82)",
            backdropFilter = "saturate(180%) blur(12px)",
            color = "var(--site-ink-strong)",
            boxShadow = "none",
            borderBottom = "1px solid rgba(var(--site-ink-rgb),0.11)"
          )
        )
      )
    )
  )
}

