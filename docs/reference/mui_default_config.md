# Default site configuration

The values
[`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md)
falls back to for any key `mui.config.yml` does not name. The palette
and fonts live here because they are the site's design, not its content:
a colour is changed by naming it in `mui.config.yml`, not by editing R.

## Usage

``` r
mui_default_config()
```

## Value

A named list.
