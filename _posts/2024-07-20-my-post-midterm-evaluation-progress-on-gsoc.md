---
layout: post
title:  "[GSoC] My post midterm evaluation progress on GSoC"
date:   2024-07-20
author: Marcelo Mendes Spessoto Junior
author_website: https://marcelospessoto.github.io/
tags: [jenkins, ci]
---

It has been a while since I've posted about my GSoC project, and a lot has changed about it.  
Since the midterm evaluation period has come to an end very recently, I will take the opportunity
to share how the CI infrastructure is now and my next steps for it.

# Completely migrating kworkflow GitHub Actions CI to Jenkins

The kworkflow project uses GitHub Actions for all its needed automation processes, such as unit and 
integration tests, code coverage analysis, and linting. However, a little bit of Jenkins automation may
help the project with some things.

First of all, it is expected that kworkflow integration tests get an improvement in complexity. In an ideal
scenario, kworkflow will be tested with realistic test cases involving virtual machines (and maybe real 
machines) and coordination between devices (such as image deployment and ssh connections). The GitHub Actions
Ubuntu VM environment will not be enough to handle such situations. It will be necessary to prepare a
self-hosted setup, and Jenkins is the best CI/CD tool for a self-hosted implementation. It is widely used
to this day and it is open source, granting decent community support and flexibility for a tool.

Also, this implementation would enable the kworkflow project to host its own code coverage, not relying on
anymore on codecov. Although codecov has made its source code available recently and also offers a 
self-hosted solution, it is still better to have a kworkflow's own coverage host, since codecov is still
on BSL license (which allows access to code, but is not open source according to OSI definition) on the 
time of this blog post.

The final Jenkins implementation for this stage of development will completely migrate all
GitHub Actions automation to Jenkins. It is expected, however, that the integration test implementation
changes over time. Also, the Jenkins infrastructure may work along existing GitHub Actions workflow,
if the former's implementation brings no benefit over the latter.

## The general architecture of the Jenkins infrastructure

First of all, the Jenkins infrastructure is open source and available as code (by using CaC Jenkins plugins,
such as Jenkins Configuration as Code and Job DSL).

The Jenkins server will be primarily composed of its controller deployed in the official Jenkins docker
container. Alongside the controller, one or more agent containers will be deployed, with docker-compose.
These agents will be launched via SSH and run the Pipelines. Their Dockerfile will also ensure the 
setup of necessary tools for some Pipelines, such as kcov for code coverage or shellcheck for bash linting.
These agent containers will run all tests, except the integration tests. 

For the integration tests, something different must be done, because it will contain testing scenarios
with containers creating other containers (such as ssh integration test). Since the agent containers are being directly
run by the host kernel, one should avoid granting them privileges with the `--privileged` flag or access to the 
container engine socket. For integration tests, this should be an absolute NO, since the 
agent containers would not only get higher privileges to create new containers for the integration tests (in
the kworkflow case, the distros containers) but also run contributors' code (such as `run_tests.sh`, which would
orchestrate the podman containers used for integration tests and could be maliciously modified by anyone). This 
would be a dangerous approach that would highly increase the attack surface for the Jenkins physical server.

The idea to overcome this is to simply follow GitHub's approach when providing their GitHub Actions CI/CD
environment: pack it into a VM. If a Virtual Machine agent is responsible for running the integration tests, 
which will allow containers in container, it won't be dangerous to grant containers higher privileges, since
they will only have access to the VM's kernel, completely isolated from Jenkins's controller and the 
host kernel.

For the other CI/CD automation, there is no need for a VM agent, because the other Pipelines will not
require privilege escalation, and the lightweight approach is sufficient.

Therefore, for the VM agent, Vagrant was the chosen tool to configure a virtualized environment for 
the integration tests. By using a Vagrantfile, one can easily set up the virtual machine setup, which
is very similar to an "as code" approach for providing VMs.

It is expected that the Jenkins CI for kworkflow will have, therefore, a containerized environment for
the majority of testing jobs (unit tests, code coverage, etc.) and a full VM for running integration tests.

## An overview of the current status

The base of the infrastructure is basically completed, for regular tests (excluding integration), but it
needs more polishing. I am also not completely satisfied with the actual container agent implementation (using SSH)
and plan to experiment a little bit more.

It is now time to prepare myself for the most complex job: the integration tests. I can easily replicate its
actual state with a VM agent, but I also need to plan how to adapt it for the upcoming deploy test validation,
which will require an approach similar to kernel-level CI testing.

## The next steps

Having a good base for a CI infrastructure to be applied to the kworkflow project, I plan to improve the 
following:

+ Experiment with Kubernetes plugin: The containerized solution for testing using SSH agents feels safer
than using the Docker plugin to instantiate new containers within the controller container. However, there
may be a more scalable and dynamic way to provide container agents. This may be the case for the Kubernetes
plugin for Jenkins, which deals with using a Kubernetes cluster to dynamically provide new inbound Jenkins
agents. This would be my final study on how to manage container agents.

+ Polish the CI infrastructure repo: Having a setup to install all dependencies required to deploy the
infrastructure would be nice. It is also very important to update its `Readme` and test the infrastructure
on a real environment (i.e. in a real server).

+ Finish replicating the integration tests agent: Ensuring the infrastructure can execute an almost
identical replica of the actual state of integration tests is something to be done soon. I also plan to 
study the (KernelCI Jenkins repository)[https://github.com/kernelci/kernelci-jenkins]. It will certainly
help me prepare to implement the next steps for a CI infrastructure (the interaction with physical agents).

+ Write many blog posts about it: I plan to write tutorial blog posts explaining the different Jenkins 
concepts I have explored so far, aiming to produce more feasible content derived from this more theoretical 
approach to GSoC and also keep a register of everything I've done so far.


