variable "https_egress_cidr_blocks" {
  default     = null
  description = "The IPv4 CIDR blocks to which allow HTTPS egress traffic"
  type        = list(string)
}

variable "https_egress_ipv6_cidr_blocks" {
  default     = null
  description = "The IPv6 CIDR blocks to which allow HTTPS egress traffic"
  type        = list(string)
}

variable "instance_name" {
  default     = "eks-jumphost"
  description = "The name of the instance"
  type        = string
}

variable "instance_type" {
  default     = "t3.micro"
  description = "The instance type"
  type        = string
}

variable "instance_profile_name" {
  default     = "EKSJumphostInstanceProfile"
  description = "The name of the instance profile associated to the instance"
  type        = string
}

variable "kms_key_id" {
  default     = null
  description = "The ID of the KMS key used to encrypt the instance root volume"
  type        = string
}

variable "monitoring" {
  default     = true
  description = "Whether to enable detailed monitoring for the instance"
  type        = bool
}

variable "role_name" {
  default     = "EKSJumphostRole"
  description = "The name of the role associated to the instance"
  type        = string
}

variable "security_group_name" {
  default     = "eks-jumphost-security-group"
  description = "The name of the security group associated to the instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where to deploy the instance"
  type        = string
}

variable "tags" {
  default     = {}
  description = "The tags applied to all the resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "The VPC ID where to deploy the instance"
  type        = string
}
