# Building the site: the one function that puts every other one to work.

#' Build the site
#'
#' Renders the site into `out_dir`: the landing page, the 404 page, the assets tree, and the
#' sitemap and robots files.
#'
#' The site is one landing page. Each `sections` entry in the configuration names a YAML
#' content file, and the home page lays those out as bands - there are no section index
#' pages and no page per item, so nothing here has to be told what the sections are.
#'
#' A content file naming an asset the built tree does not have is a dead button on the
#' page and nothing else would report it, so those are collected and warned about once,
#' by name, unless `quiet`.
#'
#' Building a site runs its `variants.R`, if it has one - see the security note in
#' [mui_read_config()]. Build only sites whose files you trust.
#'
#' @param out_dir Directory to write the built site into. Created if missing. Existing files
#'   are overwritten; whether the ones this build did not write are deleted is `clean`'s
#'   business.
#' @param input Directory holding the site's content. The default is the working directory,
#'   which is where the configuration and the content directories live.
#' @param config The site configuration. `NULL` - the default - reads `input`'s own
#'   `mui.config.yml`, which is what makes `mui_build_site("docs", input = "inst/site")`
#'   build the site under `inst/site`. A relative path passed here resolves the same way,
#'   against `input` rather than against the caller's working directory.
#' @param clean Delete the pages a previous build wrote that this one did not. Renaming a
#'   page otherwise leaves the old URL live and serving stale content, and nothing would
#'   report it. Only the HTML named in the previous build's manifest is considered, so an
#'   artefact the build does not own - a pre-rendered slide deck, a `copy_dirs` tree - is
#'   never touched. Nor is `assets/`: a file deleted from the assets directory stays in
#'   `out_dir` until you delete it there too, or build into an empty directory.
#' @param quiet Suppress the per-page build report.
#' @return The built pages, invisibly: one list per page, each carrying its `url` and `out`.
#' @export
#' @examples
#' \donttest{
#' site <- file.path(tempdir(), "example-site")
#' mui_create_site(site)
#' mui_build_site(file.path(site, "docs"), input = site, quiet = TRUE)
#' list.files(file.path(site, "docs"))
#' }
mui_build_site <- function(
  out_dir = "dist",
  input = ".",
  config = NULL,
  clean = TRUE,
  quiet = FALSE
) {

  # system.file() returns "" for a path the installed package does not have, and setwd("")
  # says nothing about the stale install behind it.
  if (!nzchar(input) || !dir.exists(input)) {
    stop(
      "site: `input` is not a directory: ",
      if (nzchar(input)) input else "\"\"",
      ". If it came from system.file(), the installed package does not ship that ",
      "directory - reinstall it.",
      call. = FALSE
    )
  }

  # Resolved before the working directory moves: a relative `out_dir` is a place in the
  # caller's world, so "docs" while building inst/site/ must not become inst/site/docs.
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_dir <- normalizePath(out_dir, "/", mustWork = TRUE)

  old_wd <- setwd(input)
  on.exit(setwd(old_wd), add = TRUE)

  # Without this, month names in datelines follow the machine locale. Restored on exit: a
  # build must not leave the session's locale changed.
  old_lc <- Sys.getlocale("LC_TIME")
  Sys.setlocale("LC_TIME", "C")
  on.exit(Sys.setlocale("LC_TIME", old_lc), add = TRUE)

  # Read here, and explicitly, because the configuration a build wants is `input`'s own and
  # the working directory has only just become `input`. This used to be the argument's lazy
  # default, forced by the first line that touched it - the same behaviour, resting on an
  # evaluation order no test could pin down and one early `config$title` would have broken.
  config <- config %||% mui_read_config()
  old_config <- mui_set_config(config)
  # Straight back to what it was, NULL included: outside a build mui_config() falls back to
  # the defaults on its own, and a build should leave no configuration set behind it.
  on.exit(the$config <- old_config, add = TRUE)
  # Strict here and nowhere else: the working directory is the site's own at last, so a
  # relative `data:` path can be checked - and nothing has been written, so a typo is
  # reported instead of half a site.
  config <- mui_validate_config(mui_config(), strict = TRUE)

  # The blank starter's placeholder. Left in, every canonical, og: and sitemap URL points
  # at somebody else's domain, and the page itself looks fine.
  if (!quiet && identical(config$url, mui_default_config()$url)) {
    warning(
      "site: `url` is still ",
      config$url,
      " - set it in mui.config.yml to the address the site is served at.",
      call. = FALSE
    )
  }

  # One copy of each dependency per build rather than one per page; see shared_dependencies().
  the$deps_done <- character()
  on.exit(the$deps_done <- NULL, add = TRUE)

  mui_copy_static(out_dir, config)

  # Keyed by the section's id, which is the same key mui_home_page() looks them up by.
  items <- list()
  for (s in config$sections) {
    items[[s$id]] <- mui_read_items(s$data, config)
  }

  if (!quiet) {
    warn_missing_assets(items, out_dir, config)
  }

  # The 404 is site plumbing and lives at the root; everything else a site writes as
  # markdown lives under `pages_dir`. Both render through the same article shell.
  built <- list()
  root_pages <- Filter(file.exists, "404.md")
  for (page in c(lapply(root_pages, mui_read_page), content_pages(config))) {
    built <- c(built, list(build_article(page, out_dir, config)))
  }

  # The home page has no source file: its body is assembled from the content directories,
  # and its title, description and card image are the site's own.
  home <- list(
    url = "/",
    out = "index.html",
    title = config$title,
    description = config$description,
    image = config$default_image
  )
  mui_render_page(
    mui_app_shell(
      mui_home_page(items, config),
      home = TRUE,
      bare = TRUE,
      config = config
    ),
    home,
    out_dir,
    config,
    fallback = mui_prerender_html(items, config),
    home = TRUE
  )
  built <- c(built, list(home))

  urls <- vapply(built, function(p) p$url, character(1))
  dates <- vapply(built, function(p) as.character(p$date %||% ""), character(1))
  outs <- vapply(built, function(p) p$out, character(1))

  # A feed the site owns is generated; a `feed:` URL points at one somewhere else and is
  # only advertised. See mui_feed_xml().
  if (isTRUE(config$feed)) {
    feed_pages <- Filter(function(p) !is.null(p$date), built)
    write_utf8(mui_feed_xml(feed_pages, config), file.path(out_dir, "feed.xml"))
    outs <- c(outs, "feed.xml")
  }

  # Read before the manifest is overwritten: what the previous build wrote is the only
  # record of which files are this build's to remove.
  stale <- if (clean) stale_pages(out_dir, outs) else character()
  # Records which HTML files this build generated, so verification - and the next build's
  # clean - can tell them apart from copied artefacts (slides.html, pre-rendered leaflet
  # widgets, ...).
  write_utf8(paste(outs, collapse = "\n"), file.path(out_dir, "_mui", "manifest.txt"))
  # The 404 is served for every missing URL and carries noindex; listing it would ask a
  # crawler to index the one page that says there is nothing here.
  listed <- urls != NOT_FOUND_URL
  write_utf8(
    mui_sitemap_xml(urls[listed], dates[listed], config),
    file.path(out_dir, "sitemap.xml")
  )
  write_utf8(mui_robots_txt(config), file.path(out_dir, "robots.txt"))

  if (!quiet) {
    message(sprintf("built %d pages -> %s", length(built), out_dir))
    invisible(lapply(sort(urls), function(u) message("  ", u)))
    if (length(stale)) {
      message(sprintf("removed %d stale page(s):", length(stale)))
      invisible(lapply(stale, function(f) message("  ", f)))
    }
  }
  invisible(built)
}

