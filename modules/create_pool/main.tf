resource "null_resource" "create_pool" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "pvesh create /pools --poolid ADMIN --comment create_admin_pool_for_pfsense;sleep 3"
  }
}
