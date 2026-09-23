# Build the site

Renders the site into `out_dir`: the landing page, the 404 page, the
assets tree, and the sitemap and robots files.

## Usage

``` r
mui_build_site(
  out_dir = "dist",
  input = ".",
  config = NULL,
  clean = TRUE,
  quiet = FALSE
)
```

## Arguments

- out_dir:

  Directory to write the built site into. Created if missing. Existing
  files are overwritten; whether the ones this build did not write are
  deleted is `clean`'s business.

- input:

  Directory holding the site's content. The default is the working
  directory, which is where the configuration and the content
  directories live.

- config:

  The site configuration. `NULL` - the default - reads `input`'s own
  `mui.config.yml`, which is what makes
  `mui_build_site("docs", input = "inst/site")` build the site under
  `inst/site`. A relative path passed here resolves the same way,
  against `input` rather than against the caller's working directory.

- clean:

  Delete the pages a previous build wrote that this one did not.
  Renaming a page otherwise leaves the old URL live and serving stale
  content, and nothing would report it. Only the HTML named in the
  previous build's manifest is considered, so an artefact the build does
  not own - a pre-rendered slide deck, a `copy_dirs` tree - is never
  touched.

- quiet:

  Suppress the per-page build report.

## Value

The built pages, invisibly: one list per page, each carrying its `url`
and `out`.

## Details

The site is one landing page. Each `sections` entry in the configuration
names a YAML content file, and the home page lays those out as bands -
there are no section index pages and no page per item, so nothing here
has to be told what the sections are.

A content file naming an asset the built tree does not have is a dead
button on the page and nothing else would report it, so those are
collected and warned about once, by name, unless `quiet`.

Building a site runs its `variants.R`, if it has one - see the security
note in
[`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md).
Build only sites whose files you trust.

## Examples

``` r
if (FALSE) { # \dontrun{
mui_build_site("dist")  # a scratch build
mui_build_site("docs")  # the tree GitHub Pages serves
} # }
```
