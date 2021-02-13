
module "laughs" {
  source  = "sblack4/laughs/terraform"
  version = "0.0.2"
}

output "laughs" {
  value = module.laughs
}
