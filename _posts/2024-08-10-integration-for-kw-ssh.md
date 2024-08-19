---
layout: post
title: Integration Testing for kw ssh
date: 2024-07-30 10:30:00
author: Aquila Macedo
author_website: https://aquilamacedo.github.io/
tags: [kw, gsoc, integration_testing, kw-ssh]
---

`kw-ssh` is a feature in kworkflow that simplifies remote access to machines
via SSH. It allows you to execute commands or bash scripts on a remote machine
easily. Additionally, this feature supports file and directory transfer between
local and remote machines.

This post aims to show what happens behind the scenes in testing a typical `kw`
feature. It provides a clear view of the challenges and solutions involved in
the integration process, helping to understand how `kw ssh` and similar
features are tested and refined.

# Overview of kw-ssh Testing Architecture 

![Picture](/images/kw-ssh-illustration.png)

This image illustrates the structure of the integration tests for the `kw-ssh`
feature, using containers to simulate different operating system environments.
This setup involves one container acting as the test environment, within which
tests are executed across three Linux distributions: **Debian**, **Fedora**,
and **Archlinux**.

Within this test environment, there is a second container, represented in the
image as "nested" which hosts the SSH server needed for the tests. This
configuration allows for the isolation of the test environment and execution of
`kw-ssh` commands on a simulated SSH server, without affecting the local system
or other containers.

By using containers for each Linux environment and for the SSH server, we
ensure that tests are conducted in controlled environments, avoiding
contamination between tests and maintaining result consistency. This approach
allows the functionality of `kw-ssh` to be validated across different
distributions, ensuring the code performs as expected on various platforms.

# Details of the Testing Environment

Inside the container that serves as the test environment, I copy a file from
the host machine, which is the `Containerfile` responsible for generating the
container with the SSH server. This SSH container is essential for enabling
connection tests using `kw-ssh`, ensuring that the authentication and transfer
processes work correctly.

```bash
# This Containerfile sets up a Debian-based container with an SSH server. The
# purpose of this container is to test SSH connections using the kw ssh tool.
# It installs necessary packages, configures the SSH server, and sets up root
# login with a pre-defined password and SSH public key authentication.

# Start with the Debian image
FROM debian:latest

# Install necessary packages
RUN apt-get update && \
    apt-get install -y openssh-server iptables rsync && \
    mkdir -p /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Copy SSH public key and set permissions
COPY id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

# Expose the SSH port
EXPOSE 22

# Start the SSH service
CMD ["/usr/sbin/sshd", "-D"]
```

# Challenges with Nested Containers

When creating containers within containers, executing commands directly from
the host machine to the nested container becomes a challenge. To address this
complexity, I developed the `container_exec_in_nested_container()` function,
which facilitates command execution within this nested environment.

```bash
# Function to execute a command within a container that is itself running
# inside another container.
#
#  @outer_container_name     The name or ID of the outer container.
#  @inner_container_name     The name or ID of the inner container.
#  @inner_container_command  The command to be executed within the inner container.
#  @podman_exec_options      Extra parameters for 'podman container exec' like
#                            --workdir, --env, and other supported options.
function container_exec_in_nested_container()
{
  local outer_container_name="$1"
  local inner_container_name="$2"
  local inner_container_command="$3"
  local podman_exec_options="$4"
  local cmd='podman container exec'

  if [[ -n "$podman_exec_options" ]]; then
    cmd+=" ${podman_exec_options}"
  fi

  inner_container_command=$(str_escape_single_quotes "$inner_container_command")
  cmd+=" ${inner_container_name} /bin/bash -c $'${inner_container_command}'"

  output=$(container_exec "$outer_container_name" "$cmd")

  if [[ "$?" -ne 0 ]]; then
    fail "(${LINENO}): failed to execute the command in the container."
  fi

  printf '%s\n' "$output"
}
```

This function facilitates the execution of commands in a nested container
within another container, which is common in kw-ssh integration tests. It uses
the `container_exec()` function, which executes commands directly in a
container. One of the challenges when passing commands to containers is
handling special characters, such as single quotes, which, in Bash, can cause a
lot of obscure issues during execution. To address this, I used the
`str_escape_single_quotes()` function, which correctly escapes these
characters, ensuring that commands are executed reliably.

# Managing Commands in Nested Containers

The `str_escape_single_quotes()` function uses the **sed** command to add
backslashes `(\)` before any single quotes found in the string, allowing
commands containing single quotes to be interpreted correctly by the shell:

```bash
# Escape (i.e. adds a '\' before) all single quotes. This is useful when we want
# to make sure that a single quote `'` is interpreted as a literal in character
# sequences like $'<string>'. For reference, see section 3.1.2.4 of
# https://www.gnu.org/software/bash/manual/bash.html#Shell-Syntax.
#
# @string: String to be processed
#
# Return:
# Returns the string with all single quotes escaped, if any, or 22 (EINVAL) if
# the string is empty.
function str_escape_single_quotes()
{
  local string="$1"

  [[ -z "$string" ]] && return 22 # EINVAL

  printf '%s' "$string" | sed "s/'/\\\'/g"
}
```


Additionally, in the `container_exec_in_nested_container()` function, I use the
Special `$''` format for strings, known as [ANSI C
Quoting](https://www.gnu.org/software/bash/manual/bash.html#ANSI_002dC-Quoting).
This format allows escape sequences such as `\'` (escaped single quotes) to be
processed correctly by the shell. The use of `$''` is essential here to ensure
that commands are interpreted correctly, even when they contain characters that
would otherwise need to be escaped. This prevents errors when running tests.

Here's an example of how this approach is implemented:


```bash
cmd+=" ${inner_container_name} /bin/bash -c $'${inner_container_command}'"
```
By using `$''`, the string passed to the container can contain special
characters without causing problems at runtime. This is especially important
when working with nested containers, where proper string handling is critical
to the success of integration tests.


# Integration Test Example with kw-ssh

```bash
# This function tests the SSH connection functionality using a remote global
# configuration file. It ensures that the 'kw ssh' command can establish a
# connection to an SSH server and execute a command.
function test_kw_ssh_connection_remote_global_config_file()
{
  local expected_output='Connection successful'
  local ssh_container_ip_address
  local distro
  local container
  local output

  for distro in "${DISTROS[@]}"; do
    container="kw-${distro}"
    # Get the IP address of the ssh container
    ssh_container_ip_address=$(container_exec_in_nested_container "$container" "$SSH_CONTAINER_NAME" 'hostname --all-ip-addresses' | xargs)

    # Update the global config file with the correct IP address of the SSH server
    container_exec "$container" "sed --in-place \"s/localhost/${ssh_container_ip_address}/\" ${KW_GLOBAL_CONFIG_FILE}"
    output=$(container_exec "$container" 'kw ssh --command "echo Connection successful"')
    assert_equals_helper "kw ssh connection failed for ${distro}" "$LINENO" "$expected_output" "$output"
  done
}
```

This test example verifies the SSH connection of `kw ssh` using the remote
connections configuration file. Typically, this file can be found at
*~/.config/kw/remote.config*. This test illustrates how the
`container_exec_in_nested_container()` function is used to manage command
execution in nested containers and how the test is conducted across different
Linux distributions.

# Conclusion

Integration tests for kw-ssh ensure that the feature works correctly across
different Linux distributions. With the isolation of test environments from
containers in conjunction with an SSH server, we achieve precise and consistent
validation. The functions developed to manage nested containers and handle
special characters ensure that commands are executed without issues.

This approach provides confidence in the functionality of `kw-ssh`, ensuring it
performs as expected in various scenarios.
