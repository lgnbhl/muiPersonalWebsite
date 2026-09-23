# Helpers shared across the package: coalescing, list merging, HTML escaping, colour
# conversion and markdown rendering. Markdown is rendered in one place only - the body of a
# .md page - so there is one function for it and no inline variant.

# yaml gives NULL for a key that is missing and NA for one written with no value, so both
# have to fall through to the default.
`%||%` <- function(x, y) {
  if (is.null(x) || (length(x) == 1 && is.na(x))) y else x
}

# Recursive merge of `over` onto `base`: a list in both is merged key by key, anything else
# in `over` replaces. This is what lets a configuration name only the keys it changes.
merge_lists <- function(base, over) {
  if (!length(over)) {
    return(base)
  }
  for (k in names(over)) {
    base[[k]] <- if (
      is.list(base[[k]]) && is.list(over[[k]]) && !is.null(names(over[[k]]))
    ) {
      merge_lists(base[[k]], over[[k]])
    } else {
      over[[k]]
    }
  }
  base
}

# A content date as the ISO string every reader of it expects, checked once at the door.
# YAML reads `date: 2023` as the integer 2023, which as.Date() quietly turns into a day in
# 1975 - so anything that is not a whole YYYY-MM-DD is refused, naming where it came from.
iso_date <- function(x, where) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "Date") && length(x) == 1L && !is.na(x)) {
    return(format(x, "%Y-%m-%d"))
  }
  if (
    is.character(x) && length(x) == 1L &&
      grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x) &&
      !is.na(as.Date(x, optional = TRUE))
  ) {
    return(x)
  }
  hint <- if (is.numeric(x) && length(x) == 1L && x >= 1000 && x <= 9999) {
    paste0(" such as '", x, "-01-01'")
  } else {
    ""
  }
  stop(
    where, " has date ", paste(format(x), collapse = ", "),
    "; write it as 'YYYY-MM-DD'", hint,
    call. = FALSE
  )
}

# htmlEscape() alone escapes &, < and > but not the double quote that would close the
# attribute it sits in - which is the escape that matters, since every attribute this
# package writes is quoted with ". A NULL is an absent value rather than the string "NULL".
attr_esc <- function(x) htmlEscape(as.character(x %||% ""), attribute = TRUE)
text_esc <- function(x) htmlEscape(as.character(x %||% ""))

# "#4f46e5" -> "79,70,229". A CSS rule cannot take an opaque hex apart, so it is handed
# the pieces.
hex_channels <- function(hex) {
  paste(
    strtoi(substring(gsub("^#", "", hex), c(1, 3, 5), c(2, 4, 6)), 16L),
    collapse = ","
  )
}

# A colour at an alpha, from either a hex or the bare channels the palette stores it as.
rgba <- function(colour, alpha) {
  sprintf(
    "rgba(%s,%s)",
    if (startsWith(colour, "#")) hex_channels(colour) else colour,
    alpha
  )
}

# `tagfilter` is on: the content is ordinary CommonMark, so the pipeline does not need to
# pass <iframe> and <script> through untouched. It is not sanitising - other raw HTML,
# attributes included, passes through as CommonMark says it should - so the markdown is
# trusted as the site author's own.
mui_md_to_html <- function(md) {
  if (is.null(md) || !nzchar(trimws(md))) {
    return("")
  }
  commonmark::markdown_html(md, smart = TRUE, extensions = "tagfilter")
}
