---
layout: post
title:  "[GSoC][Jenkins] Different Jenkins agent configurations and how I tested them for the kworkflow CI"
date:   2024-07-24
author: Marcelo Mendes Spessoto Junior
author_website: https://marcelospessoto.github.io/
tags: [jenkins, ci, docker, vms]
---

# Studying Jenkins Agents for the kworkflow CI

## Table of Contents
+ [What is a Jenkins agent?](#what)
+ [Static agents vs. Cloud](#vs)
+ [What I've tried so far](#sofar)
    + [The Docker Pipeline Plugin (`docker-workflow`)](#dworkflow)
    + [SSH Agents](#sshagents)
        + [Configuring the controller as code to implement the agents](#cascode)
        + [Deploying the agents](#dagents)
            + [The Docker agent](#dagent)
            + [The VM agent](#vmagent)
    + [The Docker Plugin (`docker-plugin`)](#dplugin)
        + [Configuring Docker as a Cloud provider for kworkflow's Jenkins CI](#cdc)
        + [Preparing the environment](#pte)
        + [Creating the Cloud](#ctc)
+ [The integration tests](#tint)
+ [Final thoughts](#ft)
+ [References](#resources)

During my GSoC project of planning a Jenkins CI for kworkflow, I spent plenty of time experimenting with different possibilities of agent types for the infrastructure.
This post aims to register every attempt of agent implementation so far, their respective implementation guide for a Jenkins server, and my insights about them for the kworkflow context.

## What is a Jenkins agent? <a name="what" />

Jenkins is designed to be a **distributed** automation server, which means that it is best used when the workload is balanced between different computing nodes. These computing nodes are the Jenkins agents and represent
computing environments assigned to execute pipeline steps.

The use of agents to run jobs exclusively is also recommended as a safer approach, as it gives appropriate controller isolation. Let's remember that a build in kworkflow's Jenkins will execute code from contributors, which
may be broken or malicious. Therefore, one should avoid exposing the controller node directly to such code and disable the controller's built-in node.

## Static agents vs. Cloud <a name="vs" />

In Jenkins, there are two primary ways to provide agents: You can either configure and launch them statically, by configuring your own containers and VMs and accessing them via (outbound) SSH connections or 
(inbound) TCP connections, or dynamically provide them through a Cloud service, such as Amazon EC2 instances, Kubernetes Pods, etc.

## What I've tried so far <a name="sofar" />

### The Docker Pipeline Plugin (`docker-workflow`) <a name="dworkflow" />

My first attempt at configuring an agent for Jenkins was by using the Docker Pipeline Plugin. It allows one to define in the **jenkinsfile** the Docker image that will be run for a specific pipeline/stage and
dynamically use it in the pipeline when required.

It is pretty simple to use. You just have to install the plugin for your Jenkins server and write a jenkinsfile invoking the dynamic docker container. You can pull a container image from the docker hub
defining 

```
agent {
    docker { image 'chosen-image' }
}
```

or even using a custom Dockerfile from the root of the project with

```
agent {
    dockerfile true 
}
```

but notice you need to define a SCM for your Pipeline or use a Multibranch Pipeline to use the custom Dockerfile since it needs a repository to get the Dockerfile from.
[There is full documentation on how to define docker agents from the pipeline with the `docker-workflow` plugin with docker and dockerfile agent options](https://www.jenkins.io/doc/book/pipeline/syntax/#agent).
If you are using this plugin for a Jenkins in Docker, remember that you must mount the host docker socket on it (Or run the jenkins container with `--privileged`, but don't do that!), and the Jenkins process must
have permissions to write on the socket.

It was a very easy and simple approach, but I am afraid it wouldn't work well with the kworkflow project. Look below at a [previously defined jenkinsfile from my kworkflow branch](https://github.com/MarceloSpessoto/kworkflow/commit/9ff5c4c408fb2fb1981c3c5138d592cbbd060a82).


```
agent { 
    dockerfile {
        filename 'Dockerfile'
        args '--privileged=true'
    }  
}
```

When trying to check if I could run kworkflow's integration tests (which requires creating new containers) with this plugin, I attempted to run the agent with the `--privileged` option, a fix that allows Docker in Docker (DinD).
A very cursed and forbidden fix, that allows a container to have control over the host kernel.

When it actually worked, I noticed that it wasn't very good news actually. Since this Jenkins CI will be used in an open source software context, exposing to every unknown contributor the ability to modify the jenkinsfiles
with this plugin active in the Jenkins server would represent a great attack surface for the server host system. Even after noticing that the integration tests should not be run in a container, but in a more isolated VM agent,
one could still modify the jenkinsfiles from other tests, such as code coverage and unit tests, and grant to the container agent the `--privileged` attribute.

The simplicity provided by this plugin is great, but it doesn't feel good for kworkflow case. It should restrict the ability to define the container agents only to trusted maintainers granted the Jenkins server administration.
So it felt wiser to not have this plugin installed on the server, disabling the possibility of defining the agents from the public Pipeline script.

### SSH agents <a name="sshagents" />

The second option I've tried is to implement static SSH agents to evaluate CI tests, i.e., configure static VMs/containers to act as agents and evaluate CI/CD Pipelines.

First of all, you need to install the [SSH Build Agents Plugin](https://plugins.jenkins.io/ssh-slaves/) and then configure your nodes. In order to be considered a valid agent, a node must:
1. have Java properly installed;
2. have a user named "jenkins"

The [docker-ssh-agent container](https://github.com/jenkinsci/docker-ssh-agent) already fills these requirements and
is very recommended for container SSH agents. For other types of nodes, such as a VM, you will have to ensure it 
yourself.

And then, to make it work with the controller node, one must:
1. configure an SSH connection method for the controller to execute the jobs on the agent. This can be done by giving the agent a public
SSH key and storing the private key on Jenkins controller as a credential.
2. Set in the controller node the directory where the job will be executed.

#### Configuring the controller as code to implement the agents <a name="cascode" />

The configuration steps above can be automated with Jenkins as Code. For the kworkflow CI, I've done the following:

```
credentials:
  [...]
  system:
    domainCredentials:
    - credentials:
      [...]
      - basicSSHUserPrivateKey:
        description: "Credentials for Docker SSH Agent"
        id: "docker-agent"
        username: "jenkins"
        passphrase: "${SSH_DOCKER_PASSWORD}"
        privateKeySource:
          directEntry:
            privateKey: "${file:/usr/local/configuration/secrets/container_key}"
      - basicSSHUserPrivateKey:
        description: "Credentials for VM Agent"
        id: "vm-agent"
        username: "jenkins"
        passphrase: "${SSH_VM_PASSWORD}"
        privateKeySource:
          directEntry:
            privateKey: "${file:/usr/local/configuration/secrets/vm_key}"
```

The configuration above configures two credentials for SSH connections. These are credentials for SSH for
storing an user, its password and its SSH private key required to connect to the node with SSH.

The Jenkins configuration as Code plugin allows one to pass sensitive information to the config yaml by
using environment variables and also by files (using `${file:/var/key}` will be translated to the content of
/var/key).

There are two configured credentials in the example above. One for the Docker agent and the other for the
VM agent.

There is also the proper configuration of each agent to be done:

```
jenkins:
  [...]
  nodes:
    - permanent:
        labelString: "docker-agent"
        name: "docker-agent"
        remoteFS: "/home/jenkins/agent"
        launcher:
          ssh:
            credentialsId: docker-agent
            host: localhost
            port: DOCKER_AGENT_PORT
            sshHostKeyVerificationStrategy: "nonVerifyingKeyVerificationStrategy"
    - permanent:
        labelString: "vm-agent"
        name: "vm-agent"
        remoteFS: "/var/lib/jenkins"
        launcher: 
          ssh:
            credentialsId: vm-agent
            host: localhost
            port: VM_AGENT_PORT
            sshHostKeyVerificationStrategy: "nonVerifyingKeyVerificationStrategy"
```

Just configure the agent label, its name, the directory where jobs will be run, and the configuration for
the launch method (in this case, an SSH agent, with the SSH credential to be used (we defined in the 
previous code block), the host, port, and SSH verification strategy).

You can get a fully detailed explanation of how to configure an SSH agent on the [Plugin official documentation](https://github.com/jenkinsci/ssh-agents-plugin/blob/main/doc/CONFIGURE.md).

#### Deploying the agents <a name="dagents" />

##### The Docker agent <a name="dagent" />

After configuring the controller properly, the last step was to deploy the static agents. For the Docker agent, I've added an extra field in the `docker-compose.yml` to include the agent service. The jenkins service image is
an extended Dockerfile `FROM jenkins/ssh-agent:latest`. It configured the environment for the kworkflow needs (such as configuring
the kcov software for code coverage tests, etc.) and also set a custom SSH port using the `sed` command. 

To pass the custom port from the host to the container, I've passed it to docker-compose.yml as an `ARG`, and in the
Dockerfile I've passed the port `ARG` to an environment variable with `ENV`. The differences between Docker `ARG`s and `ENV`s can be seen in [this nice post](https://vsupalov.com/docker-arg-env-variable-guide/).

With the jenkins/ssh-agent, the public ssh key can be easily configured by just setting the "JENKINS_AGENT_SSH_PUBKEY" env var, something I've done 
on the docker-compose script.

The docker agent worked pretty well, but I didn't like the results. The complete absence of scalability is a big reason.
But there were more problems. Many kworkflow jobs I would assign to the container require `sudo` privileged commands, such as `apt install` to test dependencies' installation.
If passwordless `sudo` was given to `jenkins` user in the Docker agent, it would be easy to mess with the container itself, making it vulnerable to breaking easily and needing manual maintenance.
One could also enable `sudo` to selected commands, but it would require manual changes if some new command was needed. It would be much better to enable `sudo` in ephemeral and dynamically provided 
container agents.

##### The VM agent <a name="vmagent" />

To automate the deployment of a VM agent, I've used Vagrant.
I've created a very simple Vagrantfile configuring the Java installation, creating of `jenkins` user, creating a directory for job execution, and injecting the SSH public key. This can be done with [Vagrant provisioning]
(https://developer.hashicorp.com/vagrant/docs/provisioning). You can provision the VM with an automation tool like Ansible, Chief, or Puppet. The basic shell provisioning was enough for my case.

To ensure the jenkins controller would be able to connect to the VM, I had to change the docker-compose network_mode to "host".
Since docker-compose isolates its orchestrated containers in its network from the docker interface, it was necessary
to change the network_mode to "host" so the container would have the host IP address and share its ports with the host.

I've also changed my Vagrant provider from libvirt to VirtualBox, because the former was presenting networking problems. For production, it is very likely that I will change to VMWare.

The VM agent has the same flaws as the Docker static SSH agent, but, since the integration tests from kworkflow
require a more isolated and less used environment, it will be enough for now. I am still trying to figure out a way
to provide a VM agent cloud that is not proprietary and can be self-owned.

### The Docker Plugin (`docker-plugin`) <a name="dplugin" />

After trying both Docker Pipeline Plugin and Docker SSH agents and not being satisfied with both, I've considered trying a Cloud for Jenkins with the Kubernetes plugin. It would be much more complex and difficult to handle, but it
would be safer than defining containers directly from the pipeline with Docker Pipeline and much more scalable and easier to maintain than static Docker SSH agents.

It would be a long path to follow and an overkill solution for the kworkflow, that doesn't contain such a high amount of PRs being opened and could benefit from something simpler. Gladly, I've found out that I've been misled by
the confusing Docker plugins: there are actually two different Docker Plugins. 

I've installed both `docker-workspace` and `docker-plugin` before, but I thought that the latter complemented the former as a solution for Pipeline Syntax for Docker usage. Turns out that the `docker-plugin` has a completely
different purpose: Allow a Docker Host API to be used as a Cloud provider for the Jenkins server. It would do exactly what I was looking for that entire time, but avoid the necessity of configuring a super complex Kubernetes
cluster or relying on a proprietary Cloud provider.

With the `docker-plugin`, it is possible to set up the Jenkins controller to communicate with a Docker Host API as a Cloud and then using dynamically provided Docker agents from this Cloud to evaluate Jobs.

#### Configuring Docker as Cloud provider for kworkflow's Jenkins CI <a name="cdc" />

Here's a basic usage of the plugin. It is very simple and straightforward to configure.

##### Preparing the environment <a name="pte" />

Since the Jenkins server for kworkflow will be run inside a Docker container communicating with the Docker Host API from the host, mounting the docker socket on the container and being sure that Jenkins can write on it
is enough to prepare the environment for my problem.

With this Jenkins plugin, it is also possible to connect to a remote Docker Host API by configuring an open TCP port for the Docker Host API. On the docker host, just go to `lib/systemd/system/docker.service`, edit the `ExecStart` config
with `ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:[PORT] -H unix:///var/run/docker.sock`, restart the Docker Daemon and ensure the Jenkins server can connect to the device on the port.

##### Creating the Cloud <a name="ctc" />

On Jenkins Controller Web Interface, create a Cloud. Ensure the Docker plugin is installed so you can check
the Cloud option to be "Docker".

![Image]({{site.url}}/images/jenkins-agents/Create_Cloud.png)

Proceed and configure the Cloud.

There are two important fields here:
+ "Docker Cloud details": here you will configure how the Jenkins server will communicate with the Docker Host API.
In the "Docker Host URI", fill it with the mounted socket path/address of the remote Docker Host. Test Connection to ensure if Jenkins can use the Docker Cloud you've set.
+ "Docker Agent templates": Here you can define multiple docker templates to be provided by the Docker Cloud. 
For each template you wish to define, the following steps are important:
    + Labels: define the labels that can identify the template. This means that if a template has the label "hello-world",
    the Cloud can provide a container agent with this template whenever a Pipeline script requires an agent with the label "hello-world". (`agent {label 'hello-world'}`).
    + Docker Image: The docker image that the container template will be built from. It must be the hash, tag, or name of an image built in the Docker Host.
    + Connect method: if the controller will connect with the container with SSH, JNLP, or just attach the container.

Configure the Cloud and save it.
Run a basic Pipeline invoking a template with its label and validate.

This is, in my opinion, the best possible implementation of Docker agents for the kworkflow. I am finally satisfied with it
and will now move on to the integration tests.

## The integration tests <a name="tint" />

The integration tests from kworkflow, in their actual state, require the creation of new containers. From what has been previously
discussed in this post, it can be noticed that container agents won't offer a proper and safe solution for this specific use case.

Because of that, a Virtual Machine SSH agent will provide the necessary isolation for this scenario. Of course, there will be 
even more expected complexity, since it is desired that the integration tests will be able to handle more sophisticated cases,
such as deployment tests on VMs and even physical devices. But, for now, the actual state of the integration tests can be replicated
with a simple VM running the test. 

The other tests can take advantage of a more lightweight Docker container environment provided by the Docker Cloud.

## Final thoughts <a name="ft" />

After studying many different Jenkins plugins and how kworkflow can benefit from each one, I've come to the decision that the best
solution is to provide a Jenkins Cloud using Docker for the basic workflows (code coverage, unit tests, etc.) and a VM agent for the 
integration tests.

After finishing and polishing the Jenkins as Code infrastructure I'm providing, and ensuring it can offer these functionalities on a real server, I will be keeping track of
the development status of the integration steps and actively plan with the maintainers and contributors of kworkflow the implementation of the most sophisticated tests, such as
the `deploy` feature testing. It probably be an even more theoretical and study-focused phase of this GSoC project of mine, and I hope to keep, from now on, constantly updating the 
progress and accumulated insights on this blog.


## References <a name="resources" />

[Controller isolation page from Jenkins](https://www.jenkins.io/doc/book/security/controller-isolation/)  
[Docker agent definition from the pipeline](https://www.jenkins.io/doc/book/pipeline/docker/)  
[Pipeline Syntax for agents](https://www.jenkins.io/doc/book/pipeline/syntax/#agent)    
[SSH Build Agents Plugin](https://plugins.jenkins.io/ssh-slaves/)   
[docker-ssh-agent container](https://github.com/jenkinsci/docker-ssh-agent)   
