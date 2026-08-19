provider "aws" {
  region                      = "eu-south-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# 1. Bucket S3 Seguro
resource "aws_s3_bucket" "dados_sensiveis" {
  # checkov:skip=CKV_AWS_144: Cross-region replication nao e necessaria para este ambiente.
  # checkov:skip=CKV2_AWS_62: Event notifications nao configuradas neste laboratorio.
  bucket = "empresa-dados-sensiveis-rh"
}

resource "aws_s3_bucket_public_access_block" "dados_sensiveis_acesso" {
  bucket = aws_s3_bucket.dados_sensiveis.id

  # Correcao: Bloqueio total de acesso publico
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dados_sensiveis_versioning" {
  bucket = aws_s3_bucket.dados_sensiveis.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Security Group Hardened
resource "aws_security_group" "servidor_web_sg" {
  name        = "web-server-sg"
  description = "Security group para o servidor web com acessos restritos"

  ingress {
    description = "Permite SSH apenas da rede interna (VPN)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Correcao: Removido o 0.0.0.0/0. Acesso restrito a um IP/Range especifico.
    cidr_blocks = ["10.0.0.0/8"] 
  }

  egress {
    description = "Permite trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # checkov:skip=CKV_AWS_382: Permitimos egress total para o servidor fazer download de patches.
    cidr_blocks = ["0.0.0.0/0"]
  }
}
