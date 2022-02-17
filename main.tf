data "aws_ami" "amazon_linux_2_ami" {
  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-ebs",
    ]
  }
  most_recent = true
  owners = [
    "amazon",
  ]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      identifiers = [
        "ec2.${data.aws_partition.current.dns_suffix}",
      ]
      type = "Service"
    }
  }
}

data "aws_partition" "current" {}

resource "aws_iam_instance_profile" "instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.role.name
  tags = merge(
    {
      Name = var.instance_profile_name,
    },
    var.tags,
  )
}

resource "aws_iam_role" "role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
  name = var.role_name
  tags = merge(
    var.tags,
    {
      Name = var.role_name,
    },
  )
}

resource "aws_instance" "instance" {
  ami                         = data.aws_ami.amazon_linux_2_ami.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  instance_type               = var.instance_type
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  monitoring = var.monitoring
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = var.kms_key_id
    volume_type           = "gp3"
  }
  subnet_id = var.subnet_id
  tags = merge(
    var.tags,
    {
      Name = var.instance_name,
    },
  )
  volume_tags = merge(
    var.tags,
    {
      Name = var.instance_name,
    },
  )
  vpc_security_group_ids = [
    aws_security_group.security_group.id,
  ]
}

resource "aws_security_group" "security_group" {
  description = "Security group for the instance ${var.instance_name}"
  egress {
    cidr_blocks      = var.https_egress_cidr_blocks # tfsec:ignore:aws-vpc-no-public-egress-sgr
    description      = "Allow HTTPS egress traffic to the specified CIDR blocks"
    from_port        = 443
    ipv6_cidr_blocks = var.https_egress_ipv6_cidr_blocks # tfsec:ignore:aws-vpc-no-public-egress-sgr
    protocol         = "tcp"
    to_port          = 443
  }
  name = var.security_group_name
  tags = merge(
    var.tags,
    {
      Name = var.security_group_name,
    },
  )
  vpc_id = var.vpc_id
}
