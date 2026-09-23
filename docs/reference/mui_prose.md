# A band of prose

Words, centred at a reading measure - an "about" band, or a note
introducing the ones below it. Each item's `body` is markdown; an item
with only a `description` is rendered as the paragraph it is.

## Usage

``` r
mui_prose(items)
```

## Arguments

- items:

  Items carrying a `body` or a `description`.

## Value

A `muiMaterial` component.

## Details

This is the one variant with no links, no dates and no pictures: a band
that is a piece of writing rather than a list of things.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)

## Examples

``` r
mui_prose(list(list(body = "Some **markdown**.")))
#> <div class="react-container" data-react-id="zarjxrrtognksqkyhbof">
#>   <script class="react-data" type="application/json">{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"sx":{"type":"raw","value":{"maxWidth":680,"mx":"auto"}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"key":{"type":"raw","value":"Some **markdown**."},"children":{"type":"array","value":[{"type":"raw","value":null},{"type":"element","name":"div","props":{"type":"object","value":{"class":{"type":"raw","value":"prose"},"children":{"type":"html","value":"<p>Some <strong>markdown<\/strong>.<\/p>\n"}}}}]}}}}]}}}}</script>
#>   <script>jsmodule['@/shiny.react'].findAndRenderReactData('zarjxrrtognksqkyhbof')</script>
#> </div>
```
