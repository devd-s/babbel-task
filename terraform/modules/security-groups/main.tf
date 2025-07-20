# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.environment}-eks-cluster-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster-sg"
  })
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.environment}-eks-nodes-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "Pod to pod communication"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description     = "Cluster API to node kubelets"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description = "Node to node communication UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-nodes-sg"
  })
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  # HTTP from CloudFront IPs
  ingress {
    description = "HTTP from CloudFront"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cloudfront_ips
  }

  # HTTPS from CloudFront IPs
  ingress {
    description = "HTTPS from CloudFront"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cloudfront_ips
  }

  # Allow health checks from ALB to nodes
  egress {
    description     = "ALB to EKS nodes"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-alb-sg"
  })
}

# RDS Security Group (if needed)
resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL/Aurora from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-sg"
  })
}

# Additional ingress rule for ALB to EKS nodes
resource "aws_security_group_rule" "eks_nodes_from_alb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_nodes.id
}

# Allow ALB to communicate with EKS nodes on all ports
resource "aws_security_group_rule" "eks_nodes_alb_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_nodes.id
}