data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ebs" {
  statement {
    actions = [
      "kms:*",
    ]
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
      type = "AWS"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
  statement {
    actions = [
      "kms:CreateGrant",
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true",
      ]
    }
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        module.eks.cluster_iam_role_arn,
      ]
      type = "AWS"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        module.eks.cluster_iam_role_arn,
      ]
      type = "AWS"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    principals {
      identifiers = [
        "ec2.${data.aws_partition.current.dns_suffix}",
      ]
      type = "Service"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "kms:*",
    ]
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
      type = "AWS"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    principals {
      identifiers = [
        "logs.${data.aws_partition.current.dns_suffix}",
      ]
      type = "Service"
    }
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
}

data "aws_partition" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.5.0"

  cloudwatch_log_group_kms_key_id        = aws_kms_key.logs.arn
  cloudwatch_log_group_retention_in_days = 30
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE",
    }
    kube-proxy = {},
    vpc-cni = {
      resolve_conflicts = "OVERWRITE",
    },
  }
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources = [
        "secrets",
      ]
    },
  ]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_name                    = "cluster"
  cluster_security_group_additional_rules = {
    ingress_vpc_https = {
      cidr_blocks = [
        module.vpc.vpc_cidr_block,
      ]
      from_port = 443,
      protocol  = "tcp",
      to_port   = 443,
      type      = "ingress",
    },
  }
  cluster_version = "1.21"
  eks_managed_node_groups = {
    eks_managed_node_group = {
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda",
          ebs = {
            delete_on_termination = true,
            encrypted             = true,
            kms_key_id            = aws_kms_key.ebs.arn,
            volume_size           = 25,
            volume_type           = "gp3",
          }
        }
      }
      desired_size = 1,
      max_size     = 1,
      min_size     = 1,
      instance_types = [
        "t3.small",
      ]
      name = "cluster",
    }
  }
  subnet_ids = module.vpc.private_subnets
  tags       = var.tags
  vpc_id     = module.vpc.vpc_id
}

module "eks_jumphost_instance" {
  source = "../.."

  https_egress_cidr_blocks = [
    "0.0.0.0/0",
  ]
  https_egress_ipv6_cidr_blocks = [
    "::/0",
  ]
  kms_key_id = aws_kms_key.ebs.arn
  subnet_id  = module.vpc.private_subnets[0]
  tags       = var.tags
  vpc_id     = module.vpc.vpc_id

  depends_on = [
    module.vpc,
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.12.0"

  azs = [
    "${var.region}a",
    "${var.region}b",
  ]
  cidr                                            = "10.0.0.0/16"
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  enable_dns_hostnames                            = true
  enable_flow_log                                 = true
  enable_nat_gateway                              = true
  flow_log_cloudwatch_log_group_kms_key_id        = aws_kms_key.logs.arn
  flow_log_cloudwatch_log_group_retention_in_days = 30
  name                                            = "vpc"
  private_subnets = [
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]
  private_subnet_tags = {
    "kubernetes.io/cluster/cluster" = "shared"
    "kubernetes.io/role/elb"        = 1
  }
  public_subnets = [
    "10.0.0.0/24",
    "10.0.1.0/24",
  ]
  public_subnet_tags = {
    "kubernetes.io/cluster/cluster" = "shared"
    "kubernetes.io/role/elb"        = 1
  }
  single_nat_gateway = true
  tags               = var.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 3.12.0"

  endpoints = {
    ec2messages = {
      private_dns_enabled = true,
      service             = "ec2messages",
      subnet_ids          = module.vpc.private_subnets,
      tags = merge(
        var.tags,
        {
          Name = "ec2messages",
        },
      ),
    },
    ssm = {
      private_dns_enabled = true,
      service             = "ssm",
      subnet_ids          = module.vpc.private_subnets,
      tags = merge(
        var.tags,
        {
          Name = "ssm",
        },
      ),
    },
    ssmmessages = {
      private_dns_enabled = true,
      service             = "ssmmessages",
      subnet_ids          = module.vpc.private_subnets,
      tags = merge(
        var.tags,
        {
          Name = "ssmmessages",
        },
      ),
    },
  }
  security_group_ids = [
    aws_security_group.security_group.id,
  ]
  vpc_id = module.vpc.vpc_id
}

provider "aws" {
  region = var.region
}

resource "aws_kms_key" "ebs" {
  description             = "EBS Volumes Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ebs.json
  tags                    = var.tags
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_key" "logs" {
  description             = "CloudWatch Logs Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.logs.json
  tags                    = var.tags
}

resource "aws_security_group" "security_group" {
  # checkov:skip=CKV2_AWS_5:Associated to the Interface VPC Endpoints
  description = "Security group for the Interface VPC Endpoints"
  ingress {
    cidr_blocks = [
      module.vpc.vpc_cidr_block,
    ]
    description = "Allow HTTPS ingress traffic from the VPC CIDR block"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  name = "vpc-endpoints"
  tags = merge(
    var.tags,
    {
      Name = "vpc-endpoints",
    },
  )
  vpc_id = module.vpc.vpc_id
}

resource "null_resource" "deploy_eks_sample_app" {
  provisioner "local-exec" {
    command = file(module.eks_jumphost_instance.start_eks_jumphost_path)
    environment = {
      AWS_PAGER   = "",
      INSTANCE_ID = module.eks_jumphost_instance.instance_id,
      REGION      = var.region,
    }
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name $CLUSTER_ID --region $REGION"
    environment = {
      AWS_PAGER  = "",
      CLUSTER_ID = module.eks.cluster_id,
      REGION     = var.region,
    }
  }
  provisioner "local-exec" {
    command = templatefile(module.eks_jumphost_instance.execute_script_jumphost_path, {
      script = <<-EOT
      HTTPS_PROXY=socks5://127.0.0.1:8443 kubectl apply -f app/manifests
      EOT
    })
    environment = {
      AWS_PAGER   = "",
      INSTANCE_ID = module.eks_jumphost_instance.instance_id,
      LOCAL_PORT  = 8443,
      NO_PROXY    = "",
      REGION      = var.region,
    }
  }
  provisioner "local-exec" {
    command = file(module.eks_jumphost_instance.stop_eks_jumphost_path)
    environment = {
      AWS_PAGER   = "",
      INSTANCE_ID = module.eks_jumphost_instance.instance_id,
      REGION      = var.region,
    }
  }
  triggers = {
    app = sha1(join("", [for file in fileset(path.cwd, "app/**") : filesha1(file)])),
  }

  depends_on = [
    module.eks,
  ]
}
