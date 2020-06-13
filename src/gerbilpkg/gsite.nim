import aes_encrypt
import algorithm
import gcomment
import gcontent
import gpage
import gpod
import gtemplate
import json
import jester
import glogging
import mustache
import os
import regex
import sequtils
import std/sha1
import strformat
import strutils
import tables
import times
import utils

type
  SiteConfig* = ref object of RootObj
    maxPendingCommentsAllowed*: int

type
  Site* = ref object of RootObj
    rootDir*: string

  SubContentInfo* = ref object of RootObj
    podName*: string
    contentID*: string

type
  SpamQuestion* = ref object of RootObj
    question*: string
    answer*: string

proc readSiteConfig*(configPath: string): SiteConfig =
  var config = parseJson(readFile(configPath))
  new(result)
  result.maxPendingCommentsAllowed =
    config["max_pending_comments_allowed"].getInt()

proc newSite*(rootDir: string): Site =
  new(result)
  result.rootDir = rootDir

proc newSubContentInfo*(podName, contentID: string): SubContentInfo =
  new(result)
  result.podName = podName
  result.contentID = contentID

proc getSiteDir*(this: Site): string =
  return joinPath(this.rootDir, "site")

proc getModLoginFailCountPath*(this: Site): string =
  return joinPath(this.getSiteDir(), "mod-login-fail-count.txt")

proc removeModLoginFailCount*(this: Site) =
  discard tryRemoveFile(this.getModLoginFailCountPath())

proc incModLoginFailCount*(this: Site) =
  ## Increments the count of failed login attempts (which will eventually
  ## "lock" (disable) moderator logins.
  let countPath = this.getModLoginFailCountPath()
  if not fileExists(countPath):
    writeFile(countPath, "1")

  let failCount = parseInt(readFile(countPath)) + 1
  writeFile(countPath, $failCount)

proc getMaxAllowedModLoginFails*(this: Site): int =
  ## Returns a number indicating how many failed login attempts are permitted
  ## before logins are "locked" (disabled).
  return 20

proc getModLoginFailCount*(this: Site): int =
  ## Get the number of failed login attempts
  let countPath = this.getModLoginFailCountPath()
  if not fileExists(countPath):
    return 0
  return parseInt(readFile(countPath)) + 1

proc getSubContentRegex*(this: Site): regex.Regex =
  return re".*?<gerbilcontent pod=""(?P<pod>[\w\-]+)"" id=""(?P<id>[\w]+)""\/>.*?"

proc getRedirectsPath*(this: Site): string =
  return joinPath(this.getSiteDir(), "redirects.json")

proc getConfigPath*(this: Site): string =
  return joinPath(this.getSiteDir(), "site.json")

proc getTemplateDir*(this: Site): string =
  return joinPath(this.rootDir, "web", "templates")

proc getSiteTemplatePath*(this: Site): string =
  return joinPath(this.getTemplateDir(), "site.html")

proc getTemplatePathOrDefault*(this: Site, fileName: string): string =
  let templatePath = joinPath(this.getTemplateDir(), fileName)
  if existsFile(templatePath):
    return templatePath
  return this.getSiteTemplatePath()

proc get404TemplatePath*(this: Site): string =
  return this.getTemplatePathOrDefault("404.html")

proc getBlocksPath*(this: Site): string =
  return joinPath(this.getTemplateDir(), "site-blocks.html")

proc getHomeTemplatePath*(this: Site): string =
  return this.getTemplatePathOrDefault("home.html")

proc getRootPageTemplatePath*(this: Site): string =
  return this.getTemplatePathOrDefault("page.html")

proc getSiteLogoHTMLPath*(this: Site): string =
  return joinPath(this.getTemplateDir(), "logo.html")

proc getSecretsConfigPath*(this: Site): string =
  return joinPath(this.getSiteDir(), "secrets.json")

proc getSecretsConfig*(this: Site): JsonNode =
  return parseJson(readFile(this.getSecretsConfigPath()))

