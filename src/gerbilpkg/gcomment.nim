import glogging
import json
import markdown
import os
import strformat
import strutils
import times

#
# Meta
#
type
  CommentMeta* = ref object of RootObj
    id*: string
    hash*: string
    path*: string
    isPublished*: bool
    createdTS*: uint64 # seconds from epoch, UTC
    updatedTS*: uint64 # seconds from epoch, UTC

proc isCommentPublished(publishedPath: string): bool =
  if not existsFile(publishedPath):
    return false
  return readFile(publishedPath).strip() == "1"

proc getCommentMeta*(path, publishedPath: string): CommentMeta =
  if not existsFile(path):
    getLogger().info(fmt"Comment meta file: {path} does not exist")
    return

  new(result)
  result.path = path
  var metaJson = parseJson(readFile(path))
  result.id = metaJson["id"].getStr()
  result.hash = metaJson["hash"].getStr()
  result.createdTS = uint64(metaJson.getOrDefault("created_ts").getBiggestInt())
  result.updatedTS = uint64(metaJson.getOrDefault("updated_ts").getBiggestInt())

  result.isPublished = isCommentPublished(publishedPath)

proc newCommentMeta*(
  path, id: string
): CommentMeta =
  new(result)
  result.path = path
  result.id = id
  result.createdTS = uint64(epochTime())
  result.updatedTS = uint64(epochTime())

proc isCommentPublished*(this: CommentMeta): bool =
  return this.isPublished

proc save*(this: CommentMeta) =
  var meta = %*{
    "id": this.id,
    "hash": this.hash,
    "created_ts": this.createdTS,
    "updated_ts": this.updatedTS
  }
  writeFile(this.path, pretty(meta))

proc `$`*(this: CommentMeta): string =
  result = "CommentMeta:\n"
  result &= "  " & fmt("path: {this.path}\n")
  result &= "  " & fmt("id: {this.id}\n")
  result &= "  " & fmt("hash: {this.hash}\n")
  result &= "  " & fmt("created_ts: {this.createdTS}\n")
  result &= "  " & fmt("updated_ts: {this.updatedTS}\n")

#
# Comment
#
type
  Comment* = ref object of RootObj
    id*: string
    dir*: string
    metaPath*: string
    path*: string
    htmlPath*: string
    publishedPath*: string

type
  PendingCommentInfo* = ref object of RootObj
    podName*: string
    contentID*: string
    commentID*: string

proc newComment*(parentDir: string, id: string): Comment =
  new(result)
  result.id = id
  result.dir = joinPath(parentDir, id)
  result.metaPath = joinPath(result.dir, "meta.json")
  result.path = joinPath(result.dir, "content.md")
  result.htmlPath = joinPath(result.dir, "content.html")
  result.publishedPath = joinPath(result.dir, "published.txt")

proc getCommentMeta*(this: Comment): CommentMeta =
  return getCommentMeta(this.metaPath, this.publishedPath)

proc getMarkdown*(this: Comment): string =
  return readFile(this.path)

proc getMarkdownToHTML*(this: Comment): string =
  return markdown(readFile(this.path), initCommonmarkConfig(keepHtml=false))

proc isPublished*(this: Comment): bool =
  return isCommentPublished(this.publishedPath)

proc setPublished*(this: Comment, value: string) =
  assert value in @["0", "1"]
  writeFile(this.publishedPath, value)

proc updateMetaHash*(this: Comment, meta: CommentMeta, hash: string) =
  meta.hash = hash
  meta.save()

proc createComment*(this: Comment, mdContent: string) =
  getLogger().info(fmt"Creating comment in dir: {this.dir}")
  createDir(this.dir)
  var meta = newCommentMeta(this.metaPath, this.id)
  meta.save()

  writeFile(this.path, mdContent)

proc writeHTML*(this: Comment, html: string) =
  writeFile(this.htmlPath, html)
