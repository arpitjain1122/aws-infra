resource "aws_db_parameter_group" "parameter_group" {
  name        = "pg-cloud-db"
  family      = "mysql8.0"
  description = "cloud RDS parameter group"
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 10
  identifier             = var.identifier
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = "db.t3.micro"
  username               = var.username
  password               = var.password
  parameter_group_name   = aws_db_parameter_group.parameter_group.name
  skip_final_snapshot    = true
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [var.security_group_id]
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.webapp-kms-rds.arn


  //Set it to false.
  publicly_accessible = false
}

output "host_name" {
  value = aws_db_instance.rds_instance.address
}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "webapp-kms-rds" {

  # alias_name = "webapp-kms-rds"

  description = "RDS Encryption key"

  key_usage = "ENCRYPT_DECRYPT"

  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  deletion_window_in_days = 7

  policy = jsonencode({


    "Id" : "key-consolepolicy-3",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
            {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}
