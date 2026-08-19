provider "aws" {
  region                      = "eu-south-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# 1. Bucket S3 Inseguro (Público e sem encriptação)
resource "aws_s3_bucket" "dados_sensiveis" {
  bucket = "empresa-dados-sensiveis-rh"
}

resource "aws_s3_bucket_public_access_block" "dados_sensiveis_acesso" {
  bucket = aws_s3_bucket.dados_sensiveis.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 2. Security Group Inseguro (Aberto para o mundo)
resource "aws_security_group" "servidor_web_sg" {
  name        = "web-server-sg"
  description = "Permite trafego SSH de qualquer lado (Ma pratica!)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Alerta crítico: SSH exposto para a internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
