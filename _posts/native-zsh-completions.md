---
layout: post
title: Adding support for native Zsh completions
---

Being a somewhat new user of Zsh - made the transition from Bash around 2
months ago - I never thought I would have to learn about its completion
system or how to write my own custom completion functions so soon.

As of writing, I'm almost at the end of a long PR that aims to bring support
for native Zsh completions to kw. In this post, I'm going to share exactly
what I think "bring support for native Zsh completions to a tool" means, its
benefits and what it encompasses in the context of this PR. You can find the PR
at <https://github.com/kworkflow/kworkflow/pull/773>.

# Motivation and Benefits

As I already stated, I'm a new Zsh user, so when I came across the issue in kw
reported [here](https://github.com/kworkflow/kworkflow/issues/501), I thought it was something related to my setup and configurations.
Upon further digging, I understood that the Zsh completions to kw were adapted
from the Bash ones using the `bashcompinit` command and that an incompatible
function was the reason the Zsh completions were broken (refer to the issue for
more info). This encouraged me to get my hands dirty and try to add native Zsh
completions to kw.

Even further, for those that never explored far enough a completion system of a
shell (like me, before Zsh) below is a demo of it for the `kw config` command.
Important to note that this whole time the "completions" I'm referring to are
sometimes called "tab completions", as they are triggered by pressing the TAB
key.

![Kw Zsh Completion]({{site.url}}/images/gifs/kw-zsh-completion.gif)

Notice two benefits from having completions for a given tool:

1. You somehow attach the documentation of the tool and its commands/options
   to its usage. The user can sometimes avoid having to look in an extensive
   documentation or having to search for online guidance on how to execute some
   task (although a "completions documentation" is probably really superficial).
2. Completions really improve the user experience of a tool, as it greatly
   reduces the amount of typing and typing related errors. Having the above GIF
   in mind, the word `build.cpu_scaling_factor`, for example, refers to a pair
   `<kw-command>.<command-config>` that must be known to the user (and typed
   correctly) before the use of the `kw config` command, if there are no
   completions for it.

Both benefits can be an important factor in making the tool more user-friendly.

# Writing native Zsh completion functions

Maybe I'm not suited for this type of system, but I'm not gonna lie: it is a
considerable challenge to create completions to a tool. There are two main
challenges in implementing completions:

1. Technical aspects such as getting the TAB key-press or defining what is a word
   and when it is considered completed.
2. Really understanding the tool as a whole is critical, because you are going to
   have to document it and know about domain-specific logics like mutually
   exclusive options, different type of arguments and how to complete them and
   so on.

The first challenge was (thankfully) already done by Zsh, but comes with a price
that "there are probably lots of bugs around", as stated by the official Zsh
documentation, making some unavoidable utility functions act weird sometimes.

The second challenge was also really simplified by the wonderful documentation
of the kw project. Of course, I had to mess around a little with some kw commands
I wasn't acquainted, and sometimes the documentation was a little outdated, but
it would not be possible to cover all the kw commands without it.

For more detailed information on how to write your own Zsh completion functions,
refer to:

* [Short but great intro to Zsh completions](https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org#writing-your-own-completion-functions)
* [A thorough and official tutorial on writing custom Zsh completions](https://zsh.sourceforge.io/Guide/zshguide06.html)
* ["Man-page" for some Zsh completion utility functions](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Completion-Functions)

As of writing, there are 28 commits in the PR. There is one commit to each kw
command, more or less.

# What is next?

1. There is no automated way to test the validity of the implementations and
   manual testing is really prone to errors
2. Probably there are some interpretation errors on my part, so some domain-
   specific logic may not be well represented by the completions
3. Although one can follow the references above and also learn from the PR,
   the Zsh completions system is really complex and has some hard-to-learn and
   unexpressive syntax, so altering/expanding any kw command and having to
   update the Zsh completions is not a straightforward task. Maybe a tutorial
   or additional documentation is needed to simplify this process.
