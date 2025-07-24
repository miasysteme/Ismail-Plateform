# Infrastructure Terraform - Plateforme ISMAIL
# Provider AWS avec région Afrique (Cape Town) pour latence optimale

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  backend "s3" {
    bucket = "ismail-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "af-south-1"
    encrypt = true
    dynamodb_table = "terraform-locks"
  }
}

# Configuration du provider AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "ISMAIL"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "ISMAIL-DevOps"
    }
  }
}

# Variables globales
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1" # Cape Town pour l'Afrique
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "ismail-cluster"
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  # Tags pour EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  # Addons EKS
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Groupes de nœuds
  eks_managed_node_groups = {
    # Nœuds système (monitoring, ingress, etc.)
    system = {
      name = "system-nodes"
      instance_types = ["t3.medium"]
      
      min_size     = 2
      max_size     = 4
      desired_size = 2
      
      labels = {
        role = "system"
      }
      
      taints = {
        system = {
          key    = "node-role"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      }
    }

    # Nœuds application
    application = {
      name = "app-nodes"
      instance_types = ["t3.large", "t3.xlarge"]
      
      min_size     = 3
      max_size     = 20
      desired_size = 5
      
      labels = {
        role = "application"
      }
    }

    # Nœuds base de données (si nécessaire)
    database = {
      name = "db-nodes"
      instance_types = ["r5.large"]
      
      min_size     = 2
      max_size     = 6
      desired_size = 2
      
      labels = {
        role = "database"
      }
      
      taints = {
        database = {
          key    = "node-role"
          value  = "database"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  # RBAC
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_admin.arn
      username = "eks-admin"
      groups   = ["system:masters"]
    }
  ]
}

# IAM Role pour administration EKS
resource "aws_iam_role" "eks_admin" {
  name = "${var.cluster_name}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# RDS PostgreSQL pour données transactionnelles
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.cluster_name}-postgres-subnet-group"
  subnet_ids = module.vpc.database_subnets

  tags = {
    Name = "PostgreSQL DB subnet group"
  }
}

resource "aws_security_group" "postgres" {
  name_prefix = "${var.cluster_name}-postgres-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres_primary" {
  identifier = "${var.cluster_name}-postgres-primary"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.environment == "prod" ? "db.r5.xlarge" : "db.t3.medium"
  
  allocated_storage     = var.environment == "prod" ? 500 : 100
  max_allocated_storage = var.environment == "prod" ? 2000 : 500
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "ismail"
  username = "postgres"
  password = random_password.postgres_password.result
  
  vpc_security_group_ids = [aws_security_group.postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = var.environment != "prod"
  deletion_protection = var.environment == "prod"
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = var.environment == "prod" ? 731 : 7
}

# Read Replica pour PostgreSQL (production uniquement)
resource "aws_db_instance" "postgres_replica" {
  count = var.environment == "prod" ? 1 : 0
  
  identifier = "${var.cluster_name}-postgres-replica"
  
  replicate_source_db = aws_db_instance.postgres_primary.identifier
  instance_class      = "db.r5.large"
  
  auto_minor_version_upgrade = false
  skip_final_snapshot       = true
  
  # Performance Insights
  performance_insights_enabled = true
}

# ElastiCache Redis pour cache et sessions
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.cluster_name}-redis-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.cluster_name}-redis"
  description                = "Redis cluster for ISMAIL platform"
  
  node_type                  = var.environment == "prod" ? "cache.r6g.large" : "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = var.environment == "prod" ? 3 : 1
  automatic_failover_enabled = var.environment == "prod"
  multi_az_enabled          = var.environment == "prod"
  
  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_password.result
  
  # Backup
  snapshot_retention_limit = var.environment == "prod" ? 7 : 1
  snapshot_window         = "03:00-05:00"
}

# Mots de passe aléatoires
resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

resource "random_password" "redis_password" {
  length  = 32
  special = false # Redis auth token ne supporte pas tous les caractères spéciaux
}

# IAM Role pour monitoring RDS
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.cluster_name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# S3 Buckets pour stockage
resource "aws_s3_bucket" "app_storage" {
  bucket = "${var.cluster_name}-app-storage-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.cluster_name}-backups-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Configuration S3
resource "aws_s3_bucket_versioning" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "postgres_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres_primary.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive   = true
}

output "s3_bucket_app" {
  description = "S3 bucket for application storage"
  value       = aws_s3_bucket.app_storage.bucket
}
