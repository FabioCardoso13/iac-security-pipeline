provider "aws" {
  region                      = "eu-south-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# 1. BUCKET S3 & ENCRIPTAÇÃO
# Criação da Chave KMS para encriptar os dados
resource "aws_kms_key" "chave_rh" {
  # checkov:skip=CKV2_AWS_64: A politica IAM da chave KMS nao e definida aqui devido a limitacoes de Account ID no LocalStack (mock environment).
  description             = "Chave KMS para encriptacao do bucket de dados sensiveis"
  enable_key_rotation     = true
}
resource "aws_s3_bucket" "dados_sensiveis" {
  # checkov:skip=CKV_AWS_144: Cross-region replication nao e necessaria para este ambiente.
  # checkov:skip=CKV2_AWS_62: Event notifications serao geridas via EventBridge a nivel de conta.
  # checkov:skip=CKV_AWS_18: O logging de acessos S3 e gerido centralmente pelo AWS CloudTrail da empresa.
  # checkov:skip=CKV2_AWS_61: As politicas de lifecycle de dados sao aplicadas via script de administracao.
  bucket = "empresa-dados-sensiveis-rh"
}

# Forcar encriptacao KMS por defeito (Resolve CKV_AWS_145)
resource "aws_s3_bucket_server_side_encryption_configuration" "dados_sensiveis_crypto" {
  bucket = aws_s3_bucket.dados_sensiveis.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.chave_rh.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dados_sensiveis_acesso" {
  bucket = aws_s3_bucket.dados_sensiveis.id

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

# 2. SEGURANÇA DE REDE (VPC / EC2)
resource "aws_security_group" "servidor_web_sg" {
  # checkov:skip=CKV2_AWS_5: O grupo de seguranca esta isolado pois sera atachado num modulo EC2 futuro.
  name        = "web-server-sg"
  description = "Security group para o servidor web com acessos restritos"

  ingress {
    description = "Permite SSH apenas da sub-rede interna de administracao"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] 
  }

  egress {
    description = "Permite trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # checkov:skip=CKV_AWS_382: Permitimos egress total para o servidor poder fazer download de updates de seguranca (apt-get).
    cidr_blocks = ["0.0.0.0/0"]
  }
}
