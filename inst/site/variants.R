# A variant of this site's own. The package ships six ways to draw a band - cards, showcase,
# accordion, list, timeline, prose - and this is the seventh, written here rather than there
# because it is about what *this* site wants to say and not about what any site might.
#
# The build sources this file and reads the `variants` list it leaves behind, so a section in
# mui.config.yml names `intro_cards` exactly as it would name a shipped variant. Nothing in
# build.R has to know about it. See "Adding a variant" in vignette("customising").

# Prose over cards. A band's heading is a kicker and two or three words, which is enough to
# say what the things below it *are* and not enough to say anything about them - and a whole
# `variant: prose` band above this one to carry one sentence would cost an id, an anchor and
# a second band of padding.
#
# The sentence is `intro` on the section rather than an item in the content file: it is said
# *about* the packages, so it belongs with the words that name the band and not in the list
# of the packages themselves. The shipped variants ignore the key; this one reads it, which
# is the point of a variant being handed the whole section.
intro_cards <- function(items, section, config) {
  muiMaterial::Box(
    if (nzchar(trimws(section$intro %||% ""))) {
      # mb rather than a gap: mui_prose() caps itself at a reading measure and centres, so
      # the intro is narrower than the grid under it by design - the words wrap where prose
      # wants to wrap, and the cards still run the full width of the container.
      muiMaterial::Box(sx = list(mb = 5), mui_prose(list(list(body = section$intro))))
    },
    mui_card_grid(items, columns = if (is.null(section$columns)) 3 else section$columns)
  )
}

variants <- list(intro_cards = intro_cards)
