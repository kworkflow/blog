---
layout: post
title: Introduction to Integration Testing in kworkflow
date: 2024-06-26 18:27:23
author: Aquila Macedo
author_website: https://aquilamacedo.github.io/
tags: [kw, gsoc, integration_testing]
---

Integration tests are designed to verify that different modules of a system
work together as expected. They ensure that the interaction between components
occurs seamlessly and that the system functions correctly as a whole.

# Using shUnit2 in Integration Tests??

Originally, [shUnit2](https://github.com/kward/shunit2) was created for unit
testing shell scripts, providing a framework to validate shell functions and
commands in isolation. Its main features include `oneTimeSetUp()` for setup
tasks before running tests, and `oneTimeTearDown()` for actions after all
tests. Methods like `setUp()` and `tearDown()` configure and clean up the
environment before and after each test. Although shUnit2's primary focus is
unit testing (hence the 'Unit' in 'shUnit2'), its flexibility has proven useful
for integration testing as well.

# A Brief Overview

In my Google Summer of Code 2024 (GSoC24) project, as detailed in a [previous
post]({{site.url}}/got-accepted-into-gsoc/), I am developing integration tests
for the kworkflow project. To facilitate this, It was introduced the
`--integration` option in the test script:

```
./run_tests.sh --integration
```

These integration tests run in isolated environments using Podman containers,
each configured with different Linux distributions: **Debian**, **Fedora**,
**Archlinux**. These three were chosen because they cover a lot of what people
use in the Linux world. Debian is very stable and widely used, and many other
distributions are based on it, like **Ubuntu**. This makes Debian a great
choice for testing in environments that are common across many different
setups. Fedora is more about using the latest technology, which helps us test
in newer, more experimental environments. Archlinux is known for always having
the latest versions of software and being very customizable, allowing us to
test in flexible setups. By testing on all three, we ensure our software works
well across a wide range of Linux distributions.

Here’s a closer look at how the process works:

1. **Container Image Building**:  Initially, container images are constructed
   for each supported distribution. These images are built in layers, starting
   with a base layer from **Docker Hub**, which provides the core operating system
   environment. On top of this base layer, additional layers are added to install
   `kw` dependencies and the `kw` itself. This process ensures that all required
   components are available in the container. After building the images, each test
   suite customizes the container environment as needed for specific tests. This
   layered approach allows for efficient and consistent setup of the test
   environments.

2. **Test Execution**: In this step, commands are executed within the
   containers to simulate real user interactions with `kw`, unlike unit tests
   that focus on individual functions. Assertions are then made to verify that
   `kw` performs correctly across various Linux platforms. Each test is run in a
   fresh container environment to ensure a clean state and prevent any
   interference from previous tests.

**Initial Execution Time**: The first execution of these integration tests may
take more than 10 minutes. This delay is due to the time required for Podman to
fetch the base images (if not already cached), build the container images and
install the necessary kworkflow dependencies on each distribution. Subsequent
test runs will be significantly faster because of the caching mechanism that
speeds up the container build process.

Here’s a snippet from the `tests/integration/utils.sh` script illustrating how
containers are started after the images are built:

```bash
# Podman containers are isolated environments designed to run a single
# process. After the process ends, the container is destroyed. In order to
# execute multiple commands in the container, we need to keep the
# container alive, which means that the primary process must not terminate.
# Therefore, we run a never-ending command as the primary process, so that
# we can execute multiple commands (secondary processes) and get the output
# of each of them separately.
container_run \
  --workdir "${working_directory}" \
  --volume "${KWROOT_DIR}":"${working_directory}:Z" \
  --env PATH='/root/.local/bin:/usr/bin' \
  --name "${container_name}" \
  --privileged \
  --detach \
  "${container_img}" sleep infinity > /dev/null

if [[ "$?" -ne 0 ]]; then
  fail "(${LINENO}): Failed to run the container ${container_name}"
fi

# Container images already have kw installed. Install it again, overwriting
# the installation.
container_exec "${container_name}" './setup.sh --install --force --skip-checks --skip-docs > /dev/null 2>&1'

if [[ "$?" -ne 0 ]]; then
  fail "(${LINENO}): Failed to install kw in the container ${container_name}"
else
  distros_ok+=("$distro")
fi

done
```

The `container_run()` function is essential for setting up the test environment
within the Podman container. It ensures that the container remains active,
allowing multiple commands to be executed sequentially. Normally, a Podman
container is designed to run a single process and terminate when that process
ends. However, to perform a series of operations in a single container session,
`container_run()` initiates a never-ending command, such as `sleep infinity`,
as the primary process. This keeps the container alive and ready for further
commands, making it an ideal setup for integration testing.

In this context, the `container_exec()` function is crucial for installing the
kworkflow binary within the container. It ensures that the installation uses
the latest version of the project available in the current execution
environment. This approach guarantees that the tests are performed with the
current state of the repository, i.e., the kw version we wish to test.

Here’s how the `container_exec()` function works:

```bash
# Execute a command within a container.
#
# @container_name       The name or ID of the target container.
# @container_command    The command to be executed within the container.
# @podman_exec_options  Extra parameters for 'podman container exec' like
#                       --workdir, --env, and other supported options.
function container_exec()
{
  local container_name="$1"
  local container_command="$2"
  local podman_exec_options="$3"
  local cmd='podman container exec'

  if [[ -n "$podman_exec_options" ]]; then
    cmd+=" ${podman_exec_options}"
  fi

  # Escape single quotes in the container command
  container_command=$(str_escape_single_quotes "$container_command")

  cmd+=" ${container_name} /bin/bash -c $'${container_command}' 2> /dev/null"

  eval "$cmd"

  if [[ "$?" -ne 0 ]]; then
    complain "$cmd"
    fail "(${LINENO}): Failed to execute the command in the container."
  fi
}
```

This is one of the most crucial functions in the `tests/integration/utils.sh`
file for integration tests. It enables the execution of commands directly
within the test environment container, which is highly useful for managing and
validating operations during the tests.

# Performance Considerations

The `kw build` command is particularly important in this context, as it can be
quite time-consuming, especially when kernel compilation is involved (`kw
build` does much more than just compilation). One solution under consideration
is to run integration tests on just one randomly selected Linux distribution.
Running the same tests across all three supported distributions (**Debian**,
**Fedora**, and **Archlinux**) would significantly increase the overall testing
time.

A future improvement in the CI pipeline could involve identifying which files
were modified in the commits and executing only the relevant integration tests
based on those changes. For instance, if the `src/build.sh` file is altered in a
commit, the CI should trigger the kw build command.

This approach would ensure that integration tests are more efficient, running
only what is necessary based on the specific changes made to the code.

# Conclusion

The integration testing process for kworkflow, as outlined, ensures that kw
functions correctly across different environments. By leveraging Podman
containers and a systematic approach to building and testing, we can achieve
reliable and consistent results, verifying that kworkflow integrates smoothly
with various Linux distributions.
