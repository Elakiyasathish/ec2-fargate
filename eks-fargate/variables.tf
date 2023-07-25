variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  default     = "AKIARRE4VNMRFAB5FID4"
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  default     = "+9YcfqhuEOV3urL0NKyWljBNvPcI3N2VhamzHrUG"
}


variable "kubernetes_namespace" {
    type = string
    description = "Kubernetes namespace for selection"
}
variable "region" {
  description = "The aws region. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones_count" {
  description = "The number of AZs."
  type        = number
  default     = 2
}

variable "environment" {
  description = "Name of the Environment"
  type = string
 
}

variable "project" {
  type = string
  
}

variable "eks_vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_bits" {
  description = "The number of subnet bits for the CIDR. For example, specifying a value 8 for this parameter will create a CIDR with a mask of /24."
  type        = number
  default     = 8
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {

    "environment" = ""
    "project" = ""

  }
}
