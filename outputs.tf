output "execute_script_jumphost_path" {
  description = "Path to the execute-script-jumphost script"
  value       = "${path.module}/scripts/execute-script-jumphost.sh"
}

output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.instance.id
}

output "start_eks_jumphost_path" {
  description = "Path to the start-eks-jumphost script"
  value       = "${path.module}/scripts/start-eks-jumphost.sh"
}

output "stop_eks_jumphost_path" {
  description = "Path to the stop-eks-jumphost script"
  value       = "${path.module}/scripts/stop-eks-jumphost.sh"
}
