variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Number of days to wait before deleting KMS key"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}