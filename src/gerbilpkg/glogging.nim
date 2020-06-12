import logging

type
  Log* = ref object of RootObj

var
  logger {.threadvar.}: Log

proc info*(logger: Log, args: varargs[string, `$`]) =
  logging.info(args)

proc addHandlers*(logger: Log) =
  var consoleLog = newConsoleLogger()
  var rollingLog = newRollingFileLogger("gerbil.log")

  addHandler(consoleLog)
  addHandler(rollingLog)

proc getLogger*(): Log =
  if logger == nil:
    logger = new(Log)
    result.addHandlers()
  return logger