proc getBlocks*(this: Site): Table[string, string] =
  return getTemplateBlocks(this.getBlocksPath())

proc getPodsDir*(this: Site): string =
  return joinPath(this.getSiteDir(), "pods")

proc getReviewDir*(this: Site): string =
  return joinPath(this.getSiteDir(), "comment-review")

proc getRootPagesDir*(this: Site): string =
  return joinPath(this.getSiteDir(), "pages")

proc getPodsIndexHTMLPath*(this: Site): string =
  return joinPath(this.getPodsDir(), "index.html")

proc getHomeContentTemplatePath*(this: Site): string =
  return joinPath(this.getTemplateDir(), "home-content.html")

proc getModBlocksPath*(this: Site): string =
  return joinPath(
    this.rootDir, "web", "templates", "moderation-blocks.html"
  )

proc getCommentReviewDir*(this: Site): string =
  return joinPath(this.getSiteDir(), "comment-review")

proc getCommentsDisabledPath*(this: Site): string =
  return joinPath(this.getSiteDir(), "disable-comments.txt")

proc getPodNames*(this: Site): seq[string] =
  for kind, path in walkDir(this.getPodsDir(), true):
    if kind == pcDir:
      result.add(path)

proc getPodNamesMap*(this: Site): Table[string, PodMeta] =
  for kind, podName in walkDir(this.getPodsDir(), true):
    if kind == pcDir:
      let pod = newPod(this.getSiteDir(), podName)
      result[podName] = pod.getMeta()

proc getSubContentList*(this: Site, html: string): seq[SubContentInfo] =
  var regMatch: RegexMatch
  for line in splitLines(html):
    if line.match(
        this.getSubContentRegex(),
        regMatch
      ):
      result.add(newSubContentInfo(
        regMatch.groupFirstCapture("pod", line),
        regMatch.groupFirstCapture("id", line)
      ))

proc buildPodsHTMLFile*(this: Site, blocks: Table[string, string]) =
  let podNamesMap = this.getPodNamesMap()
  var podNames = newSeq[string]()

  for key in podNamesMap.keys:
    podNames.add(key)
  podNames.sort()

  var podLinks = ""
  for podName in podNames:
    let podMeta = podNamesMap[podName]
    var context1 = newContext()
    context1["href"] = "/c/" & podName
    context1["text"] = podMeta.title
    podLinks &= blocks["taglink"].render(context1)

  writeFile(this.getPodsIndexHTMLPath(), podLinks)

proc buildBreadCrumbLinks(
  links: seq[Context], currentPageTitle: string,
  blocks: Table[string, string]
): string =
  var linkHTML = ""
  for linkContext in links:
    linkHTML &= blocks["crumblink"].render(linkContext)
    linkHTML &= blocks["crumbseparator"]

  var context = newContext()
  context["text"] = currentPageTitle
  linkHTML &= blocks["crumbtitle"].render(context)

  context = newContext()
  context["text"] = linkHTML
  return blocks["crumbnav"].render(context)

proc titleMetasCompare(x, y: ContentMeta): int =
  if x.title < y.title: -1 else: 1

# Read from the meta and build some data structures to help create HTML pages
# with links to the content
proc buildIndexes*(this: Site, pod: Pod, contentMetas: seq[ContentMeta]): PodIndex =
  result = new(PodIndex)

  for meta in contentMetas:
    result.titleMetas.add(meta)

    for tagName in meta.tags:
      if not (tagName in result.tagMap):
        result.tagMap[tagName] = initTable[string, ContentMeta]()
      result.tagMap[tagName][meta.id] = meta

  result.titleMetas.sort(titleMetasCompare)

