# The site footer

The bar above carries the sections; this carries the profiles, and
`sitemap.xml` carries the full page list to crawlers.

## Usage

``` r
mui_footer(config = mui_config())
```

## Arguments

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `muiMaterial` component.

## Details

Its rule, its width and its type all come from the theme rather than
from the stylesheet: `divider` is the same hairline the app bar and the
first band use, and `Container` is the same `lg` cap the bands sit in,
so the footer lines up with them without repeating a number.

## See also

Other shell:
[`mui_app_bar()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_bar.md),
[`mui_app_shell()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_shell.md),
[`mui_page_head()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_page_head.md)
