import json
import httpclient
import osproc
import unittest
import gerbil
import os
import strformat
import gerbil
import tables

proc createCommentTest(site: Site, podName, contentID: string) =
  let client = newHttpClient(timeout=5000)
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  var config = getAESConfig(joinPath(site.getSiteDir(), "secrets.json"))
  let answer = "secret answer!"
  var answerEncrypted = encryptTextAES(config, answer)

  let body = %*{
      "answer": answer,
      "encryptedAnswer": answerEncrypted,
      "text": "Comment text!!!"
  }
  let url = fmt"http://localhost:5000/content/{podName}/{contentID}/comment"
  let response = client.request(url, httpMethod = HttpPost, body = $body)
  assert response.status == $Http201

suite "content creation and building":
  # echo "Setting up test..."
  # var siteDir = joinPath(getCurrentDir(), "site")
  # removeDir(siteDir)
  # copyDirWithPermissions(joinPath(getCurrentDir(), "site_src"), siteDir)
  # echo "Tests setup complete."

  test "create and build pod":
    let podName = "tutorials"
    var
      site: Site = newSite(getCurrentDir())
      pod: Pod = newPod(site.getSiteDir(), podName)
    let content = pod.createContent()

    var commentID = getRandStr(8)
    var comment = newComment(content.commentsDir, commentID)
    comment.createComment(
      "I __really__ like this article\n\nand the comment system is **great**"
    )

    commentID = getRandStr(8)
    comment = newComment(content.commentsDir, commentID)
    comment.createComment(
      "This content needs...a bit of reworking in my opinion."
    )

    # pod.build(site.getBlocks())
    site.build()

    assert site.isPodNameValid(podName)
    assert not site.isPodNameValid("a-pod-does-not-exist")
    assert not site.isPodNameValid("no spaces allowed")
    assert not site.isPodNameValid("no%*allowed")
    var badName = (
      "A really long name that spans multiple lines, and has spaces" &
      "is not a valid pod name, because the length is way too long"
    )
    assert not site.isPodNameValid(badName)

    var contentHTML = """
      # Introduction to Python
      Python is *awesome*.
      <gerbilcontent pod="python" id="2ec63ab223b64339a6e5d9692f8d4f31"/>
    """
    var contentList = site.getSubContentList(contentHTML)
    assert len(contentList) == 1
    assert contentList[0].podName == "python"

    echo "Starting site..."

    let process = startProcess(
      "gerbil", args=["serve"], options={
        poStdErrToStdOut,poUsePath,poInteractive,poParentStreams
      }
    )
    sleep(2000)

    try:
      echo "Calling comment creation endpoint..."
      createCommentTest(site, podName, content.id)
    finally:
      process.close()

    echo fmt"Deleting content with ID: {content.id}..."
    pod.deleteContent(content.id)
    site.build()
    site.deleteAllFromCommentReview()

  echo "Tests teardown complete."

suite "non content tests":
  test "get random string for IDs":
    let randStr = getRandStr(8)
    assert len(randStr) == 8
    let randStr2 = getRandStr(8)
    assert len(randStr2) == 8
    assert randStr != randStr2

  test "get slug from title":
    var slug = getSlugFromTitle("My Title")
    assert slug == "my-title"

  test "template parsing":
    var blocks = getTemplateBlocks(
      joinPath(getCurrentDir(), "web", "templates", "site-blocks.html")
    )
    assert "crumbnav" in blocks

  test "AES encryption":
    var secretText = "Secret Text!!!"
    var config = getAESConfig("site/secrets.json")
    var encText = encryptTextAES(config, secretText)
    assert secretText == decryptTextAES(config, encText)
