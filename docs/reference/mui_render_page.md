# Render a page to a standalone HTML file

[`htmltools::save_html()`](https://rstudio.github.io/htmltools/reference/save_html.html)
is deliberately not used: it cannot emit per-page `<meta>` tags, and it
copies the full dependency tree next to every single page. Each
dependency is copied once into `<out_dir>/_mui/libs` and referenced
site-absolutely instead.

## Usage

``` r
mui_render_page(
  ui,
  page,
  out_dir,
  config = mui_config(),
  fallback = "",
  home = FALSE
)
```

## Arguments

- ui:

  The page's tag tree.

- page:

  A page: its `out` path and its `url`, plus the front matter the
  `<head>` metadata is built from.

- out_dir:

  Directory to write into.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

- fallback:

  The page's content as plain HTML, written into the document ahead of
  the React tree and removed on mount - see
  [`mui_prerender_html()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prerender_html.md).
  `""` writes none.

- home:

  Whether this page carries the bands the scroll spy watches; see
  [`mui_boot_script()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_boot_script.md).

## Value

The page's URL, invisibly.

## See also

Other render:
[`mui_boot_script()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_boot_script.md),
[`mui_feed_xml()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_feed_xml.md),
[`mui_prerender_html()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prerender_html.md),
[`mui_trim_payload()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_trim_payload.md)