proc buildPodTagHTMLFile*(
  this: Site, pod: Pod, contentIndex: PodIndex, blocks: Table[string, string]
) =
  var tagNames = toSeq(contentIndex.tagMap.keys)
  tagNames.sort()

  var html = ""
  for tagName in tagNames:
    var context = newContext()
    context["text"] = tagName
    html &= blocks["h2"].render(context)

    var metaMap = contentIndex.tagMap[tagName]
    for contentID, meta in metaMap:
      if not meta.isContentPublished():
        continue
      context = newContext()
      context["href"] = fmt"/c/{pod.name}/{contentID}/{meta.slug}"
      context["text"] = meta.title
      html &= blocks["taglink"].render(context)

  getLogger().info(fmt"Writing tags HTML file: {pod.tagsHTMLPath}")
  writeFile(pod.tagsHTMLPath, html)

proc buildPodHTMLFile*(
  this: Site, pod: Pod, contentIndex: PodIndex, blocks: Table[string, string]
) =
  var crumbs: seq[Context]

  var context = newContext()
  context["href"] = "/"
  context["text"] = "Home"
  crumbs.add(context)

  let podMeta = pod.getMeta()

  var html = buildBreadCrumbLinks(crumbs, podMeta.title, blocks)

  context = newContext()
  context["text"] = podMeta.title
  html &= blocks["h2"].render(context)

  for meta in contentIndex.titleMetas:
    if not meta.isContentPublished():
      continue
    context = newContext()
    context["href"] = fmt"/c/{pod.name}/{meta.id}/{meta.slug}"
    context["text"] = meta.title
    html &= blocks["taglink"].render(context)

  getLogger().info(fmt"Writing tags HTML file: {pod.tagsHTMLPath}")
  writeFile(pod.htmlPath, html)

proc commentMetasUpdatedCompare(x, y: CommentMeta): int =
  if x.updatedTS < y.updatedTS: -1 else: 1

proc buildCommentsMDToHTML*(
  this: Site, pod: Pod, content: Content, contentMeta: ContentMeta,
  blocks: Table[string, string]
) =
  var commentIDs = content.getCommentIDs()
  var commentMetas = newSeq[CommentMeta]()

  var metaMap = initTable[string, Comment]()

  # build each individual comment HTML
  for id in commentIDs:
    var comment = newComment(content.commentsDir, id)

    var commentMeta = getCommentMeta(comment.metaPath, comment.publishedPath)
    commentMetas.add(commentMeta)

    metaMap.add(commentMeta.id, comment)

    var hash = ($secureHashFile(comment.path)).toLower()

    if hash == commentMeta.hash and existsFile(comment.htmlPath):
      continue

    getLogger().info(fmt"Building comment: {comment.id}")

    comment.writeHTML(comment.getMarkdownToHTML())
    comment.updateMetaHash(commentMeta, hash)

  # sort and build HTML file with all comments
  commentMetas.sort(commentMetasUpdatedCompare)

  var commentsHTML = ""
  for meta in commentMetas:
    if not meta.isPublished:
      continue
    let comment = metaMap[meta.id]

    var context = newContext()
    var updatedTSTime = fromUnix(int64(meta.updatedTS))
    context["date"] = $updatedTSTime.utc().format("MMMM d, yyyy HH:MM")
    context["text"] = readFile(comment.htmlPath)
    commentsHTML &= blocks["comment"].render(context)

  createDir(content.commentsDir)
  writeFile(content.commentsHTMLPath, commentsHTML)

proc addCommentForModeration*(
    this: Site, podName, contentID, commentID: string
  ) =
  let reviewDir = this.getCommentReviewDir()
  createDir(reviewDir)
  writeFile(
    joinPath(reviewDir, fmt"{commentID}.txt"),
    fmt"{podName}|{contentID}|{commentID}"
  )

proc addComment*(this: Site, text, podName, contentID: string) =
  let pod = newPod(this.getSiteDir(), podName)
  let content = newContent(pod.contentDir, contentID)

  var commentID = getRandStr(8)
  var comment = newComment(content.commentsDir, commentID)
  comment.createComment(text)
  this.addCommentForModeration(pod.name, content.id, comment.id)

proc isContentLastModChanged(
  this: Site, content: Content, contentMeta: ContentMeta
): bool =
  let mdLastmod = content.getMDLastMod()
  let buildLastmod = content.getLastBuildMod()
  return mdLastmod >= buildLastmod

