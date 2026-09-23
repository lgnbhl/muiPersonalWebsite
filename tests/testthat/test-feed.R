# The feed. `feed:` is two things under one name: a URL is a feed somewhere else and is only
# advertised, `true` is one this build writes.

feed_site <- function(name, dated = TRUE) {
  dir <- file.path(tempdir(), name)
  unlink(dir, recursive = TRUE)
  suppressMessages(mui_create_site(dir, cname = "www.example.org"))
  dir.create(file.path(dir, "pages"), showWarnings = FALSE, recursive = TRUE)
  writeLines(
    c(
      "---",
      "title: A post",
      "description: What it is about.",
      if (dated) "date: '2025-03-14'",
      "---",
      "",
      "Words."
    ),
    file.path(dir, "pages", "post.md")
  )
  writeLines(
    c("---", "title: Colophon", "---", "", "No date, so not a post."),
    file.path(dir, "pages", "colophon.md")
  )
  dir
}

test_that("feed: true writes a feed and advertises it", {
  dir <- feed_site("feed-on")
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  config$feed <- TRUE
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, config = config, quiet = TRUE)

  xml <- slurp(out, "feed.xml")
  expect_match(xml, '<rss version="2.0"', fixed = TRUE)
  expect_match(xml, "<title>A post</title>", fixed = TRUE)
  expect_match(xml, "<link>https://www.example.org/post.html</link>", fixed = TRUE)
  # RFC 822, which is what RSS wants and nothing else on the site uses. The build pins
  # LC_TIME to C, so the day and month names are the English ones the format requires
  # rather than the build machine's.
  expect_match(xml, "<pubDate>Fri, 14 Mar 2025 00:00:00 +0000</pubDate>", fixed = TRUE)
  # A feed has to say where it lives or a copy of it cannot be told from the original.
  expect_match(
    xml,
    'href="https://www.example.org/feed.xml" rel="self"',
    fixed = TRUE
  )

  # An undated page is a colophon, not a post: a reader pushed one on every edit would be
  # right to unsubscribe.
  expect_false(grepl("Colophon", xml, fixed = TRUE))

  expect_match(
    slurp(out, "index.html"),
    'href="https://www.example.org/feed.xml"',
    fixed = TRUE
  )
})

test_that("a feed: URL is advertised and not generated", {
  dir <- feed_site("feed-elsewhere")
  config <- mui_read_config(file.path(dir, "mui.config.yml"))
  config$feed <- "https://someone.substack.com/feed"
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, config = config, quiet = TRUE)

  expect_false(file.exists(file.path(out, "feed.xml")))
  expect_match(
    slurp(out, "index.html"),
    "https://someone.substack.com/feed",
    fixed = TRUE
  )
})

test_that("no feed key means no feed and no link", {
  dir <- feed_site("feed-off")
  out <- file.path(dir, "_out")
  mui_build_site(out_dir = out, input = dir, quiet = TRUE)
  expect_false(file.exists(file.path(out, "feed.xml")))
  expect_false(
    grepl("application/rss+xml", slurp(out, "index.html"), fixed = TRUE)
  )
})

test_that("a feed with nothing dated in it is still a valid feed", {
  # An empty channel, not a broken document: a site whose writing has not started yet should
  # not publish a file no reader can parse.
  config <- mui_default_config()
  config$title <- "T"
  config$url <- "https://x.example"
  xml <- mui_feed_xml(list(), config)
  expect_match(xml, "<channel>", fixed = TRUE)
  expect_match(xml, "</rss>", fixed = TRUE)
  expect_false(grepl("<item>", xml, fixed = TRUE))
})

test_that("the feed escapes what it carries", {
  config <- mui_default_config()
  config$title <- "Ampersands & Co"
  config$url <- "https://x.example"
  page <- list(
    url = "/p.html",
    title = 'a <b> & "c"',
    date = "2025-01-01",
    description = "1 < 2 & 3 > 2"
  )
  xml <- mui_feed_xml(list(page), config)
  expect_match(xml, '<title>a &lt;b&gt; &amp; "c"</title>', fixed = TRUE)
  expect_match(xml, "<description>1 &lt; 2 &amp; 3 &gt; 2</description>", fixed = TRUE)
  expect_match(xml, "<title>Ampersands &amp; Co</title>", fixed = TRUE)
  # The ampersand is escaped once, not twice: a feed full of &amp;amp; is a feed whose
  # escaping ran over its own output.
  expect_false(grepl("&amp;amp;", xml, fixed = TRUE))
})

test_that("the newest post leads the feed", {
  config <- mui_default_config()
  config$title <- "T"
  config$url <- "https://x.example"
  pages <- list(
    list(url = "/old.html", title = "Old", date = "2024-01-01"),
    list(url = "/new.html", title = "New", date = "2025-01-01")
  )
  xml <- mui_feed_xml(pages, config)
  expect_lt(
    regexpr("<title>New</title>", xml, fixed = TRUE),
    regexpr("<title>Old</title>", xml, fixed = TRUE)
  )
})
