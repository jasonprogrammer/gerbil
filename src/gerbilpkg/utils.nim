import random
import strutils
import uuids
from times import getTime, toUnix, nanosecond

proc getUUID*(): string =
  result = $genUUID()
  result = result.replace("-", "")

proc getRandNum*(minNum, maxNum: int): int =
  let now = getTime()
  var r = initRand(now.toUnix * 1000000000 + now.nanosecond)
  return r.rand(minNum..<maxNum)

proc getRandStr*(numChars: int): string =
  let alphaNumChars = "0123456789abcdefghijklmnopqrstuvwxyz"
  let numRandChars = len(alphaNumChars)

  var randStr = ""
  for i in 0..<numChars:
    randStr &= alphaNumChars[getRandNum(0, numRandChars)]
  return randStr
