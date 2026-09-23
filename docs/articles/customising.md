# Customising your site

A site is YAML, optional markdown pages and a one-line `build.R`. This
vignette lists every key. Anything you leave out keeps its value from
[`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md).

## Start

``` r

library(muiPersonalWebsite)
mui_create_site("my-site", cname = "www.example.com")
mui_build_site(out_dir = "my-site/docs", input = "my-site")
```

Push, then set GitHub Pages to deploy from branch `main`, folder
`/docs`. `url` says where the site is served, and its path is the site’s
base path:

- a custom domain: pass `cname`, and `url` follows from it;
- a repository named `<user>.github.io`: set
  `url: https://<user>.github.io`;
- a project site in any other repository: pass
  `url = "https://<user>.github.io/<repo>"`. Every URL the build writes
  is prefixed with `/<repo>`.

An href you write starting with `/` is a path on the host and is left as
it is, since on a project site it may point at a sibling site. Name an
asset by its filename to have it resolved under the base path. For a
link to one of the site’s own pages, write `{base}` in front of it -
`{base}/about.html` - in a markdown page or a `nav_links` href: it is
replaced by the base path, and by nothing at a domain root.

`starter = "blank"` (default) writes placeholder content.
`starter = "demo"` copies the author’s site; its talks reference slide
decks that are not shipped, so the first build warns about missing
assets.

## Layout

    mui.config.yml     configuration and the list of sections
    variants.R         optional: your own section variants
    content/
      *.yml            one content file per section
      assets/          images and files, published at /assets/
    pages/             optional markdown pages: pages/about.md -> /about.html
    404.md
    build.R

The build writes HTML pages, `assets/`, `sitemap.xml`, `robots.txt`,
`CNAME`, `.nojekyll`, and puts its own files (CSS, JavaScript) under
`_mui/`.

## Site keys

| Key | Description |
|----|----|
| `title` | Site name. Required. |
| `url` | Site URL. Required. |
| `wordmark` | App bar text, if different from `title`. |
| `description` | Default meta description. |
| `twitter` | Twitter handle for social cards. |
| `locale` | `og:locale`, default `en_US`. |
| `lang` | `<html lang>`; derived from `locale` by default. |
| `default_image` | Default social card image. |
| `counterdev` | [counter.dev](https://counter.dev) id, or `{id: ..., utcoffset: 2}`. |
| `feed` | `true` builds `/feed.xml` from dated pages; a URL links an external feed. |
| `jsonld` | schema.org `Person` block on the home page. Default `true`. |
| `prerender` | Plain-HTML copy of the content for crawlers and no-JS readers. Default `true`. |
| `noscript` | Message shown without JavaScript; only used with `prerender: false`. |
| `trim_payload` | Remove unused lodash code from the bundle (~470 KB). Default `true`. |
| `assets_dir` | Assets directory, default `content/assets`. |
| `pages_dir` | Markdown pages directory, default `pages`. |
| `copy_dirs` | Extra directories copied as-is (e.g. a pkgdown site). |
| `icons` | `favicon`, `png_32`, `png_16`, `apple_touch`, `manifest`: file names in assets. |
| `pages` | `cname` (custom domain) and `nojekyll` (must stay `true`). |
| `github_href` | Link for the empty hexagon in the hero. |

``` yaml
footer:
  copyright: Your Name     # defaults to title
  credit: 'built with <a href="https://github.com/lgnbhl/muiMaterial">muiMaterial</a>'  # raw HTML; ~ to drop
```

## Sections

``` yaml
sections:
  - id: projects
    kicker: Things I build
    title: Projects
    nav: work
    variant: cards
    data: content/projects.yml
    columns: 3
    hero: true
```

| Key | Description |
|----|----|
| `id` | Required. Element id, app bar anchor and scroll cue target. |
| `variant` | Required. A shipped variant (below) or one from `variants.R`. |
| `data` | Required. The content file. |
| `kicker`, `title` | Small label and heading. |
| `nav` | App bar label. Omit for no tab. |
| `columns` | `cards` only: 2, 3, 4 or 6. |
| `hero` | This section’s items fill the hero honeycomb. At most one. |

Extra app bar links:

``` yaml
nav_links:
  - {text: about, href: "{base}/about.html"}   # {base}: the site's base path
  - {text: blog,  href: "https://example.com/blog"}   # http links open in a new tab
```

## Hero and social links

``` yaml
hero:
  greeting: "Hi, I'm"
  name: Your Name
  role: What you do
  lead: A sentence or two about the work.
  scroll_to: projects    # default: first section

social:
  - {name: GitHub,   href: "https://github.com/you"}
  - {name: LinkedIn, href: "https://linkedin.com/in/you"}
  - {name: Email,    href: "mailto:you@example.com"}
  - name: Mastodon       # custom icon: an SVG viewBox and path, e.g. from simpleicons.org
    href: "https://fosstodon.org/@you"
    icon: {box: "0 0 24 24", d: "M23.268 5.313c..."}
hero_social: [GitHub, LinkedIn]   # which ones the hero shows; the footer shows all
```

Built-in icons: GitHub, LinkedIn, YouTube, Email.

## Markdown pages

Each `.md` in `pages_dir` becomes a page (`pages/cv/index.md` -\>
`/cv/`) and is added to the sitemap. `.qmd` files are refused: render
them with Quarto first.

``` yaml
---
title: About
description: Lead sentence and social card text.
date: 2025-01-01     # needed for the page to appear in the feed
hide_title: true     # if the body starts with its own heading
---
```

## Content files

A content file has optional `defaults`, merged under every item, and
`items`. `{slug}` is replaced by the item’s `slug`. Items are sorted by
`date`, newest first. `image`, `shots[].src` and relative `url`s resolve
against `assets_dir`.

**`cards`**

``` yaml
defaults:
  fit: contain
  primary:   {label: Docs,   href: "/{slug}/"}
  secondary: {label: Source, href: "https://github.com/you/{slug}"}
items:
  - slug: BFS
    title: BFS R package
    description: Search and download Swiss federal statistics.
    image: BFS-logo.png
    date: 2024-01-01
```

`fit` is `contain` for logos, `cover` for screenshots.

**`showcase`**: the same keys as a card, plus screenshots:

``` yaml
    shots:
      - {src: apps/{slug}/overview.png, caption: The overview page}
```

Without `shots`, the item’s `image` is used.

**`accordion`**

``` yaml
items:
  - title: Talk title
    event: Some Meetup
    event_url: "https://example.com/meetup"
    date: 2025-03-01
    location: Zurich, Switzerland
    abstract: |
      Plain text; blank lines separate paragraphs.
    links:
      - {name: Slides, url: talks/example/slides.html}
```

**`list` and `timeline`** read `title`, `description`, `body`
(markdown), `date`, `primary`, `secondary` and `links` when present, so
any content file works. `timeline` shows only the year.

**`prose`** renders each item’s `body` as markdown:

``` yaml
items:
  - body: |-
      A paragraph about me, with [a link](https://example.com).
```

## Theme

``` yaml
theme:
  mode: auto               # auto | light | dark
  fonts:
    sans: "'DM Sans', system-ui, sans-serif"
    serif: "Fraunces, Georgia, serif"
  font_head: '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=...">'
  palette:
    primary: "#4f46e5"
    background: "#FAF6F1"
  palette_dark:            # only what differs from palette
    primary: "#a5b4fc"
```

Palette keys are roles (`primary`, `accent`, `background`, `paper`,
`ink_strong`, …); see
[`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md)
for the full list. In your own CSS, use the `--site-*` variables,
e.g. `var(--site-primary)`, `var(--site-ink)`, `var(--site-bg)`.

## Custom variants

Add a named list `variants` in `variants.R`. Each is
`function(items, section, config)` returning a `muiMaterial` component,
and can reuse
[`mui_card_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md),
[`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md),
[`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md)
and the other exported functions. A name matching a shipped variant
replaces it.

`variants.R` is R code, and reading the configuration runs it:
[`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md)
and
[`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
[`source()`](https://rdrr.io/r/base/source.html) it. Build only sites
whose files you trust.

``` r

# variants.R
variants <- list(
  intro_cards = function(items, section, config) {
    muiMaterial::Box(
      if (!is.null(section$intro)) mui_prose(list(list(body = section$intro))),
      mui_card_grid(items, columns = if (is.null(section$columns)) 3 else section$columns)
    )
  }
)
```

The whole `section` is passed in, so extra keys such as `intro:` become
the variant’s own settings:

``` yaml
  - id: packages
    title: R packages
    variant: intro_cards
    intro: Tools I built along the way.
    data: content/packages.yml
```

## Build options

`mui_build_site(clean = TRUE)` (default) removes pages written by a
previous build that no longer exist. Only files listed in
`_mui/manifest.txt` are removed.
