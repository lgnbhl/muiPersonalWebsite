config <- mui_validate_config(modifyList(mui_default_config(), list(
  title       = "A Site",
  url         = "https://example.com",
  description = "The site description.",
  twitter     = "@handle",
  default_image = "/static/social.png",
  counterdev  = "abc123",
  feed        = "https://elsewhere.example.com/feed"
)))

test_that("a page's own title and description win over the site's", {
  page <- list(url = "/talks/x/", title = "A Talk", description = "About a thing.")
  h <- mui_head_meta(page, config)
  expect_match(h, "<title>A Talk | A Site</title>", fixed = TRUE)
  expect_match(h, 'content="About a thing."', fixed = TRUE)
})

test_that("the home page is titled with the site alone, not doubled", {
  h <- mui_head_meta(list(url = "/"), config)
  expect_match(h, "<title>A Site</title>", fixed = TRUE)
  expect_false(grepl("A Site | A Site", h, fixed = TRUE))
})

test_that("front matter carrying an empty title falls back to the site's", {
  expect_match(mui_head_meta(list(url = "/x/", title = "  "), config),
               "<title>A Site</title>", fixed = TRUE)
})

test_that("canonical and og urls are absolute, as scrapers need them", {
  h <- mui_head_meta(list(url = "/talks/x/", title = "T"), config)
  expect_match(h, '<link rel="canonical" href="https://example.com/talks/x/">',
               fixed = TRUE)
  expect_match(h, 'property="og:url" content="https://example.com/talks/x/"',
               fixed = TRUE)
  # A page with no image of its own still gets an absolute one.
  expect_match(h, 'content="https://example.com/static/social.png"', fixed = TRUE)
})

test_that("a dated page is an article and carries its publication time", {
  h <- mui_head_meta(list(url = "/talks/x/", title = "T", date = "2025-04-01"), config)
  expect_match(h, 'property="og:type" content="article"', fixed = TRUE)
  expect_match(h, 'property="article:published_time" content="2025-04-01"', fixed = TRUE)
  # An undated one is a website.
  expect_match(mui_head_meta(list(url = "/", title = "T"), config),
               'property="og:type" content="website"', fixed = TRUE)
})

test_that("optional identity is omitted rather than emitted empty", {
  bare <- mui_validate_config(modifyList(mui_default_config(),
                                     list(title = "B", url = "https://b.example.com")))
  h <- mui_head_meta(list(url = "/"), bare)
  expect_false(grepl("counter.dev", h, fixed = TRUE))
  expect_false(grepl("application/rss+xml", h, fixed = TRUE))
  # The configured site does emit both.
  full <- mui_head_meta(list(url = "/"), config)
  expect_match(full, 'data-id="abc123"', fixed = TRUE)
  expect_match(full, "https://elsewhere.example.com/feed", fixed = TRUE)
})

test_that("metadata content is escaped", {
  h <- mui_head_meta(list(url = "/", title = 'Quote " and <tag>'), config)
  expect_false(grepl('content="Quote " and', h, fixed = TRUE))
  expect_match(h, "&lt;tag&gt;", fixed = TRUE)
})

test_that("the sitemap lists absolute urls and carries dates when it has them", {
  x <- mui_sitemap_xml(c("/", "/404.html"), c("2025-01-01", ""), config)
  expect_match(x, "<loc>https://example.com/</loc>", fixed = TRUE)
  expect_match(x, "<lastmod>2025-01-01</lastmod>", fixed = TRUE)
  # An undated page gets a bare entry rather than an empty lastmod.
  expect_false(grepl("<lastmod></lastmod>", x, fixed = TRUE))
})

test_that("robots points crawlers at the sitemap", {
  expect_match(mui_robots_txt(config), "Sitemap: https://example.com/sitemap.xml", fixed = TRUE)
})

