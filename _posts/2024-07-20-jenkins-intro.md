---
layout: post
title:  "[Jenkins] Introduction to Jenkins"
date:   2024-07-20
author: Marcelo Mendes Spessoto Junior
author_website: https://marcelospessoto.github.io/
tags: [jenkins, ci]
---

# Exploring Jenkins 

This the very first post from my Jenkins series. The idea of this series is to
register valuable information about the Jenkins tool but also to track different aspects
of it that I've explored during Google Summer of Code.

These blog posts will try to explain core concepts/practices regarding Jenkins in a succint way.
Of course, you can always dive into official documentation for more detailed explanations.

## Summary
+ [Introduction to Jenkins](#intro)
    + [The Pipeline](#pipeline)
        + [Nodes and Distributed CI](#nodes)
        + [The Jenkinsfile](#jenkinsfile)
        + [Plugins](#plugins)
+ [Glossary](#glossary)
+ [Resources](#resources)

<a name="intro" />

## Introduction to Jenkins

Jenkins is a Java-based tool used for providing a self-hosted automation server. 

It is quite useful for CI/CD infrastructures, since it provides the necessary automations for
building and deploying code in a self-owned server.

Since Jenkins is open source software, there are many good reasons to
choose Jenkins over other CI/CD alternatives, such as:
+ Althought it requires from the user the management of their own server, it is a completely free tool.
+ There are plenty of plugins to extend Jenkins functionalities, making it very versatile.
+ The open source model is good for improving overall security.

Let's take a look on some key concepts to understand how to effectively use Jenkins for a CI/CD context...

<a name="pipeline" />

### The Pipeline

The Jenkins Pipeline is the heart of every Jenkins automation. It is basically the automation pipeline 
to be executed itself.

<a name="nodes" />

#### Nodes and Distributed CI

In Jenkin, it is very important to distribute the CI/CD tasks between different computing nodes. You can
assign Jenkins agents (which can be an entire physical computer, a VM, a container, etc.) to execute specific
tasks.

<a name="jenkinsfile" />

#### The Jenkinsfile

The Jenkinsfile is the "as code" definition of the instructions to be executed by a pipeline, usually placed
in the root of the project. It is basically a groovy script describing each **step** (i.e., task) to be executed 
by the CI/CD pipeline. These steps can be conceptually separated in different **stages**.

The Jenkinsfile also enables the definition of which **agent** (i.e., nodes) will run the pipeline or specific stage or step.

Here's an example of a Jenkinsfile, in a kworkflow fork root, which installs kworkflow and prints some content.:

```
pipeline {
    agent any
    stages {
        stage('Install kworkflow'){
            agent {
                label 'kw-installer'
            }
            steps {
                sh './setup.sh --install --force'
            }
        }
        stage('Echo Something'){
            steps {
                echo 'kworkflow has been installed'
                echo 'Now I will print some statements'
            }
        }
    }
}
```

The Jenkinsfile above assings any agents to execute the pipeline. Then it executes the first stage, "Install kworkflow",
which will use exclusively the agents labeled as "kw-installer". This stage has a single step: execute the sh command 
"./setup.sh --install --force".

Then, it reaches the second stage, "Echo Something", which doesn't assign any specific agent, so the agents any from the 
outer scope are applied. It executes two steps, each `echo`ing a different statement.

<a name="plugins" />

#### Plugins

Plugins are one of the most important features of Jenkins. They extend Jenkins functionalities, and this
applies to the Pipeline as well. With plugins, one can, for example, extend the Pipeline Syntax for Jenkinsfile,
and, for example, use a new `junit` command in a step, or define the use of a dynamic `docker` agent in the Pipeline.

<a name="glossary">

## Glossary

+ CI/CD: Continuous Integration and Continuous Delivery, i.e., the automation of the process of developing and
delivering code.
+ Groovy: A dynamic scripting language that can be compiled to bytecode for JVM (Java Virtual Machine). This
enables Groovy to work pretty well with Java applications, such as Jenkins.
+ kworkflow: Open source project for eliminating manual overhead on the context of kernel development.

<a name="resources">

## Resources

+ [Jenkins Handbook](https://www.jenkins.io/doc/book/)

