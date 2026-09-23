# The home page

The whole site, bar the 404: a `muiMaterial` hero over one `muiMaterial`
band per section.

## Usage

``` r
mui_home_page(items, config = mui_config())
```

## Arguments

- items:

  Items by section id.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A tag list.

## Details

The bands are not named here. Each one is a `sections` entry in
`mui.config.yml` - its id, its kicker and title, and the
`SECTION_VARIANTS` key that says how to draw it - so the page's shape,
order and words are configuration. The id it carries is the same one the
app bar anchors at and the hero's scroll cue points to, which is what
lets a section be renamed or added without touching R.

There is no `ThemeProvider` here:
[`mui_app_shell()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_shell.md)
wraps the whole page in one, so the hero and the bands render under the
same theme as the chrome around them.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)
