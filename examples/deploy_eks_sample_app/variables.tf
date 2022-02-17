variable "region" {
  default     = "us-east-1"
  description = "The AWS region that Terraform will use"
  type        = string
}

variable "tags" {
  default     = {}
  description = "The tags applied to all the resources"
  type        = map(string)
}
