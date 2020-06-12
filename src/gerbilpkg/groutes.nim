import aes_encrypt
import gcomment
import gcontent
import glogging
import gpage
import gpod
import gsession
import gsite
import json
import jester
import mustache
import os
import re
import strutils
import tables
import times
import utils

proc isModPinValid(request: Request): bool =
  ## A moderator pin is used to intentionally hide the login page
  var site = getSite()
  let config = site.getSecretsConfig()
  return (
   request.params.hasKey("pin") and
   (request.params["pin"] == config["moderator_pin"].getStr())
  )

router GerbilModerateRouter:
  ## Returning 404s instead of 403s in these handlers is intentional, to
  ## provide a little extra bit of obscurity against attackers fishing for an
  ## endpoint to attack.
  get "/moderate":
    var site = getSite()
    if not isSessionValid(request):
      resp Http404, site.get404HTML()

    resp site.getPendingCommentsHTML()

  get "/moderate/unlock":
    ## This deletes a file that keeps track of failed moderator login attempts.
    ## If the count in this file gets large enough, it will prevent even valid
    ## moderator login attempts, for security reasons (to avoid brute force
    ## password attacks). A valid "moderator pin" must be passed in the URL to
    ## successfully "unlock" a "locked" login system. Either way a 404 is
    ## returned to not give any indication that the URL exists, or the unlock
    ## was successful or unsuccessful.
    if not isModPinValid(request):
      resp Http404

    var site = getSite()
    discard tryRemoveFile(site.getModLoginFailCountPath())
    resp Http404

  get "/moderate/login":
    ## Shows the moderator login page. A valid ?pin=MODERATOR_PIN must be
    ## passed in, or a 404 will be returned instead of a 403 (to help mislead
    ## attackers who might be snooping around for a login page).
    var site = getSite()

    if site.getModLoginFailCount() >= site.getMaxAllowedModLoginFails():
      getLogger().info(
        "Moderator login page not showing, too many login failures"
      )
      resp Http404, site.get404HTML()

    if not isModPinValid(request):
      site.incModLoginFailCount()
      resp Http404, site.get404HTML()

    var context = newContext()
    context["pin"] = request.params["pin"]
    var html = readFile(joinPath(site.getTemplateDir(), "moderate-login.html"))
    html = html.render(context)

    resp site.getPageHTML(html, "")

  get "/moderate/logout":
    if not deleteSession(request):
      resp "Unable to delete session"
    setCookie("sessionid", "", fromUnix(0).utc, path="/", httpOnly=true)
    resp "You have been logged out"

  post "/moderate/login/submit":
    ## The moderator login form submits the username and password here to log
    ## the moderator in.
    var site = getSite()

    if site.getModLoginFailCount() >= site.getMaxAllowedModLoginFails():
      getLogger().info("Moderator login locked!")
      resp Http404, site.get404HTML()

    if not isModPinValid(request):
      getLogger().info("Moderator pin invalid")
      resp Http404, site.get404HTML()

    let config = site.getSecretsConfig()

    if request.params["username"] != config["moderator_username"].getStr():
      getLogger().info("Username invalid")
      site.incModLoginFailCount()
      resp(Http404)

    if request.params["password"] != config["moderator_password"].getStr():
      getLogger().info("Password invalid")
      site.incModLoginFailCount()
      resp(Http404)

    let sessionID = getUUID()
    createDir(".sessions")
    let expireSeconds = getTime().toUnix + (60 * 60 * 24)
    let expireDT = fromUnix(expireSeconds).utc
    let username = request.params["username"]
    saveSession(sessionID, username, expireSeconds)
    setCookie("sessionid", sessionID, expireDT, path="/", httpOnly=true)
    redirect("/moderate")

  post "/moderate/@podName/@contentID/@commentID/preview":
    ## Endpoint for previewing a comment
    if not isSessionValid(request):
      resp(Http403)

    let podName = @"podName"
    let contentID = @"contentID"
    let commentID = @"commentID"

    var site = getSite()
    if not site.isPodNameValid(podName):
      resp Http404, site.get404HTML()

    let pod = newPod(site.getSiteDir(), podName)
    var content = newContent(pod.contentDir, contentID)
    var comment = newComment(content.commentsDir, commentID)

    let commentMD = request.params["commentMD"]
    writeFile(comment.path, commentMD)

    var context = newContext()
    context["commentHTML"] = comment.getMarkdownToHTML()
    var html = readFile(joinPath(site.getTemplateDir(), "moderate-comment-preview.html"))
    html = html.render(context)

    resp site.getPageHTML(
      html, ""
    )

  get "/moderate/@podName/@contentID/@commentID/publish/@publishValue":
    if not isSessionValid(request):
      resp(Http403)

    let podName = @"podName"
    let contentID = @"contentID"
    let commentID = @"commentID"
    let publishValue = @"publishValue"

    var site = getSite()
    if not site.isPodNameValid(podName):
      resp Http404, site.get404HTML()

    let pod = newPod(site.getSiteDir(), podName)
    var content = newContent(pod.contentDir, contentID)
    var comment = newComment(content.commentsDir, commentID)
    comment.setPublished(publishValue)

    var context = newContext()
    context["podName"] = podName
    context["contentID"] = contentID
    context["publishedText"] = if publishValue == "1": "published" else: "unpublished"

    var meta = content.getMeta()
    site.buildCommentsMDToHTML(pod, content, meta, site.getBlocks())

    var html = readFile(joinPath(site.getTemplateDir(), "moderate-comment-publish.html"))
    html = html.render(context)

    resp site.getPageHTML(
      html, ""
    )

  get "/moderate/@podName/@contentID/@commentID":
    if not isSessionValid(request):
      resp(Http403)

    let podName = @"podName"
    let contentID = @"contentID"
    let commentID = @"commentID"

    var site = getSite()
    if not site.isPodNameValid(podName):
      resp Http404, site.get404HTML()

    let commentMD = site.getPendingCommentMD(podName, contentID, commentID)

    let pod = newPod(site.getSiteDir(), podName)
    var content = newContent(pod.contentDir, contentID)
    var comment = newComment(content.commentsDir, commentID)

    var context = newContext()
    context["commentMD"] = commentMD
    context["commentHTML"] = comment.getMarkdownToHTML()
    var html = readFile(joinPath(site.getTemplateDir(), "moderate-comment.html"))
    html = html.render(context)

    resp site.getPageHTML(
      html, "<script src=\"/static/dist/js/moderate-comment.entry.js\"></script>"
    )

