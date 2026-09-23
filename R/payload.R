# Making the JavaScript bundle smaller, on the way into the built tree.
#
# The site cannot do without `shiny.react`: `findAndRenderReactData()` is what finds each
# `<script class="react-data">` block and mounts React over it, so dropping the dependency
# would leave every page as the JSON blob it starts life as. What it *can* do without is
# most of the bundle's weight.
#
# 481 KB of `shiny-react.js`'s 653 KB is the whole of lodash, unminified. One module imports
# it - `src/react/adapters.js` - and imports exactly two names, `debounce` and `throttle`,
# which it re-exports and never calls. They are part of shiny.react's public JavaScript API,
# for an app author writing a `JS()` callback; a static page has no `.shinyInput` on it and
# never reaches them.
#
# So the lodash module is replaced, in the copy under `_mui/libs` and never in the installed
# package, with a small one providing those two functions. The rest of the bundle is
# untouched, and the module map it lives in does not care what is behind a key.
#
# This reaches into another package's build output, which is only defensible because it
# refuses to guess. Every assumption above is checked against the file in front of it, and
# any one of them failing leaves the bundle exactly as it was. See lodash_stub_ok().

# The bundle, and the module inside it. Both are shiny.react's own paths; if either moves,
# the checks below find nothing and nothing is rewritten.
TRIM_TARGET <- list(
  dep = "shiny.react",
  file = "shiny-react.js",
  module = "./node_modules/lodash/lodash.js"
)

# The two names, implemented rather than stubbed out. A `debounce` that silently never fired
# would be a far worse thing to ship than the 481 KB it saves - and these are thirty lines.
LODASH_STUB <- '/***/ "./node_modules/lodash/lodash.js":
/***/ ((module) => {

// Replaced at build time by muiPersonalWebsite. The original module is the whole of lodash,
// 481 KB of it, imported by src/react/adapters.js for the two names below - which it
// re-exports and never calls. A statically built page has no Shiny inputs on it and never
// reaches them either. Implemented rather than stubbed, so that anything which does reach
// them gets a working function rather than a silent no-op.
function debounce(fn, wait, options) {
  wait = wait || 0;
  var leading = !!(options && options.leading);
  var trailing = !options || options.trailing !== false;
  var timer = null, lastArgs = null, lastThis = null, result;
  function invoke() {
    timer = null;
    if (trailing && lastArgs) {
      result = fn.apply(lastThis, lastArgs);
      lastArgs = lastThis = null;
    }
  }
  function debounced() {
    lastArgs = arguments;
    lastThis = this;
    var first = timer === null;
    if (timer !== null) clearTimeout(timer);
    timer = setTimeout(invoke, wait);
    if (first && leading) {
      result = fn.apply(lastThis, lastArgs);
      lastArgs = lastThis = null;
    }
    return result;
  }
  debounced.cancel = function () {
    if (timer !== null) clearTimeout(timer);
    timer = null;
    lastArgs = lastThis = null;
  };
  debounced.flush = function () {
    if (timer !== null) invoke();
    return result;
  };
  return debounced;
}

function throttle(fn, wait, options) {
  var leading = !options || options.leading !== false;
  var trailing = !options || options.trailing !== false;
  return debounce(fn, wait, { leading: leading, trailing: trailing });
}

module.exports = { debounce: debounce, throttle: throttle };

/***/ }),

'

# The module's text, from its header to the start of the next one. NULL when the bundle does
# not hold a module under that key at all.
bundle_module <- function(js, key) {
  head <- paste0('/***/ "', key, '":')
  at <- regexpr(head, js, fixed = TRUE)
  if (at < 0) {
    return(NULL)
  }
  rest <- substring(js, at + nchar(head))
  nxt <- regexpr('/***/ "', rest, fixed = TRUE)
  list(
    start = at,
    stop = if (nxt < 0) nchar(js) else at + nchar(head) + nxt - 2L
  )
}

