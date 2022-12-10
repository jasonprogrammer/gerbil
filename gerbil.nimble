# Package

version     = "0.1.2"
author      = "Jason Jones"
description = "Dynamic site generator"
license     = "MIT"
srcDir      = "src"
bin         = @["gerbil"]
installExt = @["nim"]

# Deps

requires "nim >= 1.6.10"
requires "argparse 4.0.1"
requires "cligen 1.5.32"
requires "jester 0.5.0"
requires "markdown 0.8.5"
requires "mustache 0.4.3"
requires "nimcrypto 0.5.4"
requires "regex 0.20.0"
requires "uuids 0.1.11"
