import glogging
import json
import markdown
import os
import re
import strformat
import strutils
import times
import utils

#
# Meta
#
type
  ContentMeta* = ref object of RootObj
    id*: string
    slug*: string
    tags*: seq[string]
    hash*: string
    title*: string
    path*: string
    isPublished*: bool
    contentType: string
    createdTS*: uint64 # seconds from epoch, UTC
    updatedTS*: uint64 # seconds from epoch, UTC

proc getContentMeta*(path, publishedPath: string): ContentMeta =
  if not fileExists(path):
    getLogger().info(fmt"Content meta file: {path} does not exist")
    return

  new(result)
  result.path = path
  var metaJson = parseJson(readFile(path))
  result.id = metaJson["id"].getStr()
  result.slug = metaJson["slug"].getStr()

  var elems = metaJson["tags"].getElems()
  for elem in elems:
    result.tags.add(elem.getStr())

  result.hash = metaJson["hash"].getStr()
  result.title = metaJson["title"].getStr()

  result.contentType = "content"
  if "content_type" in metaJson:
    result.contentType = metaJson["content_type"].getStr()

  result.createdTS = uint64(metaJson.getOrDefault("created_ts").getBiggestInt())
  result.updatedTS = uint64(metaJson.getOrDefault("updated_ts").getBiggestInt())

  result.isPublished = readFile(publishedPath).strip() == "1"

proc newContentMeta*(
  path, id, title: string, slug=""
): ContentMeta =
  new(result)
  result.path = path
  result.id = id
  result.title = title
  if slug == "":
    result.slug = if slug == "": getRandStr(8) else: slug
  result.content_type = "content"
  result.createdTS = uint64(epochTime())
  result.updatedTS = uint64(epochTime())

proc isContentPublished*(this: ContentMeta): bool =
  if this.contentType in @["subcontent"]:
    return false
  return this.isPublished

proc save*(this: ContentMeta) =
  var meta = %*{
    "id": this.id,
    "slug": this.slug,
    "tags": this.tags,
    "hash": this.hash,
    "title": this.title,
    "content_type": this.contentType,
    "created_ts": this.createdTS,
    "updated_ts": this.updatedTS
  }
  writeFile(this.path, pretty(meta))

proc `$`*(this: ContentMeta): string =
  result = "ContentMeta:\n"
  result &= "  " & fmt("path: {this.path}\n")
  result &= "  " & fmt("id: {this.id}\n")
  result &= "  " & fmt("slug: {this.slug}\n")
  result &= "  " & fmt("tags: {this.tags}\n")
  result &= "  " & fmt("hash: {this.hash}\n")
  result &= "  " & fmt("title: {this.title}\n")

#
# Content
#
type
  Content* = ref object of RootObj
    id*: string
    dir*: string
    metaPath*: string
    path*: string
    htmlPath*: string
    publishedPath*: string
    commentsDir*: string
    commentsHTMLPath*: string
    staticDir*: string

  LinkAtxHeadingParser = ref object of AtxHeadingParser
  LinkHeading = ref object of Heading

proc newContent*(parentDir: string, id: string): Content =
  new(result)
  result.id = id
  result.dir = joinPath(parentDir, id)
  result.metaPath = joinPath(result.dir, "meta.json")
  result.path = joinPath(result.dir, "content.md")
  result.htmlPath = joinPath(result.dir, "content.html")
  result.publishedPath = joinPath(result.dir, "published.txt")
  result.commentsDir = joinPath(result.dir, "comments")
  result.commentsHTMLPath = joinPath(result.commentsDir, "comments.html")
  result.staticDir = joinPath(result.dir, "static")

proc getLastBuildModPath*(this: Content): string =
  return joinPath(this.dir, ".buildts")

proc getLastBuildMod*(this: Content): int64 =
  let lastmodPath = this.getLastBuildModPath()
  if not fileExists(lastmodPath):
    return 0
  return parseBiggestInt(readFile(lastmodPath))

proc getMDLastMod*(this: Content): int64 =
  return getLastModificationTime(this.path).toUnix()

