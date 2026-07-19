output "control_node_public_ip" {
  description = "Public IP of the Ansible control node"
  value       = aws_instance.control.public_ip
}

output "control_node_private_ip" {
  description = "Private IP of the Ansible control node"
  value       = aws_instance.control.private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker nodes"
  value       = aws_instance.workers[*].public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses used by Ansible"
  value       = aws_instance.workers[*].private_ip
}

output "ssh_to_control_node" {
  description = "Command used to connect to the control node"
  value       = "ssh -i ansible-lab-key.pem ubuntu@${aws_instance.control.public_ip}"
}

output "private_key_path" {
  description = "Local path of the generated SSH private key"
  value       = local_sensitive_file.private_key.filename
  sensitive   = true
}
