# Terraform + Ansible AWS Automation

## Project Overview

This project demonstrates a complete Infrastructure as Code (IaC) and Configuration Management workflow using Terraform and Ansible on AWS.

Terraform was used to provision the AWS infrastructure, including networking, security groups, SSH key management, and EC2 instances. After the infrastructure was deployed, Ansible was installed on a dedicated control node to automate software installation and configuration across multiple worker nodes.

The project follows a real-world workflow where:

Infrastructure → Terraform

Configuration → Ansible

Instead of manually SSHing into every server, Ansible connected to multiple EC2 instances simultaneously over SSH and configured them automatically.

---

# Architecture

```
                 Laptop
                    │
             SSH (Public IP)
                    │
                    ▼
        ┌──────────────────────┐
        │   Ansible Control    │
        │      EC2 Instance    │
        └──────────┬───────────┘
                   │
          SSH using Private IPs
        ┌──────────┴───────────┐
        │                      │
        ▼                      ▼
 ┌──────────────┐      ┌──────────────┐
 │   Worker 1   │      │   Worker 2   │
 │ Ubuntu EC2   │      │ Ubuntu EC2   │
 └──────────────┘      └──────────────┘
```

---

# Technologies Used

- AWS EC2
- AWS VPC
- Internet Gateway
- Route Tables
- Security Groups
- Terraform
- Ansible
- Ubuntu 24.04
- SSH
- Git
- VS Code

---

# Project Objectives

- Provision AWS infrastructure using Terraform
- Create an Ansible control node
- Deploy two Ubuntu worker nodes
- Configure secure SSH communication
- Install Ansible
- Create inventory files
- Configure ansible.cfg
- Execute Ansible modules
- Deploy Nginx automatically
- Verify idempotent configuration management

---

# Infrastructure Provisioned with Terraform

Terraform created:

- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Route Table Association
- Security Group
- SSH Key Pair
- Local Private Key
- Control Node EC2
- Worker Node 1 EC2
- Worker Node 2 EC2

Everything was provisioned from code without manually creating AWS resources.

---

# Terraform Workflow

The project followed the standard Terraform workflow:

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

After the project was completed:

```bash
terraform destroy
```

was used to remove all AWS resources.

---

# SSH Connectivity

SSH communication was verified in multiple stages.

Laptop

↓

Control Node

↓

Worker 1

↓

Worker 2

The control node communicated with worker nodes using their private IP addresses.

Security Group rules allowed SSH communication between instances belonging to the same Security Group.

---

# Installing Ansible

Ansible was installed on the control node.

Inventory was configured with both worker nodes.

Example:

```ini
[workers]
worker1
worker2
```

Ansible configuration:

```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
interpreter_python = auto_silent
```

---

# Connectivity Test

The first Ansible test executed:

```bash
ansible workers -m ping
```

Output:

```
worker1 => pong
worker2 => pong
```

This confirmed:

- SSH connectivity
- Python availability
- Successful remote execution

---

# Nginx Deployment Playbook

A playbook was created to automate server configuration.

Tasks included:

- Update package cache
- Upgrade installed packages
- Install Nginx
- Enable Nginx
- Start Nginx
- Deploy a custom HTML page
- Verify HTTP response

The playbook configured both worker nodes simultaneously.

---

# Custom Web Page

The playbook deployed a custom web page displaying:

- Worker hostname
- Private IP address

Each server returned its own customized page when accessed through its public IP.

---

# Idempotency

One of Ansible's core features is idempotency.

Running the playbook multiple times does not repeatedly modify already-configured systems.

Example:

First run

```
changed = multiple tasks
```

Second run

```
changed = 0
```

Only systems that drift from the desired configuration are modified.

---

# Configuration Drift Recovery

To demonstrate configuration management:

- Nginx was manually stopped
- The custom web page was deleted

The playbook was executed again.

Ansible automatically:

- Restarted Nginx
- Restored the deleted HTML page

Only the modified server was changed while the healthy server remained untouched.

---

# Repository Structure

```
terraform-ansible-aws-labs/

│

├── terraform/

│ ├── versions.tf

│ ├── provider.tf

│ ├── variables.tf

│ ├── locals.tf

│ ├── data.tf

│ ├── main.tf

│ ├── outputs.tf

│ └── .gitignore

│

├── ansible/

│ ├── inventory.ini

│ ├── ansible.cfg

│ └── nginx.yml

│

├── screenshots/

│

└── README.md
```

---

# Skills Demonstrated

- Infrastructure as Code (Terraform)
- AWS Networking
- Security Groups
- EC2 Provisioning
- SSH Authentication
- Linux Administration
- Ansible Inventory
- Ansible Configuration
- Playbook Development
- Configuration Management
- Idempotent Automation
- Nginx Deployment
- Infrastructure Verification

---

# Future Improvements

The next phase of this learning journey will include:

- Dynamic Ansible Inventory
- Multiple Inventory Groups
- Docker Deployment
- Ansible Roles
- Templates (Jinja2)
- Variables
- Handlers
- Prometheus
- Grafana
- Production Terraform Modules
- Remote Terraform State (S3 Backend)
- Amazon EKS
- GitHub Actions
- Argo CD
- GitOps Deployment

---

# Conclusion

This project demonstrates the complete workflow of provisioning AWS infrastructure with Terraform and automating server configuration with Ansible.

Rather than manually configuring each EC2 instance, infrastructure was created from code and server configuration was applied consistently across multiple hosts using Ansible playbooks.

The project provides a solid foundation for larger production deployments using Terraform modules, Ansible roles, Kubernetes, and GitOps workflows.

---
