# The shared card

Apps and packages are the same kind of thing: a picture, a sentence,
somewhere to try it and somewhere to read the code. They resolve to one
shape and render through one card, rather than two components that would
drift apart.

## Usage

``` r
mui_card(item)

mui_card_grid(items, columns = 3)
```

## Arguments

- item:

  A card:
  `list(image, fit, title, description, primary = list(label, href), secondary = ...)` -
  which is exactly what an item in a `variant: cards` content file says,
  so a content file feeds this directly with nothing in between.

- items:

  Cards, for the grid.

- columns:

  How many cards stand across a medium screen.

## Value

A `muiMaterial` component.

## Details

The card is deliberately not wrapped in a `CardActionArea`: two
destinations means two links, and a Button inside a CardActionArea is an
`<a>` inside an `<a>`.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)

## Examples

``` r
mui_card(list(title = "aniview", description = "Animate on scroll.",
               primary = list(label = "Docs", href = "/aniview/")))
#> <div class="react-container" data-react-id="uvkfkrnrnvswaxznjupq">
#>   <script class="react-data" type="application/json">{"type":"element","module":"@mui/material","name":"Card","props":{"type":"object","value":{"key":{"type":"raw","value":"aniview"},"children":{"type":"array","value":[{"type":"raw","value":null},{"type":"element","module":"@mui/material","name":"CardContent","props":{"type":"object","value":{"sx":{"type":"raw","value":{"p":2.25,"pb":1,"flexGrow":1}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"h5","component":"h3","sx":{"mb":0.75},"children":"aniview"}}},{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"body2","color":"text.secondary","sx":{"lineHeight":1.55},"children":"Animate on scroll."}}}]}}}},{"type":"element","module":"@mui/material","name":"CardActions","props":{"type":"object","value":{"sx":{"type":"raw","value":{"px":2.25,"pb":2,"pt":0,"gap":1}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Button","props":{"type":"raw","value":{"href":"/aniview/","variant":"contained","size":"small","children":"Docs"}}}]}}}}]}}}}</script>
#>   <script>jsmodule['@/shiny.react'].findAndRenderReactData('uvkfkrnrnvswaxznjupq')</script>
#> </div>
```
