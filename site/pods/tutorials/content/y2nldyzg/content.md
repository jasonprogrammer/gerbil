# How to build a site

To build your site, run:

```shell
gerbil build
```

in the root directory (the directory that contains the **site/** and **web/**
directories).

The HTML files for each article should only built if the markdown changes. To
*force* a rebuild, run:

```shell
gerbil clean && gerbil build
```

**Next**: [Serving the site](/c/tutorials/so8t3bl8/how-to-serve-the-site)

