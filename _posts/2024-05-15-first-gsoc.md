---
layout: post
title:  "[GSoC] I was accepted into Google Summer of Code!"
date:   2024-05-15
author: Marcelo Mendes Spessoto Junior
author_website: https://marcelospessoto.github.io/
tags: [jenkins, ci, kcov, code coverage]
---

# My first steps of community bonding in Google Summer of Code
I've been accepted into GSoC program for the kworkflow project this year! My proposal is to implement a self-owned server that will host a CI pipeline in Jenkins (replacing the actual GitHub Actions pipeline) and manage data telemetry. Let's see what I've done in the first two weeks.

## Studying the Jenkins capabilities
Jenkins is an open-sourced tool for providing automation, especially for Continuous Integration and other DevOps practices. It is a very solid and consolidated project that offers a variety of different plugins, allowing easier integration with different automation infrastructures. It is meant to be structured as a distributed system with a central Jenkins controller, which will manage the automation requests and schedule them to its different computing nodes (known as agents).

Therefore, one of the most important first tasks is to implement a first Jenkins agent to deal with the CI tasks. I've gone through the [official Jenkins agent tutorial](https://www.jenkins.io/doc/book/using/using-agents/). The agent worked fine, but a bit more refining will be done next days.

![Image]({{site.url}}/images/post_1_nodes.png)

Another major aspect of the initial Jenkins setup is the integration of the Jenkins pipeline with [the GitHub repository](https://github.com/kworkflow/kworkflow), so it can receive webhooks and build the Pull Requests and commits into the pipeline accordingly. I've already done this before the start of the Community Bonding period, but I will expand on that next section.

## The GitHub Branch Source Plugin

One of the most used Jenkins plugins is the GitHub Branch Source Plugin. It is responsible for abstracting in Jenkins the process of setting the controller to listen for webhooks sent from GitHub.

To correctly use the plugin and implement the functionality, one needs to first set up a GitHub App in GitHub. It will be responsible for receiving subscriptions from other services (in our case, Jenkins), conceding them chosen permissions in a repository, and sending them webhooks for certain events in the given repository.

It is a simple process once you get it. Create the GitHub App, select permissions regarding Checks and Pull Requests, and set the webhook URL. It is also very important to generate the App's private key and download it, so it can be given to Jenkins and used by it to authenticate with the GitHub App.

In Jenkins, create the Multibranch pipeline. With the Branch Source Plugin, VCS hosts integration options will be displayed on the pipeline settings. Then, give the appropriate branch required information, including the private key.

I've done these steps in a kworkflow's fork of mine. Then, following the suggestions of the maintainers, I implemented the first required task for the pipeline: The code coverage.

## Implementing a code coverage stage for the pipeline

When the Jenkins pipeline got associated with the repository, it didn't detect many branches at first. It is because the pipeline was set to interact only with branches containing a **Jenkinsfile** in the root directory. It is the file containing all the pipeline steps to be executed. This way, the CI pipeline is on the project repository itself, open to the general public.

![Image](assets/images/post_1/post_1_branches.png)

This is the starting point for developing the basic pipeline for code coverage generation. 

I've started by understanding how kworkflow initially generated their code coverage using GitHub Actions. It appears that the [kcov](https://github.com/SimonKagstrom/kcov) software is used, and the output is then integrated with CodeCov. By reading their documentation, I've found out that kcov also generates output in XML Cobertura format, which can then be parsed by Jenkins by using the Cobertura Plugin. Finding out how to use the cobertura command in the Groovy-scripted Jenkinsfile was not that hard, since Jenkins offers a Snippet Generator.

![Image](assets/images/post_1/post_1_codecoverage.png)

[The initial Jenkinsfile](https://github.com/MarceloSpessoto/kworkflow/commit/36b7b40ea32d5c09fbb5246839af459032b43fa4) was then finished. It resolved the code coverage problem in general.

There are still some problems that need to be addressed soon. First, I will ensure that the docker agent is set in the most efficient and scalable way possible.  Then, I will also improve the modularization of the pipeline steps for the code coverage job. 

Another important fix to be addressed is related to the vm_test and signal_manager_test, which failed in the pipeline and had to be "suspended" to validate the overall pipeline. I highly suspect it is caused by some dependency missing in the pipeline environment, and I hope I can fix it this month.

This is what I did in the first two GSoC weeks. In my first proposed schedule, I had a bigger emphasis on studying/setting virtual and physical hosts. However, after some discussions with the maintainers, we've decided to focus on replicating the actual GitHub Actions pipeline and validating it as a primary focus.
