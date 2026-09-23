# The package honeycomb

A comb of package stickers, plus exactly one empty slot: a dashed hex
linking to GitHub, saying the next package goes here.

## Usage

``` r
mui_hex_grid(items, config = mui_config(), label = "Projects")
```

## Arguments

- items:

  Items of the hero section.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

- label:

  What the comb is a comb of, for its `aria-label`.

## Value

A `muiMaterial` component, or `NULL` when there is nothing to draw.

## Details

The components are handed the answers rather than the algebra -
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md)
decides the shape and the stylesheet sizes the cells from the fractions
it is given. The comb is the one part of the site that keeps its
stylesheet: clip-path cells, rows nested by negative margins, a bloom-in
fanned out along `--d` and an idle shimmer phased by `--i` are what CSS
is for, and restating them as `sx` would buy nothing. What is
muiMaterial here is the markup.

Which items these are is configuration: the comb is filled by the
section that sets `hero: true` in `mui.config.yml`, and an item with no
image is skipped, since a sticker is the one thing a cell cannot do
without.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)