proc getCommentIDs*(this: Content): seq[string] =
  if not dirExists(this.commentsDir):
    return result

  for kind, path in walkDir(this.commentsDir, true):
    if kind == pcDir:
      result.add(path)

proc getMeta*(this: Content): ContentMeta =
  return getContentMeta(this.metaPath, this.publishedPath)

method `$`*(token: LinkHeading): string {.locks: "unknown".} =
  let num = fmt"{token.level}"
  let child = $token.children
  let anchorName = child.strip().toLower().replace(re"\W+", "")
  result = (
    fmt("<h{num}><a class=\"st-header-anchor\" id=\"{anchorName}\"") &
    fmt(" href=\"#{anchorName}\">{child}</a></h{num}>")
  )

proc writeBuildMod*(this: Content) =
  let ts = int64(epochTime())
  writeFile(this.getLastBuildModPath(), fmt"{ts}")

method parse(
  this: LinkAtxHeadingParser, doc: string, start: int = 0
): ParseResult {.locks: "unknown".} =
  let res = doc.getAtxHeading(start)
  if res.size == -1: return ParseResult(token: nil, pos: -1)
  return ParseResult(
    token: LinkHeading(
      doc: res.doc,
      level: res.level,
    ),
    pos: start+res.size
  )

proc getMarkdownToHTML*(this: Content): string =
  let blockParsers = @[
    ReferenceParser(),
    ThematicBreakParser(),
    BlockquoteParser(),
    UlParser(),
    OlParser(),
    IndentedCodeParser(),
    FencedCodeParser(),
    HtmlBlockParser(),
    LinkAtxHeadingParser(),
    SetextHeadingParser(),
    BlanklineParser(),
    ParagraphParser(),
  ]
  return markdown(
    readFile(this.path), initCommonmarkConfig(
      keepHtml=true, blockParsers=blockParsers
    )
  )

proc getTitleFromMarkdown*(this: Content): string =
  result = ""
  for rawLine in lines(this.path):
    var line = rawLine.strip()
    if line.startsWith("# "):
      return line[2.. ^1]

proc getSlugFromTitle*(title: string): string =
  result = title.strip().replace(" ", "-").replace(
    re"[^a-zA-Z0-9_-]+", ""
  ).toLower()
  let maxLen = 80
  if len(result) > maxLen:
    result = result[0..maxLen-1]
  if result[^1] == '-':
    return result[0..len(result)-2]
  return result

proc isPublished*(this: Content): bool =
  return readFile(this.publishedPath).strip() == "1"

proc setMetaAttrsFromMarkdown*(this: Content, meta: ContentMeta) =
  var markdownTitle = this.getTitleFromMarkdown()
  if markdownTitle != "":
    meta.title = markdownTitle

    var slug = getSlugFromTitle(markdownTitle)
    if slug != "":
      meta.slug = slug
    meta.save()

proc updateMetaHash*(this: Content, meta: ContentMeta, hash: string) =
  meta.hash = hash
  meta.save()

proc scaffold*(this: Content) =
  getLogger().info(fmt"Creating content in dir: {this.dir}")
  createDir(this.dir)
  getLogger().info(fmt"Creating content static dir: {this.staticDir}")
  createDir(this.staticDir)
  setFilePermissions(this.staticDir, {
    fpUserRead, fpUserWrite, fpUserExec,
    fpGroupWrite, fpGroupRead, fpGroupExec,
    fpOthersRead, fpOthersExec
  })
  createDir(this.commentsDir)
  var titleID = getRandStr(8)
  getLogger().info(fmt"Creating meta file: {this.metaPath}")
  var meta = newContentMeta(this.metaPath, this.id, "MyTitle" & titleid)
  meta.save()

  writeFile(this.publishedPath, "1")

  getLogger().info(fmt"Creating content markdown file: {this.path}")
  writeFile(this.path, "# My Title\n\n")

proc writeHTML*(this: Content, html: string) =
  writeFile(this.htmlPath, html)
