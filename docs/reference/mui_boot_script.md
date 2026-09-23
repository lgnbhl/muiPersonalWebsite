# The page's boot script

Written at the end of `<body>`, outside the React tree. See the notes at
the top of `R/boot.R` for why it cannot be a component.

## Usage

``` r
mui_boot_script(home = FALSE, config = mui_config())
```

## Arguments

- home:

  Whether this page carries the bands the scroll spy watches.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `<script>` element, as a string, or `""` when it would have nothing to
do.

## See also

Other render:
[`mui_feed_xml()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_feed_xml.md),
[`mui_prerender_html()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prerender_html.md),
[`mui_render_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_render_page.md),
[`mui_trim_payload()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_trim_payload.md)
