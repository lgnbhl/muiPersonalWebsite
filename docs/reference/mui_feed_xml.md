# The site's RSS feed

An RSS 2.0 document over the dated pages of the site, newest first.
Built only when the configuration says `feed: true`; a `feed:` naming a
URL is a feed the site does not own and is advertised in `<head>`
without being generated.

## Usage

``` r
mui_feed_xml(pages, config = mui_config())
```

## Arguments

- pages:

  Built pages carrying a `date`; see
  [`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md).

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

The feed document, as a string.

## See also

Other render:
[`mui_boot_script()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_boot_script.md),
[`mui_prerender_html()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prerender_html.md),
[`mui_render_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_render_page.md),
[`mui_trim_payload()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_trim_payload.md)
