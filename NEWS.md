## muiPersonalWebsite 0.1.0

Initial release.

Changes made in the pre-release review:

* Content and page dates must be `YYYY-MM-DD`. A bare year such as `date: 2023` used to
  render as a day in 1975; it is now an error naming the file and the item.
* `{base}` in a markdown page or a `nav_links` href expands to the site's base path, so a
  link to the site's own root works on a GitHub Pages project site. Both 404 pages use it.
* Stricter configuration checks: a section `id` must be usable as an anchor, every
  `nav_links` entry needs a `text`, a showcase item needs a `slug` or a `title`, and a head
  value written as a YAML list is refused.
* The shipped demo site no longer carries an analytics id; it is added at publish time.
* The demo site's content (writing, images, logos) is marked as not MIT-licensed, in
  `content/LICENSE-CONTENT.md` and in the message `mui_create_site(starter = "demo")` prints.
