# Comment and Moderation System

At the bottom of this page, there's a comment form that allows the user to
submit a CommonMark (markdown) formatted comment about the article. All
comments are moderated, so the comment will not immediately appear on the page
after submission.

## What happens when a comment is submitted?

The comment is stored in a
**comments/** directory that resides in the directory for the associated piece
of content (article). For example, this article resides on a file system, with
the following path:

```shell
~/projects/gerbil/site/pods/tutorials/content/uujjkdd9/content.md
```

If a comment is submitted for this article, a directory will be
created under **\<article directory\>**/comments/, and a markdown file with the
comment's contents will be created there.

A file will also be created in this directory:

```shell
~/projects/gerbil/site/comment-review
```

to help the moderation system list new comments needing review. The file is
named using the comment ID, e.g.:

```shell
$:~/projects/gerbil/site/comment-review$ cat xms0bqd1.txt
tutorials|uujjkdd9|xms0bqd1
```
