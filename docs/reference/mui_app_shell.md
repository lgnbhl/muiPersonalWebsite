# The page shell

Everything every page has: the app bar, the mobile drawer, `<main>`, and
the footer - all of it inside one `ThemeProvider`, so every element on
the page is a `muiMaterial` component rendering under the site's theme.

## Usage

``` r
mui_app_shell(body, home = FALSE, bare = FALSE, config = mui_config())
```

## Arguments

- body:

  The page's content.

- home:

  Whether this page carries the bands the app bar's anchors point at.
  Only the landing page does, and the anchor tabs are hidden everywhere
  else - a fragment cannot reach a band that React has not rendered yet.

- bare:

  Drop the width cap from `<main>`, for the home page whose bands run
  edge to edge and set their own inner width. Every other page keeps the
  cap.

- config:

  The site configuration; see
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

A `muiMaterial` page.

## Details

One themed block rather than two: the chrome used to sit inside it and
`<main>` and the footer outside, because plain HTML was what put the
page's words in the source. Nothing is outside it now - see the design
notes on what `R/seo.R` carries instead.

No `useMaterialIconsOutlined`: the site draws its icons as inline SVG
precisely so it does not load an icon font.

## See also

Other shell:
[`mui_app_bar()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_bar.md),
[`mui_footer()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_footer.md),
[`mui_page_head()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_page_head.md)
