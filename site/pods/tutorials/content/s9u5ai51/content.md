# How to add an article

Articles are grouped into pods (topics). To add an article, run the following CLI command:

```shell
gerbil create mytopic
```

This will create a directory called **mytopic** under the **pods** directory, as
well as some additional files:

```shell
jason@mint:~/projects/mysite$ gerbil create mytopic
INFO Creating pod meta file: /home/jason/projects/mysite/site/pods/mytopic/meta.json
INFO Creating content in dir: /home/jason/projects/mysite/site/pods/mytopic/content/9wi969rj
INFO Creating content static dir: /home/jason/projects/mysite/site/pods/mytopic/content/9wi969rj/static
INFO Creating meta file: /home/jason/projects/mysite/site/pods/mytopic/content/9wi969rj/meta.json
INFO Creating content markdown file: /home/jason/projects/mysite/site/pods/mytopic/content/9wi969rj/content.md
```

What are these files for?

- mytopic/meta.json: Metadata for the pod (topic), such as the display name
- mytopic/content/9wi969rj: A unique directory for the article
- mytopic/content/9wi969rj/static: A directory for the article's static files
- mytopic/content/9wi969rj/meta.json: Metadata for the article (e.g the URL slug to use)
- mytopic/content/9wi969rj/content.md: The markdown file for the article's content

The "content ID" that was automatically created is **9wi969rj**. A content ID
is created for a couple of reasons:

1. To ensure uniqueness in identifying an article
2. To help navigate to an article, even the article title and "slug" change.

## Editing the markdown

We can use a text editor to edit the markdown file that was created. The
markdown format expected by Gerbil is [CommonMark](https://commonmark.org/).

Please see this [example Gerbil markdown document](/c/tutorials/04n1xhdz/a-sample-markdown-page).
There is a
[link to the markdown source](https://github.com/jasonprogrammer/gerbil/blob/master/site/pods/tutorials/content/04n1xhdz/content.md),
so you can see how to add elements like images.

Once you have edited the markdown file to your satisfaction, you can build
the site.

**Next**: [Building the site](/c/tutorials/y2nldyzg/building-a-site-with-gerbil)
