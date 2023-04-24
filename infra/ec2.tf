resource "aws_security_group" "allow_all" {
  name        = "${local.instance_name}-allow-all"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.instance_name}-allow-all"
  }
}

resource "null_resource" "generate_key_pair" {
  provisioner "local-exec" {
    command = "test -f ${local.instance_name}_id_rsa || ssh-keygen -t rsa -b 2048 -f ${local.instance_name}_id_rsa -N ''"
  }
}

data "external" "generated_public_key" {
  depends_on = [null_resource.generate_key_pair]
  program    = ["sh", "-c", "echo \"{\\\"public_key\\\": \\\"$(cat ${local.instance_name}_id_rsa.pub)\\\"}\""]
}

resource "aws_key_pair" "hello-world-key-pair" {
  key_name   = "${local.instance_name}-key"
  public_key = data.external.generated_public_key.result["public_key"]
}

resource "aws_instance" "example" {
  ami           = "ami-0578f2b35d0328762" # Amazon Linux 2023
  instance_type = "t2.micro"

  subnet_id = local.subnet_id

  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = local.instance_name
  }

  key_name = aws_key_pair.hello-world-key-pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker -y
              usermod -a -G docker ec2-user
              systemctl enable docker.service
              systemctl start docker.service

              # pull from imohammd02 repo  
              docker pull ${local.docker_repo_name}

              # run on port 8090
              docker run -d --name hello-world-ec2 -p 8090:8090 ${local.docker_repo_name}:latest
              EOF
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