proc buildContentMDToHTML*(
  this: Site, pod: Pod, content: Content, contentMeta: ContentMeta,
  blocks: Table[string, string]
) =
  if not this.isContentLastModChanged(content, contentMeta):
    return

  var hash = ($secureHashFile(content.path)).toLower()
  let isHashChanged = (
    (hash != contentMeta.hash) or not existsFile(content.htmlPath)
  )
  if not isHashChanged:
    return

  getLogger().info(fmt"Building content: {content.id}, {contentMeta.title}")
  content.setMetaAttrsFromMarkdown(contentMeta)

  var crumbHTML = ""
  if contentMeta.isContentPublished():
    var crumbs: seq[Context]

    var context = newContext()
    context["href"] = "/"
    context["text"] = "Home"
    crumbs.add(context)

    var podMeta = pod.getMeta()
    context = newContext()
    context["href"] = "/c/" & pod.name
    context["text"] = podMeta.title
    crumbs.add(context)

    crumbHTML = buildBreadCrumbLinks(crumbs, contentMeta.title, blocks)

  content.writeHTML(crumbHTML & content.getMarkdownToHTML())
  content.updateMetaHash(contentMeta, hash)
  content.writeBuildMod()

proc buildContentReplaceTags*(this: Site, pod: Pod, content: Content, contentMeta: ContentMeta) =
  var contentHTML = readFile(content.htmlPath)

  for sc in this.getSubContentList(contentHTML):
    let scPod = newPod(this.getSiteDir(), sc.podName)
    var scContent = newContent(scPod.contentDir, sc.contentID)

    let tagHTML = fmt"<gerbilcontent pod=""{sc.podName}"" id=""{sc.contentID}""/>"

    var scHTML = ""
    if fileExists(scContent.htmlPath):
      scHTML = readFile(scContent.htmlPath)
    else:
      echo fmt"Warning: content not found for {tagHTML}"

    contentHTML = contentHTML.replace(tagHTML, scHTML)
  content.writeHTML(contentHTML)

proc listContent*(this: Site, pod: Pod, content: Content) =
  let meta = content.getMeta()
  getLogger().info(fmt"{content.dir} {meta.title}")

proc listPod*(this: Site, pod: Pod) =
  if not existsDir(pod.dir):
    getLogger().info(fmt"Pod dir: {pod.dir} does not exist")
    return

  var contentIDs = pod.getContentIDs()
  for id in contentIDs:
    var content = newContent(pod.contentDir, id)
    this.listContent(pod, content)

proc listSiteContent*(this: Site) =
  for podName in this.getPodNames():
    let pod = newPod(this.getSiteDir(), podName)
    this.listPod(pod)

proc buildPod*(this: Site, pod: Pod, blocks: Table[string, string]) =
  if not existsDir(pod.dir):
    getLogger().info(fmt"Pod dir: {pod.dir} does not exist")
    return

  getLogger().info(fmt"Recreating routes path: {pod.routesDir}")
  removeDir(pod.routesDir)
  createDir(pod.routesDir)

  var contentIDs = pod.getContentIDs()

  var
    metas: seq[ContentMeta]

  for id in contentIDs:
    var content = newContent(pod.contentDir, id)
    getLogger().info(fmt"Building content: {content.dir}")
    var meta = content.getMeta()

    this.buildContentMDToHTML(pod, content, meta, blocks)
    this.buildCommentsMDToHTML(pod, content, meta, blocks)
    metas.add(meta)

  for id in contentIDs:
    var content = newContent(pod.contentDir, id)
    var meta = content.getMeta()

    this.buildContentReplaceTags(pod, content, meta)

  var contentIndex = this.buildIndexes(pod, metas)
  this.buildPodHTMLFile(pod, contentIndex, blocks)
  this.buildPodTagHTMLFile(pod, contentIndex, blocks)

