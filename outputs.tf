output "master_security_group_id" {
  value = aws_security_group.master.id
}

output "node_security_group_id" {
  value = aws_security_group.node.id
}

output "mysql_security_group_id" {
  value = aws_security_group.mysql.id
}

output "nlb_security_group_id" {
  value = aws_security_group.nlb.id
}

output "nat_security_group_id" {
  value = aws_security_group.nat.id
}