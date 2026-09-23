# A site served under a path rather than at a domain root - a GitHub Pages project site at
# https://<user>.github.io/<repo>. Every URL the build writes into the tree has to carry that
# path, or the page loads none of its scripts and renders blank; every URL written for a
# scraper has to be absolute on the right host, without the path doubled.

project_config <- function(url = "https://someone.github.io/my-site") {
  mui_validate_config(modifyList(mui_default_config(), list(title = "P", url = url)))
}

test_that("the base path is read off url, and is empty at a domain root", {
  expect_equal(site_base(project_config()), "/my-site")
  expect_equal(site_origin(project_config()), "https://someone.github.io")
  expect_equal(site_base(project_config("https://example.com")), "")
  # A trailing slash is stripped by validation before anything reads it.
  expect_equal(site_base(project_config("https://someone.github.io/my-site/")), "/my-site")
})

test_that("a url without a scheme is refused rather than read as a path", {
  expect_error(project_config("example.com"), "`url` is example.com")
  expect_error(project_config("https://x.example/?q=1"), "`url`")
})

test_that("an asset named by filename resolves under the base path; a written path does not", {
  config <- project_config()
  expect_equal(mui_asset_url("logo.png", config), "/my-site/assets/logo.png")
  # "/BFS/" is a path on the host the author chose - on a project site, a sibling site.
  expect_equal(mui_asset_url("/BFS/", config), "/BFS/")
  expect_equal(mui_asset_url("https://cdn.example.org/x.png", config),
               "https://cdn.example.org/x.png")
})

test_that("head metadata is absolute on the right host, with the path once", {
  config <- project_config()
  config$default_image <- "card.png"
  h <- mui_head_meta(list(url = "/about.html", title = "About"), config)
  expect_match(h, 'rel="canonical" href="https://someone.github.io/my-site/about.html"',
               fixed = TRUE)
  expect_match(h, 'content="https://someone.github.io/my-site/assets/card.png"', fixed = TRUE)
  expect_false(grepl("my-site/my-site", h, fixed = TRUE))
  expect_match(h, 'href="/my-site/_mui/site.css"', fixed = TRUE)
})

test_that("a project site builds with every tree reference under its base path", {
  dir <- file.path(tempdir(), "base-path-site")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, url = "https://someone.github.io/my-site"))
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  expect_equal(config$url, "https://someone.github.io/my-site")
  expect_null(config$pages$cname)

  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  for (p in generated_pages(out)) {
    h <- slurp(out, p)
    expect_match(h, 'src="/my-site/_mui/libs/', fixed = TRUE, info = p)
    expect_match(h, 'href="/my-site/_mui/site.css"', fixed = TRUE, info = p)
    # No reference to the build's own trees is left at the host root.
    expect_false(grepl('(src|href)="/_mui/', h), info = p)
  }
  expect_match(slurp(out, "sitemap.xml"),
               "<loc>https://someone.github.io/my-site/</loc>", fixed = TRUE)
  # The 404's wordmark goes home to the site, not to the host - and so does the link in its
  # body, which is all a reader without JavaScript has.
  nf <- unescaped(slurp(out, "404.html"))
  expect_match(nf, '"href":"/my-site/"', fixed = TRUE)
  expect_match(nf, '<a href="/my-site/">home page</a>', fixed = TRUE)
  expect_false(grepl('href="/"', nf, fixed = TRUE))
  expect_false(grepl("{base}", nf, fixed = TRUE))
})

test_that("{base} expands to the base path, and to nothing at a domain root", {
  expect_equal(expand_base("{base}/about.html", project_config()), "/my-site/about.html")
  expect_equal(expand_base("{base}/about.html", project_config("https://example.com")),
               "/about.html")
  expect_equal(nav_href(list(href = "{base}/cv/"), project_config()), "/my-site/cv/")
  expect_equal(nav_href(list(anchor = "talks"), project_config()), "#talks")
})

test_that("a missing asset is still reported on a project site", {
  dir <- file.path(tempdir(), "base-path-missing")
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, url = "https://someone.github.io/my-site"))
  yml <- file.path(dir, "content", "projects.yml")
  writeLines(sub("# image: example-logo.png", "image: not-there.png",
                 readLines(yml, encoding = "UTF-8"), fixed = TRUE), yml)
  expect_warning(
    suppressMessages(mui_build_site(out_dir = file.path(dir, "_out"), input = dir)),
    "/my-site/assets/not-there.png",
    fixed = TRUE
  )
})