proc cleanFilesInPod*(this: Site, pod: Pod) =
  if not existsDir(pod.dir):
    getLogger().info(fmt"Pod dir: {pod.dir} does not exist")
    return

  discard tryRemoveFile(pod.htmlPath)
  var contentIDs = pod.getContentIDs()

  for id in contentIDs:
    var content = newContent(pod.contentDir, id)
    discard tryRemoveFile(content.htmlPath)
    discard tryRemoveFile(content.commentsHTMLPath)
    discard tryRemoveFile(content.getLastBuildModPath())

proc cleanFiles*(this: Site) =
  for podName in this.getPodNames():
    let pod = newPod(this.getSiteDir(), podName)
    this.cleanFilesInPod(pod)

proc buildRootPage*(this: Site, mdPath: string) =
  let fileNoExt = mdPath[0..^4]
  let htmlPath = fmt"{fileNoExt}.html"
  writeFile(htmlPath, getHTMLFromMarkdown(mdPath))

proc buildRootPages*(this: Site, pagesDir: string) =
  for kind, path in walkDir(pagesDir, true):
    if path.contains(".md"):
      this.buildRootPage(joinPath(pagesDir, path))

proc getRandAESAAD*(numChars: int): string =
  let alphaNumChars = "0123456789ABCDEF"
  let numRandChars = len(alphaNumChars)

  var randStr = ""
  for i in 0..<numChars:
    randStr &= alphaNumChars[getRandNum(0, numRandChars)]
  return randStr

proc createDefaultSecrets*(this: Site) =
  let configPath = this.getSecretsConfigPath()
  if not existsFile(configPath):
    echo "Creating default secrets file in site/secrets.json..."
    var meta = %*{
      "aes_secret_key": getRandStr(8),
      "aes_secret_aad": getRandStr(8),
      "aes_secret_iv": getRandAESAAD(16),
      "moderator_pin": getRandStr(8),
      "moderator_username": getRandStr(8),
      "moderator_password": getRandStr(8)
    }
    writeFile(configPath, pretty(meta))

proc build*(this: Site) =
  this.createDefaultSecrets()

  let blocks = this.getBlocks()
  for podName in this.getPodNames():
    let pod = newPod(this.getSiteDir(), podName)
    this.buildPod(pod, blocks)

  this.buildRootPages(this.getRootPagesDir())
  this.buildPodsHTMLFile(blocks)

proc deleteAllFromCommentReview*(this: Site) =
  removeDir(this.getCommentReviewDir())

proc findPodWithContentID*(this: Site, contentID: string): Pod =
  for podName in this.getPodNames():
    let pod = newPod(this.getSiteDir(), podName)
    if pod.hasContentID(contentID):
      return pod
  return nil

proc watchContent*(this: Site, contentID: string) =
  let pod = this.findPodWithContentID(contentID)
  if pod == nil:
    getLogger().info(fmt"Pod with content ID: {contentID} not found")
    return

  var content = newContent(pod.contentDir, contentID)
  getLogger().info(fmt"Watching content in dir: {content.dir}")
  var meta = content.getMeta()

  let blocks = this.getBlocks()

  while true:
    this.buildContentMDToHTML(pod, content, meta, blocks)
    this.buildContentReplaceTags(pod, content, meta)
    sleep(1000)

proc getPendingComments*(this: Site): seq[PendingCommentInfo] =
  for kind, path in walkDir(this.getReviewDir()):
    if kind == pcFile:
      let parts = readFile(path).split('|')
      result.add(
        PendingCommentInfo(
          podName: parts[0],
          contentID: parts[1],
          commentID: parts[2]
        )
      )

proc getPageHTML*(
  this: Site, html, headHTML: string, bodyClass: string=""
): string =
  var context = newContext()
  context["title"] = ""
  context["head"] = headHTML #"<link href=\"pods.css\"></link>" & headHTML
  context["body"] = html
  context["logo"] = readFile(this.getSiteLogoHTMLPath())
  context["body_class"] = bodyClass

  var siteHTML = readFile(this.getSiteTemplatePath())
  return siteHTML.render(context)

