# Getting started

## Prequisites

- Install the latest version of [Nim](https://nim-lang.org/install.html).
- Install NodeJS (the version used in testing was v13.9.0).
- Install [nvm](https://github.com/nvm-sh/nvm).

## Installing

For now, the easiest way to install Gerbil is to do the following:

1. Clone the repository:

```shell
git clone https://github.com/jasonprogrammer/gerbil
```

2. Run:

```shell
nimble install
```

This should make the **gerbil** executable ready for use.

## Build the front-end files

Now that we've installed Gerbil, we need to build the front-end files in the
**web/** directory.

Run:

```shell
cd web
nvm use && npm install && npm start
```

## Run the sample site

Next, open up another terminal window, navigate to the **gerbil/** directory
and run:

```shell
gerbil build && gerbil serve
```

If you see the following:

```shell
INFO Jester is making jokes at http://0.0.0.0:5000
Starting 50 threads
Listening on port 5000
```

then you should be able to open a browser, and navigate to
[http://localhost:5000](http://localhost:5000) to browse the running site.

Once you've seen that the site is running, cancel the running process
(\<ctrl\>-c) and let's create some content!

**Next**: [How to add an article](/c/tutorials/s9u5ai51/how-to-add-an-article)

