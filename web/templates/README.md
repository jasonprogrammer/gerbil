# Mustache templates

The files in this directory are HTML templates files for the site. Some are
"outer" templates that are used to define a consistent look across
different pages, and some are "inner" templates
(e.g. [home-content.html](home-content.html)) that contain HTML for a portion
of a page.

- site.html: The default "outer" template used across most pages of the site.
- site-blocks.html: This defines lots of customizable "mini" templates that are
  used to construct things like bread-crumb navigation.
- 404-content.html: An "inner" template used to display some custom 404 content.
- logo.html: This can be used with a **{{{logo}}}** mustache tag to put a logo
  on the page. **Important**: If you are going to use an SVG logo that contains
  a significant amount of XML, you will want to put the logo here to avoid a
  huge performance penalty incurred when the site.html is parsed by the
  mustache templating engine.
- home.html: This is an optional outer template file that does not exist by
  default. If created, this template will be used as the outer template for the
  home page.
- comments.html: This is the markup for the comment-form that is displayed at
  the bottom of articles (content pieces).
- content.html: This is a small template that wraps the article content. It is
  only used for articles, which is why it does not exist in the site.html.
- moderate\*.html: These templates are used for the comment moderation system.

## What Nim mustache templating library is used?

The [nim-mustache](https://github.com/soasme/nim-mustache) template library is
used for rendering these templates.
