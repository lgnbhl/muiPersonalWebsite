# muiPersonalWebsite

<!-- badges: start -->
[![R-CMD-check](https://github.com/lgnbhl/muiPersonalWebsite/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lgnbhl/muiPersonalWebsite/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**muiPersonalWebsite** builds a personal website from YAML, using
[muiMaterial](https://github.com/lgnbhl/muiMaterial) components. It is the generator behind
[felixluginbuhl.com](https://felixluginbuhl.com/).

```r
pak::pak("lgnbhl/muiPersonalWebsite")
```

## Run felixluginbuhl.com locally

```r
muiPersonalWebsite::mui_build_site(
  out_dir = "dist",
  input = system.file("site", package = "muiPersonalWebsite")
)
servr::httd("dist", port = 8000)
```

The installed package lacks the talks' slides and posters, which are too large to ship in an R
package, so the build warns that they are missing and their links are broken. To get them,
clone this repository and build its `inst/site/` instead, with `input = "inst/site"`.

Open <http://localhost:8000>. The server keeps running in the background; stop it with:

```r
servr::daemon_stop()
```

A `Failed to create server` error means one is still running on that port from an earlier
call. Stop it as above, or pass another `port`.

## Create your own site

```r
library(muiPersonalWebsite)

mui_create_site(
  path = "my-site",
  cname = "www.example.com", # custom domain; NULL for a <user>.github.io site
  starter = "demo",         # "blank" (placeholders) or "demo" (a copy of felixluginbuhl.com)
  overwrite = FALSE          # TRUE to replace existing files
)
mui_build_site(out_dir = "my-site/docs", input = "my-site")
servr::httd("my-site/docs") # preview
```

Push, then enable GitHub Pages for the `main` branch and the `/docs` folder.

For a project site served under `<user>.github.io/<repo>`, pass
`url = "https://<user>.github.io/<repo>"` instead of `cname`. The build prefixes every URL
it writes with `/<repo>`.

With `starter = "demo"`, the talks reference slide decks that are not shipped, so the first
build warns about missing assets.

## Edit it

Sections are listed in `mui.config.yml`; each one points to a content file:

```yaml
sections:
  - id: packages
    kicker: Data tools
    title: R packages
    nav: tools            # app bar label
    variant: cards
    data: content/packages.yml
```

```yaml
# content/packages.yml
defaults:
  primary: {label: Docs, href: "/{slug}/"}
items:
  - slug: BFS
    title: BFS R package
    description: Search and download Swiss federal statistics.
    image: BFS-logo.png
    date: 2024-01-01
```

| `variant` | Draws |
|---|---|
| `cards` | A grid of cards with an image and two buttons |
| `accordion` | Talks: date, event, expandable abstract |
| `showcase` | A list of apps beside their screenshots |
| `list` | Titles, a line of text and links |
| `timeline` | The same, with the year in its own column |
| `prose` | Markdown text |

Custom variants go in `variants.R` beside the config. That file is R code and the build
runs it, so build only sites you trust. See `vignette("customising")` for every key.

## Good to know

- Every page is React, so the build also writes a plain-HTML copy of the content for
  crawlers and readers without JavaScript (`prerender: false` turns it off).
- The JavaScript bundle is about 0.9 MB uncompressed. For a tiny static site, Quarto is a
  better fit.
- Dark mode follows the system setting; `theme.mode: light` or `dark` pins it.

## License

MIT © Félix Luginbühl. The site's content (writing, images, slides) is not covered.
