---
layout: post
title: Lore Interface
author: Rodrigo Siqueira
author_website: https://siqueira.tech
date: 2022-02-12
tags: [kw, lore, kw patch-hub]
---

When I started contributing to Linux Kernel, one of my favorite tasks for
learning more about the kernel was following the public mailing list of the
subsystem that I was interested in. A few months after I started contributing
to the kernel, I became a maintainer and had to follow patches related to the
driver that I was maintaining. A few weeks ago, I also became one of the
maintainers of the display component under the amdgpu driver. Yeah... I am
aware that I'm doing poor work as a maintainer, which  I blame the lack of
structure in my review flow. Don't get me wrong, I was trying... for example, I
set up my neomutt to help me with that, but unfortunately, I could not use it
anymore due to external forces, which broke my already inefficient review
process. Anyway, I'm uncomfortable about that since I want to be a better
maintainer, but I realize that I need to fix my workflow.

With these ideas in mind, I have to admit:

1. I'm not well versed in Linux Kernel yet, which means that I like to test
   patches before adding my Reviewed-by;
2. Download patches from my email client was painful and not comfortable to me;

3. The lack of mailing list management becomes a problem in a short time;
4. Relying on multiple external tools (e.g., patchwork, email client, lore,
   etc.) was not working for me.

I use kw every day, I thought I could include patch reviews and some
maintainer's tasks as part of my workflow with kw. Fortunately, this can be
possible thanks to the lore API introduced to the Linux kernel mailing list.
Finally, I want something that makes my life easier and with as little overhead
as possible, and a simple UI would be perfect for that; luckily, I became aware
of an elegant (at least from my perspective), simple, and stable tool named
dialog!

Since all pieces were in the table, I made a super simple interface prototype
and shared it with [Melissa Wen](https://melissawen.github.io/), who
immediately liked it and got on board with this project idea. To make things
simple, Melissa and I decided to create a small prototype in a separate
repository to simplify our collaboration. You can see it here:

<https://gitlab.freedesktop.org/siqueira/lore-prototype>

After two months of work, we have a tiny functional prototype. In this post, I
don't want to talk about the details, but I want to share a gif that shows a
demo of this little prototype:

![Lore Prototype]({{site.url}}/images/gifs/lore-prototype-hello-world.gif )

That's it for this post. Stay tuned for new kw updates.

# What is next?

1. Complete our prototype
 * Complete all windows that we planned in this issue:
   <https://gitlab.freedesktop.org/siqueira/lore-prototype/-/issues/4>
 * Squash as many bugs as possible
2. Integrate it to kw
 * PR 1: Introduce liblore file with massive code coverage.
 * PR 2: Introduce dialog lib.
 * PR 3: Implement windows
