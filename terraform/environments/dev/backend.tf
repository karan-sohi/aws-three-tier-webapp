
terraform {
  backend "s3" {
    bucket         = "aws-three-tier-webapp-tfstate-6a9015e6"
    key            = "aws-three-tier-webapp/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-three-tier-webapp-tfstate-lock"
    encrypt        = true
  }
}
