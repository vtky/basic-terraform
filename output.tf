output "basic_IP_Address" {
  value = aws_instance.basic.*.public_ip
}

# output "spot_IP_Address" {
#   value = aws_spot_instance_request.spot.*.public_ip
# }