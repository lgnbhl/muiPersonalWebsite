# The palette as CSS custom properties

The same colours
[`mui_theme()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_theme.md)
gives the MUI half of the site, emitted as `:root` custom properties for
the half the stylesheet still draws - the markdown body and the
honeycomb. Written into `<head>` at build time so those paint in the
right colours on the first frame rather than after a stylesheet
round-trip.

## Usage

``` r
mui_css_root_vars(config = mui_config())
```

## Arguments

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `<style>` element, as a string.

## Details

Both halves name colours by role (`--site-ink`, `--site-bg`,
`--site-primary`) rather than by hue, so a colour can be repointed in
the configuration without touching CSS. The `--site-` prefix keeps these
clear of `--mui-palette-*`, which MUI owns in its CSS-variables mode,
and of whatever a site adds in its own stylesheet.

## See also

Other theme:
[`mui_theme()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_theme.md)
