# Create a new site

Writes a working site into `path`: a configuration, content files, an
assets directory, a 404 page and a build script. Build it with
[`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
into the `docs/` tree GitHub Pages serves, commit that, and switch Pages
on for the `main` branch and the `/docs` folder. Then edit YAML: the
blank starter has no R in it beyond the one-line `build.R`, and the demo
starter adds only a `variants.R` holding the one band it draws itself.

## Usage

``` r
mui_create_site(
  path = ".",
  cname = NULL,
  starter = c("blank", "demo"),
  overwrite = FALSE,
  url = NULL
)
```

## Arguments

- path:

  Directory to create the site in. Created if missing.

- cname:

  The custom domain to serve the site at, written into the configuration
  and published as `CNAME`. Leave `NULL` for a site served at
  `<user>.github.io`, with or without a repository path, which needs
  none.

- starter:

  `"blank"` for placeholder words, `"demo"` for this author's real site.

- overwrite:

  Overwrite files that are already there. `FALSE` stops rather than
  quietly replacing a configuration someone has edited.

- url:

  The address the site is served at, when it is not `https://<cname>` -
  for a project site, `https://<user>.github.io/<repo>`. See
  [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

## Value

`path`, invisibly.

## Details

Where the site is served decides what to pass. For a custom domain, give
`cname`; the `url` follows from it. For a repository named
`<user>.github.io`, give neither and set `url` in `mui.config.yml` to
`https://<user>.github.io`. For a project site - any other repository,
served under `https://<user>.github.io/<repo>` - give that as `url`: its
path becomes the site's base path, and every URL the build writes is
prefixed with it.

Building a site runs its `variants.R`; see the security note in
[`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).

No CI workflow is scaffolded: how a site is published is the site's own
business, and a workflow shipped here would be one more file to delete
for anyone publishing another way.

## Which starter

`starter = "blank"`, the default, writes a site whose words are
placeholders and whose three sections hold one example item each. It is
generated from
[`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md)
rather than stored, so it cannot fall out of step with the code, and the
first thing it asks you to do is write rather than delete.

`starter = "demo"` copies this package's own site instead -
felixluginbuhl.com, the tree under `inst/site`. It is a site that is
really built and really published, so what it shows cannot quietly rot.
The trade is that the words in it are somebody else's, and that its
talks name slide decks too large to ship inside an R package, so a first
build of it warns about assets that are not there. Replace the words;
`hero`, `social`, `footer` and the content files are where the identity
lives. The writing, images and logos it copies are not covered by the
package's MIT licence - see `content/LICENSE-CONTENT.md` in the copy -
and are there to be replaced, not republished.

What the demo starter does *not* hand over is what would act as the
author on your behalf, invisibly from the page: there is no analytics
id, the Twitter handle is commented out, and the domain is replaced by
yours - or, when you give neither `cname` nor `url`, by the
`https://example.com` placeholder the first build warns about.

## Examples

``` r
site <- file.path(tempdir(), "my-site")
mui_create_site(site)
#> site created in /tmp/RtmpcbmlQo/my-site
#>   1. edit mui.config.yml and content/*.yml
#>   2. Rscript build.R docs
#>   3. push, then switch on GitHub Pages for the main branch and /docs
#>   `url` in mui.config.yml is where the site is served: a custom domain, or
#>   https://<user>.github.io/<repo> for a project site.
list.files(site)
#> [1] "404.md"         "build.R"        "content"        "mui.config.yml"
```
