locals {
  hash = substr(random_uuid.hash.result, 0, 8)
}

resource "random_uuid" "hash" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# Security groups

resource "aws_security_group" "master" {
  name   = join("-", [var.project, "master", local.hash])
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.tags
}

resource "aws_security_group" "node" {
  name   = join("-", [var.project, "node", local.hash])
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.tags
}

resource "aws_security_group" "mysql" {
  name   = join("-", [var.project, "mysql", local.hash])
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.tags
}

resource "aws_security_group" "nlb" {
  name   = join("-", [var.project, "nlb", local.hash])
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.tags
}

resource "aws_security_group" "nat" {
  name   = join("-", [var.project, "nat", local.hash])
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.tags
}

# Ingress Rules

resource "aws_security_group_rule" "node-all-traffic-master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.master.id
  security_group_id        = aws_security_group.node.id
}

resource "aws_security_group_rule" "master-all-traffic-node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.master.id
}

resource "aws_security_group_rule" "master-nodeport-services-ingress-nlb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  security_group_id        = aws_security_group.master.id
}

resource "aws_security_group_rule" "node-nodeport-services-ingress-nlb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  security_group_id        = aws_security_group.node.id
}

resource "aws_security_group_rule" "mysql-datastore-ingress-master" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master.id
  security_group_id        = aws_security_group.mysql.id
}

resource "aws_security_group_rule" "master-apiserver-ingress-nlb" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  security_group_id        = aws_security_group.master.id
}

resource "aws_security_group_rule" "master-ssh-ingress-nat" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.master.id
}

resource "aws_security_group_rule" "node-ssh-ingress-nat" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.node.id
}

resource "aws_security_group_rule" "mysql-ssh-ingress-nat" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.mysql.id
}

resource "aws_security_group_rule" "nlb-ssh-ingress-nat" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nat.id
  security_group_id        = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nat-all-ingress-private-subnet" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.vpc.cidr_block]
  security_group_id = aws_security_group.nat.id
}

# Whitelisted Ingress Rules

resource "aws_security_group_rule" "nlb-http-ingress-whitelisted-ips" {
  for_each          = toset(var.whitelisted_ips)
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nlb-https-ingress-whitelisted-ips" {
  for_each          = toset(var.whitelisted_ips)
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nat-ssh-ingress-whitelisted-ips" {
  for_each          = toset(var.whitelisted_ips)
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.nat.id
}

# Egress Rules

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.master.id
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "mysql-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysql.id
}

resource "aws_security_group_rule" "nlb-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nlb.id
}

resource "aws_security_group_rule" "nat-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
}