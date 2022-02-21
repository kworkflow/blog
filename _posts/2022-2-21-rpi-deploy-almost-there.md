---
layout: post
title: Add support for Raspberry PI
---

Since January, I have been refactoring and improving the deploy code in order
to make it easy to add other platforms. Introducing Raspberry Pi support was a
great study case to find the weak points in the deploy and make it more
generic. As a result, I finally have a PR that enables Raspberry PI deploy and
modularizes the deploy code. Check it at:

* <https://github.com/kworkflow/kworkflow/pull/563>

In this post, I want to describe the above PR briefly.

# Commits

I tested this PR in the following devices and software:

* Raspberry PI 4 - 32 bits - Rasbian - Remote deploy
* x86 - 64 bits - Ubuntu - Remote deploy

## Commit 1: Fix progress bar

I added a progress bar to the `modules install` command, but my first
implementation had a lot of bias from the x86 environment. One bias is the
assumption that all modules are signed, producing one extra line per module in
the output message. This claim was not valid for a standard Rasp `.config`
file, which resulted in a progress bar that ends in 50%, which is not a big
deal, but I could not find my peace with that. After searching about this
module sign, I figured out that the config option `CONFIG_MODULE_SIG=y` is
responsible for enabling the driver sign. After finding this information, it
was easy to fix the issue since I just needed to check for the
`CONFIG_MODULES_SIG=y` in the config file before adding the multiplying factor.

## Commit 2: Pack boot file and deploy it

In x86, we need to deal with a few extra files from the boot perspective:
kernel image and initramfs (or similar). This is not true for a Raspberry PI
since it needs to deal with dtb and dtbo files; to support Rasp system and
probably others. I realized that we need to deal with `/boot` files in a
dedicated deployment step. My strategy was:

1. Check for files that need to deployed
2. Copy all of these files to a single place that I can compress
3. Send the compressed file to the remote
4. In the remote, uncompress those files in the boot folder

We don't need to compress anything for the local and VM deploy because we can
easily copy files around. Anyway, now kw is way more generic in how we handle
`/boot`. Finally, a lot of tests were refactored to work with this new
approach.

## Commit 3: Enable Raspberry PI support

IMHO, Raspberry PI has a weird bootload, and as far as I know, it lacks a
command line or tool to deal with it. For this reason, I had to implement a
file that will interface kw with `config.txt` file from Raspberry PI
bootloader; it was a mix of fun work and tedious tasks... It has many tiny
things that can go wrong, but I think I found many of the issues and added a
test for each case to avoid potential regressions.

## Commit 4: Final adjustments

In the final commit, I made a lot of adjustments to make the kernel uninstall
in a PI a little bit easier. As a result, I also made it more generic. Most of
the work in this commit was related to the test refactor.

# What is next:

I'm sure that the current implementation is not flawless, but I need reviews
and people reporting issues in this feature. Also, I do not work with Raspberry
PI, so I'm not super focused on that; if you work with Rasp consider helping us
with this feature. Anyway, the next part should be:

* Run `kernel deploy` using local target
* Check the behavior with VM and fix issues
* Polish this PR and merge it
* Check with Raspbian 64 bits
* Check with Ubuntu in a PI
* Check with ArchLinux in a PI
