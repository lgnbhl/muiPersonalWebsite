# The landing page in plain HTML

The same hero and the same items the React tree renders, as a document a
crawler, a reader mode or a text browser can read. Written into the page
ahead of the React container and removed when React mounts, so it costs
a reader with JavaScript nothing but is the whole page to a reader
without it.

## Usage

``` r
mui_prerender_html(items, config = mui_config())
```

## Arguments

- items:

  Items by section id, exactly as
  [`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
  assembles them.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `<div>`, as a string, or `""` when `prerender` is off.

## Details

It mirrors the *content*, not the layout: one `<section>` per band and
one `<article>` per item, whatever variant the band is drawn with.
Arrangement is what a plain document does not need.

## See also

Other render:
[`mui_boot_script()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_boot_script.md),
[`mui_feed_xml()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_feed_xml.md),
[`mui_render_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_render_page.md),
[`mui_trim_payload()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_trim_payload.md)
