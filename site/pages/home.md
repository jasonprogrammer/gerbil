## Introduction

Gerbil is a "dynamic website generator", written in
[Nim](https://nim-lang.org/). It is meant to provide many of the
conveniences of static site generators (ease of content creation, deploying, and
maintenance), but to also provide a customizable backend for dynamic features
such as hosting user comments. It is flat-file based (no database used) by
design.

The Gerbil binary can be used to scaffold and serve a site without writing Nim
code, or the Gerbil library can be imported and customized.

**Note**: This is a new project and is still heavily in development.

## Motivation

Gerbil was written for
[simpletutorials.com](https://simpletutorials.com), a programming
tutorials website.

## Features

This site is built and served with the Gerbil binary. The articles are meant
to both be a guide to Gerbil, as well as demonstrate its capabilities, which
include:

- Articles written in [CommonMark markdown format](https://commonmark.org/)
- [CLI command to help scaffold new topics and articles](/c/tutorials/s9u5ai51/how-to-add-an-article)
- [Auto-generated bread crumb navigation to articles](/c/tutorials/x2ozb8eo/bread-crumb-navigation)
- [Source code highlighting](/c/tutorials/16m8cbsl/syntax-highlighting-for-code)
- [Basic anonymous commenting and moderation system](/c/tutorials/uujjkdd9/comment-and-moderation-system)
- [Embedding HTML into the markdown](/c/tutorials/pgpbssmk/writing-articles-in-commonmark-and-html)
- [Anchor links to headers created for articles](/c/tutorials/3p581if8/anchor-links-for-each-article-header)
- [Customizable mustache templates used to construct pages](/c/tutorials/4zziocpv/customizable-mustache-templates-for-pages)
- [Links to each topic generated for optional use on the home page](/c/tutorials/21owtxh3/generated-topic-links-for-use-in-the-home-page-template)
- [A generated page listing tags and their associated articles, per topic](/c/tutorials/hto4cwju/tags-for-articles)
- [Embedding one piece of content into another, using a custom tag](/c/tutorials/9o1l3zkz/embedding-one-piece-of-content-into-another)
- [Pages with URLs at the site root, generated from markdown files](/sample-root-page)

## Getting started

See the
[getting started guide](/c/tutorials/nbxtspuk/getting-started).

## Documentation

{{{topics}}}

## Source

The MIT-licensed source is available
[here](https://github.com/jasonprogrammer/gerbil).<br><br>

Gerbil serves websites using the
[Jester web framework](https://github.com/dom96/jester) and could
not exist without it. Gerbil also relies heavily on the following dependencies:

- [https://github.com/iffy/nim-argparse](https://github.com/iffy/nim-argparse)
- [https://github.com/soasme/nim-markdown](https://github.com/soasme/nim-markdown)
- [https://github.com/soasme/nim-mustache](https://github.com/soasme/nim-mustache)
- [https://github.com/c-blake/cligen](https://github.com/c-blake/cligen)
- [https://github.com/cheatfate/nimcrypto](https://github.com/cheatfate/nimcrypto)
- [https://github.com/nitely/nim-regex](https://github.com/nitely/nim-regex)
- [https://github.com/pragmagic/uuids](https://github.com/pragmagic/uuids)

Many thanks to the authors of these libraries!

## Contact

Gerbil is written by [Jason Jones](https://twitter.com/jasonprogrammer).

## FAQ

Why is it named Gerbil?

As pets, gerbils are:

- Inexpensive
- Easy to maintain
- Lighweight
- Fast

Those are goals of this project. Also, the name was short and didn't seem to be
used anywhere else. 😉
