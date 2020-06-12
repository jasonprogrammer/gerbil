import argparse
import jester
import json
import mustache
import os
import parseopt
import times

proc getSessionPath*(sessionID: string): string =
  return joinPath(".sessions", sessionID & ".json")

proc sessionExists*(sessionID: string): bool =
  return existsFile(getSessionPath(sessionID))

proc getSession*(sessionID: string): JsonNode =
  return parseJson(readFile(getSessionPath(sessionID)))

proc deleteSession*(request: Request): bool =
  let key = "sessionid"
  let cookies = request.cookies()

  if not cookies.hasKey(key):
    return true

  if not sessionExists(cookies[key]):
    return true

  let sessionPath = getSessionPath(cookies[key])

  if existsFile(sessionPath):
    return tryRemoveFile(sessionPath)

  return true

proc saveSession*(sessionID, username: string, expireTS: int64) =
  let sessionData = %*{
      "username": username,
      "expireTS": expireTS
  }
  writeFile(getSessionPath(sessionID), $sessionData)

proc isSessionValid*(request: Request): bool =
  let key = "sessionid"
  let cookies = request.cookies()

  if not cookies.hasKey(key):
    return false

  if not sessionExists(cookies[key]):
    return false

  let sessionData = getSession(cookies[key])
  let expireTS = sessionData["expireTS"].getBiggestInt()
  let epochSeconds = toUnix(getTime())
  return epochSeconds < expireTS

