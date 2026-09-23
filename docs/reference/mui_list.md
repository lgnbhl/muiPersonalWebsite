# A band of rows

Titles, a line of context and the links out, one under the other. The
variant for a section whose items are neither pictures nor talks -
publications, posts, a reading list - where a grid of cards would be a
grid of mostly-empty boxes.

## Usage

``` r
mui_list(items)

mui_timeline(items)
```

## Arguments

- items:

  Items from a section's content file.

## Value

A `muiMaterial` component.

## Details

`timeline` is the same rows with the year pulled into a column of its
own and a rule down the side, for items whose order is the point.

Neither knows what an item is. `title`, `description`, `body`, `date`,
`primary`, `secondary` and `links` are read where they are there and
skipped where they are not, so any content file feeds either. `body` is
markdown, for a description whose links belong in the sentence rather
than under it.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)

## Examples

``` r
mui_list(list(list(title = "A paper", description = "In a journal.")))
#> <div class="react-container" data-react-id="jyfadwffbyguhwhzptvt">
#>   <script class="react-data" type="application/json">{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"key":{"type":"raw","value":"A paper"},"sx":{"type":"raw","value":{"borderBottom":"1px solid","borderColor":"divider","pt":3,"&:first-of-type":{"pt":0}}},"children":{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"sx":{"type":"raw","value":{"minWidth":0,"flexGrow":1,"pb":3}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"h5","component":"h3","children":"A paper"}}},{"type":"raw","value":null},{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"body1","color":"text.secondary","sx":{"mt":0.75,"maxWidth":640},"children":"In a journal."}}},{"type":"raw","value":null},{"type":"raw","value":null}]}}}}}}}]}}}}</script>
#>   <script>jsmodule['@/shiny.react'].findAndRenderReactData('jyfadwffbyguhwhzptvt')</script>
#> </div>
```
