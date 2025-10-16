data "aws_ami" "latest" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "main" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.latest.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    delete_on_termination = var.root_volume_delete_on_termination
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_encrypted ? var.kms_key_id : null
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.volume_type == "io1" || ebs_block_device.value.volume_type == "io2" ? ebs_block_device.value.iops : null
      throughput            = ebs_block_device.value.volume_type == "gp3" ? ebs_block_device.value.throughput : null
      delete_on_termination = ebs_block_device.value.delete_on_termination
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.encrypted ? var.kms_key_id : null
    }
  }

  monitoring = var.enable_detailed_monitoring

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = var.metadata_hop_limit
    instance_metadata_tags      = var.enable_metadata_tags ? "enabled" : "disabled"
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  disable_api_termination = var.disable_api_termination

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )

  volume_tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-volume"
    }
  )

  lifecycle {
    ignore_changes = var.ignore_ami_changes ? [ami] : []
  }
}

resource "aws_eip" "main" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )
}