proc getPendingCommentsHTML*(this: Site): string =
  let blocks = getTemplateBlocks(this.getModBlocksPath())

  var linksHTML = ""
  var comments = this.getPendingComments()
  for comment in comments:
    var context = newContext()
    let pod = newPod(this.getSiteDir(), comment.podName)
    var content = newContent(pod.contentDir, comment.contentID)
    var contentMeta = content.getMeta()
    context["href"] = fmt"/moderate/{comment.podName}/{comment.contentID}/" &
        comment.commentID
    context["text"] = fmt"Comment on: {contentMeta.title}"
    linksHTML &= blocks["commentlink"].render(context)

  var context = newContext()
  context["links"] = if len(comments) > 0: linksHTML else: "No comments"
  var html = readFile(joinPath(this.getTemplateDir(), "moderate.html"))
  html = html.render(context)

  return this.getPageHTML(html, "")

proc getTemplate*(this: Site, templateName: string): string =
  readFile(joinPath(this.getTemplateDir(), "moderate.html"))

proc getPendingCommentMD*(
  this: Site, podName, contentID, commentID: string
  ): string =
    let pod = newPod(this.getSiteDir(), podName)
    var content = newContent(pod.contentDir, contentID)
    var comment = newComment(content.commentsDir, commentID)
    return comment.getMarkdown()

proc getRootPageHTML*(this: Site, slug, pagesDir: string): string =
  ## This method is for displaying a "root page", which is a page that is
  ## generated from a markdown file placed in the <SITE_DIR>/pages directory.
  ## The markdown file is named after the "URL slug" (only alphanumeric
  ## characters or the dash character). During the build process, an HTML file
  ## will be generated for each markdown file in the pages/ directory, and the
  ## name of each file will be used to display the page at the "root" of the
  ## site, e.g.: <SITE_URL>/my-slug
  let pagePath = joinPath(pagesDir, fmt"{slug}.html")
  let pageHTML = readFile(pagePath)

  var context = newContext()
  context["title"] = ""
  context["head"] = "" #"<link href=\"pods.css\"></link>" & headHTML
  context["body"] = pageHTML
  context["logo"] = readFile(this.getSiteLogoHTMLPath())
  context["body_class"] = "gerbil-root-page"

  var outerHTML = readFile(this.getRootPageTemplatePath())
  return outerHTML.render(context)

proc getHomePageHTML*(this: Site): string =
  var context = newContext()
  context["title"] = ""
  context["head"] = "" #"<link href=\"pods.css\"></link>" & headHTML

  var context1 = newContext()
  context1["topics"] = readFile(this.getPodsIndexHTMLPath())

  let homeBodyHTML = readFile(this.getHomeContentTemplatePath())
  context["body"] = homeBodyHTML.render(context1)
  context["logo"] = readFile(this.getSiteLogoHTMLPath())
  context["body_class"] = "gerbil-home"

  var siteHTML = readFile(this.getHomeTemplatePath())
  return siteHTML.render(context)

proc getPodsHTML*(this: Site, podName: string): string =
  let pod = newPod(this.getSiteDir(), podName)
  return this.getPageHTML(readFile(pod.htmlPath), "")

proc getPodTagsHTML*(this: Site, podName: string): string =
  let pod = newPod(this.getSiteDir(), podName)
  return this.getPageHTML(readFile(pod.tagsHTMLPath), "")

proc getRandomSpamQuestion*(this: Site): SpamQuestion =
  new(result)

  let spamDir = joinPath(this.getSiteDir(), "spam_questions")
  let numQuestions = parseInt(
    readFile(joinPath(spamDir, "num_questions.txt")).strip()
  )
  let questionNum = getRandNum(1, numQuestions)
  let questionText = readFile(
    joinPath(spamDir, intToStr(questionNum) & ".txt")
  )
  (result.question, result.answer) = questionText.split('|')
  result.answer = strip(result.answer)

