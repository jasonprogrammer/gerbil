import gpod
import gsite

proc createContentCLI*(args: seq[string]) =
  var site = getSite()
  if args.len == 0:
    echo "Please enter a pod name"
    quit(1)
  var
    pod: Pod = newPod(site.getSiteDir(), args[0])

  pod.scaffold()

proc buildSiteCLI*() =
  var site = getSite()
  site.build()

proc cleanCLI*() =
  var site = getSite()
  site.cleanFiles()

proc listCLI*() =
  var site = getSite()
  site.listSiteContent()

proc watchContentCLI*(args: seq[string]) =
  if args.len == 0:
    echo "Please enter a content ID"
    quit(1)

  var site = getSite()
  site.watchContent(args[0])
