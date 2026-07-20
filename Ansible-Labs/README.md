# Ansible Hands-On Learning Labs

A practical collection of Ansible labs covering variables, package and service management, loops, templates, handlers, roles, tags, idempotency, troubleshooting, and reusable automation structure.

These labs were completed on AWS using:

- One Ansible control node
- Two Ubuntu worker nodes
- SSH key-based authentication
- Infrastructure provisioned with Terraform
- Ansible Core installed on the control node

The purpose of this repository is to document my progression from basic Ansible playbooks to production-style role-based automation.

> This repository contains learning labs. A separate final Ansible project will combine these concepts with AWS dynamic inventory, Ansible Vault, Galaxy collections, Terraform, and a more production-focused architecture.

---

# Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Repository Structure](#repository-structure)
4. [How Ansible Works](#how-ansible-works)
5. [Ansible Control Flow](#ansible-control-flow)
6. [Lab 3 — Variables and Idempotency](#lab-3--variables-and-idempotency)
7. [Lab 4 — Loops, Linux Patching, and Docker](#lab-4--loops-linux-patching-and-docker)
8. [Lab 5 — Jinja2 Templates and Handlers](#lab-5--jinja2-templates-and-handlers)
9. [Lab 6 — Production-Style Ansible Roles](#lab-6--production-style-ansible-roles)
10. [Lab 7 — Tags and Selective Execution](#lab-7--tags-and-selective-execution)
11. [Lab 8 — Concepts Moved to Final Project](#lab-8--concepts-moved-to-final-project)
12. [Variable Precedence and Role Defaults](#variable-precedence-and-role-defaults)
13. [Idempotency](#idempotency)
14. [Handlers and Notifications](#handlers-and-notifications)
15. [Manual Verification](#manual-verification)
16. [Troubleshooting](#troubleshooting)
17. [Security Considerations](#security-considerations)
18. [GitHub Preparation](#github-preparation)
19. [Skills Practiced](#skills-practiced)
20. [Next Project](#next-project)

---

# Project Overview

Ansible is a configuration-management and automation tool.

Terraform and Ansible solve different problems:

```text
Terraform
    |
    | Provisions infrastructure
    v
VPC, subnets, security groups, EC2 instances and key pairs
    |
    v
Ansible
    |
    | Configures the operating systems
    v
Packages, users, files, services, Docker and Nginx
```

Terraform answers:

> What infrastructure should exist?

Ansible answers:

> How should the operating systems and applications be configured?

In these labs, Terraform created the AWS infrastructure, while Ansible configured the worker nodes.

---

# Architecture

```text
                         AWS VPC
+-----------------------------------------------------------+
|                                                           |
|   +----------------------+                                |
|   | Ansible Control Node |                                |
|   | Ubuntu EC2           |                                |
|   |                      |                                |
|   | - ansible-core       |                                |
|   | - inventory.ini      |                                |
|   | - ansible.cfg        |                                |
|   | - playbooks          |                                |
|   | - SSH private key    |                                |
|   +----------+-----------+                                |
|              |                                            |
|              | SSH                                        |
|       +------+----------------------+                     |
|       |                             |                     |
|       v                             v                     |
|   +----------------+          +----------------+          |
|   | Worker 1       |          | Worker 2       |          |
|   | Ubuntu EC2     |          | Ubuntu EC2     |          |
|   |                |          |                |          |
|   | Docker         |          | Docker         |          |
|   | Nginx          |          | Nginx          |          |
|   | Linux packages |          | Linux packages |          |
|   +----------------+          +----------------+          |
|                                                           |
+-----------------------------------------------------------+
```

The control node does not normally install the applications for itself.

Instead, it:

1. Reads the playbook.
2. Loads the inventory.
3. Loads variables.
4. Connects to the workers over SSH.
5. Transfers temporary Ansible modules.
6. Executes the requested tasks.
7. Reports the result.
8. Removes temporary files.

---

# Repository Structure

```text
Ansible-Labs/
├── .gitignore
├── README.md
├── lab3-variables/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── playbook.yml
│   └── vars.yml
├── lab4-loops/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── playbook.yml
│   └── vars.yml
├── lab5-templates/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── playbook.yml
│   ├── vars.yml
│   └── templates/
│       └── index.html.j2
└── lab6-roles/
    ├── ansible.cfg
    ├── inventory.ini
    ├── playbook.yml
    └── roles/
        ├── common/
        │   ├── defaults/
        │   │   └── main.yml
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── handlers/
        │   │   └── main.yml
        │   ├── templates/
        │   ├── files/
        │   ├── vars/
        │   │   └── main.yml
        │   ├── meta/
        │   │   └── main.yml
        │   └── tests/
        ├── docker/
        │   ├── defaults/
        │   │   └── main.yml
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── handlers/
        │   │   └── main.yml
        │   ├── templates/
        │   ├── files/
        │   ├── vars/
        │   │   └── main.yml
        │   ├── meta/
        │   │   └── main.yml
        │   └── tests/
        └── nginx/
            ├── defaults/
            │   └── main.yml
            ├── tasks/
            │   └── main.yml
            ├── handlers/
            │   └── main.yml
            ├── templates/
            │   └── index.html.j2
            ├── files/
            ├── vars/
            │   └── main.yml
            ├── meta/
            │   └── main.yml
            └── tests/
```

---

# How Ansible Works

The core Ansible workflow is:

```text
ansible-playbook playbook.yml
        |
        v
Read ansible.cfg
        |
        v
Read inventory.ini
        |
        v
Identify target group
        |
        v
Connect to each host with SSH
        |
        v
Gather facts about each host
        |
        v
Load variables
        |
        v
Run tasks in order
        |
        v
Run notified handlers
        |
        v
Display play recap
```

## What `ansible.cfg` does

The configuration file defines Ansible behavior.

Example:

```ini
[defaults]
inventory = inventory.ini
remote_user = ubuntu
host_key_checking = False
private_key_file = /home/ubuntu/ansible-lab-key.pem
```

This tells Ansible:

- Use `inventory.ini`.
- Connect as `ubuntu`.
- Use the specified SSH key.
- Disable interactive host-key confirmation for the lab.

The private-key path is specific to the lab environment and should not be committed if it exposes local or sensitive configuration.

---

## What `inventory.ini` does

The inventory defines the managed servers.

Example:

```ini
[workers]
worker1 ansible_host=10.50.1.219
worker2 ansible_host=10.50.2.153
```

The group is:

```text
workers
```

The host aliases are:

```text
worker1
worker2
```

The actual addresses are supplied by:

```text
ansible_host
```

A playbook can target the entire group:

```yaml
hosts: workers
```

Ansible then executes the play against both servers.

For a public GitHub repository, real ephemeral addresses should be replaced with safe examples:

```ini
[workers]
worker1 ansible_host=10.0.1.10
worker2 ansible_host=10.0.2.10
```

---

## What `become: true` does

Many Linux tasks require root privileges.

Examples include:

- Installing packages
- Modifying `/etc`
- Managing services
- Writing to `/var/www/html`
- Creating system users
- Changing file ownership

The playbook uses:

```yaml
become: true
```

This tells Ansible to use privilege escalation, normally through `sudo`.

It is similar to running:

```bash
sudo apt install nginx
```

but Ansible manages the operation declaratively.

---

# Ansible Control Flow

Consider this playbook:

```yaml
---
- name: Configure Linux workers
  hosts: workers
  become: true

  vars_files:
    - vars.yml

  tasks:
    - name: Install package
      ansible.builtin.apt:
        name: "{{ package_name }}"
        state: "{{ package_state }}"
```

Ansible processes it as follows:

```text
1. Read playbook.yml
2. Find the workers group
3. Read inventory.ini
4. Resolve worker1 and worker2
5. Connect to both servers through SSH
6. Gather system facts
7. Load vars.yml
8. Find package_name
9. Find package_state
10. Execute the apt module
11. Compare current and desired states
12. Make a change only if required
13. Report ok, changed, failed or unreachable
```

Possible task results include:

```text
ok
changed
failed
unreachable
skipped
rescued
ignored
```

### `ok`

The system already matches the desired state.

### `changed`

Ansible modified something.

### `failed`

The task executed but was unsuccessful.

### `unreachable`

Ansible could not establish the required connection.

### `skipped`

The task was skipped because a condition or tag excluded it.

---

# Lab 3 — Variables and Idempotency

## Objective

Lab 3 introduced:

- Playbook variables
- External variable files
- `vars_files`
- Package management
- Service state management
- Idempotency
- Configuration drift

The main goal was to separate configuration data from automation logic.

---

## Why variables matter

A hard-coded task might look like:

```yaml
- name: Install Nginx
  ansible.builtin.apt:
    name: nginx
    state: present
```

This works, but the package and state are embedded in the task.

A variable-based version looks like:

```yaml
- name: Install package
  ansible.builtin.apt:
    name: "{{ package_name }}"
    state: "{{ package_state }}"
```

The task contains the logic:

> Manage a package.

The variable file contains the configuration:

> The package should be Nginx and it should be present.

---

## Example `vars.yml`

```yaml
---
package_name: nginx
package_state: present

service_name: nginx
service_state: started
service_enabled: true
```

---

## Example playbook

```yaml
---
- name: Lab 3 - Variables and Idempotency
  hosts: workers
  become: true

  vars_files:
    - vars.yml

  tasks:
    - name: Install required package
      ansible.builtin.apt:
        name: "{{ package_name }}"
        state: "{{ package_state }}"
        update_cache: true

    - name: Ensure service is running and enabled
      ansible.builtin.service:
        name: "{{ service_name }}"
        state: "{{ service_state }}"
        enabled: "{{ service_enabled }}"
```

---

## Variable-loading flow

```text
playbook.yml
    |
    | vars_files:
    |   - vars.yml
    v
vars.yml
    |
    | package_name: nginx
    | package_state: present
    v
Task
    |
    | name: "{{ package_name }}"
    | state: "{{ package_state }}"
    v
Rendered task
    |
    | name: nginx
    | state: present
    v
APT module checks the worker
```

The value:

```yaml
package_name: nginx
```

replaces:

```jinja2
{{ package_name }}
```

before the module is executed.

---

## Package state versus service state

These are separate concepts.

### Package state

```yaml
package_state: present
```

This means:

> The Nginx software must be installed.

### Service state

```yaml
service_state: started
```

This means:

> The Nginx process must be running.

A package can be installed while its service is stopped.

For example:

```text
nginx package: installed
nginx service: stopped
```

Ansible can manage both conditions independently.

---

## Configuration drift test

To demonstrate drift, a service can be manually stopped:

```bash
sudo systemctl stop nginx
```

The server now differs from the desired state.

Desired state:

```yaml
service_state: started
```

Current state:

```text
stopped
```

Running the playbook again causes Ansible to correct the drift:

```text
Current state: stopped
Desired state: started
Action: start service
Result: changed
```

Running the playbook again without another manual change produces:

```text
Current state: started
Desired state: started
Action: none
Result: ok
```

This is idempotency.

---

# Lab 4 — Loops, Linux Patching, and Docker

## Objective

Lab 4 introduced:

- Updating the APT cache
- Upgrading installed packages
- Installing multiple packages
- Loops
- Removing unused dependencies
- Installing Docker
- Managing the Docker service
- Manual Docker verification

---

## Example variables

```yaml
---
packages:
  - git
  - curl
  - unzip
  - vim
  - htop
  - docker.io

package_state: present

docker_service_name: docker
docker_service_state: started
docker_service_enabled: true
```

---

## Example playbook

```yaml
---
- name: Lab 4 - Loops and Linux Patching
  hosts: workers
  become: true

  vars_files:
    - vars.yml

  tasks:
    - name: Update apt package cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Upgrade installed packages
      ansible.builtin.apt:
        upgrade: dist

    - name: Install required packages
      ansible.builtin.apt:
        name: "{{ item }}"
        state: "{{ package_state }}"
      loop: "{{ packages }}"

    - name: Remove unused packages
      ansible.builtin.apt:
        autoremove: true

    - name: Ensure Docker service is running and enabled
      ansible.builtin.service:
        name: "{{ docker_service_name }}"
        state: "{{ docker_service_state }}"
        enabled: "{{ docker_service_enabled }}"
```

---

## Loop execution flow

The variable file contains a list:

```yaml
packages:
  - git
  - curl
  - unzip
```

The task uses:

```yaml
name: "{{ item }}"
loop: "{{ packages }}"
```

Ansible processes it like this:

```text
packages list
    |
    v
Iteration 1
item = git
Install git
    |
    v
Iteration 2
item = curl
Install curl
    |
    v
Iteration 3
item = unzip
Install unzip
```

`item` is automatically assigned by Ansible during each loop iteration.

The task is conceptually expanded into:

```yaml
- install git
- install curl
- install unzip
```

without duplicating the task definition.

---

## List directly versus loop

The APT module can also receive a complete list:

```yaml
- name: Install packages
  ansible.builtin.apt:
    name: "{{ packages }}"
    state: present
```

This is often cleaner and can be more efficient because APT handles the list in one operation.

A loop is still useful when:

- Each item needs separate processing.
- The module does not support lists.
- Different conditions are needed per item.
- The output for each item matters.
- Each item is a structured dictionary.

Example structured loop:

```yaml
users:
  - name: developer
    group: docker
  - name: monitoring
    group: adm
```

```yaml
- name: Create users
  ansible.builtin.user:
    name: "{{ item.name }}"
    groups: "{{ item.group }}"
  loop: "{{ users }}"
```

---

## Docker verification

The Docker service was checked with:

```bash
systemctl status docker
```

Docker installation was checked with:

```bash
docker --version
```

Initially, the regular user received a Docker socket permission error:

```text
permission denied while trying to connect to the Docker daemon socket
```

This happened because Docker communicates through:

```text
/var/run/docker.sock
```

and the regular user was not yet a member of the `docker` group.

Using:

```bash
sudo docker ps
```

worked because root had access.

A later role corrected this by adding the Ubuntu user to the Docker group.

---

## Container verification

An interactive Ubuntu container was started:

```bash
sudo docker run -it ubuntu bash
```

Inside the container:

```bash
whoami
pwd
```

Expected output:

```text
root
/
```

An Nginx container was then launched:

```bash
sudo docker run -d \
  --name web \
  -p 8080:80 \
  nginx
```

The port mapping means:

```text
Worker port 8080
        |
        v
Container port 80
```

The page was accessed through:

```text
http://WORKER_PUBLIC_IP:8080
```

This verified the complete chain:

```text
Ansible installs Docker
        |
        v
Docker service starts
        |
        v
Docker pulls Nginx image
        |
        v
Container starts
        |
        v
Port 8080 maps to container port 80
        |
        v
Browser reaches Nginx
```

---

# Lab 5 — Jinja2 Templates and Handlers

## Objective

Lab 5 introduced:

- Jinja2 templates
- The Ansible `template` module
- Dynamic file generation
- Notifications
- Handlers
- Conditional service restarts
- Host-specific file rendering

---

## Variables

Example `vars.yml`:

```yaml
---
page_title: "Syed's Production Nginx"
welcome_message: "Managed by Ansible"
server_name: "AWS Worker Node"
lab_environment: "Development Lab"
owner: "Syed Aftab - Cloud Engineer"
company: "Cloud Engineering Lab"
footer: "Lab 5 - Templates & Handlers"
```

An important lesson was avoiding reserved keywords and invalid variable names.

### Reserved name problem

Using:

```yaml
environment: "Development"
```

generated an Ansible warning because `environment` has a special meaning in Ansible.

A clearer variable was used:

```yaml
lab_environment: "Development Lab"
```

### Hyphen problem

This variable name is not recommended:

```yaml
lab-environment: "Development"
```

In Jinja2:

```jinja2
{{ lab-environment }}
```

is interpreted as:

```text
lab minus environment
```

Jinja therefore tries to find a variable called `lab` and reports:

```text
'lab' is undefined
```

The correct convention is:

```yaml
lab_environment: "Development"
```

and:

```jinja2
{{ lab_environment }}
```

Use underscores in Ansible and Jinja2 variable names.

---

## Jinja2 template

Example:

```html
<!DOCTYPE html>
<html>

<head>
    <title>{{ page_title }}</title>
</head>

<body>

    <h1>{{ welcome_message }}</h1>

    <h2>{{ server_name }}</h2>

    <hr>

    <p><strong>Environment:</strong> {{ lab_environment }}</p>
    <p><strong>Owner:</strong> {{ owner }}</p>
    <p><strong>Company:</strong> {{ company }}</p>

    <hr>

    <p>{{ footer }}</p>

</body>

</html>
```

The `.j2` extension identifies it as a Jinja2 template.

---

## Template rendering flow

```text
vars.yml
    |
    | owner: "Syed Aftab"
    |
    +--------------------------+
                               |
index.html.j2                  |
    |                          |
    | {{ owner }} <------------+
    v
Ansible template engine
    |
    v
Rendered index.html
    |
    | Owner: Syed Aftab
    v
/var/www/html/index.html
```

The worker does not receive the `.j2` file.

It receives the final rendered HTML file.

---

## `copy` versus `template`

### Copy module

```yaml
ansible.builtin.copy:
  src: index.html
  dest: /var/www/html/index.html
```

The source and destination content remain identical.

No variables are replaced.

### Template module

```yaml
ansible.builtin.template:
  src: templates/index.html.j2
  dest: /var/www/html/index.html
```

Ansible:

1. Reads the template.
2. Loads variables.
3. Replaces placeholders.
4. Produces the final file.
5. Compares it with the remote file.
6. Copies it only when required.

---

## Lab 5 playbook

```yaml
---
- name: Lab 5 - Templates and Handlers
  hosts: workers
  become: true

  vars_files:
    - vars.yml

  tasks:
    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        update_cache: true

    - name: Deploy custom Nginx homepage
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: /var/www/html/index.html
        owner: root
        group: root
        mode: "0644"
      notify: Restart Nginx

  handlers:
    - name: Restart Nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

---

## Handler execution flow

```text
Template task runs on worker1
        |
        v
Is generated file different?
   |                 |
   | No              | Yes
   v                 v
Result: ok       Copy new file
                      |
                      v
               Notify handler
                      |
                      v
Template task runs on worker2
                      |
                      v
All normal tasks finish
                      |
                      v
Run notified handler once per changed host
```

The handler does not run immediately when `notify` is encountered.

The notification is queued.

At the end of normal task execution, Ansible runs the handler.

---

## Why handlers matter

Without handlers:

```text
Copy nginx.conf
Restart Nginx

Copy index.html
Restart Nginx

Copy TLS configuration
Restart Nginx
```

This could restart Nginx three times.

With handlers:

```text
Copy nginx.conf
Notify restart

Copy index.html
Notify restart

Copy TLS configuration
Notify restart

End of tasks
Restart Nginx once
```

Handlers reduce unnecessary interruptions.

---

## Host-specific changes

Ansible evaluates changes separately on each host.

Imagine 100 servers:

```text
99 servers already have the correct file
1 server was manually modified
```

When the playbook runs:

```text
99 hosts: ok
1 host: changed
```

Only the changed host notifies and runs the handler.

This is what is meant by:

> Only changed servers restart Nginx.

---

## File ownership and permissions

The template task used:

```yaml
owner: root
group: root
mode: "0644"
```

This produces:

```text
-rw-r--r--
```

Meaning:

```text
Owner:  read and write
Group:  read
Others: read
```

Equivalent Linux commands:

```bash
sudo chown root:root /var/www/html/index.html
sudo chmod 644 /var/www/html/index.html
```

---

# Lab 6 — Production-Style Ansible Roles

## Objective

Lab 6 reorganized the automation into reusable roles.

The project used three roles:

```text
common
docker
nginx
```

The top-level playbook became very small:

```yaml
---
- name: Lab 6 - Ansible Roles
  hosts: workers
  become: true

  roles:
    - common
    - docker
    - nginx
```

The top-level playbook describes what roles should run.

Each role contains the implementation.

---

## Role execution order

Roles are executed in the order listed:

```text
common
   |
   v
docker
   |
   v
nginx
```

Ansible automatically looks for:

```text
roles/common/tasks/main.yml
roles/docker/tasks/main.yml
roles/nginx/tasks/main.yml
```

It also automatically loads role defaults, handlers, templates and related role content.

There is no need to write:

```yaml
vars_files:
  - roles/common/defaults/main.yml
```

Ansible understands the standard role structure.

---

# Understanding Role Directories

A generated role may contain:

```text
role-name/
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
├── vars/
│   └── main.yml
└── README.md
```

---

## `tasks/main.yml`

This contains the work performed by the role.

Example:

```yaml
- name: Install Docker
  ansible.builtin.apt:
    name: "{{ docker_package_name }}"
    state: "{{ docker_package_state }}"
```

Think of it as:

> What should this role do?

---

## `defaults/main.yml`

This contains default configuration values.

Example:

```yaml
docker_package_name: docker.io
docker_package_state: present
```

Defaults have low variable precedence and are intentionally easy to override.

Think of defaults as:

> Use these values unless the caller provides different ones.

---

## `vars/main.yml`

This also stores variables, but role variables have much higher precedence than role defaults.

They are harder to override.

Use `vars/main.yml` for role-internal values that callers generally should not change.

For reusable roles, configurable values usually belong in:

```text
defaults/main.yml
```

rather than:

```text
vars/main.yml
```

---

## `templates/`

This stores Jinja2 templates.

Example:

```text
roles/nginx/templates/index.html.j2
```

A role task references it simply as:

```yaml
src: index.html.j2
```

Ansible automatically searches the role's template directory.

There is no need to write:

```yaml
src: roles/nginx/templates/index.html.j2
```

---

## `files/`

This stores static files that do not require Jinja2 rendering.

Examples:

```text
install.sh
company-logo.png
certificate.crt
configuration.json
```

Static files are commonly deployed using:

```yaml
ansible.builtin.copy:
```

Templates are deployed using:

```yaml
ansible.builtin.template:
```

---

## `handlers/main.yml`

This contains handlers owned by the role.

Example:

```yaml
---
- name: Restart Nginx
  ansible.builtin.service:
    name: "{{ nginx_service_name }}"
    state: restarted
```

The task can notify it:

```yaml
notify: Restart Nginx
```

The role remains self-contained.

---

## `meta/main.yml`

This stores role metadata.

It can describe:

- Role author
- Supported platforms
- Supported Ansible versions
- Galaxy information
- Role dependencies

Example dependency:

```yaml
dependencies:
  - common
```

This can cause another role to run as a dependency.

It was not required for these labs.

---

## `tests/`

This contains basic role test scaffolding.

For larger projects, dedicated testing tools such as Molecule may be used.

The generated tests directory was not central to this learning lab.

---

# Common Role

## Defaults

```yaml
---
common_packages:
  - jq
  - net-tools
  - dnsutils
  - traceroute
  - tcpdump
  - rsync

common_package_state: present
common_update_cache: true
common_cache_valid_time: 3600
```

These packages support Linux, networking and cloud troubleshooting.

### Package purposes

| Package | Purpose |
|---|---|
| `jq` | Parses and filters JSON |
| `net-tools` | Provides tools such as `netstat` |
| `dnsutils` | Provides `dig` and `nslookup` |
| `traceroute` | Displays the network route to a destination |
| `tcpdump` | Captures and inspects network packets |
| `rsync` | Synchronizes files and directories efficiently |

---

## Tasks

```yaml
---
- name: Update apt package cache
  ansible.builtin.apt:
    update_cache: "{{ common_update_cache }}"
    cache_valid_time: "{{ common_cache_valid_time }}"

- name: Install common operations packages
  ansible.builtin.apt:
    name: "{{ common_packages }}"
    state: "{{ common_package_state }}"
```

Here the whole package list is passed directly to the APT module:

```yaml
name: "{{ common_packages }}"
```

The relationship is:

```text
defaults/main.yml
        |
        | common_packages
        | common_package_state
        v
tasks/main.yml
        |
        | Install configured packages
        v
Worker nodes
```

---

# Docker Role

## Defaults

```yaml
---
docker_package_name: docker.io
docker_package_state: present

docker_service_name: docker
docker_service_state: started
docker_service_enabled: true

docker_user: ubuntu
```

---

## Tasks

```yaml
---
- name: Install Docker package
  ansible.builtin.apt:
    name: "{{ docker_package_name }}"
    state: "{{ docker_package_state }}"
    update_cache: true

- name: Ensure Docker service is running and enabled
  ansible.builtin.service:
    name: "{{ docker_service_name }}"
    state: "{{ docker_service_state }}"
    enabled: "{{ docker_service_enabled }}"

- name: Add user to Docker group
  ansible.builtin.user:
    name: "{{ docker_user }}"
    groups: docker
    append: true
```

---

## Why `append: true` matters

The task uses:

```yaml
groups: docker
append: true
```

This means:

> Add the user to the Docker group while preserving existing supplementary groups.

Without:

```yaml
append: true
```

Ansible could replace the user's supplementary group memberships.

After adding the user to the Docker group, a new login session may be required before an existing shell recognizes the new membership.

Commands:

```bash
exit
```

and reconnect, or:

```bash
newgrp docker
```

---

## Single user versus loop

For one user:

```yaml
docker_user: ubuntu
```

```yaml
name: "{{ docker_user }}"
```

is simple and appropriate.

For multiple users:

```yaml
docker_users:
  - ubuntu
  - jenkins
  - developer
```

a loop would be useful:

```yaml
- name: Add users to Docker group
  ansible.builtin.user:
    name: "{{ item }}"
    groups: docker
    append: true
  loop: "{{ docker_users }}"
```

The simplest solution should be used for the current requirement.

---

# Nginx Role

The Nginx role demonstrates a complete role containing:

- Defaults
- Tasks
- Template
- Handler
- Variables
- Host-specific rendering

---

## Defaults

```yaml
---
nginx_package_name: nginx
nginx_package_state: present

nginx_service_name: nginx
nginx_service_state: started
nginx_service_enabled: true

nginx_page_title: "Ansible Roles Demo"
nginx_welcome_message: "Nginx Managed Through an Ansible Role"
nginx_environment: "Development"
nginx_owner: "Syed Aftab"
nginx_footer: "Lab 6 - Ansible Roles"
```

---

## Template

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>{{ nginx_page_title }}</title>
</head>

<body>

    <h1>{{ nginx_welcome_message }}</h1>

    <hr>

    <p><strong>Server:</strong> {{ inventory_hostname }}</p>
    <p><strong>Environment:</strong> {{ nginx_environment }}</p>
    <p><strong>Owner:</strong> {{ nginx_owner }}</p>

    <hr>

    <p>{{ nginx_footer }}</p>

</body>

</html>
```

---

## `inventory_hostname`

`inventory_hostname` is an Ansible-provided variable.

If the inventory contains:

```ini
[workers]
worker1 ansible_host=10.0.1.10
worker2 ansible_host=10.0.2.10
```

Ansible renders:

```text
Server: worker1
```

on Worker 1 and:

```text
Server: worker2
```

on Worker 2.

The same template therefore generates different output per host.

---

## Tasks

```yaml
---
- name: Install Nginx package
  ansible.builtin.apt:
    name: "{{ nginx_package_name }}"
    state: "{{ nginx_package_state }}"
    update_cache: true

- name: Ensure Nginx service is running and enabled
  ansible.builtin.service:
    name: "{{ nginx_service_name }}"
    state: "{{ nginx_service_state }}"
    enabled: "{{ nginx_service_enabled }}"

- name: Deploy custom Nginx homepage
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: root
    group: root
    mode: "0644"
  notify: Restart Nginx
```

---

## Handler

```yaml
---
- name: Restart Nginx
  ansible.builtin.service:
    name: "{{ nginx_service_name }}"
    state: restarted
```

---

## Complete Nginx role flow

```text
Top-level playbook
        |
        | roles:
        |   - nginx
        v
Load roles/nginx/defaults/main.yml
        |
        | nginx_package_name
        | nginx_service_name
        | nginx_owner
        | nginx_environment
        v
Run roles/nginx/tasks/main.yml
        |
        +--> Ensure package exists
        |
        +--> Ensure service is running
        |
        +--> Load templates/index.html.j2
                    |
                    v
             Render variables
                    |
                    v
        Compare rendered file with remote file
                    |
             +------+------+
             |             |
             v             v
          identical      different
             |             |
             v             v
            ok          copy file
                           |
                           v
                 notify Restart Nginx
                           |
                           v
             Run handlers/main.yml
```

---

# Lab 7 — Tags and Selective Execution

## Objective

Lab 7 introduced tags so that only selected portions of a playbook need to run.

Without tags:

```bash
ansible-playbook playbook.yml
```

Ansible evaluates all configured roles and tasks.

With tags:

```bash
ansible-playbook playbook.yml --tags nginx
```

only tasks marked with the `nginx` tag are selected.

---

## Common tags

```yaml
tags:
  - common
```

## Docker tags

```yaml
tags:
  - docker
```

## Nginx tags

```yaml
tags:
  - nginx
```

---

## Example tagged task

```yaml
- name: Install Docker package
  ansible.builtin.apt:
    name: "{{ docker_package_name }}"
    state: "{{ docker_package_state }}"
  tags:
    - docker
```

---

## List available tags

```bash
ansible-playbook playbook.yml --list-tags
```

Example output:

```text
TASK TAGS: [common, docker, nginx]
```

---

## Run only common tasks

```bash
ansible-playbook playbook.yml --tags common
```

Execution:

```text
common tasks: selected
docker tasks: skipped
nginx tasks: skipped
```

---

## Run only Docker tasks

```bash
ansible-playbook playbook.yml --tags docker
```

---

## Run only Nginx tasks

```bash
ansible-playbook playbook.yml --tags nginx
```

---

## Run multiple tags

```bash
ansible-playbook playbook.yml --tags "docker,nginx"
```

---

## Skip a tag

```bash
ansible-playbook playbook.yml --skip-tags docker
```

This runs everything except Docker-tagged tasks.

---

## Why tags matter

Imagine a production playbook containing:

```text
common
users
security
docker
nginx
monitoring
logging
backup
firewall
```

A change is needed only for Nginx.

Running every task would be unnecessary.

Instead:

```bash
ansible-playbook site.yml --tags nginx
```

selects only the required automation.

Tags can:

- Reduce execution time
- Limit the scope of a change
- Support maintenance windows
- Simplify troubleshooting
- Avoid unnecessary service interaction
- Make large playbooks easier to operate

Tags do not replace proper role design.

They add execution control to a well-structured project.

---

# Lab 8 — Concepts Moved to Final Project

A separate Lab 8 was intentionally not created.

The remaining concepts will be implemented directly in the final combined Ansible project so they are learned in a realistic context.

These concepts include:

- AWS EC2 dynamic inventory
- Ansible Vault
- Ansible Galaxy
- Collections
- Terraform-to-Ansible integration
- Automatically discovering worker nodes
- More production-focused role organization

---

## AWS Dynamic Inventory

The static labs used:

```ini
[workers]
worker1 ansible_host=10.0.1.10
worker2 ansible_host=10.0.2.10
```

This becomes inconvenient when Terraform destroys and recreates EC2 instances because the addresses can change.

Dynamic inventory allows Ansible to query AWS.

Conceptual flow:

```text
Terraform creates EC2 instances
        |
        v
EC2 instances receive tags
        |
        | Role=worker
        | Environment=dev
        v
Ansible AWS inventory plugin
        |
        v
Query AWS API
        |
        v
Find matching EC2 instances
        |
        v
Build inventory automatically
```

Example plugin configuration:

```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1

filters:
  instance-state-name: running
  tag:Role: worker

keyed_groups:
  - key: tags.Role
    prefix: role
```

This will be completed in the final project.

---

## Terraform-generated inventory

Another possible integration is having Terraform create an inventory file from outputs or templates.

Conceptual flow:

```text
Terraform creates worker1 and worker2
        |
        v
Terraform knows their IP addresses
        |
        v
Terraform template_file or local_file
        |
        v
Generate inventory.ini
        |
        v
Ansible uses generated inventory
```

The final project will compare this method with AWS dynamic inventory.

---

## Ansible Vault

Ansible Vault protects sensitive Ansible data at rest.

Example plaintext variable:

```yaml
database_password: "example-password"
```

Encrypt a file:

```bash
ansible-vault encrypt secrets.yml
```

Edit an encrypted file:

```bash
ansible-vault edit secrets.yml
```

View an encrypted file:

```bash
ansible-vault view secrets.yml
```

Run a playbook that uses Vault:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

A local password file can also be used:

```bash
ansible-playbook playbook.yml \
  --vault-password-file .vault_pass
```

The Vault password file must never be committed.

In AWS-focused environments, sensitive values may instead be stored in:

- AWS Secrets Manager
- AWS Systems Manager Parameter Store
- HashiCorp Vault

Ansible Vault remains useful for Ansible-centric repositories and local encrypted variable files.

---

## Ansible Galaxy

Ansible Galaxy supports:

- Creating role structures
- Installing reusable community roles
- Installing collections
- Publishing roles

The role structures in Lab 6 were generated using:

```bash
ansible-galaxy role init roles/common
ansible-galaxy role init roles/docker
ansible-galaxy role init roles/nginx
```

This creates the standard directories.

A third-party role can be installed using:

```bash
ansible-galaxy role install ROLE_NAME
```

Collections are installed using:

```bash
ansible-galaxy collection install amazon.aws
```

The AWS collection is required for AWS-specific modules and inventory plugins.

A project can document dependencies in:

```text
requirements.yml
```

Example:

```yaml
---
collections:
  - name: amazon.aws
  - name: community.general
```

Install dependencies:

```bash
ansible-galaxy install -r requirements.yml
```

This will be incorporated into the final combined project.

---

# Variable Precedence and Role Defaults

Ansible can load variables from many locations.

A simplified precedence model is:

```text
Role defaults
    |
    | Lowest precedence
    v
Inventory variables
    |
    v
Group variables
    |
    v
Host variables
    |
    v
Play variables
    |
    v
vars_files
    |
    v
Role vars
    |
    v
Extra variables
    |
    | Highest common precedence
    v
-e variable=value
```

This is simplified, but it explains why reusable role configuration belongs in:

```text
defaults/main.yml
```

The caller can override defaults.

Example role default:

```yaml
nginx_environment: development
```

Override from a play:

```yaml
- name: Configure production servers
  hosts: workers

  roles:
    - role: nginx
      vars:
        nginx_environment: production
```

The role remains unchanged.

---

## Why not put everything in `vars/main.yml`?

Role variables have stronger precedence.

They are more difficult for callers to override.

Use:

```text
defaults/main.yml
```

for:

- Package names
- Service states
- Enablement flags
- Ports
- Users
- Paths that projects may customize
- Environment labels
- Template content values

Use:

```text
vars/main.yml
```

for internal constants that normally should not change.

---

# Idempotency

Idempotency means repeatedly applying the same automation produces the same final state without unnecessary changes.

First run:

```text
Package missing
Service stopped
Template missing

Result:
changed=3
```

Second run:

```text
Package present
Service started
Template identical

Result:
changed=0
```

This is different from a basic shell script that might run the same command every time regardless of current state.

Example shell script:

```bash
apt install nginx -y
systemctl restart nginx
```

It attempts both operations every time.

Ansible declares the desired state:

```yaml
name: nginx
state: present
```

and:

```yaml
name: nginx
state: started
```

Ansible checks before changing.

---

# Handlers and Notifications

A handler has three important properties:

1. It runs only when notified.
2. Notification normally occurs only when a task reports `changed`.
3. Multiple notifications usually cause one handler execution per host at the end of the play.

Example:

```yaml
- name: Deploy configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Restart Nginx
```

Handler:

```yaml
- name: Restart Nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

Flow:

```text
Configuration identical
        |
        v
Task result: ok
        |
        v
No notification
        |
        v
No restart
```

or:

```text
Configuration changed
        |
        v
Task result: changed
        |
        v
Handler notified
        |
        v
Normal tasks finish
        |
        v
Nginx restarted once
```

---

# Manual Verification

Automation should be verified independently.

A successful Ansible recap is important, but real validation confirms the service works.

---

## Connectivity

```bash
ansible workers -m ansible.builtin.ping
```

Expected:

```text
pong
```

---

## Package verification

```bash
ansible workers -m ansible.builtin.command -a "jq --version"
```

```bash
ansible workers -m ansible.builtin.command -a "traceroute --version"
```

```bash
ansible workers -m ansible.builtin.command -a "rsync --version"
```

---

## Package database verification

```bash
ansible workers -b -m ansible.builtin.shell -a \
"dpkg -l jq net-tools dnsutils traceroute tcpdump rsync | grep '^ii'"
```

---

## Docker service

```bash
ansible workers -b \
  -m ansible.builtin.command \
  -a "systemctl is-active docker"
```

Expected:

```text
active
```

---

## Docker enablement

```bash
ansible workers -b \
  -m ansible.builtin.command \
  -a "systemctl is-enabled docker"
```

Expected:

```text
enabled
```

---

## Docker group membership

```bash
ansible workers \
  -m ansible.builtin.command \
  -a "id ubuntu"
```

The result should include:

```text
docker
```

---

## Docker access

```bash
ansible workers \
  -m ansible.builtin.command \
  -a "docker ps"
```

---

## Nginx service

```bash
ansible workers -b \
  -m ansible.builtin.command \
  -a "systemctl is-active nginx"
```

Expected:

```text
active
```

---

## HTTP verification

```bash
curl http://WORKER_PUBLIC_IP
```

Browser verification:

```text
http://WORKER_PUBLIC_IP
```

Worker 1 should display:

```text
Server: worker1
```

Worker 2 should display:

```text
Server: worker2
```

---

# Useful Commands

## Syntax check

```bash
ansible-playbook --syntax-check playbook.yml
```

This validates YAML and playbook structure without executing the tasks.

---

## List hosts

```bash
ansible-playbook playbook.yml --list-hosts
```

---

## List tasks

```bash
ansible-playbook playbook.yml --list-tasks
```

---

## List tags

```bash
ansible-playbook playbook.yml --list-tags
```

---

## Check mode

```bash
ansible-playbook playbook.yml --check
```

Check mode attempts to predict changes without applying them.

Not every module supports perfect check-mode behavior.

---

## Diff mode

```bash
ansible-playbook playbook.yml --check --diff
```

This is particularly helpful for templates and configuration files.

---

## Verbose output

```bash
ansible-playbook playbook.yml -v
```

More detail:

```bash
ansible-playbook playbook.yml -vv
```

SSH and deeper troubleshooting:

```bash
ansible-playbook playbook.yml -vvv
```

---

## Limit execution to one host

```bash
ansible-playbook playbook.yml --limit worker1
```

---

## Run selected tags

```bash
ansible-playbook playbook.yml --tags nginx
```

---

## Skip selected tags

```bash
ansible-playbook playbook.yml --skip-tags docker
```

---

# Troubleshooting

## YAML: found another document

Error:

```text
Syntax Error while loading YAML.
but found another document
```

Common cause:

```yaml
---
- name: First task
  ...

---
- name: Second task
```

A second `---` incorrectly begins another YAML document.

Correct:

```yaml
---
- name: First task
  ...

- name: Second task
  ...
```

Use one document separator at the top.

---

## Undefined variable

Error:

```text
AnsibleUndefinedVariable: 'lab' is undefined
```

Possible cause:

```jinja2
{{ lab-environment }}
```

Jinja interprets the hyphen as subtraction.

Correct:

```jinja2
{{ lab_environment }}
```

and:

```yaml
lab_environment: "Development"
```

---

## Reserved variable warning

Warning:

```text
Found variable using reserved name: environment
```

Use a more specific name:

```yaml
lab_environment: development
```

---

## Permission denied connecting to Docker

Error:

```text
permission denied while trying to connect to the Docker daemon socket
```

Cause:

The current user is not a member of the Docker group or the current session has not loaded the updated group membership.

Fix:

```yaml
ansible.builtin.user:
  name: ubuntu
  groups: docker
  append: true
```

Reconnect or run:

```bash
newgrp docker
```

---

## Unreachable host

Example:

```text
UNREACHABLE! Permission denied (publickey)
```

Check:

- Correct private key
- Correct SSH user
- Security-group port 22
- Route tables
- Worker IP address
- File permissions on private key
- `ansible.cfg`
- `inventory.ini`

Test manually:

```bash
ssh -i KEY.pem ubuntu@HOST
```

---

## Incorrect inventory group

If the playbook contains:

```yaml
hosts: workers
```

but inventory contains:

```ini
[webservers]
```

the group does not match.

Both must use the same group name.

---

## Handler does not run

Check:

1. Did the notifying task report `changed`?
2. Does `notify` exactly match the handler name?
3. Is the handler correctly indented?
4. Is the handler part of the same play or loaded role?
5. Did the play fail before handlers ran?

Example exact match:

```yaml
notify: Restart Nginx
```

```yaml
- name: Restart Nginx
```

---

## Template source not found

Outside a role:

```yaml
src: templates/index.html.j2
```

Inside a role:

```yaml
src: index.html.j2
```

Ansible automatically searches:

```text
roles/ROLE_NAME/templates/
```

---

## Service installed but not running

Installing a package does not always guarantee its service state.

Manage both:

```yaml
- name: Install Nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Start Nginx
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

---

# Security Considerations

Never commit:

- Private SSH keys
- PEM files
- Vault password files
- Plaintext passwords
- AWS access keys
- Database credentials
- API tokens
- Terraform variable files containing secrets
- Real production inventories containing sensitive addressing
- Ansible fact caches containing sensitive data

---

## Recommended `.gitignore`

```gitignore
# SSH private keys
*.pem
*.key
id_rsa
id_ed25519

# Ansible
*.retry
.ansible/
fact_cache/

# Vault password files
.vault_pass
vault_pass.txt
vault-password.txt
*.vault-password

# Python
__pycache__/
*.pyc
*.pyo

# Environment variables
.env
.env.*
!.env.example

# Editors
.vscode/
.idea/
*.swp
*~

# Operating system files
.DS_Store
Thumbs.db

# Terraform, if later added
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.tfplan
crash.log
```

Public keys are not secret, but they should only be included when intentionally needed.

---

# GitHub Preparation

Before committing:

```bash
cd ~/Ansible-Labs
```

Check for private keys:

```bash
find . -type f \( -name "*.pem" -o -name "*.key" \)
```

Check for possible credentials:

```bash
grep -RniE \
'password|secret|token|access[_-]?key|private[_-]?key' \
. \
--exclude-dir=.git
```

Review inventory files:

```bash
find . -name "inventory.ini" -print
```

Replace ephemeral addresses with safe examples when appropriate.

---

## Initialize Git

```bash
git init
```

---

## Check files

```bash
git status
```

---

## Stage files

```bash
git add .
```

---

## Review staged content

```bash
git diff --cached
```

This step is important before pushing infrastructure or automation code.

---

## Commit

```bash
git commit -m "Add Ansible hands-on labs"
```

---

## Create GitHub repository

Using GitHub CLI:

```bash
gh repo create Ansible-Labs \
  --public \
  --source=. \
  --remote=origin \
  --push
```

Or connect an existing repository:

```bash
git remote add origin \
https://github.com/USERNAME/Ansible-Labs.git
```

```bash
git branch -M main
git push -u origin main
```

---

# Skills Practiced

This repository demonstrates hands-on practice with:

- Ansible control nodes
- Managed worker nodes
- SSH key authentication
- Static inventory
- `ansible.cfg`
- Ad-hoc commands
- Playbooks
- YAML
- Variables
- External variable files
- Jinja2
- Package management
- Service management
- Linux patching
- Loops
- List-based module arguments
- Templates
- Handlers
- Notifications
- File ownership
- File permissions
- Roles
- Role defaults
- Role tasks
- Role handlers
- Role templates
- Tags
- Idempotency
- Configuration drift
- Docker installation
- Docker group access
- Nginx installation
- Dynamic per-host web content
- Syntax checking
- Manual verification
- Troubleshooting

---

# Key Lessons

## 1. Desired state is more important than commands

Instead of saying:

```text
Run apt install
```

Ansible declares:

```yaml
state: present
```

The tool determines whether a change is needed.

---

## 2. Package state and service state are different

```text
Installed does not always mean running.
Running does not automatically mean enabled at boot.
```

Manage each state intentionally.

---

## 3. Variables separate logic from configuration

```text
Tasks = how
Variables = what
```

---

## 4. Templates generate environment-specific configuration

One template can generate different files based on:

- Host
- Environment
- Owner
- Port
- Region
- Application version
- Inventory group

---

## 5. Handlers reduce unnecessary service disruption

Services restart only after relevant changes.

---

## 6. Roles create reusable building blocks

```text
common
docker
nginx
monitoring
security
```

Each role owns one responsibility.

---

## 7. Defaults should be easy to override

Reusable role configuration belongs primarily in:

```text
defaults/main.yml
```

---

## 8. Tags control execution scope

Tags allow operators to run only the required part of a large automation repository.

---

## 9. Automation must be verified

A green Ansible recap is not the final proof.

Services, ports, applications and user access should also be tested directly.

---

# Next Project

The next combined project will build a complete Terraform and Ansible automation workflow.

Planned architecture:

```text
Local workstation
        |
        | terraform apply
        v
AWS infrastructure
        |
        +--> VPC
        +--> Subnets
        +--> Security groups
        +--> Control node or local Ansible execution
        +--> Worker nodes
        |
        v
EC2 tags
        |
        v
AWS dynamic inventory
        |
        | Automatically discover workers
        v
Ansible playbook
        |
        +--> Common role
        +--> Docker role
        +--> Nginx role
        +--> User-management role
        +--> Monitoring role
        |
        +--> Variables
        +--> Loops
        +--> Templates
        +--> Handlers
        +--> Tags
        +--> Vault demonstration
        +--> Galaxy collections
        |
        v
Fully configured AWS Linux environment
```

The final project will demonstrate:

- Terraform infrastructure provisioning
- AWS tags
- Dynamic EC2 discovery
- Automatic inventory management
- Ansible collections
- Vault-encrypted variables
- Reusable roles
- Selective execution with tags
- Jinja2 configuration generation
- Conditional service restarts
- End-to-end validation
- GitHub documentation

After completing the final Ansible project, the main learning focus will move to:

```text
Terraform
Kubernetes
Amazon EKS
Docker
GitHub Actions
Amazon ECR
Argo CD
GitOps
Helm
Prometheus
Grafana
```

Ansible will remain a supporting configuration-management skill for Linux server fleets, legacy infrastructure, operational automation, patching, and VM-based application environments.

---

# Status

| Lab | Topic | Status |
|---|---|---|
| Lab 1 | Installation, inventory and connectivity | Completed |
| Lab 2 | Ad-hoc commands and basic management | Completed |
| Lab 3 | Variables and idempotency | Completed |
| Lab 4 | Loops, patching and Docker | Completed |
| Lab 5 | Jinja2 templates and handlers | Completed |
| Lab 6 | Ansible roles | Completed |
| Lab 7 | Tags and selective execution | Completed |
| Lab 8 | Vault, Galaxy and dynamic inventory | Moved to final combined project |
| Final project | Terraform and complete Ansible integration | Planned |

---

# Author

**Syed Aftab**

Aspiring Cloud and DevOps Engineer building hands-on projects with AWS, Terraform, Linux, Docker, Ansible, Kubernetes, GitHub Actions and GitOps.
