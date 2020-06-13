# Topic links

During a `gerbil build`, an HTML file is created that contains a list of links
for each pod (topic) you have created.

An example of this page is [here](https://github.com/jasonprogrammer/gerbil/blob/master/site/pods/index.html).
In the [home page content template](https://github.com/jasonprogrammer/gerbil/blob/master/web/templates/home-content.html),
you can insert the following mustache tag:

```xml
{{{topics}}}
```

This will insert the links into the template.

