# Turning a tag tree into a standalone HTML file, and copying the static trees beside it.
#
# Everything this build owns lives under one `_mui/` prefix, the way Next writes `_next/`
# and Astro `_astro/`: the leading underscore says the tree is generated rather than
# written. It is also why mui_validate_config() refuses `pages.nojekyll: false`.

write_utf8 <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeLines(enc2utf8(text), con, useBytes = TRUE)
}

# copyDependencyToDir() copies the whole package directory, which for react/shiny.react
# means unminified development builds and source maps that no page ever requests.
DEAD_WEIGHT <- "([.]development[.]js|[.]js[.]map|[.]css[.]map)$"

# Every page of a build carries the same dependencies, so within a build each one is copied
# and trimmed once, by the first page that needs it: mui_build_site() opens `the$deps_done`
# and every later page finds its directory there. Outside a build it is NULL and nothing is
# remembered - a caller rendering one page by hand gets a fresh copy every time, which is
# the safe answer when nothing says the tree has not changed underneath.
shared_dependencies <- function(deps, out_dir, config = mui_config()) {
  lapply(deps, function(d) {
    dir <- file.path(out_dir, "_mui", "libs", paste0(d$name, "-", d$version))
    remember <- !is.null(the$deps_done)
    if (!(remember && dir %in% the$deps_done)) {
      d <- htmltools::copyDependencyToDir(
        d,
        file.path(out_dir, "_mui", "libs"),
        FALSE
      )
      unlink(list.files(
        dir,
        pattern = DEAD_WEIGHT,
        recursive = TRUE,
        full.names = TRUE
      ))
      # The copy, never the installed package - see R/payload.R. Safe to repeat for a
      # caller outside a build: the stub keeps the key it replaced, so a second pass
      # rewrites it with itself.
      mui_trim_payload(dir, d$name, config)
      if (remember) the$deps_done <- c(the$deps_done, dir)
    }
    # Under the site's base path, so a project site finds its bundle - see site_base().
    d$src <- list(
      href = paste0(site_base(config), "/_mui/libs/", d$name, "-", d$version)
    )
    d
  })
}


#' Render a page to a standalone HTML file
#'
#' `htmltools::save_html()` is deliberately not used: it cannot emit per-page `<meta>` tags,
#' and it copies the full dependency tree next to every single page. Each dependency is
#' copied once into `<out_dir>/_mui/libs` and referenced site-absolutely instead.
#'
#' @param ui The page's tag tree.
#' @param page A page: its `out` path and its `url`, plus the front matter the `<head>`
#'   metadata is built from.
#' @param out_dir Directory to write into.
#' @param fallback The page's content as plain HTML, written into the document ahead of the
#'   React tree and removed on mount - see [mui_prerender_html()]. `""` writes none.
#' @param home Whether this page carries the bands the scroll spy watches; see
#'   [mui_boot_script()].
#' @inheritParams mui_theme
#' @return The page's URL, invisibly.
#' @family render
#' @export
mui_render_page <- function(
  ui,
  page,
  out_dir,
  config = mui_config(),
  fallback = "",
  home = FALSE
) {

  rt <- htmltools::renderTags(ui)
  deps <- htmltools::renderDependencies(
    shared_dependencies(rt$dependencies, out_dir, config),
    srcType = "href"
  )

  html <- paste0(
    # A site that is not in English should not tell every screen reader and crawler that
    # it is, so the document language follows the configuration.
    sprintf(
      "<!DOCTYPE html>\n<html lang=\"%s\">\n",
      attr_esc(site_lang(config))
    ),
    # muiMaterialPage() writes a charset and a viewport of its own, and they arrive below in
    # rt$head. These are still written here, and first: a charset has to fall inside the
    # document's first 1024 bytes to be honoured, and muiMaterialPage's copy lands after two
    # kilobytes of metadata. A browser takes the first of each and ignores the rest. Writing
    # them here is also what lets mui_render_page() render a tag tree that is not a
    # muiMaterialPage at all.
    "<head>\n<meta charset=\"utf-8\">\n",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    # A `js` class on <html> before anything paints, so site.css can keep the prerendered
    # fallback off the screen of a reader who is about to be handed the React page. The
    # fallback is a plain text document and would otherwise be painted, and replaced, on
    # every load: the scripts above stall the parser, but the parser still reaches the
    # fallback well before the call that mounts React. The markup itself is untouched, so
    # anything reading the document without running scripts still finds every word.
    if (isTRUE(config$prerender %||% TRUE)) {
      "<script>document.documentElement.className+=' js';</script>\n"
    } else {
      ""
    },
    mui_head_meta(page, config),
    "\n",
    as.character(deps),
    "\n",
    as.character(rt$head),
    "\n",
    "</head>\n<body>\n",
    # Before the React container, so a reader without JavaScript - and a crawler that stops
    # at the raw document - meets the page's words rather than a blob of JSON. No skip link
    # here: there is no chrome above it to skip. The React tree carries its own.
    fallback,
    "\n",
    as.character(rt$html),
    "\n",
    mui_boot_script(home, config),
    "\n</body>\n</html>\n"
  )

  # paste0() recycles: a head fragment that comes back as a length-2 vector - a config value
  # fed to sprintf() unsplit, say - silently yields two whole documents in one file, which a
  # browser renders as the page repeated. Fail here instead.
  if (length(html) != 1L) {
    stop(
      "render: ",
      page$out,
      " assembled into ",
      length(html),
      " documents - a head fragment is not a single string",
      call. = FALSE
    )
  }
  write_utf8(html, file.path(out_dir, page$out))
  page$url
}

# The site's assets directory, the package's stylesheet, the `copy_dirs` trees and the
# GitHub Pages plumbing. Three trees, kept apart on purpose: `assets_dir` is the site's own
# files under one prefix, the stylesheet goes to /_mui/ so a site with its own site.css
# cannot collide with it, and `copy_dirs` are trees this build does not generate but the
# domain serves - copying them is what keeps a clean rebuild from deleting a live part of
# the site. The Pages files are written rather than copied, but a loose CNAME or .nojekyll
# at the site root is still honoured.
mui_copy_static <- function(out_dir, config = mui_config()) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (d in config$copy_dirs) {
    if (dir.exists(d)) file.copy(d, out_dir, recursive = TRUE, overwrite = TRUE)
  }

  copy_tree(config$assets_dir, file.path(out_dir, "assets"))
  copy_tree(
    system.file("assets", package = "muiPersonalWebsite"),
    file.path(out_dir, "_mui")
  )

  cname <- config$pages$cname
  if (!is.null(cname) && nzchar(cname)) {
    write_utf8(cname, file.path(out_dir, "CNAME"))
  } else if (file.exists("CNAME")) {
    file.copy("CNAME", out_dir, overwrite = TRUE)
  }
  if (isTRUE(config$pages$nojekyll) || file.exists(".nojekyll")) {
    write_utf8("", file.path(out_dir, ".nojekyll"))
  }
  invisible()
}

# A directory's *contents* into `dest`, rather than the directory itself: file.copy() on a
# directory nests it under the target, which would put the assets at /assets/assets/.
copy_tree <- function(from, dest) {
  if (!nzchar(from %||% "") || !dir.exists(from)) {
    return(invisible())
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    dest,
    recursive = TRUE,
    overwrite = TRUE
  )
  invisible()
}
