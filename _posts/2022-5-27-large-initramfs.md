---
layout: post
title: How to fix Kernel boot "error, out of memory"
---

I usually have my dev system and a test machine to validate my changes for
developing to the Linux kernel. I also keep my config files and use them every
time for my test systems. Nevertheless, I recently had to get a different test
system (but very similar), and I created a new config file based on the ones
that I already had; everything worked as usual, except for this error during
the boot:

 ![Huge Initramfs]({{site.url}}/images/initramfs-error.png )

I was surprised because I did not change many things. After I started to look
into the problem, I realized that my initramfs had more than 200MB, which was
the root cause. Next, I asked myself why my initramfs were so huge? Thanks to
some folks in the kernelnewbies channel, I figured out that I have the
CONFIG_DEBUG_INFO option set. I dropped this option and re-deploy my kernel,
and everything worked as expected. Yet, I was intrigued because the Debian
package generated during the compilation worked fine... after digging about
this topic, I realized that the Debian package uses the `INSTALL_MOD_STRIP`
option by default:

 <https://01.org/linuxgraphics/gfx-docs/drm/kbuild/kbuild.html#install-mod-strip>

If you set this option during the modules_install operation, you will have
small initramfs. I decided to use it by default inside kw to avoid problems
like this for all kw users. See:

 <https://github.com/kworkflow/kworkflow/pull/606>
