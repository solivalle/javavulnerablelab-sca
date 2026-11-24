terraform {
  required_version = ">= 1.5.0"

  required_providers {
    terraform = {
      source = "terraform.io/builtin/terraform"
    }
  }
}

# This resource only stores IaC demonstration data and creates no cloud infrastructure.
resource "terraform_data" "lab" {
  input = {
    environment = "lab"
    owner       = "security-course"
    cost_center = "education"
  }
}

