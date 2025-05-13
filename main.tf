resource "aws_db_subnet_group" "subnet" {
  name       = "${var.name}-${var.env}"
  subnet_ids = var.subnets

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-rds"})

}


resource "aws_security_group" "sg" {
  name        = "${var.name}-${var.env}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    description = "RDS"
    from_port        = var.port_no
    to_port          = var.port_no
    protocol         = "tcp"
    cidr_blocks      = var.allow_db_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-sg"})
}

resource "aws_rds_cluster" "default" {
  cluster_identifier      = "${var.name}-${var.env}-cluster"
  engine                  = "aurora-mysql"
  engine_version          = var.engine_version
  database_name           = "dummy"
  master_username         = data.aws_ssm_parameter.db_user.value
  master_password         = data.aws_ssm_parameter.db_pass.value
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids = [aws_security_group.sg.id]
  db_subnet_group_name = aws_db_subnet_group.subnet.name
  skip_final_snapshot = true
  storage_encrypted = true
  kms_key_id = var.kms_arn
  tags = merge(var.tags, { Name = "${var.name}-${var.env}-cluster"})
}

resource "aws_db_parameter_group" "pg" {
  name   = "rds-pg"
  family = "aurora-mysql5.7"
}
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
  tags = merge(var.tags, { Name = "${var.name}-${var.env}-rds-${count.index+1}"})

}
