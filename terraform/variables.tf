variable "project" {
  type = string 
  default = "roboshop"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "tags" {
  type = map 
  default = {
    Component = "catalogue"
  }
}

variable "common_tags" {
  type = map 
  default = {
    Project = "roboshop"
    Terraform = "true"
    Environment = "dev"
  }
}

variable "zone_id" {
  default = "Z059178135GSKTAXVUIAQ"
}

variable "domain_name" {
  default = "devopsprocloud.in"
}

variable "app_version" {
  
}

variable "components" {
    default = {
        # backend components are attaching to backend ALB
        catalogue = {
            rule_priority = 10
        }
        # user = {
        #     rule_priority = 20
        # }
        # cart = {
        #     rule_priority = 30
        # }
        # shipping = {
        #     rule_priority = 40
        # }
        # payment = {
        #     rule_priority = 50
        # }
        # # this is attaching to frontend ALB, there is only component there
        # frontend = {
        #     rule_priority = 10
        # }
    }
}