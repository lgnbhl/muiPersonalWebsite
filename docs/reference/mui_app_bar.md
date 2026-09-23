# The site's app bar and mobile drawer

A sticky bar carrying the wordmark, the section tabs, the profile icons
and - on a phone, where the bar has room for nothing else - a hamburger
opening the drawer.

## Usage

``` r
mui_app_bar(home = FALSE, config = mui_config())

mui_nav_drawer(home = FALSE, config = mui_config())
```

## Arguments

- home:

  Whether this page carries the bands the app bar's anchors point at.
  Only the landing page does, and the anchor tabs are hidden everywhere
  else - a fragment cannot reach a band that React has not rendered yet.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `muiMaterial` component.

## See also

Other shell:
[`mui_app_shell()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_shell.md),
[`mui_footer()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_footer.md),
[`mui_page_head()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_page_head.md)
