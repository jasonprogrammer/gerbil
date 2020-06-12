# Package

version     = "0.1.0"
author      = "Jason Jones"
description = "Dynamic site generator"
license     = "MIT"
srcDir      = "src"
bin         = @["gerbil"]
installExt = @["nim"]

# Deps

requires "nim >= 1.2.0"
requires "argparse 0.10.0"
requires "cligen 0.9.41"
requires "jester 0.4.3"
requires "markdown 0.8.0"
requires "mustache 0.2.1"
requires "nimcrypto 0.4.11"
requires "regex 0.13.0"
requires "uuids 0.1.10"
