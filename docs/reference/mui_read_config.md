# Read a site configuration

Reads `mui.config.yml` and merges it over
[`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md).
Keys the file does not name keep their default, so a configuration only
has to say what is particular to it.

## Usage

``` r
mui_read_config(path = "mui.config.yml")

mui_validate_config(config, strict = FALSE)
```

## Arguments

- path:

  Path to the YAML configuration file. A missing file is not an error:
  the defaults alone are a valid configuration.

- config:

  A configuration list.

- strict:

  Also make the checks only a build can make: that there is at least one
  section, and that every section's content file exists. Off by default,
  because
  [`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md)
  alone is a valid configuration but is not yet a site.

## Value

A named list, validated by `mui_validate_config()`.

## Details

The file is `mui.config.yml` and not `_site.yml`, because rmarkdown
defines a directory holding `_site.yml` to be an R Markdown website and
would try to render this one.

`url` is the address the site is served at, and its path is the site's
base path: a site served at the root of a domain names the domain alone,
and a GitHub Pages project site names `https://<user>.github.io/<repo>`,
which prefixes every URL the build writes with `/<repo>`. An href a
content file writes starting with `/` is a path on the host and is not
prefixed; name an asset by its filename to have it resolved under the
base path.

## Security

If a `variants.R` file sits beside the configuration, reading it **runs
that file**: it is [`source()`](https://rdrr.io/r/base/source.html)d so
the section variants it defines can be named in the YAML. Read and build
only sites whose files you trust, exactly as you would only
[`source()`](https://rdrr.io/r/base/source.html) a script you trust.
[`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
reads the configuration the same way.

## Examples

``` r
config <- mui_read_config(system.file("site", "mui.config.yml", package = "muiPersonalWebsite"))
config$title
#> [1] "Félix Luginbühl"
```
