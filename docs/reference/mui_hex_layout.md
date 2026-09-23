# Choose the honeycomb's shape

What is decided per build is the comb's *shape* - cells to a row, and
the rows that follow from it. Its proportions depend on those two counts
alone, since scaling the cells scales both sides of the block, so the
shape is chosen against a target aspect ratio and the size follows from
whichever budget binds.

## Usage

``` r
mui_hex_layout(n)
```

## Arguments

- n:

  Number of cells: the packages, plus the one empty slot.

## Value

A list: `rows` (cells per row), `box` (px), `aspect`, `cell_px`,
`cell_f`, `gap_f`.

## Details

Choosing by cell size instead - the fewest cells per row that fits a
height cap - always lands on the widest, shortest comb that will fit,
which reads as a banner rather than as paving.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)