router GerbilStaticRouter:
  get re"^/static/(.*+)$":
    let requestPath = request.matches[0]

    if ".." in requestPath:
      resp(Http403)

    let staticDir = getSiteStaticDir()
    let path = normalizedPath(
      joinPath(staticDir, requestPath)
    )

    if not path.startsWith(staticDir):
      resp(Http403)

    if not existsFile(path):
      resp Http404, getSite().get404HTML()

    sendFile(path)

router GerbilPodTagsRouter:
  get "/c/@podName/tags":
    let podName = @"podName"

    var site = getSite()
    if not site.isPodNameValid(podName):
      resp Http404, site.get404HTML()

    resp site.getPodTagsHTML(podName)

router GerbilContentRouter:
  get "/c/@podName":
    let podName = @"podName"

    var site = getSite()
    if not site.isPodNameValid(podName):
      resp Http404, site.get404HTML()

    resp site.getPodsHTML(podName)

  get "/c/@podName/@contentID/@title":
    let podName = @"podName"
    let contentID = @"contentID"

    var site = getSite()
    if not site.isContentValid(podName, contentID):
      resp Http404, site.get404HTML()

    resp site.getContentHTML(podName, contentID)

  get re"^/c/([\w\-^/]+)/([\w^/]+)/static/(.*+)$":
    let podName = request.matches[0]
    let contentID = request.matches[1]
    let requestPath = request.matches[2]

    if ".." in requestPath:
      resp(Http403)

    var site = getSite()
    if not site.isContentValid(podName, contentID):
      resp Http404, site.get404HTML()

    let contentDir = site.getContentDir(podName, contentID)
    let staticDir = joinPath(contentDir, "static")

    let path = normalizedPath(
      joinPath(staticDir, requestPath)
    )

    if not path.startsWith(staticDir):
      resp(Http403)

    if not existsFile(path):
      resp Http404, site.get404HTML()

    sendFile(path)

router GerbilCommentRouter:
  post "/content/@podName/@contentID/comment":
    var site = getSite()
    if site.isCommentingDisabledGlobally():
      resp(Http403, "Commenting is currently disabled")

    let podName = @"podName"
    let contentID = @"contentID"

    if not site.isContentValid(podName, contentID):
      resp(Http400, "Content path is invalid")

    var data = parseJson(request.body)

    var node = data.getOrDefault("encryptedAnswer")
    if node == nil:
      resp(Http400, "Spam prevention encrypted answer missing")
    let encryptedAnswer = node.getStr()

    node = data.getOrDefault("answer")
    if node == nil:
      resp(Http400, "Spam prevention answer missing")
    let answer = node.getStr().strip().toLower()

    node = data.getOrDefault("text")
    if node == nil:
      resp(Http400, "Comment text missing")
    let text = node.getStr()

    var config = getAESConfig(joinPath(site.getSiteDir(), "secrets.json"))

    let decryptedAnswerWithTimestamp = decryptTextAES(config, encryptedAnswer)
    let parts = decryptedAnswerWithTimestamp.split('|')
    let decryptedAnswer = parts[0].toLower()

    if answer != decryptedAnswer:
      resp(Http403, "Spam prevention answer incorrect")

    site.addComment(text, podName, contentID)
    resp(Http201)

router GerbilSiteRouter:
  get "/":
    var site = getSite()
    resp site.getHomePageHTML()

router GerbilSlugRouter:
  get "/@slug":
    let slug = @"slug"
    var site = getSite()
    let pagesDir = site.getRootPagesDir()
    if not isPageSlugValid(slug, pagesDir):
      resp Http404, site.get404HTML()
    resp site.getRootPageHTML(slug, pagesDir)

router Gerbil404Router:
  error Http404:
    resp Http404, getSite().get404HTML()

export GerbilStaticRouter
export GerbilContentRouter
export GerbilPodTagsRouter
export GerbilCommentRouter
export GerbilModerateRouter
export GerbilSiteRouter
export GerbilSlugRouter
export Gerbil404Router
