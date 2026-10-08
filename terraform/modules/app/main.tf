# App module
# One private EC2 instance running the Flask app under gunicorn + systemd.
# - No public IP, no SSH key: access is through SSM Session Manager.
# - IAM role: SSM core policy + read access to the one DB secret.
# - User data clones the repo, installs deps into a virtualenv and starts the service.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_region" "current" {}


data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# --- IAM ---

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-app-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "read_db_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "read_db_secret" {
  name   = "read-db-secret"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.read_db_secret.json
}

# EC2 can't take a role directly - it takes an instance profile that wraps the role.
resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-profile"
  role = aws_iam_role.app.name
}

# --- Instance ---

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [var.app_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    app_repo_url = var.app_repo_url
    app_repo_ref = var.app_repo_ref
    app_port     = var.app_port
    db_host      = var.db_address
    db_name      = var.db_name
    db_user      = var.db_username
    db_secret_id = var.db_secret_arn
    aws_region   = data.aws_region.current.name
  })

  user_data_replace_on_change = true

  # IMDSv2 only: credentials from the metadata service need a session token.
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-app"
    Tier = "app"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