proc getContentHTML*(this: Site, podName, contentID: string): string =
  let pod = newPod(this.getSiteDir(), podName)
  let content = newContent(pod.contentDir, contentID)

  let contentHTML = readFile(content.htmlPath)
  var commentsHTML = ""
  if existsFile(content.commentsHTMLPath):
    commentsHTML = readFile(content.commentsHTMLPath)

  var context1 = newContext()
  context1["body"] = contentHTML
  context1["podName"] = podName
  context1["contentID"] = contentID
  var contentWrapHTML = readFile(joinPath(this.getTemplateDir(), "content.html"))

  var context2 = newContext()
  context2["body"] = commentsHTML

  let spam = this.getRandomSpamQuestion()

  context2["spam_question"] = spam.question

  var secretText = spam.answer & "|" & fmt"{uint64(epochTime())}"
  var config = getAESConfig(joinPath(this.getSiteDir(), "secrets.json"))
  var encText = encryptTextAES(config, secretText)

  context2["spam_answer_encrypted"] = encText
  var commentsWrapHTML = readFile(joinPath(this.getTemplateDir(), "comments.html"))

  return this.getPageHTML(
    contentWrapHTML.render(context1) & commentsWrapHTML.render(context2),
    "<script src=\"/static/dist/js/content.entry.js\"></script>",
    "gerbil-content"
  )

proc isPodNameValid*(this: Site, podName: string): bool =
  var regexMatch: RegexMatch
  return (
    (len(podName) <= 80) and
    podName.match(re"^[\w\-]+$", regexMatch) and
    existsDir(joinPath(this.getPodsDir(), podName)) and
    existsFile(joinPath(this.getPodsDir(), podName, "meta.json"))
  )

proc isContentIDValid*(this: Site, podName: string): bool =
  var regexMatch: RegexMatch
  return (
    (len(podName) <= 80) and
    podName.match(re"^[\w\-]+$", regexMatch) and
    existsDir(joinPath(this.getPodsDir(), podName)) and
    existsFile(joinPath(this.getPodsDir(), podName, "meta.json"))
  )

proc getContentDir*(this: Site, podName: string, contentID: string): string =
  return joinPath(this.getPodsDir(), podName, "content", contentID)

proc isContentValid*(this: Site, podName: string, contentID: string): bool =
  if not this.isPodNameValid(podName):
    return false

  if len(contentID) != 8:
    return false

  var regexMatch: RegexMatch
  if not contentID.match(re"^[\w]+$", regexMatch):
    return false

  let contentDir = this.getContentDir(podName, contentID)
  return existsFile(joinPath(contentDir, "meta.json"))

proc getNumPendingComments*(this: Site): int =
  let config = readSiteConfig(this.getConfigPath())

  for kind, path in walkDir(this.getCommentReviewDir(), true):
    if kind == pcFile:
      result += 1
      if result >= config.maxPendingCommentsAllowed:
        return result

proc isCommentingDisabledGlobally*(this: Site): bool =
  let disabledPath = this.getCommentsDisabledPath()
  if (
    existsFile(disabledPath) and
    readFile(disabledPath).strip() == "1"
  ):
    return true

  let config = readSiteConfig(this.getConfigPath())
  if this.getNumPendingComments() > config.maxPendingCommentsAllowed:
    writeFile(disabledPath, "1")
    return true

  return false

proc get404HTML*(this: Site): string =
  var context = newContext()
  context["title"] = ""
  context["head"] = "" #"<link href=\"pods.css\"></link>" & headHTML
  context["body"] = readFile(joinPath(this.getTemplateDir(), "404-content.html"))
  context["logo"] = readFile(this.getSiteLogoHTMLPath())

  var siteHTML = readFile(this.get404TemplatePath())
  return siteHTML.render(context)

proc getSiteDir*(): string =
  var path = getCurrentDir()

  while not existsFile(joinPath(path, "site", "site.json")):
    path = parentDir(path)
    if path == "":
      raise newException(Exception, "Unable to find site directory")

  return path

proc getSite*(): Site =
  return newSite(getSiteDir())

proc getSiteStaticDir*(): string =
  return joinPath(getSiteDir(), "web", "static")


