# import nimpcre
import argparse
import cligen
import jester
import mustache
import os

import  ./gerbilpkg/aes_encrypt,
        ./gerbilpkg/gcli,
        ./gerbilpkg/gcomment,
        ./gerbilpkg/gcontent,
        ./gerbilpkg/glogging,
        ./gerbilpkg/gpod,
        ./gerbilpkg/groutes,
        ./gerbilpkg/gsession,
        ./gerbilpkg/gsite,
        ./gerbilpkg/gtemplate,
        ./gerbilpkg/utils

export  aes_encrypt,
        gcli,
        gcomment,
        gcontent,
        glogging,
        gpod,
        groutes,
        gsession,
        gsite,
        gtemplate,
        utils

proc listenCLI() =
  let port = parseInt(getEnv("SERVER_PORT", "5000"))
  let settings = newSettings(
    port=port.Port, staticDir=getSiteStaticDir()
  )
  var jesterServer = initJester(settings=settings)
  jesterServer.register(GerbilSiteRouter)
  jesterServer.register(GerbilStaticRouter)
  jesterServer.register(GerbilContentRouter)
  jesterServer.register(GerbilPodTagsRouter)
  jesterServer.register(GerbilCommentRouter)
  jesterServer.register(GerbilModerateRouter)
  jesterServer.register(GerbilSlugRouter)

  # this route matcher must be last
  jesterServer.register(Gerbil404RouteMatcher)

  jesterServer.serve()

when isMainModule:
  dispatchMulti(
    [createContentCLI, cmdName="create", help={"args":"<pod name>"}],
    [listenCLI, cmdName="serve"], [cleanCLI, cmdName="clean"],
    [buildSiteCLI, cmdName="build"], [listCLI, cmdName="list"],
    [watchContentCLI, cmdName="watchcontent", help={"args":"<content ID>"}]
  )
