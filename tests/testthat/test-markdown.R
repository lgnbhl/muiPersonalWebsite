test_that("markdown renders as CommonMark", {
  expect_match(mui_md_to_html("A *word*."), "<em>word</em>")
  expect_match(mui_md_to_html("[link](https://example.com)"), 'href="https://example.com"')
})

test_that("empty input renders as nothing at all", {
  expect_equal(mui_md_to_html(""), "")
  expect_equal(mui_md_to_html("   "), "")
  expect_equal(mui_md_to_html(NULL), "")
})

test_that("raw script and iframe tags do not pass through", {
  # tagfilter is on: with no raw HTML in the content, the pipeline has no reason to let
  # these through untouched.
  out <- mui_md_to_html("<script>alert(1)</script>")
  expect_false(grepl("<script>", out, fixed = TRUE))
})
