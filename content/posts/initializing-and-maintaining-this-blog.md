+++
title = "Initializing and maintaining this blog"
date = "2026-07-19 13:07:37"

[taxonomies]
tags = ["blog", "git"]
+++


I always have some kind of uncommitted README file laying around with notes about how I created and maintain this site, so I figured, why not turn it into a post?


## Installing & Updating

Installation followed the Serene usage guide found here: [USAGE.md](https://github.com/isunjn/serene/blob/latest/USAGE.md)

```bash
zola init devedge.github.io && cd $_
git init
git submodule add -b latest https://github.com/isunjn/serene.git themes/serene
```

To update, the [Update](https://github.com/isunjn/serene/blob/latest/USAGE.md#update) section covers how to pick up the latest version of the theme:

```bash
git submodule update --remote themes/serene
```

The local environment can be previewed by running the `zola` webserver:

```bash
zola serve
```


## Useful Locations

Posts are under: `content/posts/`

Assets are stored under `static/assets/`, and post-specific assets are stored in a subfolder that matches the page name. Currently, this is manually created.

New pages are new directories under `content/`, and have an `_index.md` file that defines the home page.

Theme files can be modified/overwritten by placing a duplicate file under the root site's equivalent directory. For example, the `_base.html` file from the Serene theme was overwritten to adjust the favicon names. This is originally under `themes/serene/templates/_base.html`, so the modified version was copied from there and placed under `templates/_base.html`.


## Creating New Posts

Creating a new post is super simple - just create a new markdown file under `content/posts/` with the following:


```markdown 
+++
title = "Post title"
date = "2026-07-18 14:20:33"

[taxonomies]
tags = ["tag1", "tag2"]
+++

..._Markdown content here_...
```

Given how simple this is, I have 2 scripts to handle this, `new-post.sh` & `update-post-date.sh`.

First, create a new Git branch:

```bash
git switch --create initializing-and-maintaining-blog
```

Create the new post with:

```bash
$ ./new-post.sh "Initializing and maintaining this blog"
Slug: initializing-and-maintaining-this-blog
Path: content/posts/initializing-and-maintaining-this-blog.md
```

and then begin writing/committing work to this file in this branch.

Once the post is complete and ready to be merged into `master`, run and commit:

```bash
./update-post-date.sh content/posts/initializing-and-maintaining-this-blog.md
```

- The `new-post.sh` script generates a url-safe slug & creates the draft post with the slug as the filename.
- The `update-post-date.sh` script updates the placeholder draft date of `9999-01-01 00:00:00` to the current date.

Usually, I'll squash all the commit in the branch before merging it. To squash the last 4 commits:

```bash
git rebase -i HEAD~4
```

In the rebase popup, set the topmost commit as `pick` and all the following ones as `squash`es. Once written, it will pop up again with all the previous commit messages, which can be removed & replaced with a single commit line.

If this was done locally, a merge+push will work fine. However, if the rebase is done to a commit that has already been pushed to the remote master, the push needs to be forced:

```bash
git push --force
```

Merge the branch into `master` and push to `origin` with:

```bash
git checkout master
git merge initializing-and-maintaining-blog
git push
```

## Miscellaneous

These are a few Git specific situations that commonly happen.

### Updating a branch with the latest from `master`

If there are new modifications to `master` that need to be applied to a current branch, rebase it off of `master` with:

```bash
git checkout initializing-and-maintaining-blog
git rebase master initializing-and-maintaining-blog
```

### Stashing work

Stashing is useful when quickly jumping branches, where a commit would be too much.

```bash
git add .
git stash push --message "description"
```

The `--all` command also includes ignored items, which can break the `zola` precompiled data under `public/`. The `--include-untracked` is more likely to be useful.

Re-apply with:

```bash
git stash pop stash@{0}
```
