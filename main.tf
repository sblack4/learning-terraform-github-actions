

resource "null_resource" "hello_world" {
  provisioner "local-exec" {
    command = "echo 'hello hoppity bunny world'"
  }
}

module "laughs" {
  source  = "sblack4/laughs/terraform"
  version = "0.0.2"
}

output "laughs" {
  value = module.laughs
}
