import gcontent
import glogging
import json
import mustache
import os
import strformat
import tables
import "utils"

#
# Meta
#
type
  PodMeta* = ref object of RootObj
    title*: string
    path*: string

proc getMeta*(path: string): PodMeta =
  if not existsFile(path):
    getLogger().info(fmt"Pod meta file: {path} does not exist")
    return

  new(result)
  result.path = path
  var metaJson = parseJson(readFile(path))
  result.title = metaJson["title"].getStr()

proc newPodMeta*(path, title: string): PodMeta =
  new(result)
  result.path = path
  result.title = title

proc save*(this: PodMeta) =
  var meta = %*{
    "title": this.title
  }
  writeFile(this.path, pretty(meta))

proc `$`*(this: PodMeta): string =
  result = "PodMeta:\n"
  result &= "  " & fmt("path: {this.path}\n")
  result &= "  " & fmt("title: {this.title}\n")

#
# PodIndex
#
type
  PodIndex* = ref object of RootObj
    tagMap*: Table[string, Table[string, ContentMeta]]
    titleMetas*: seq[ContentMeta]

#
# Pod
#
type
  Pod* = ref object of RootObj
    name*: string
    dir*: string
    contentDir*: string
    routesDir*: string
    metaPath*: string
    htmlPath*: string
    tagsHTMLPath*: string
    siteDir*: string

proc newPod*(siteDir, name: string): Pod =
  new(result)
  result.siteDir = siteDir
  result.name = name
  result.dir = joinPath(siteDir, "pods", name)
  result.contentDir = joinPath(result.dir, "content")
  result.routesDir = joinPath(result.dir, "routes")
  result.metaPath = joinPath(result.dir, "meta.json")
  result.htmlPath = joinPath(result.dir, "index.html")
  result.tagsHTMLPath = joinPath(result.dir, "tags.html")

proc hasContentID*(this: Pod, contentID: string): bool =
  return existsDir(joinPath(this.contentDir, contentID))

proc getMeta*(this: Pod): PodMeta =
  return getMeta(this.metaPath)

proc getContentIDs*(this: Pod): seq[string] =
  for kind, path in walkDir(this.contentDir, true):
    if kind == pcDir:
      result.add(path)

proc contentExists*(this: Pod, contentID: string): bool =
  return existsFile(joinPath(this.contentDir, contentID))

proc createContent*(this: Pod): Content =
  var contentID = getRandStr(8)

  while this.contentExists(contentID):
    # a content ID collision is very unlikely, but just in case...
    contentID = getRandStr(8)

  var content = newContent(this.contentDir, contentID)
  content.scaffold()
  return content

proc deleteContent*(this: Pod, contentID: string) =
  removeDir(joinPath(this.contentDir, contentID))

proc scaffold*(this: Pod) =
  let metaDirExists = existsOrCreateDir(this.dir)

  if not metaDirExists:
    getLogger().info(fmt"Creating pod meta file: {this.metaPath}")
    var meta = newPodMeta(this.metaPath, this.name)
    meta.save()

  discard this.createContent()
  writeFile(joinPath(this.dir, "published.txt"), "1")
