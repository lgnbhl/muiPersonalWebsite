# Reading content. Two shapes, for two jobs. A *page* is a markdown file - front matter plus
# a body: the 404, and whatever lives under `pages_dir`. An *item* is an entry in a section's
# YAML file: an app, a package, a talk. Items are what the landing page is made of.

# The parsed front matter and the body. An unterminated fence is an error rather than a page
# whose YAML silently becomes prose.
mui_split_front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) == 0 || !grepl("^---[[:space:]]*$", lines[1])) {
    return(list(front = list(), body = paste(lines, collapse = "\n")))
  }
  fences <- which(grepl("^---[[:space:]]*$", lines))
  if (length(fences) < 2) {
    stop("Unterminated YAML front matter in ", path)
  }
  close_at <- fences[2]
  front <- yaml::yaml.load(paste(lines[2:(close_at - 1)], collapse = "\n"))
  body <- paste(lines[-seq_len(close_at)], collapse = "\n")
  list(front = front %||% list(), body = body)
}

# "talks/adminr-zurich/index.md" -> url "/talks/adminr-zurich/", out "talks/adminr-zurich/index.html"
page_paths <- function(rel) {
  rel <- gsub("\\\\", "/", rel)
  out <- sub("[.](md|qmd)$", ".html", rel)
  url <- if (basename(out) == "index.html") {
    d <- dirname(out)
    if (d == ".") "/" else paste0("/", d, "/")
  } else {
    paste0("/", out)
  }
  list(out = out, url = url)
}

# A page is its front matter and its markdown body, plus where it came from and where it is
# going: src, src_dir, rel, body, out and url, then every front-matter key alongside.
mui_read_page <- function(path, root = ".") {
  fm <- mui_split_front_matter(path)
  root_abs <- normalizePath(root, "/", mustWork = TRUE)
  path_abs <- normalizePath(path, "/", mustWork = TRUE)
  rel <- substring(path_abs, nchar(root_abs) + 2L)
  pp <- page_paths(rel)
  page <- c(
    list(src = path, src_dir = dirname(path), rel = rel, body = fm$body),
    pp,
    fm$front
  )
  page$date <- iso_date(page$date, path)
  page
}

# A content file names a file the way the assets directory holds it - "BFS-logo.png",
# "talks/adminr-zurich/slides.html" - and this resolves that into the URL the built tree
# serves it at, under the site's base path (see site_base()). Absolute and protocol-relative
# hrefs are somewhere else entirely and pass through untouched, and so does one starting with
# "/": that is a path on the host the author chose, which on a project site may well be a
# sibling site rather than this one.
mui_asset_url <- function(href, config = mui_config()) {
  if (is.null(href) || !nzchar(href)) {
    return(NULL)
  }
  if (grepl("^(https?:)?//", href) || startsWith(href, "/")) {
    return(href)
  }
  paste0(site_base(config), "/assets/", sub("^[.]?/", "", href))
}

# `{slug}` in any string, so a section's defaults can state a convention once. Recursive:
# the substitution has to reach `primary$href` and every `links[].url`, not just the top
# level. An item without a slug is left alone rather than having "{slug}" pasted into it.
expand_slug <- function(x, slug) {
  if (is.null(slug)) {
    return(x)
  }
  if (is.character(x)) {
    return(gsub("{slug}", slug, x, fixed = TRUE))
  }
  if (is.list(x)) {
    return(lapply(x, expand_slug, slug = slug))
  }
  x
}

# Every field of an item that can point at a file, in one place. Named rather than walked
# blindly: a `description` that happens to look like a path must not be turned into a URL.
# Both the resolver below and warn_missing_assets() in build.R go through this, so a new URL
# field cannot be resolved without also being checked for.
item_urls <- function(it, f) {
  it$image <- f(it$image)
  it$event_url <- f(it$event_url)
  for (k in c("primary", "secondary")) {
    if (!is.null(it[[k]])) it[[k]]$href <- f(it[[k]]$href)
  }
  it$shots <- lapply(it$shots %||% list(), function(s) {
    s$src <- f(s$src)
    s
  })
  it$links <- lapply(it$links %||% list(), function(l) {
    l$url <- f(l$url)
    l
  })
  it
}

# Every href an item carries, resolved in place. A shot or a link that pointed nowhere is
# dropped rather than rendered as a frame with no image or a button that does nothing.
resolve_item_urls <- function(it, config) {
  it <- item_urls(it, function(href) mui_asset_url(href %||% "", config))
  it$shots <- Filter(function(s) !is.null(s$src), it$shots)
  it$links <- Filter(function(l) !is.null(l$url), it$links)
  it
}

# A section is one YAML file holding an optional `defaults` block and a list of `items`. The
# defaults are merged *under* every item and `{slug}` is expanded throughout, which is what
# lets a whole section state its conventions once instead of repeating two URLs per package.
mui_read_items <- function(path, config = mui_config()) {
  if (!file.exists(path)) {
    stop("content file not found: ", path, call. = FALSE)
  }
  doc <- yaml::yaml.load_file(path) %||% list()
  # A bare list of items, with no `defaults:` block, is a valid file too - it is what a
  # section with no conventions to state looks like.
  items <- if (is.null(doc$items) && is.null(doc$defaults)) {
    doc
  } else {
    doc$items %||% list()
  }

  items <- lapply(items, function(it) {
    it <- merge_lists(doc$defaults %||% list(), it)
    it$date <- iso_date(
      it$date,
      paste0(path, ": item `", it$slug %||% it$title %||% "?", "`")
    )
    resolve_item_urls(expand_slug(it, it$slug), config)
  })
  # Newest first. Items without a date sort last rather than being dropped: a package's
  # date is optional.
  dates <- vapply(
    items,
    function(it) as.character(it$date %||% ""),
    character(1)
  )
  items[order(dates, decreasing = TRUE)]
}
