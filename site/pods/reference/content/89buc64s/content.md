# The Gerbil CLI

<div class="st-content-gray">June 8, 2020</div>

To see the CLI commands available, run `gerbil` at a command prompt:

```shell
$ gerbil
Usage:
  gerbil {SUBCMD}  [sub-command options & parameters]
where {SUBCMD} is one of:
  help          print comprehensive or per-cmd help
  create
  serve
  clean
  build
  list
  watchcontent

gerbil {-h|--help} or with no args at all prints this message.
gerbil --help-syntax gives general cligen syntax help.
Run "gerbil {help SUBCMD|SUBCMD --help}" to see help for just SUBCMD.
Run "gerbil help" to get *comprehensive* help.
```

## gerbil create

This command is used to create new content. See examples [here](TODOLINK)

## gerbil serve

Serves the website (default on port 5000). To serve on another port, set the
`SERVER_PORT` environment variable, e.g.:

```shell
export SERVER_PORT=5002
```

## gerbil clean

Deletes files (e.g. HTML files) created during the build process.

## gerbil build

Builds the markdown files into HTML files, along with breadcrumb navigation and
topic pages.

## gerbil list

Lists all of the articles created.

## gerbil watchcontent

This is used to build a piece of content on an interval.
