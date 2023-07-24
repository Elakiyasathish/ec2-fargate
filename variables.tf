variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  default     = "AKIASD5RRDLXELDNX6XY"
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  default     = "8CQoO8ZRfAnVFs7iUYz35aHzpm5rzIN3/Igy7pw1"
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

variable "ami_type" {
  description = "The type of AMI (Amazon Machine Image)"
  type        = string
  default     = "AL2_x86_64" #Change the AMI as per the requirements
}

variable "instance_types" {
  description = "A list of instance types"
  type        = list(string)
  default     = ["t2.micro", "t3.small"]   # Change the Instance type according to your requirements
}


variable "environment" {
  description = "Name of the Environment"
  type = string
 
}

variable "project" {
  type = string
  
}

variable "nodegroupname" {
  type  = string
  
}

variable "disk_size" {
  type    = number
  default = 200
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
