# Starting a site. The package builds *a* site; this writes the smallest one that works.

#' Create a new site
#'
#' Writes a working site into `path`: a configuration, content files, an assets directory, a
#' 404 page and a build script. Build it with [mui_build_site()] into the `docs/` tree GitHub
#' Pages serves, commit that, and switch Pages on for the `main` branch and the `/docs`
#' folder. Then edit YAML: the blank starter has no R in it beyond the one-line `build.R`,
#' and the demo starter adds only a `variants.R` holding the one band it draws itself.
#'
#' Where the site is served decides what to pass. For a custom domain, give `cname`; the
#' `url` follows from it. For a repository named `<user>.github.io`, give neither and set
#' `url` in `mui.config.yml` to `https://<user>.github.io`. For a project site - any other
#' repository, served under `https://<user>.github.io/<repo>` - give that as `url`: its path
#' becomes the site's base path, and every URL the build writes is prefixed with it.
#'
#' Building a site runs its `variants.R`; see the security note in [mui_read_config()].
#'
#' No CI workflow is scaffolded: how a site is published is the site's own business, and a
#' workflow shipped here would be one more file to delete for anyone publishing another
#' way.
#'
#' # Which starter
#'
#' `starter = "blank"`, the default, writes a site whose words are placeholders and whose
#' three sections hold one example item each. It is generated from [mui_default_config()]
#' rather than stored, so it cannot fall out of step with the code, and the first thing it
#' asks you to do is write rather than delete.
#'
#' `starter = "demo"` copies this package's own site instead - felixluginbuhl.com, the tree
#' under `inst/site`. It is a site that is really built and really published, so what it
#' shows cannot quietly rot. The trade is that the words in it
#' are somebody else's, and that its talks name slide decks too large to ship inside an R
#' package, so a first build of it warns about assets that are not there. Replace the words;
#' `hero`, `social`, `footer` and the content files are where the identity lives. The
#' writing, images and logos it copies are not covered by the package's MIT licence - see
#' `content/LICENSE-CONTENT.md` in the copy - and are there to be replaced, not republished.
#'
#' What the demo starter does *not* hand over is what would act as the author on your
#' behalf, invisibly from the page: there is no analytics id, the Twitter handle is commented
#' out, and the domain is replaced by yours - or, when you give neither `cname` nor `url`,
#' by the `https://example.com` placeholder the first build warns about.
#'
#' @param path Directory to create the site in. Created if missing.
#' @param cname The custom domain to serve the site at, written into the configuration and
#'   published as `CNAME`. Leave `NULL` for a site served at `<user>.github.io`, with or
#'   without a repository path, which needs none.
#' @param starter `"blank"` for placeholder words, `"demo"` for this author's real site.
#' @param overwrite Overwrite files that are already there. `FALSE` stops rather than
#'   quietly replacing a configuration someone has edited.
#' @param url The address the site is served at, when it is not `https://<cname>` - for a
#'   project site, `https://<user>.github.io/<repo>`. See [mui_read_config()].
#' @return `path`, invisibly.
#' @export
#' @examples
#' site <- file.path(tempdir(), "my-site")
#' mui_create_site(site)
#' list.files(site)
mui_create_site <- function(
  path = ".",
  cname = NULL,
  starter = c("blank", "demo"),
  overwrite = FALSE,
  url = NULL
) {
  starter <- match.arg(starter)
  url <- url %||% if (!is.null(cname)) paste0("https://", cname)
  if (!is.null(url)) url <- sub("/$", "", url)
  if (identical(starter, "blank")) {
    return(blank_site(path, cname, overwrite, url))
  }
  from <- system.file("site", package = "muiPersonalWebsite")

  if (!nzchar(from)) {
    stop(
      "the site template is missing from the installed package",
      call. = FALSE
    )
  }

  # `dot-` rather than `.` in the template tree: R CMD check reports a hidden directory
  # inside inst/ as a file included in error.
  files <- list.files(from, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  dest_of <- function(f) gsub("(^|/)dot-", "\\1.", f)
  # Reported under the names they would have on disk, not the ones the template tree uses:
  # being told `dot-github/...` already exists names a file the user has never seen.
  dests <- vapply(files, dest_of, character(1), USE.NAMES = FALSE)
  clash <- dests[file.exists(file.path(path, dests))]
  if (length(clash) && !overwrite) {
    stop(
      "these already exist in ",
      path,
      ": ",
      paste(clash, collapse = ", "),
      "\n  pass overwrite = TRUE to replace them",
      call. = FALSE
    )
  }

  for (f in files) {
    dest <- file.path(path, dest_of(f))
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    file.copy(file.path(from, f), dest, overwrite = TRUE)
  }

  # The domain is the one thing that cannot be guessed and that a site is wrong without, so
  # it is substituted rather than left for the reader to find in the file.
  config_path <- file.path(path, "mui.config.yml")
  config <- readLines(config_path, warn = FALSE, encoding = "UTF-8")
  config <- if (is.null(cname)) {
    sub("^  cname: .*$", "  # cname: www.example.com", config)
  } else {
    sub("^  cname: .*$", paste0("  cname: ", cname), config)
  }
  # Never the author's own domain: left in, every canonical, og: and sitemap URL of the
  # copy would point at felixluginbuhl.com. The placeholder is one the build warns about.
  config <- sub(
    "^url: .*$",
    paste0("url: ", url %||% mui_default_config()$url),
    config
  )
  config <- drop_analytics(config)
  config <- drop_twitter(config)
  write_utf8(paste(config, collapse = "\n"), config_path)

  created_message(path)
  message(
    "  The demo's words, images and logos are not MIT-licensed: replace them before ",
    "publishing.
  See content/LICENSE-CONTENT.md."
  )
  invisible(path)
}

# What to do next, and where the site can be served. Shared by both starters.
created_message <- function(path) {
  message(
    "site created in ",
    normalizePath(path, "/", mustWork = FALSE),
    "\n",
    "  1. edit mui.config.yml and content/*.yml\n",
    "  2. Rscript build.R docs\n",
    "  3. push, then switch on GitHub Pages for the main branch and /docs\n",
    "  `url` in mui.config.yml is where the site is served: a custom domain, or\n",
    "  https://<user>.github.io/<repo> for a project site."
  )
}

# The handle social cards credit the site to. Left in, every page shared from the copy
# would be attributed to the author's account rather than to its own.
drop_twitter <- function(config) {
  sub(
    "^twitter:.*$",
    "# twitter: \"@your-handle\"   # credited on social cards: yours, not the starter's",
    config
  )
}

# The one key the starter does not hand over. Everything else in it is words to be
# rewritten, and a name left in by accident is only embarrassing; an analytics id left in
# reports this site's traffic into somebody else's account, invisibly from the page.
drop_analytics <- function(config) {
  at <- grep("^counterdev:", config)
  if (!length(at)) {
    return(config)
  }
  # The block is the key plus the indented lines under it.
  last <- at
  while (
    last < length(config) && grepl("^(\\s+\\S|\\s*$)", config[last + 1L])
  ) {
    last <- last + 1L
  }
  # Trailing blank lines belong to whatever follows, not to the block being removed.
  while (last > at && !nzchar(trimws(config[last]))) {
    last <- last - 1L
  }
  c(
    config[seq_len(at - 1L)],
    "# counterdev: <your counter.dev id>   # analytics: yours, not the starter's",
    if (last < length(config)) config[seq(last + 1L, length(config))]
  )
}

# --- the blank starter -----------------------------------------------------------------
#
# Generated rather than stored. A second tree under inst/ would be a second site to keep in
# step with the code, and the whole argument for scaffolding the real one is that a site
# nobody builds goes stale - which a stored blank would too, quietly, since nobody builds
# that either. What is below is small enough to read in one screen, and every key in it is
# one mui_default_config() already documents.

BLANK_CONFIG <- '# Your site. Every key not named here keeps its default; run
# muiPersonalWebsite::mui_default_config() to see the full set, and
# vignette("customising") for what each one does.

title: Your Name
# Where the site is served: a domain, or https://<user>.github.io/<repo> for a project site.
url: https://example.com
description: One sentence about you, used as the page description and the social card.

pages:
  cname: www.example.com
  nojekyll: true

# The bands of the landing page, in order. Each `id` is at once the band\'s element id, the
# anchor its app bar tab points at, and what the hero\'s scroll cue targets - so renaming a
# section here moves all three together.
#
#   variant - how to draw it: cards, list, timeline, accordion, showcase or prose
#   nav     - the app bar tab\'s label; omit the key for a band with no tab
#   hero    - the one section whose items fill the honeycomb behind the hero
sections:
  - id: projects
    kicker: Things I built
    title: Projects
    nav: projects
    variant: cards
    columns: 3
    data: content/projects.yml
    hero: true
  - id: writing
    kicker: Posts and papers
    title: Writing
    nav: writing
    variant: list
    data: content/writing.yml
  - id: about
    kicker: Who I am
    title: About
    nav: about
    variant: prose
    data: content/about.yml

social:
  - {name: GitHub,   href: "https://github.com/your-handle"}
  - {name: LinkedIn, href: "https://linkedin.com/in/your-handle"}
hero_social: [GitHub, LinkedIn]

hero:
  greeting: "Hi, I\'m"
  name: Your Name
  role: What you do
  lead: >-
    Two lines about the work. This is the first thing anybody reads, so it is worth
    more time than the rest of this file put together.

theme:
  # auto follows the reader\'s system setting. light or dark pins the site to one.
  mode: auto
  # The palette is the package default. Name only the colours you change; see
  # mui_default_config() for the full set, and `palette_dark` for the dark scheme.
  # palette:
  #   primary: "#4f46e5"
'

BLANK_CONTENT <- list(
  "content/projects.yml" = '# `defaults` is merged under every item, and {slug} is expanded throughout - so a section
# states its conventions once instead of repeating two URLs per item.
defaults:
  primary:   {label: Docs,   href: "/{slug}/"}
  secondary: {label: Source, href: "https://github.com/your-handle/{slug}"}
items:
  - slug: example
    title: An example project
    description: One or two sentences. What it is, and who it is for.
    # A file in content/assets/, named the way that directory holds it.
    # image: example-logo.png
    date: 2025-01-01
',
  "content/writing.yml" = '# The `list` variant: a title, a line of context, and the links out. No pictures, so it
# suits posts, papers and talks that have no logo to show.
items:
  - title: An example post
    description: What it is about, in a sentence.
    date: 2025-01-01
    links:
      - {name: Read it, url: "https://example.com/post"}
',
  "content/about.yml" = '# The `prose` variant: a band that is a piece of writing rather than a list of things.
# `body` is markdown.
items:
  - body: |-
      A paragraph about you. **Markdown** works here, and so do [links](https://example.com)
      and lists.

      A second paragraph, if there is more to say.
'
)

BLANK_404 <- '---
title: Page not found
description: That page is not here.
---

The page you asked for is not here. Try the [home page]({base}/).
'

BLANK_BUILD <- '#!/usr/bin/env Rscript
# Rscript build.R [out_dir]   - out_dir defaults to docs/, which GitHub Pages can serve.
out <- commandArgs(trailingOnly = TRUE)[1]
muiPersonalWebsite::mui_build_site(if (is.na(out)) "docs" else out)
'

BLANK_GITIGNORE <- ".Rproj.user\n.Rhistory\n.RData\ndist/\n"

# The blank starter, written file by file. Shares mui_create_site()'s clash check, so the two
# starters refuse to overwrite an edited configuration in exactly the same way.
blank_site <- function(path, cname = NULL, overwrite = FALSE, url = NULL) {
  files <- c(
    list(
      "mui.config.yml" = BLANK_CONFIG,
      "404.md" = BLANK_404,
      "build.R" = BLANK_BUILD,
      ".gitignore" = BLANK_GITIGNORE,
      # An assets directory that is there and empty, so the first image has somewhere
      # obvious to go and the build has a tree to copy.
      "content/assets/.gitkeep" = ""
    ),
    BLANK_CONTENT
  )

  clash <- names(files)[file.exists(file.path(path, names(files)))]
  if (length(clash) && !overwrite) {
    stop(
      "these already exist in ",
      path,
      ": ",
      paste(clash, collapse = ", "),
      "\n  pass overwrite = TRUE to replace them",
      call. = FALSE
    )
  }

  # (?m) and perl: the configuration is one string with newlines in it, not a vector of
  # lines, so an unanchored `^` would only ever match at the very start of the file.
  line_sub <- function(x, pattern, value) {
    sub(paste0("(?m)^", pattern, "$"), value, x, perl = TRUE)
  }
  config <- files[["mui.config.yml"]]
  if (!is.null(url)) {
    config <- line_sub(config, "url: .*", paste0("url: ", url))
  }
  if (!is.null(cname)) {
    config <- line_sub(config, "  cname: .*", paste0("  cname: ", cname))
  } else {
    config <- line_sub(config, "  cname: .*", "  # cname: www.example.com")
  }
  files[["mui.config.yml"]] <- config

  for (f in names(files)) {
    write_utf8(files[[f]], file.path(path, f))
  }

  created_message(path)
  invisible(path)
}
