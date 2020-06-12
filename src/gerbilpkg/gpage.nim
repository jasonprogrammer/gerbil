import markdown
import os
import regex
import strformat

# This file exists because I got weird conflicts/errors importing markdown in
# gsite.nim

proc getHTMLFromMarkdown*(mdPath: string): string =
  return markdown(
    readFile(mdPath), initCommonmarkConfig(keepHtml=true)
  )

proc isPageSlugValid*(slug, pagesDir: string): bool =
  var regexMatch: RegexMatch
  return (
    (len(slug) <= 130) and
    slug.match(re"^[\w\-]+$", regexMatch) and
    existsFile(joinPath(pagesDir, fmt"{slug}.html"))
  )


