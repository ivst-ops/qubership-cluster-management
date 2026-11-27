# Same output in every <cloud>/vms component; the kubemarine component and local/lab.sh consume it.
output "vms" {
  description = "The created VMs: name, roles, address (public or private, by `public`) and internal address"
  value = [
    for name, vm in var.vms : {
      name             = name
      roles            = vm.roles
      address          = var.public ? aws_instance.vm[name].public_ip : aws_instance.vm[name].private_ip
      internal_address = aws_instance.vm[name].private_ip
    }
  ]
}
