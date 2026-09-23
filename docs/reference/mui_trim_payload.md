# Trim the copied JavaScript

Rewrites `shiny-react.js` in place, under `_mui/libs`, replacing the
whole of lodash with the two functions the bundle actually imports from
it. Roughly 470 KB of the built site's 1.4 MB, and the one saving
available without a JavaScript toolchain: `shiny.react` itself is what
mounts every page and cannot be dropped, and the MUI bundle beside it is
already minified.

## Usage

``` r
mui_trim_payload(dir, name, config = mui_config())
```

## Arguments

- dir:

  The dependency's directory in the built tree.

- name:

  The dependency's name.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

The bytes saved, invisibly - `0` when nothing was rewritten.

## Details

Every assumption is checked against the bundle in front of it, and any
one of them failing leaves the file untouched and reports why.
`trim_payload: false` turns it off.

## See also

Other render:
[`mui_boot_script()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_boot_script.md),
[`mui_feed_xml()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_feed_xml.md),
[`mui_prerender_html()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prerender_html.md),
[`mui_render_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_render_page.md)
