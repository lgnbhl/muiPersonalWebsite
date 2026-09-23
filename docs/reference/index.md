# Package index

## Getting started

Starting a site, and building one.

- [`mui_create_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_create_site.md)
  : Create a new site
- [`mui_build_site()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_build_site.md)
  : Build the site

## Configuration

What mui.config.yml says, what it falls back to, and the configuration
the build is currently using.

- [`mui_read_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md)
  [`mui_validate_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_read_config.md)
  : Read a site configuration
- [`mui_default_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_default_config.md)
  : Default site configuration
- [`mui_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_config.md)
  [`mui_set_config()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_config.md)
  : The active site configuration

## Design

The one palette both halves of the site read.

- [`mui_theme()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_theme.md)
  : The site's MUI theme

## Section variants

How a section draws its items. These are the components a `variants`
entry of your own returns, and the ones it replaces.

- [`mui_card()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md)
  [`mui_card_grid()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_card.md)
  : The shared card
- [`mui_accordion()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_accordion.md)
  : The talks band
- [`mui_showcase()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_showcase.md)
  : The applications band
- [`mui_list()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md)
  [`mui_timeline()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_list.md)
  : A band of rows
- [`mui_prose()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_prose.md)
  : A band of prose

## Building a page of your own

The shell every page carries and the writer that turns one into a file -
the pair a site needs to render a page this package does not build for
it.

- [`mui_app_shell()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_app_shell.md)
  : The page shell
- [`mui_render_page()`](https://felixluginbuhl.com/muiPersonalWebsite/reference/mui_render_page.md)
  : Render a page to a standalone HTML file
