---
layout: post
title: GSoC24 Final Report 
date: 2024-08-23 22:24:25
author: Aquila Macedo
author_website: https://aquilamacedo.github.io/
tags: [kw, gsoc, integration_testing]
---

Well, after spending the last few months studying and contributing to
[kworkflow](https://kworkflow.org/) as part of **Google Summer of Code 2024**
under the **Linux Foundation**, it’s time to catalog all the contributions made
during this period. I can confidently say that this experience has been
extremely enriching and has significantly advanced my development skills.

# Proposal

My GSoC24 proposal focused on enhancing and expanding the integration tests for
**kworkflow**, which previously had only unit tests and a starting
infrastructure for the integration tests. Throughout the program, I worked on
introducing, enhancing, and solidifying these integration tests to ensure more
effective validation of the project's features. Additionally, I aimed to make
the test suite easily expandable by implementing clear standards and robust
infrastructure. This approach allows future contributors to add new tests with
minimal effort, ensuring that the suite can grow alongside the project.

# Overall Progress

Throughout my participation in the GSoC24, I achieved significant milestones
that reflect both the breadth and depth of my contributions.

### Key Achievements

1. **Enhanced Integration Test Coverage**: I focused on making the test
   infrastructure stronger and more scalable. I improved the existing
   integration tests and added new ones for important features like `kw ssh`, `kw
   build`, and `kw deploy`. This significantly increased the range of tested
   scenarios.

   ![Picture](/images/kw_ssh_example.png)

2. **Adaptation of CI for Integration Tests**: As part of enhancing the testing
   process, I adapted the GitHub Actions CI workflow to include the execution
   of integration tests.

   ![Picture](/images/integration_github_ci.png)

3. **Refinement of the kworkflow test script**: During the refinement of the
   integration tests, the `run_tests.sh` script used to execute the kw tests
   was updated to include a `--verbose` option. This option aids in debugging by
   displaying detailed information about the Podman containers, such as real-time
   status and specific data to identify which container from which distribution is
   being started.

   ![Picture](/images/run_tests.gif)

   By default, running `./run_tests.sh` without any optopns will execute only unit
   tests, which helps reduce execution time. An `--all` option was implemented for
   users who want to run all tests, including time-consuming integration tests.
   For example, the `kw build` integration test involves kernel compilation, which
   can be lengthy. If a contributor makes a minor change that doesn't affect `kw
   build`` functionality, running the full integration tests is unnecessary. This
   update ensures more efficient test runs by allowing contributors to focus on
   relevant tests only.

# Challenges and Solutions

During my journey in the Google Summer of Code, I faced several challenges
while implementing and improving integration tests for kworkflow. Initially,
adapting the tests to run in Podman containers was a considerable challenge. I
resolved this by thoroughly studying the [Podman
documentation](https://docs.podman.io/en/latest/) and adjusting the test
scripts to ensure compatibility and performance within the testing framework.

Another major challenge was integrating tests for the `kw build` feature due to
the extended time required for kernel compilation. To mitigate this issue, the
tests were adapted to run on only one random distribution, saving both time and
resources. I utilized Podman containers and the
[shUnit2](https://github.com/kward/shunit2) framework to organize the tests,
along with specific scripts to monitor and validate CPU usage with the
`--cpu-scaling` option. This allowed `kw build` to be tested without the need
to compile the entire kernel

The integration tests for the `kw ssh` feature were more complex due to the use
of nested containers. Adapting the tests for this scenario was challenging, but
it also provided a valuable learning opportunity. Additionally, I had to manage
the execution of commands with special characters inside the containers. To
address this, I developed functions to ensure that these commands were
correctly interpreted by the shell.

Throughout my GSoC24 experience, I encountered numerous challenges, but I was
able to overcome them thanks to the consistent support from my mentors, who
were always available to address my questions. Beyond the dedicated meetings
for my project, the weekly discussions with the kworkflow community proved
extremely helpful. These sessions offered broader insights and helped ensure
that my work was in line with the community's goals and expectations.

# Blogpost Series Timeline

This post is a high-level view of my GSoC24 project. A more detailed and
technical overview of the work done can be seen in previous posts. I have
prepared a series of blog posts that explore different aspects of the
**kworkflow** project. Here is a timeline of the posts, with direct links to
each one:

1. [Accepted to Google Summer of Code 2024]({{site.url}}/got-accepted-into-gsoc/)

2. [Introduction to Integration Testing in kworkflow ]({{site.url}}/introduction-to-integration-testing/)

3. [Integration Testing for kw ssh]({{site.url}}/integration-for-kw-ssh/)

4. [Integration Testing for kw build]({{site.url}}/integration-for-kw-build/)

# Contributions

Throughout the project, I created several pull requests (PRs) addressing
different aspects of kworkflow. Each PR was carefully crafted to enhance
functionality, increase test coverage, and/or ensure code robustness. Below are
some of the most significant PRs:

| Pull Request | N° of Commits | 
|--------------|:---------------:|
| [setup: install kernel build dependencies](https://github.com/kworkflow/kworkflow/pull/1108) |4|
| [tests: integration: device_test: modify kw device integration test to run entirely in container](https://github.com/kworkflow/kworkflow/pull/1135) | 2 |
| [tests: integration: refactor kw_version_test to run entirely in container](https://github.com/kworkflow/kworkflow/pull/1113) | 1 |
| [run_tests: dedicate a container per test file for integration tests](https://github.com/kworkflow/kworkflow/pull/1130) | 2 |
| [run_tests: streamline test execution logic](https://github.com/kworkflow/kworkflow/pull/1148) | 1 |
| [tests: integration: self_update_test: add self-update test](https://github.com/kworkflow/kworkflow/pull/1055) | 3 |
| [tests: integration: deploy_test: introducing deploy tests](https://github.com/kworkflow/kworkflow/pull/1161) | 2 |
| [tests: integration: kw_ssh_test: Add integration tests for kw ssh functionality](https://github.com/kworkflow/kworkflow/pull/1116) | 5 |
| [tests: integration: build_test: add the kw build test](https://github.com/kworkflow/kworkflow/pull/1143) | 3 |

However, these PRs represent only the visible contributions. A significant
amount of work was done behind the scenes, including researching the best
approaches, communicating with mentors, gathering feedback, and iterating on
solutions. This "offline" work was crucial in shaping the direction and quality
of the contributions.

### Features in Development: Almost Ready to be Merged

The PRs listed above include features that are actively in development, such as
tests for the `kw ssh`, `kw build`, and `kw deploy` functionalities. Although
many of these PRs are already well-structured, they are still undergoing final
reviews and refinements. A significant portion of the important decisions has
already been discussed within the kworkflow community, and have the green light
of the mentors, so I can safely say that the direction of my project is set and
aligned with kworkflow goals and needs.

# Next Steps

As a long-time contributor to **kworkflow**, I am committed to continuing my
contributions to the project. Here are the key areas I plan to focus on:

1. **Expanding even more the Integration Test Coverage**:
 Continuing to expand the test coverage is a priority. I will work on creating
 and refining tests for additional functionalities that have not yet been fully
 covered, ensuring a comprehensive and effective validation process. Although
 this initial phase involved tackling complex and diverse features such as `kw
 build`, `kw deploy`, `kw device`, and `kw ssh`, which required significant
 effort due to their intricate infrastructure, this groundwork has paved the way
 for easier and more straightforward expansion of the test suite. The standards
 and infrastructure established during this process will streamline the addition
 and revision of tests, making future coverage enhancements more efficient and
 scalable.

2. **Migrating to New CI Pipeline**:
 An important next step is migrating the integration tests to a new CI pipeline
 which is being developed with" **Jenkins** by Marcelo Spessoto, a fellow Google
 Summer of Code 2024 participant working on the kworkflow project. This
 migration will demand some small tinkering on my end to accommodate the
 integration tests pipeline in this new infrastructure. Nevertheless, thanks to
 close communication with my fellow kworkflow contributor, we are confident that
 this will happen as seamlessly as possible

3. **Implementing Acceptance Tests**:
 I plan to develop acceptance tests that will validate multiple functionalities
 in sequence. These tests will ensure that the integration of various features
 works seamlessly and meets the overall requirements of the project.

4. **Improving Documentation**:
 I will focus on improving the documentation specifically related to the
 integration testing processes within the project. This includes updating
 existing documentation to reflect new practices, enhancing clarity, and
 ensuring that all relevant information is accessible and useful to contributors
 and users alike. By providing clear and detailed documentation, the integration
 testing process will become more transparent and easier for future contributors
 to understand and build upon.

# Acknowledgments

I would like to express my deep gratitude to my mentors, **David de Barros
Tadokoro**, **Rodrigo Siqueira**, **Paulo Meirelles**, and **Magali Lemes**.
Your attention, ideas, and feedback were crucial to the success of this project
and made the journey much more enriching. I sincerely appreciate your constant
support and valuable contributions :-).

Additionally, I would like to thank the **Linux Foundation** for the
opportunity to participate in Google Summer of Code 2024. It was an incredible
and transformative experience.
