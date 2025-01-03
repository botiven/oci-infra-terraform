variable "ssh_public_key" {
  type        = string
  description = "The public key to be used for SSH access to the instances"
}

variable "compartment_id" {
  type        = string
  description = "The OCID of the compartment"
}

variable "region" {
  type        = string
  description = "The region to create the resources"
}
