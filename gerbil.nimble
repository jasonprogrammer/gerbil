# Package

version     = "0.1.1"
author      = "Jason Jones"
description = "Dynamic site generator"
license     = "MIT"
srcDir      = "src"
bin         = @["gerbil"]
installExt = @["nim"]

# Deps

requires "nim >= 1.2.0"
requires "argparse 3.0.0"
requires "cligen 1.5.21"
requires "jester 0.5.0"
requires "markdown 0.8.5"
requires "mustache 0.4.3"
requires "nimcrypto 0.5.4"
requires "regex 0.19.0"
requires "uuids 0.1.11"
