resource "null_resource" "delete_pool" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    when        = destroy
    command     = "sleep 1;pvesh delete /pools/ADMIN"
  }
}