# Whether this bundle is the one the stub was written against. Three questions, and a no to
# any of them means the bundle is left alone:
#
#   1. Is the lodash module there, under the key the stub replaces?
#   2. Is it imported exactly once, so there is one importer to reason about?
#   3. Does anything reach for a lodash name the stub does not provide?
#
# The third is the one that matters. shiny.react is free to start using `_.merge` in a
# release, and a rewrite that had not noticed would produce a site that builds cleanly and is
# blank in the browser - the exact failure this package spends its error messages avoiding.
lodash_stub_ok <- function(js, provided = c("debounce", "throttle")) {
  if (is.null(bundle_module(js, TRIM_TARGET$module))) {
    return("the bundle has no lodash module to replace")
  }
  imports <- gregexpr(
    "var ([A-Za-z0-9_$]+) = __webpack_require__\\([^\"]*\"[.][/]node_modules[/]lodash[/]lodash[.]js\"\\)",
    js
  )[[1]]
  if (length(imports) != 1L || imports[1] < 0) {
    return("lodash is imported somewhere other than the one module this expects")
  }
  var <- sub(
    "^var ([A-Za-z0-9_$]+) .*$",
    "\\1",
    regmatches(js, gregexpr("var [A-Za-z0-9_$]+ = __webpack_require__\\([^\"]*\"[.][/]node_modules[/]lodash[/]lodash[.]js\"\\)", js))[[1]][1]
  )
  used <- unique(sub(
    paste0("^", var, "[.]"),
    "",
    regmatches(js, gregexpr(paste0(var, "[.][A-Za-z_$][A-Za-z0-9_$]*"), js))[[1]]
  ))
  unknown <- setdiff(used, provided)
  if (length(unknown)) {
    return(paste0(
      "the bundle uses lodash names this does not provide: ",
      paste(sort(unknown), collapse = ", ")
    ))
  }
  ""
}

# The source map comment at the foot of the bundle, pointing at a file DEAD_WEIGHT has just
# deleted. Harmless - only devtools ever asks for it - but it is a 404 against the site, and
# the file is being rewritten anyway.
drop_sourcemap <- function(js) {
  sub("\n//# sourceMappingURL=[^\n]*\n?$", "\n", js)
}

#' Trim the copied JavaScript
#'
#' Rewrites `shiny-react.js` in place, under `_mui/libs`, replacing the whole of lodash with
#' the two functions the bundle actually imports from it. Roughly 470 KB of the built site's
#' 1.4 MB, and the one saving available without a JavaScript toolchain: `shiny.react` itself
#' is what mounts every page and cannot be dropped, and the MUI bundle beside it is already
#' minified.
#'
#' Every assumption is checked against the bundle in front of it, and any one of them failing
#' leaves the file untouched and reports why. `trim_payload: false` turns it off.
#'
#' @param dir The dependency's directory in the built tree.
#' @param name The dependency's name.
#' @inheritParams mui_theme
#' @return The bytes saved, invisibly - `0` when nothing was rewritten.
#' @family render
#' @keywords internal
mui_trim_payload <- function(dir, name, config = mui_config()) {
  if (
    !isTRUE(config$trim_payload %||% TRUE) ||
      !identical(name, TRIM_TARGET$dep)
  ) {
    return(invisible(0))
  }
  path <- file.path(dir, TRIM_TARGET$file)
  if (!file.exists(path)) {
    return(invisible(0))
  }

  js <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  why <- lodash_stub_ok(js)
  if (nzchar(why)) {
    warning(
      "site: the JavaScript bundle was left at full size - ",
      why,
      ".\n  This is shiny.react ",
      as.character(utils::packageVersion("shiny.react")),
      "; the trim in R/payload.R was written against a bundle that imports lodash for ",
      "`debounce` and `throttle` alone. Set `trim_payload: false` to silence this.",
      call. = FALSE
    )
    return(invisible(0))
  }

  at <- bundle_module(js, TRIM_TARGET$module)
  before <- nchar(js, type = "bytes")
  js <- paste0(
    substring(js, 1, at$start - 1L),
    LODASH_STUB,
    substring(js, at$stop + 1L)
  )
  write_utf8(drop_sourcemap(js), path)
  invisible(before - nchar(js, type = "bytes"))
}
