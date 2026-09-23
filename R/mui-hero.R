# The hero: the page's opening screen, in muiMaterial.
#
# Its words are the site's own, so they live under `hero` in mui.config.yml. What stays in
# the stylesheet is the layout - `.hero` carries a `100svh` min-height with a `100vh`
# fallback, which is two declarations of one property and so cannot be written as `sx`, and
# the 900px breakpoint that moves the honeycomb alongside the copy couples `.hero-copy` to
# `.hexgrid`. The type, the colour and the scroll cue are the theme's.

#' The hero
#'
#' The greeting, the name, the role, the lead, the profile links, the honeycomb of package
#' stickers and the scroll cue.
#'
#' The footer carries every profile; the hero shows the ones `hero_social` names. The scroll
#' cue is a real link to a real band, so it is reachable by keyboard - the smooth scroll is
#' CSS on `<html>`.
#'
#' @param items Items of the hero section, for the honeycomb.
#' @inheritParams mui_theme
#' @return A `muiMaterial` component.
#' @family home
#' @keywords internal
mui_hero <- function(items = list(), config = mui_config()) {
  h <- config$hero
  cue <- scroll_cue_section(config)
  comb <- Filter(
    function(s) identical(s$id, hero_section_id(config)),
    config$sections
  )
  shown <- Filter(
    function(s) s$name %in% (config$hero_social %||% character()),
    config$social
  )

  Box(
    component = "header",
    className = "hero",
    # The width cap sits here rather than on each child. It used to be `.hero-copy > *` in
    # the stylesheet, but every child is a Typography now, and MUI gives those a `margin: 0`
    # that emotion injects after site.css - which would win the tie and drop the auto side
    # margins that did the centring.
    Box(
      className = "hero-copy",
      sx = list(width = "100%", maxWidth = 980, mx = "auto"),
      # Serif to match the h1 it introduces, and deliberately quiet, so the name below
      # carries the page.
      Typography(
        color = "text.secondary",
        sx = list(
          fontFamily = font("serif", config),
          fontSize = "clamp(1.1rem, 1rem + 0.5vw, 1.45rem)",
          mb = 0.75
        ),
        h$greeting %||% ""
      ),
      # The ceiling is bounded by the nowrap: the name runs about 7.2em at this tracking, so
      # 5rem needs ~576px. The column beside the honeycomb is 602px at 1440px, which leaves
      # that a little room. Wider and the name would collide with the comb.
      Typography(
        variant = "h1",
        sx = list(
          fontSize = "clamp(1.95rem, 0.5rem + 6.4vw, 5rem)",
          lineHeight = 1.05,
          letterSpacing = "-0.04em",
          whiteSpace = "nowrap",
          mb = 1.5
        ),
        h$name %||% config$title
      ),
      Typography(
        color = "text.secondary",
        sx = list(
          fontSize = "0.82rem",
          fontWeight = 600,
          letterSpacing = "0.14em",
          textTransform = "uppercase",
          mb = 3.25
        ),
        h$role %||% ""
      ),
      Typography(
        color = "text.secondary",
        sx = list(
          fontSize = "clamp(1.1rem, 1rem + 0.4vw, 1.28rem)",
          lineHeight = 1.6,
          maxWidth = "40em",
          mb = 4,
          # Two even lines beat one long line and one short one at this measure.
          textWrap = "balance",
          # The lead is authored with emphasis in it, so the strong it carries is styled
          # here rather than left at the browser's default weight.
          "& strong" = list(color = "text.primary", fontWeight = 600)
        ),
        h$lead %||% ""
      ),
      Stack(
        component = "nav",
        `aria-label` = "Elsewhere",
        direction = "row",
        useFlexGap = TRUE,
        flexWrap = "wrap",
        spacing = 1,
        sx = list(justifyContent = "center"),
        social_links(
          shown,
          sx = c(PILL_RING, list(fontSize = "0.85rem", px = 1.75, py = 0.625))
        )
      )
    ),
    mui_hex_grid(
      items,
      config,
      label = if (length(comb)) comb[[1]]$title %||% "Projects" else "Projects"
    ),
    # A real link to a real band, so it works by keyboard and needs no script. The bob
    # animates the svg rather than the anchor, whose transform does the centring;
    # `hero-bob` is declared in site.css, next to its reduced-motion opt-out.
    IconButton(
      component = "a",
      href = paste0("#", cue$id %||% "top"),
      `aria-label` = paste(
        "Scroll to",
        tolower(cue$title %||% cue$id %||% "the page")
      ),
      sx = c(
        PILL_RING,
        list(
          position = "absolute",
          bottom = 18,
          left = "50%",
          transform = "translateX(-50%)",
          width = 44,
          height = 44,
          "& svg" = list(animation = "hero-bob 2.4s ease-in-out infinite"),
          "@media (prefers-reduced-motion: reduce)" = list(
            "& svg" = list(animation = "none")
          )
        )
      ),
      chevron_icon(24)
    )
  )
}

# The ring the hero draws its profile links and its scroll cue with: a hairline on a
# translucent ground that takes the site's one interactive colour on hover. Shared, so the
# two cannot drift apart; each adds its own size, since one is a pill of text and the other
# a 44px circle.
PILL_RING <- list(
  color = "text.secondary",
  border = "1px solid",
  borderColor = "divider",
  borderRadius = "999px",
  # A translucent mat, not a colour: on the cream ground it is the white of a card at half
  # strength, and on the dark one the same gesture in reverse. The palette names it, because
  # "white" is only right in one of the two schemes.
  backgroundColor = "var(--site-pill)",
  transition = "color .15s ease, border-color .15s ease, background-color .15s ease",
  "&:hover" = list(
    color = "primary.main",
    borderColor = "primary.main",
    backgroundColor = "background.paper"
  )
)
