# The site's MUI theme

The single theme every MUI component on the site renders under: palette,
shape, typography, and the component overrides that make a Card, an
Accordion and an AppBar look like this site rather than like stock
Material Design.

## Usage

``` r
mui_theme(config = mui_config())
```

## Arguments

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A theme list, ready for
[`muiMaterial::ThemeProvider()`](https://rdrr.io/pkg/muiMaterial/man/ThemeProvider.html).

## Details

Its colours are read from `config`, not declared here, because the half
of the site that MUI does not render needs the same ones - see
[`mui_css_root_vars()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_css_root_vars.md).

`theme.mode: auto` emits *both* schemes, as MUI `colorSchemes` under
`cssVariables$colorSchemeSelector = "media"`: MUI then writes one set of
CSS variables per scheme and switches them on `prefers-color-scheme`,
with no toggle, no stored preference and no script. The component
overrides below name `var(--site-*)` rather than a colour for the same
reason - a hex baked into a `styleOverride` would stay light in the dark
scheme.

## See also

Other theme:
[`mui_css_root_vars()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_css_root_vars.md)

## Examples

``` r
theme <- mui_theme()
theme$colorSchemes$light$palette$primary$main
#> [1] "#4f46e5"
theme$typography$kicker
#> $fontFamily
#> [1] "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
#> 
#> $fontSize
#> [1] "0.72rem"
#> 
#> $fontWeight
#> [1] 600
#> 
#> $letterSpacing
#> [1] "0.14em"
#> 
#> $textTransform
#> [1] "uppercase"
#> 
```
