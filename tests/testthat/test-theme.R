# The theme carries one palette per colour scheme, always under `colorSchemes`, so a check
# has to name the scheme it means. Every check below names the light one unless it is about
# the dark scheme in particular.
light_palette <- function(theme) theme$colorSchemes$light$palette

test_that("the theme reads its colours from the configuration", {
  config <- modifyList(mui_default_config(),
                    list(title = "T", url = "https://e.com"))
  config$theme$palette$primary <- "#123456"
  theme <- mui_theme(config)
  expect_equal(light_palette(theme)$primary$main, "#123456")
  expect_equal(light_palette(theme)$background$default, config$theme$palette$background)
  expect_equal(theme$typography$fontFamily, config$theme$fonts$sans)
})

test_that("auto emits both schemes and a pinned mode emits only the one", {
  # `colorSchemes` plus a "media" selector is what makes MUI switch in CSS rather than in
  # JavaScript - no toggle, no stored preference, nothing to run on mount.
  config <- mui_default_config()
  config$title <- "T"; config$url <- "https://e.com"

  auto <- mui_theme(config)
  expect_setequal(names(auto$colorSchemes), c("light", "dark"))
  expect_equal(auto$cssVariables$colorSchemeSelector, "media")
  expect_equal(auto$colorSchemes$dark$palette$mode, "dark")

  for (mode in c("light", "dark")) {
    pinned <- config; pinned$theme$mode <- mode
    expect_equal(names(mui_theme(pinned)$colorSchemes), mode)
  }
})

test_that("the dark scheme is the light one with only its differences named", {
  # `palette_dark` names what changes; everything it is silent about it inherits. That is
  # what stops the dark scheme from quietly missing a colour when a new one is added.
  config <- mui_default_config()
  light <- site_palette(config, "light")
  dark  <- site_palette(config, "dark")

  expect_setequal(names(light), names(dark))
  expect_false(identical(light$background, dark$background))
  # Not named in palette_dark, so it is inherited rather than dropped.
  expect_equal(dark$text_on_dark, light$text_on_dark)

  # The roles hold: on a dark ground the hairline ink is a light one, or every rule drawn
  # with it would be invisible.
  expect_equal(dark$ink_rgb, "232,226,220")
})

test_that("both schemes reach the stylesheet, the second behind a media query", {
  config <- mui_default_config()
  vars <- mui_css_root_vars(config)
  expect_match(vars, "@media (prefers-color-scheme:dark)", fixed = TRUE)
  expect_match(vars, paste0("--site-bg:", site_palette(config, "light")$background),
               fixed = TRUE)
  expect_match(vars, paste0("--site-bg:", site_palette(config, "dark")$background),
               fixed = TRUE)
  # `color-scheme` is a real CSS property and keeps its own name; it is what stops the
  # browser painting a white canvas behind a dark page before the first frame.
  expect_match(vars, "color-scheme:dark", fixed = TRUE)

  # A pinned mode writes one block and no query at all.
  pinned <- config; pinned$theme$mode <- "light"
  expect_false(grepl("prefers-color-scheme", mui_css_root_vars(pinned), fixed = TRUE))
})

test_that("no component override bakes in a colour that cannot follow the scheme", {
  # A styleOverride is written once and used under both schemes, so a hex in one is a light
  # colour surviving into the dark page. They name var(--site-*) instead, and this is what
  # says so - the same argument mui_css_root_vars() exists for, one level down.
  flat <- unlist(mui_theme(mui_default_config())$components)
  hexes <- grep("#[0-9a-fA-F]{6}", flat, value = TRUE)
  expect_length(hexes, 0)
})


test_that("the MUI theme and the CSS custom properties agree on the palette", {
  # The invariant the single-source design exists for: the site renders in two halves and
  # both must paint the same colours. A colour defined twice is a colour that drifts.
  config <- mui_read_config(test_path("fixtures/mui.config.yml"))
  theme <- mui_theme(config)
  vars  <- mui_css_root_vars(config)

  for (scheme in names(theme$colorSchemes)) {
    p <- theme$colorSchemes[[scheme]]$palette
    expect_match(vars, paste0("--site-primary:", p$primary$main), fixed = TRUE)
    expect_match(vars, paste0("--site-bg:", p$background$default), fixed = TRUE)
    expect_match(vars, paste0("--site-ink:", p$text$primary), fixed = TRUE)
    expect_match(vars, paste0("--site-accent:", p$kicker), fixed = TRUE)
  }
  expect_match(vars, paste0("--site-serif:", config$theme$fonts$serif), fixed = TRUE)
})

test_that("the ink is reachable at any alpha from one definition", {
  config <- mui_default_config()
  expect_equal(rgba(config$theme$palette$ink_rgb, 0.12), "rgba(28,25,23,0.12)")
  expect_equal(light_palette(mui_theme(config))$divider, "rgba(28,25,23,0.12)")
})


test_that("rgba() takes either a hex or the bare channels the palette stores", {
  # The app bar's translucent ground comes from the opaque background hex; the hairlines
  # come from the ink, which the palette already holds as channels.
  expect_equal(rgba("#FAF6F1", 0.82), "rgba(250,246,241,0.82)")
  expect_equal(rgba("#000000", 1), "rgba(0,0,0,1)")
  expect_equal(rgba("28,25,23", 0.5), "rgba(28,25,23,0.5)")
})

test_that("custom typography variants are mapped to real elements", {
  # An unmapped variant renders as <span>; these keep the markup meaningful.
  theme <- mui_theme()
  expect_equal(theme$components$MuiTypography$defaultProps$variantMapping$kicker, "p")
  expect_true(!is.null(theme$typography$kicker))
})

test_that("the primary is emitted as bare channels for the rules that add their own alpha", {
  # The hero wash is rgba(var(--site-primary-rgb), .15). Without this the stylesheet would have
  # to hard-code the brand colour, and repointing `primary` would leave the wash behind.
  config <- mui_default_config()
  config$theme$palette$primary <- "#4f46e5"
  expect_match(mui_css_root_vars(config), "--site-primary-rgb:79,70,229", fixed = TRUE)
  config$theme$palette$primary <- "#000000"
  expect_match(mui_css_root_vars(config), "--site-primary-rgb:0,0,0", fixed = TRUE)
})