# The pages the last build wrote that this one did not. Read from the manifest rather than
# by listing the tree, so nothing this build does not own can be deleted by it - a slide
# deck copied in from the assets directory is somebody's real page, not a leftover.
stale_pages <- function(out_dir, keep) {
  manifest <- file.path(out_dir, "_mui", "manifest.txt")
  if (!file.exists(manifest)) {
    return(character())
  }
  before <- readLines(manifest, warn = FALSE, encoding = "UTF-8")
  gone <- setdiff(before[nzchar(before)], keep)
  # A path that climbed out of the tree would be a manifest somebody had edited, and this
  # deletes files - so it is checked rather than trusted.
  gone <- gone[!grepl("(^|/)[.][.](/|$)", gone) & !grepl("^([/]|[A-Za-z]:)", gone)]
  hit <- gone[file.exists(file.path(out_dir, gone))]
  unlink(file.path(out_dir, hit))
  hit
}


# Every site-absolute asset URL an item carries, collected through the same field list
# resolve_item_urls() resolves - see item_urls() in content.R.
item_asset_urls <- function(it) {
  seen <- character()
  item_urls(it, function(href) {
    seen <<- c(seen, href %||% character())
    href
  })
  seen
}

# Assets the content names that the built tree does not have. Every other check passes for
# these: the YAML is valid, the URL is well formed, the file is simply not there. A warning
# rather than an error, because a half-published site with one dead link is still worth
# having - and this package's own site is in that position, its slide decks being too large
# to ship.
warn_missing_assets <- function(items, out_dir, config = mui_config()) {
  urls <- unlist(lapply(unlist(items, recursive = FALSE), item_asset_urls))
  # `<base>/assets/` and nothing else: the one prefix this build resolves a bare filename
  # into, so the only one where a missing file means the content is wrong. A site-absolute
  # href outside it - "/BFS/", a pkgdown site at the same domain - is deliberately elsewhere.
  prefix <- paste0(site_base(config), "/assets/")
  urls <- unique(Filter(
    function(u) !is.null(u) && startsWith(u, prefix),
    urls
  ))
  missing <- Filter(
    function(u) {
      !file.exists(file.path(out_dir, "assets", substring(u, nchar(prefix) + 1L)))
    },
    urls
  )
  if (!length(missing)) {
    return(invisible(character()))
  }
  warning(
    "site: ",
    length(missing),
    " asset(s) named by a content file are not in the built tree:\n  ",
    paste(missing, collapse = "\n  "),
    call. = FALSE
  )
  invisible(unlist(missing))
}

