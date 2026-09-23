# The active site configuration

The configuration
[`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
is currently building with. Every function that needs configuration
defaults its `config` argument to this, so that callers do not have to
pass one and tests can.

## Usage

``` r
mui_config()

mui_set_config(config)
```

## Arguments

- config:

  A configuration list to make active.

## Value

`mui_config()` returns the active configuration, falling back to
[`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md)
outside a build. `mui_set_config()` returns the previous one, invisibly,
so a caller can restore it.
