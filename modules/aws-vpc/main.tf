// Instance config

resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_gateway_tag"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-for-ec2"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_network_interface" "eni" {
  subnet_id   = aws_subnet.my_subnet.id

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "my-instance" {
  user_data_replace_on_change = true

# update/upgrade ubuntu and install redis-cli
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y | sudo tee /tmp/updatelog.log
    sudo apt-get upgrade -y | sudo tee /tmp/upgradelog.log
    sudo apt install -y redis-tools | sudo tee /tmp/redislog.log
  EOF

  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.elasticache_sg.id
  ]
  associate_public_ip_address = true
  subnet_id = aws_subnet.my_subnet.id
}

//Redis config

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.replication_group_id}-redis-${var.environment}"
  description                   = var.replication_group_description
  node_type                     = var.node_type
  port                          = var.port
  parameter_group_name          = var.parameter_group_name
  automatic_failover_enabled    = var.automatic_failover_enabled
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
  snapshot_retention_limit      = var.snapshot_retention_limit
  engine_version                = var.engine_version
  maintenance_window            = var.maintenance_window
  transit_encryption_enabled    = var.transit_encryption_enabled
  at_rest_encryption_enabled    = var.at_rest_encryption_enabled
  replicas_per_node_group       = var.cluster_mode_enabled ? var.replicas_per_node_group : null
  num_node_groups               = var.cluster_mode_enabled ? var.num_node_groups : null

  security_group_ids = [
    aws_security_group.elasticache_sg.id,
  ]
  tags = var.tags
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [
    aws_security_group.elasticache_sg.id,
  ]
}

resource "aws_security_group" "elasticache_sg" {
  name        = "${var.app_name}-elasticache-${var.environment} SG"
  description = "${var.app_name} ${var.environment} Security Group"
  vpc_id      = aws_vpc.my_vpc.id
  tags = var.tags
}

resource "aws_security_group_rule" "elasticache_sg_rule" {
  security_group_id = aws_security_group.elasticache_sg.id
  from_port         = 6379
  to_port           = 6379
  
#   protocol          = "tcp"
  protocol          = "all"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0", aws_subnet.my_subnet.cidr_block]
}

resource "aws_security_group_rule" "elasticache_sg_rule_egress" {
  security_group_id = aws_security_group.elasticache_sg.id
  
  from_port         = 0
  to_port           = 65535
  
#   protocol          = "tcp"
  protocol          = "all"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0", aws_subnet.my_subnet.cidr_block]
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.app_name}-redis-subnet-group-${lower(var.environment)}"
  subnet_ids = [aws_subnet.my_subnet.id]
}
