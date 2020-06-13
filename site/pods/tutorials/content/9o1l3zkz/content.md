# Embedding one piece of content into another

If you're writing a series of articles, and you want to provide links to each
article in the series at the bottom of each content page, doing this manually
would be time-consuming. There is a tag, however, that can be used to embed
once piece of content into another piece. It looks like this:

```
<gerbilcontent pod="tutorials" id="wrrrn9zw"/>
```

## Embedding example

Let's create [a sample piece of content to embed](https://github.com/jasonprogrammer/gerbil/blob/master/site/pods/tutorials/content/wrrrn9zw/content.md),
and embed it in the [source of this page](https://github.com/jasonprogrammer/gerbil/blob/master/site/pods/tutorials/content/9o1l3zkz/content.md)
as an example. You should see a list of links below:

<gerbilcontent pod="tutorials" id="wrrrn9zw"/>
