# The honeycomb's promise is that adding a package changes the cell size, not the hero's
# height, and that the comb goes on reading as paving rather than as a banner. That only
# holds if mui_hex_layout keeps picking a shape inside both budgets and hex_split keeps dealing
# every package into it, so both are checked across far more packages than exist — the
# point is that publishing the next one needs no layout work.

# The geometry hex_shape optimises against, restated independently of it, so a mistake in
# there does not simply agree with itself here.
comb_w <- function(k) k + (k - 1) * HEX_GAP_R
comb_h <- function(r) 1.1547 + (r - 1) * (0.866 + 0.5 * HEX_GAP_R)
cell_w <- function(k, box) box / comb_w(k)
grid_h <- function(r, k, box) cell_w(k, box) * comb_h(r)

test_that("every package is dealt into the comb exactly once", {
  for (n in 1:40) {
    flat <- unlist(hex_split(n, mui_hex_layout(n)))
    # Blanks (0) hold a lattice position without drawing; they are not packages.
    expect_identical(flat[!is.na(flat) & flat > 0L], seq_len(n),
                     info = paste("n =", n))
  }
})

test_that("there is exactly one empty slot, and it is the comb's last cell", {
  # The invitation to the next package rather than a row of placeholders, and the only
  # cell carrying the GitHub link.
  for (n in 1:40) {
    flat <- unlist(hex_split(n, mui_hex_layout(n)))
    expect_equal(sum(is.na(flat)), 1L, info = paste("n =", n))
    expect_true(is.na(flat[length(flat)]), info = paste("n =", n))
  }
})

test_that("rows alternate long and short, and only the last is short of its width", {
  for (n in 1:40) {
    lay  <- mui_hex_layout(n)
    k    <- lay$per_row
    rows <- hex_split(n, lay)
    want <- vapply(seq_along(rows), function(r) if (r %% 2 == 1) k else k - 1L, integer(1))
    last <- length(rows)
    expect_equal(lengths(rows)[-last], want[-last], info = paste("n =", n))
    expect_lte(length(rows[[last]]), want[last])
    # The rows the shape was scored on are the rows actually emitted.
    expect_equal(length(rows), lay$rows, info = paste("n =", n))
  }
})

test_that("the fractions handed to the stylesheet tile the box", {
  # per_row cells and per_row - 1 gaps have to come back to the whole width, or the
  # rendered comb is not the one that was scored.
  for (n in 1:40) {
    lay <- mui_hex_layout(n)
    k   <- lay$per_row
    expect_lt(abs(k * lay$cell_f + (k - 1) * lay$gap_f - 1), 1e-4)
  }
})

test_that("the comb reads as paving rather than as a banner", {
  # From 8 packages up the comb lands between 0.81 and 1.14 at every count but one, so the
  # band is drawn tight enough to catch a regression. Below 8 the few shapes that hold the
  # cells at all are too coarse to land near square, and the site passed 8 years ago. n=10
  # is the single count where eleven cells deal into nothing better than 4-3-4; the
  # alternative, 3-2-3-2-1, is worse at 0.66.
  for (n in setdiff(8:40, 10)) {
    lay    <- mui_hex_layout(n)
    aspect <- lay$box / grid_h(length(hex_split(n, lay)), lay$per_row, lay$box)
    expect_gte(aspect, 0.75)
    expect_lte(aspect, 1.20)
  }
})

test_that("the comb never grows past the space the hero has for it", {
  # The whole point: a new package shrinks the stickers, it does not push the scroll cue
  # off the fold.
  for (n in 1:40) {
    lay <- mui_hex_layout(n)
    h   <- grid_h(length(hex_split(n, lay)), lay$per_row, lay$box)
    expect_lte(h, HEX_MAX_H)
  }
})

test_that("stickers stay legible out to 40 packages", {
  # Below about 40px a sticker stops being recognisable at a glance; past that point the
  # comb would need capping and the tail moving to its own page.
  smallest <- min(vapply(1:40, function(n) {
    lay <- mui_hex_layout(n)
    cell_w(lay$per_row, lay$box)
  }, numeric(1)))
  expect_gte(smallest, 40)
})

test_that("the empty slot is a link only when there is somewhere for it to go", {
  items <- list(list(image = "x.png", slug = "p", primary = list(href = "/p/")))
  config <- mui_validate_config(modifyList(mui_default_config(), list(url = "https://x.example")))
  # No github_href: still the dashed hex, but decoration rather than a dead link.
  bare <- as.character(mui_hex_grid(items, config))
  expect_match(bare, '"hex hex-empty"', fixed = TRUE)
  expect_false(grepl("More on GitHub", bare, fixed = TRUE))
  expect_match(bare, '"component":{"type":"raw","value":"span"}', fixed = TRUE)
  # With one, it is a real link carrying its label.
  config$github_href <- "https://github.com/someone"
  linked <- as.character(mui_hex_grid(items, config))
  expect_match(linked, "More on GitHub", fixed = TRUE)
  expect_match(linked, "https://github.com/someone", fixed = TRUE)
})
