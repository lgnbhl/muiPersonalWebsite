# A page's title block

One header for every page type. `hide_title: true` in front matter
suppresses it for a page that opens with its own heading, without losing
the `<title>` and `og:title` metadata.

## Usage

``` r
mui_page_head(page)
```

## Arguments

- page:

  A page read from a markdown file.

## Value

A `muiMaterial` component, or `NULL` when the page has no title to show.

## Details

The action links are `Button`s rather than the hand-rolled pill the
stylesheet used to draw: an outlined and a contained Button under this
theme is what that pill was imitating, and it is the same pair a card in
any band shows.

## See also

Other shell:
[`mui_app_bar()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_bar.md),
[`mui_app_shell()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_shell.md),
[`mui_footer()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_footer.md)
