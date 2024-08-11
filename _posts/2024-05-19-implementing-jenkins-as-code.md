---
layout: post
title:  "[GSoC] Implementing Jenkins as Code"
date:   2024-05-19
author: Marcelo Mendes Spessoto Junior
author_website: https://marcelospessoto.github.io/
tags: [jenkins, ci, CaC]
---

# Applying the Jenkins as Code paradigm

On my first two GSoC weeks, I've dealt with a basic Code Coverage pipeline and implemented it on a 
bare-metal infrastructure. My next expected steps, according to my project schedule, were to start 
implementing the virtual machine and physical device agents. Turns out, however, that this task may be
delayed a little bit more, so I can focus on polishing the Jenkins pipeline foundation.

As I've immersed myself in the Community Bonding period, the proper port of the complete actual GitHub 
Actions CI to Jenkins has emerged as a more important task. From that, we will have a nicer environment
to plan and develop the new testing workflow. Also, the dummy implementations could be seamlessly packed
into the development period, where I will direct all my efforts on this specific issue.

## Applying CaC

Configuration as Code (CaC) is a paradigm where the configuration of an application is described in "code",
such as yaml scripts. This way, one can easily automate the deployment of such infrastructure by using the
code instead of setting things up manually.

Doing that for the kworkflow Jenkins pipeline would bring many benefits. Most of the CI configurations
and plugin settings could be saved on a VCS host server, keeping all the DevOps work preserved and ready
for deployment on any bare-metal network.

### First step: setting a Docker Compose environment

First of all, it will be interesting to replace the actual Jenkins bare-metal install with a containerized
service. It makes the service deployment easier and also enables one to set up a specific configuration for
Jenkins as Code Plugin (we'll come into that really soon) and plugin set.

Also, this enables the use of Docker Compose to orchestrate the automated deployment of the Jenkins servers
alongside its Jenkins agent container. 

The only important configuration I needed to set on the Dockerfile was to install the necessary Jenkins plugins.

The full setup can be found [here](https://github.com/MarceloSpessoto/jenkins-kw-infra). 

### Using Jenkins plugins for CaC deployment

After setting up the basic docker environment, my next steps would be to configure Jenkins as Code for immediate configuration of newly deployed Jenkins containers.

The core Jenkins for CaC is JCaC (Jenkins Configuration as Code). It lets you write on a simple yaml file the configuration settings of your Jenkins server.

It is very simple to figure out how to write the configuration file. You can access their [example configuration samples](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos). You can also export yaml from a Jenkins server.

By using their example configuration as a reference and by exporting the configuration from a Jenkins server I've previously set before, I was able to deliver a basic Jenkins configuration for kworkflow's needs.

The most important configuration, however, was to allow the automated setup of the Jenkins credentials. I've managed to achieve that by mounting the credentials files (private keys, etc.) into the docker containers, and loading the mounted credential files directly from the JCaC configuration file.

### Job DSL plugin

For the kworkflow pipeline, it is also very important to setup the pipelines automatically. The kworkflow's CI workflow actually executes 5 different jobs, and thus, we need to easily configure 5 different pipelines in Jenkins, each having the same credentials configuration and executing their unique pipeline jobs. 

This can be achieved by using the Job DSL plugin. It is called by JCaC plugin to create jobs in an automated way. We set a groovy file, declare an array with 5 different job names. For each job, create a Jenkins multibranch pipeline, and set it to execute the job from a Jenkinsfile with the job's name.

The Jenkinsfile with the job to be executed is expected to remain in the kworkflow repository.

