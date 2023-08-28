---
layout: post
title: The Finite-State Machine in kw patch-hub
date: 2023-08-24 11:30:00 -0300
categories: [software engineering]
tags: [kw, kw patch-hub, finite-state machine, lore, gsoc23]
---

My GSoC23 project (which I talked about in a [previous post](https://davidbtadokoro.github.io/posts/got-accepted-into-gsoc-2023/))
is about implementing a feature in [kw](https://kworkflow.org) that serves
as a hub for the public mailing lists archived on <https://lore.kernel.org>,
with a focus on patch-reviewing. The feature is called `kw patch-hub` and
I will talk about what are the lore archives and its API in a later post,
but in this post, I'm going to describe the Finite-State Machine model used on
this feature.

## Finite-State Machines

Finite-State Machine (FSM), or Finite-State Automaton (FSA), is a mathematical
model of computation that can be used to model a variety of problems, both for
hardware and software.

This model is made of an abstract machine that can be on a **finite number of states**,
but **only one state is active at once**. The machine receives inputs and a
**transition** is the change from state A to state B when certain conditions are
met. Notice that state A can be the same state as state B and that not every possible
transition exists, in other words, not every state A has a transition that takes the
machine to any other state B. In fact, it is possible for it to be no transitions, only
states. An **input** can be considered any type of interaction with a machine, be it a
human feeding characters to software (the machine), or a device (the machine) receiving
signals from sensors.

Below, is a diagram of an FSM that has 4 states A, B, C, and D, and only receives inputs
0 and 1. The labeled circles represent the states and the arrows the transitions, the
pointed end is the state that it's being transitioned to. The 0s and 1s next to the
arrows, represent the input needed for the transition to happen. Notice that we could
omit transitions that take the machine to the same state, but this illustrates that not
every input triggers a change of state.

{:refdef: style="text-align: center;"}
![FSM example]({{site.url}}/images/diagrams/fsm-example.png)
{: refdef}

FSMs can be of two types: a deterministic Finite-State Machine (DFSM) and a
non-deterministic Finite-State Machine (NFSM). An FSM is a DFSM if two restrictions
are followed:

1. Each transition is totally and uniquely defined by its starting state and the inputs
necessary for the transition to happen.
2. For a transition to happen, the FSM needs to receive input.

The previous diagram is also an example of a DFSM.

NFSMs **don't need** to follow these restrictions, in fact, DFSMs are actually a subset
of NFSMs. In simpler terms, For DFSMs, the machine only transitions between two states
when well-defined inputs occur (that's why it is called deterministic), and, for NFSMs,
this isn't true, so a transition between two states has a probability of happening with
the machine receiving, or not, a set of inputs.

Below, is a diagram of an NFSM which is built upon the previous diagram. The only
difference is that two transitions were added:

1. From state A to state C by receiving 0.
2. From state B to state C by receiving 1.

{:refdef: style="text-align: center;"}
![NFSM example]({{site.url}}/images/diagrams/nfsm-example.png)
{:refdef}

These additions turn the previous DFSM into an NFSM because the machine in state A
can either transition to C or stay in state A by receiving 0. The same thing happens
when the machine is in state B and receives 1, it can either transition to state A or
state D.

## kw patch-hub architecture

> `kw patch-hub` is under development, so some details in this section may get outdated.
{: .prompt-warning }

As with any other kw feature, `kw patch-hub` ([link to man page](https://kworkflow.org/man/features/patch-hub.html))
has a dedicated file inside the `src` directory named `patch_hub.sh` that follows [kw's component structure](https://kworkflow.org/content/project_structure.html#components).
This means that, at the top of the file, a function named `patch_hub_main` is defined,
which is the entry point of the feature, and, at the end of the file, the functions 
`parse_patch_hub_options` and `patch_hub_help` are defined, which parses the options
passed to the feature and displays the feature's help (either a short help or the
man-page), respectively. A simplified listing of `src/patch_hub.sh` is below:

```bash
include "${KW_LIB_DIR}/ui/patch_hub/patch_hub_core.sh"

function patch_hub_main()
{
  if [[ "$1" =~ -h|--help ]]; then
    patch_hub_help "$1"
    exit 0
  fi

  parse_patch_hub_options "$@"
  if [[ "$?" -gt 0 ]]; then
    complain "${options_values['ERROR']}"
    patch_hub_help
    return 22 # EINVAL
  fi

  patch_hub_main_loop
  return "$?"
}

function parse_patch_hub_options()
{
  ...
}

function patch_hub_help()
{
  ...
}
```

Notice in the listing above that, after entering the feature through `patch_hub_main`,
it first checks if the help should be displayed, then it parses the options, then it
calls the function `patch_hub_main_loop`, which is not defined in `src/patch_hub.sh`,
but rather in `src/ui/patch_hub/patch_hub_core.sh`.

Unlike any other kw feature that has all feature-specific actions handled by functions
defined in the same file, `kw patch-hub` goes in another direction and implements the
core of the feature in files at the `src/ui/patch_hub` directory. 

That is because `kw patch-hub` is a screen-driven feature that displays screens using
[dialog](https://linux.die.net/man/1/dialog) that transitions depending on the input
the feature receives. This results in many of the functions having a similar structure:

1. Displaying a dialog screen.
2. Collecting the necessary input.
3. Setting the next screen to be displayed.

As such, implementing all these similar functions on the same source file would be a
bad design choice. Maybe worse than that, implementing step 3 described above using a
direct call to another function would make the call stack grow indefinitely. 

## The Finite-State Machine in kw patch-hub

After entering `patch_hub_main_loop`, `kw patch-hub` behaves as a Finite-State Machine,
in which the states are screens and its subscreens, and the transitions are the
setting of the `screen_sequence['SHOW_SCREEN']` value. Below, is a simplified listing
of `src/ui/patch_hub/patch_hub_core.sh`:

```bash
declare -gA screen_sequence=(
  ['SHOW_SCREEN']=''
  ['SHOW_SCREEN_PARAMETER']=''
  ['PREVIOUS_SCREEN']=''
)

function patch_hub_main_loop()
{
  local ret

  # "Dashboard" is the default state
  screen_sequence['SHOW_SCREEN']='dashboard'

  # Main loop of the state-machine
  while true; do
    case "${screen_sequence['SHOW_SCREEN']}" in
      'dashboard')
        dashboard_entry_menu
        ret="$?"
        ;;
      'lore_mailing_lists')
        show_lore_mailing_lists
        ret="$?"
        ;;
      'registered_mailing_lists')
        show_registered_mailing_lists
        ret="$?"
        ;;
      'latest_patchsets_from_mailing_list')
        show_latest_patchsets_from_mailing_list
        ret="$?"
        ;;
      'bookmarked_patches')
        show_bookmarked_patches
        ret="$?"
        ;;
      'settings')
        show_settings_screen
        ret="$?"
        ;;
      'patchset_details_and_actions')
        show_patchset_details_and_actions "${screen_sequence['SHOW_SCREEN_PARAMETER']}"
        ret="$?"
        ;;
    esac

    handle_exit "$ret"
  done
}
```

Each case in the `switch-case` is a state in the FSM. A state is composed of a screen
and (maybe) subscreens. For example, the state `dashboard` is represented by only one
screen named 'Dashboard', as shown in the image below:

![kw patch-hub Dashboard]({{site.url}}/images/kw_patch_hub_dashboard.png)

On the other hand, the state `settings` is represented by the 'Settings' screen, each
setting subscreen, and any auxiliary screen, as shown in the GIF below:

![kw patch-hub Settings]({{site.url}}/images/gifs/kw_patch_hub_settings.gif)

By selecting the option `Save Patches To`, a subscreen to select the path of the default
directory to save patches is displayed. Inside this screen, if the user hits the button
labeled 'Help', a help screen is displayed. If the option 'Kernel Tree Target Branch'
is selected before setting 'Kernel Tree Path', a screen with an error message is displayed.
Both sequences described take the FSM from and to the `settings` state. At the end of the
GIF, the option 'Register/Unregister Mailing Lists' is selected, which takes the FSM from
the `settings` state to the `lore_mailing_lists` state.

Notice that in each iteration of the loop, the active state is determined and the
function that displays the necessary screen (and subscreens), collects the necessary
inputs, and transitions the FSM to another state if that is the case. To illustrate
this, look at this simplified listing of the `dashboard_entry_menu` function:

```bash
function dashboard_entry_menu()
{
  local -a menu_list_string_array
  local ret

  menu_list_string_array=('Registered mailing list' 'Bookmarked patches' 'Settings')

  create_menu_options 'Dashboard' '' 'menu_list_string_array'
  ret="$?"
  if [[ "$ret" != 0 ]]; then
    complain 'Something went wrong when kw tried to display the Dashboard screen.'
    return "$ret"
  fi

  case "$menu_return_string" in
    0) # Registered mailing list
      screen_sequence['SHOW_SCREEN']='registered_mailing_lists'
      ;;
    1) # Bookmarked patches
      screen_sequence['SHOW_SCREEN']='bookmarked_patches'
      ;;
    2) # Settings
      screen_sequence['SHOW_SCREEN']='settings'
      ;;
  esac
}
```

The function `create_menu_options` displays a menu for the user to choose an option
between all available options (in this case, the elements of `menu_list_string_array`).
The interaction of the user with the screen by selecting an option results in the
`menu_return_string` variable storing the option number, from which the function
determines the next state by updating `screen_sequence['SHOW_SCREEN']`, or, in other
words, determines the transition that must happen.

It is worth noting that there are cases in which two different transitions can happen
**with the same user interaction**. For example, if there are no bookmarked patches
and the user selects the option 'Bookmarked patches' in the 'Dashboard' screen, a
message is displayed, then the FSM state reverts back to `dashboard`, instead of
the FSM transisitoning to `bookmarked_patches` and showing a screen with the list
of bookmarked patches, then waiting for the user interaction. Below, is a GIF showing
these two different transitions with the same user input:

![kw patch-hub different transitions]({{site.url}}/images/gifs/kw_patch_hub_different_transitions.gif)

It is important to stress that `kw patch-hub` is an DFSM, because these different
transitions happen depending on the existence of bookmarked patches, which is also
an input to the FSM.

## Conclusion

The Finite-State Machine model is simple to understand and implement. In the case
of `kw patch-hub`, adopting this model as the base of the feature was really beneficial,
as we can abstract the feature in these states represented by the screens/subscreens
and transitions, which makes the code less complex and easy to expand.

It is worth noting that the model isn't strictly implemented wherever possible, as
we could make the states more fine-grained by having a state for each and every type
of screen. In my opinion, we could extract new states, but , if this extraction lowers
the quality of the code, we should opt not to do it.
