# The applications band

A list of applications, and the screenshots of the selected one on a
stage beside it. An application is worth looking at for what it looks
like, and a card in a grid shows one strip of it.

## Usage

``` r
mui_showcase(items)
```

## Arguments

- items:

  Application items: `slug`, `title`, `description`, `primary`,
  `secondary`, and a `shots` list of `src` and optional `caption`. An
  item with no `shots` falls back to its `image`.

## Value

A `muiMaterial` component.

## Details

Which app is showing is MUI's own state - `TabContext.static`, the way
the talks accordion and the mobile drawer are - so the band needs no
server and no script. So is which screenshot: each one is a `TabPanel`
of a second `TabContext.static`, switched by the dots under the stage.
The stage is one fixed 16:10 shape for every app, so the band's height
does not move as you click down the list, and each screenshot is fitted
into it rather than cropped to it. Clicking a screenshot opens it full
size in a `Dialog.triggerId`.

## See also

Other home:
[`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md),
[`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_hero()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hero.md),
[`mui_hex_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_grid.md),
[`mui_hex_layout()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_hex_layout.md),
[`mui_home_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_home_page.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md)

## Examples

``` r
mui_showcase(list(list(slug = "app", title = "An app",
                       shots = list(list(src = "/assets/app.png")))))
#> <div class="react-container" data-react-id="jqdrwvwgpxittwzczqbm">
#>   <script class="react-data" type="application/json">{"type":"element","module":"@/muiMaterial","name":"MuiStaticTabContext","props":{"type":"object","value":{"defaultValue":{"type":"raw","value":"app"},"children":{"type":"element","module":"@mui/material","name":"Grid","props":{"type":"object","value":{"container":{"type":"raw","value":true},"spacing":{"type":"raw","value":{"xs":3,"md":4}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Grid","props":{"type":"object","value":{"size":{"type":"raw","value":{"xs":12,"md":5}},"children":{"type":"element","module":"@/muiMaterial","name":"MuiStaticTabList","props":{"type":"object","value":{"orientation":{"type":"raw","value":"vertical"},"sx":{"type":"raw","value":{"& .MuiTabs-indicator":{"display":"none"},"& .MuiTabs-flexContainer":{"gap":0}}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Tab","props":{"type":"object","value":{"key":{"type":"raw","value":"app"},"value":{"type":"raw","value":"app"},"component":{"type":"raw","value":"div"},"sx":{"type":"raw","value":{"p":0,"maxWidth":"none","textTransform":"none","textAlign":"left","alignItems":"stretch","opacity":1,"color":"text.primary","borderLeft":"3px solid transparent","borderBottom":"1px solid","borderBottomColor":"divider","&:first-of-type":{"borderTop":"1px solid","borderTopColor":"divider"},"&:hover":{"backgroundColor":"action.hover"},"&.Mui-selected":{"color":"text.primary","backgroundColor":"action.hover","borderLeftColor":"primary.main"}}},"label":{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"sx":{"type":"raw","value":{"px":2,"py":1.75,"width":"100%"}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"h6","component":"h3","sx":{"fontSize":"1.05rem","mb":0.5},"children":"An app"}}},{"type":"raw","value":null},{"type":"raw","value":null}]}}}}}}}]}}}}}}},{"type":"element","module":"@mui/material","name":"Grid","props":{"type":"object","value":{"size":{"type":"raw","value":{"xs":12,"md":7}},"sx":{"type":"raw","value":{"minWidth":0}},"children":{"type":"array","value":[{"type":"element","module":"@mui/lab","name":"TabPanel","props":{"type":"object","value":{"key":{"type":"raw","value":"app"},"value":{"type":"raw","value":"app"},"sx":{"type":"raw","value":{"p":0}},"children":{"type":"element","module":"@/muiMaterial","name":"MuiStaticTabContext","props":{"type":"object","value":{"defaultValue":{"type":"raw","value":"1"},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"sx":{"type":"raw","value":{"width":"100%","minWidth":0}},"children":{"type":"array","value":[{"type":"element","module":"@mui/lab","name":"TabPanel","props":{"type":"object","value":{"key":{"type":"raw","value":1},"value":{"type":"raw","value":"1"},"sx":{"type":"raw","value":{"p":0}},"children":{"type":"array","value":[{"type":"element","module":"@mui/material","name":"Box","props":{"type":"object","value":{"id":{"type":"raw","value":"shot-app-1"},"sx":{"type":"raw","value":{"aspectRatio":"16 / 10","width":"100%","p":1,"display":"flex","alignItems":"center","justifyContent":"center","overflow":"hidden","cursor":"zoom-in","borderRadius":1.5,"border":"1px solid","borderColor":"divider","backgroundColor":"background.paper"}},"children":{"type":"element","module":"@mui/material","name":"CardMedia","props":{"type":"raw","value":{"component":"img","image":"/assets/app.png","alt":"An app","loading":"lazy","sx":{"maxWidth":"100%","maxHeight":"100%","width":"auto","height":"auto","objectFit":"contain","display":"block","borderRadius":1}}}}}}},{"type":"element","module":"@mui/material","name":"Typography","props":{"type":"raw","value":{"variant":"body2","color":"text.secondary","noWrap":true,"align":"center","sx":{"mt":1,"minHeight":22},"children":""}}},{"type":"element","module":"@/muiMaterial","name":"MuiDialogTriggerId","props":{"type":"object","value":{"triggerId":{"type":"raw","value":"shot-app-1"},"maxWidth":{"type":"raw","value":"lg"},"children":{"type":"element","module":"@mui/material","name":"DialogContent","props":{"type":"object","value":{"sx":{"type":"raw","value":{"p":0,"lineHeight":0}},"children":{"type":"element","module":"@mui/material","name":"CardMedia","props":{"type":"raw","value":{"component":"img","image":"/assets/app.png","alt":"An app","sx":{"width":"100%","height":"auto"}}}}}}}}}}]}}}}]}}}},{"type":"raw","value":null}]}}}}}}}]}}}}]}}}}}}}</script>
#>   <script>jsmodule['@/shiny.react'].findAndRenderReactData('jqdrwvwgpxittwzczqbm')</script>
#> </div>
```
