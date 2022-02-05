---
layout: post
title: Preparing for adding support for RaspberryPi 4 deploy
---

For a long time, I'm aiming to expand kw to provide good support for non-x86
machines. As part of this effort, I enabled `kw deploy` to work with an ARM
target system that resembles x86, and fortunately, it works really well.
However, as a DIY enthusiast, I always wanted to enable kw to deploy custom
kernels to Raspberry pi, but I had the following obstacles:

* Raspberry Pi does not use a well-known bootloader such as Grub or Syslinux
  (tbh, I don't know yet what it is).
* Kw deploy had a lot of x86 assumptions.
* I did not have a Raspberry Pi.

This situation changed, and in the last few weeks, I have been working to
improve the deploy code to make it more modularized and flexible. See:

1. <https://github.com/kworkflow/kworkflow/pull/536>
2. <https://github.com/kworkflow/kworkflow/pull/559>

After the above rework, kw deploy had these phases:

1. Basic setup in the remote (install required package and distro-specific
   adjustments).
2. Modules deploy.
3. Kernel image deploy.
4. Bootloader update.

Each of the above steps has room for specific routines, and thanks to that, we
can have something specific for Raspberry Pi hooked in each phase. Now that I
had prepared the house to receive this new family member, I needed to know it
better, and for this reason, I tried to deploy a custom kernel manually. From
this experiment, follows a highlight of each step:

## Use the correct repository

I thought Torvalds or dri-devel repository would work as expected as a naive
approach. Unfortunately, I realized that I was missing something, and those
repositories do not work out of the box. After I had a quick chat with Melissa,
I realized that my life with Raspberry Pi would be way simpler if I use:

<https://github.com/raspberrypi/linux>

I used the rpi-5.10.y branch.

## Use the correct config file

For the config file, we need to pay attention to the correct config file for
the target Raspberry Pi and remember to use the cross-compilation flag. For
example, in my x86 dev system, I constantly use:

`make bcm2711_defconfig`

This created a set of headaches since I did not use the cross-compilation flag.
In other words, I need to use:

`make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig`

## Build and Deploy

You can read the below link to learn everything you need to deploy a new
kernel:

<https://www.raspberrypi.com/documentation/computers/linux_kernel.html>

From the kw perspective, the following command sequence is important:

``
make -j4 zImage modules dtbs
sudo make modules_install
scp arch/arm/boot/dts/*.dtb root@IP:/boot/
scp arch/arm/boot/dts/overlays/*.dtb* root@IP:/boot/overlays/
scp arch/arm/boot/zImage root@IP:/boot/$KERNEL.img
``

The most exciting thing that I learned in this process is the Device Tree
Source/Blob (DTS/DTB). In the embedded system world, we have these DTS files
that describe the SoC resources in a human-readable way, and later on, the
developer compiles them to generate DTB, which is used in the boot phase.

## Raspberry Pi boot config.txt

In the `/boot` folder, we have this `config.txt` file that describes multiple
things about the system, one of them is the kernel name. We need to put the new
kernel name as something like `kernel=kernel-myconfig.img`.

## What is next

Ok, now that I know how to build and deploy, it is time to integrate it to kw.
This is my plan:

1. Add support to `make olddefconfig` that work with multiple platforms.
2. Check if we have dtb and dtbo files in the kernel image phase. If we have
   those files, let's deploy them in the `/boot` folder.
3. Create a Raspberry Pi script that updates the Pi bootloader (i.e.,
   `config.txt`).
4. Creates a new parameter under `kw init` named `--template` and adds a rpi4
   template.

This work will be a little bit slow because I'll work on it in my free time;
hopefully, I can have it done by the end of February.
