+++
title = "Another year, another blog redesign"
date = "2026-07-04 16:12:39"

[taxonomies]
tags = ["blog"]
+++


After a lot of consideration, I've gone ahead and switched out both the backend and the theme of this site yet again. There were a number of ongoing issues, the most notable of which were:

- The monospace font for the [`Cactus` theme](https://github.com/probberechts/hexo-theme-cactus) was honestly hard to read. Additionally, the mobile layout had poor padding.
- Configuration of the theme involved managing 2 different config files, which quickly became convoluted.
- There was no auto-dark mode for `Cactus`, and I was not particularly interested in trying to design and configure it.
- The theme was not self-contained, and was loading 5 different minified JS scripts through Cloudflare.
- The [`hexo` backend](https://hexo.io/) was excessive for what was essentially a collection of static webpages. It required 10 NPM packages, installing nearly 60Mb of dependencies (the theme was another 12Mb).
- To run `hexo`, I had to install a NodeJS runtime and a specific version of NPM, which I was doing with NVM ([Node Version Manager](https://github.com/nvm-sh/nvm)). Sourcing this in my `zshrc` was so bloated it was taking seconds to load my shell, which is a [known problem](https://superuser.com/a/1611283).

Ultimately, my requirements are very basic: convert Markdown files into HTML & attach minimal CSS styling (and maybe some very minimal JS for page interactions). I could have put in a lot of time trying to address these items with the existing framework, but my skills in the graphic design department, especially webdev, is currently not my strongest suit. I knew I had gone too far when I started to learn Figma...

Luckily, there was an existing project made specifically for this use case!: [Zola](https://www.getzola.org/)

This project hits all the points in my wishlist:

- A single, simple, small binary
- Built-in, easy to use templating engine that can transpile Markdown into HTML
- Can compile Sass into CSS

I also found a theme that also looks much better on both mobile and on desktop: [Serene](https://github.com/isunjn/serene)

- It has an auto-dark mode theme that looks nice
- Padding is significantly better
- The font choice is much more readable

All in all, this framework and theme is much easier to configure, so I may actually tweak it further (unlike with the previous theme). The only negative impact of this change is that the URL slugs have changed, which will break previous links: 

-  date baked-in (`/2026/03/14/replacin...`) --> directly under `/posts/` (`/posts/replacin...`)

Given how minimal (and external dependency-free) this new theme is, I can also revisit hosting a copy of it on a Hidden site through Tor (or even I2P) which, although a fun project, was also annoyingly slow with the heavier framework & additional JS dependencies.
