# Syntax highlighting for code

Here is a sample Python code snippet:

```python
for i in range(10):
    print("Sample python snippet!")
```

Notice how some of the text appears in different colors, for readability.

To accomplish this, specify the language in the Markdown, e.g.:

~~~
```python
for i in range(10):
    print("Sample python snippet!")
```
~~~

The colorization is done on the front-end, using
<a href="https://highlightjs.org/">highlightjs</a>.

Make sure that any languages you'd like to colorize are added to the
part of the code that configures highlightJS (see **web/js/content.entry.js**).