test_that("the landing page carries a Person block, and no other page does", {
  config <- modifyList(mui_default_config(), list(
    title = "X", url = "https://x.example", description = "About X.",
    hero = list(name = "A. Person", role = "Data scientist")))
  # Assigned, not merged: modifyList() recurses into a list and leaves an unnamed one alone.
  config$social <- list(list(name = "GitHub", href = "https://github.com/x"))
  home <- mui_head_meta(list(url = "/", title = "X"), config)
  expect_match(home, '"@type":"Person"', fixed = TRUE)
  expect_match(home, '"name":"A. Person"', fixed = TRUE)
  expect_match(home, '"jobTitle":"Data scientist"', fixed = TRUE)
  expect_match(home, '"sameAs":["https://github.com/x"]', fixed = TRUE)
  # A Person block on the 404 would claim the error page is a person.
  expect_false(grepl("ld+json", mui_head_meta(list(url = "/404.html"), config), fixed = TRUE))
  expect_false(grepl("ld+json", mui_head_meta(list(url = "/"), modifyList(config, list(jsonld = FALSE))),
                     fixed = TRUE))
})

test_that("a value cannot close the ld+json block it sits inside", {
  config <- modifyList(mui_default_config(), list(
    title = "X", url = "https://x.example",
    hero = list(name = '</script><script>alert("x")')))
  out <- mui_head_meta(list(url = "/"), config)
  expect_false(grepl("</script><script>", out, fixed = TRUE))
  expect_match(out, "u003c", fixed = TRUE)
})

test_that("the counter.dev offset is the site's own, not this package's", {
  config <- modifyList(mui_default_config(), list(title = "X", url = "https://x.example"))
  plain <- mui_head_meta(list(url = "/"), modifyList(config, list(counterdev = "abc")))
  expect_match(plain, 'data-id="abc" data-utcoffset="0"', fixed = TRUE)
  zurich <- mui_head_meta(list(url = "/"),
                      modifyList(config, list(counterdev = list(id = "abc", utcoffset = 2))))
  expect_match(zurich, 'data-utcoffset="2"', fixed = TRUE)
  expect_false(grepl("counter.dev", mui_head_meta(list(url = "/"), config), fixed = TRUE))
})

test_that("the 404 is noindex and nothing else is", {
  expect_match(mui_head_meta(list(url = "/404.html"), config),
               '<meta name="robots" content="noindex">', fixed = TRUE)
  expect_false(grepl("noindex", mui_head_meta(list(url = "/"), config), fixed = TRUE))
})

test_that("a page with no image, on a site with none, carries no image tags", {
  # The failure this replaces: abs_url("") is the site's own URL, so the card pointed its
  # picture at an HTML page.
  bare <- mui_validate_config(modifyList(mui_default_config(),
                                         list(title = "B", url = "https://b.example.com")))
  h <- mui_head_meta(list(url = "/about.html", title = "About"), bare)
  expect_false(grepl("og:image", h, fixed = TRUE))
  expect_false(grepl("twitter:image", h, fixed = TRUE))
  # A large card with no picture is an empty frame, so the card shrinks to fit.
  expect_match(h, 'name="twitter:card" content="summary"', fixed = TRUE)
  # With one, the large card stays.
  expect_match(mui_head_meta(list(url = "/"), config),
               'name="twitter:card" content="summary_large_image"', fixed = TRUE)
})

test_that("an off-site image is used as it is, not pasted onto the site's url", {
  h <- mui_head_meta(list(url = "/", image = "https://cdn.example.org/card.png"), config)
  expect_match(h, 'property="og:image" content="https://cdn.example.org/card.png"',
               fixed = TRUE)
})

test_that("the Person block is valid JSON whatever control characters a value carries", {
  s <- json_str("a\tb\rc\nd\001e")
  expect_equal(s, '"a\\tb\\rc\\nd\\u0001e"')
  # Decoded by a real parser, it is the string it started as.
  skip_if_not_installed("jsonlite")
  expect_equal(jsonlite::fromJSON(paste0("[", s, "]")), "a\tb\rc\nd\001e")
})

test_that("a sitemap url carrying an ampersand is escaped, not left to break the XML", {
  x <- mui_sitemap_xml("/a&b.html", config = config)
  expect_match(x, "<loc>https://example.com/a&amp;b.html</loc>", fixed = TRUE)
  expect_false(grepl("a&b", x, fixed = TRUE))
})
