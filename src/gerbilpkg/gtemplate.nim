import regex
import tables

proc getTemplateBlocks*(path: string): Table[string, string] =
  result = initTable[string, string]()

  var blockName = ""
  var regMatch: RegexMatch
  for line in lines(path):
    if line.match(re"<!--BLOCK\((?P<blockname>\w+)\)-->", regMatch):
      blockName = regMatch.groupFirstCapture("blockname", line)
    elif blockName != "":
      if blockName in result:
        result[blockName] &= line & "\n"
      else:
        result[blockName] = line & "\n"