# Every .md and .qmd under `pages_dir`, at any depth. Reading them with that directory as
# the root is what gives them URLs off the site root - pages/about.md at /about.html.
content_pages <- function(config = mui_config()) {
  dir <- config$pages_dir %||% ""
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(list())
  }
  # A .qmd used to be read here as if it were markdown, which is right up to the first code
  # chunk and then silently publishes the chunk's source instead of its output. This build
  # renders markdown and has no Quarto in it, so it says so rather than guessing.
  qmd <- list.files(dir, pattern = "[.]qmd$", recursive = TRUE)
  if (length(qmd)) {
    stop(
      "site: this build renders markdown, not Quarto, so a .qmd would publish its code ",
      "chunks as source:\n  ",
      paste(file.path(dir, qmd), collapse = "\n  "),
      "\n  Render them with Quarto first and keep the .md, or rename them if they carry ",
      "no chunks.",
      call. = FALSE
    )
  }
  files <- list.files(
    dir,
    pattern = "[.]md$",
    recursive = TRUE,
    full.names = TRUE
  )
  pages <- lapply(files, mui_read_page, root = dir)
  # A page at the top of the tree named index would claim "/", be written, and then be
  # overwritten by the landing page a moment later - a page that silently does not exist.
  clash <- Filter(function(p) identical(p$out, "index.html"), pages)
  if (length(clash)) {
    stop(
      "site: ",
      clash[[1]]$src,
      " would take the landing page's URL. The landing page ",
      "is assembled from the content files and has no source of its own.",
      call. = FALSE
    )
  }
  pages
}

# A page whose body is markdown: the title block, then the prose.
build_article <- function(page, out_dir, config = mui_config()) {
  page$body <- expand_base(page$body, config)
  # The .prose class must sit on the markdown body alone: prose typography rules would
  # otherwise cascade into the React-rendered subtree and repaint MUI's own components.
  ui <- mui_app_shell(
    tagList(
      mui_page_head(page),
      tags$div(class = "prose", HTML(mui_md_to_html(page$body)))
    ),
    config = config
  )
  mui_render_page(
    ui,
    page,
    out_dir,
    config,
    fallback = mui_prerender_page(page, config)
  )
  page
}

