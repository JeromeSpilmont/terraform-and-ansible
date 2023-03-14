

#Providers
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region 
}

#Data
data "aws_ami" "aws_linux" {
    most_recent = true
    owners = ["amazon"]
  
  filter {
    name = "name"
    values =["amzn-ami-hvm*"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]  
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# ne fonctionne pas
# data "template_file" "user_data" {
#  template = "./userdata.yaml"
# }



#resources
#Default vpc

resource "aws_default_vpc" "default" {
  
}

resource "aws_security_group" "allow_ssh_http_80" {
    name = "allow_ssh_http"
    description = "allow ssh on 22 & http on 80"
    vpc_id = aws_default_vpc.default.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  
}

resource "aws_instance" "server_apache" {
  ami             = data.aws_ami.aws_linux.id 
  instance_type   = "t2.micro" 
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http_80.id] 

  tags = {
    Name = var.host
  }

  #user_data - upgrade et installations de base sur l'instance 
  #user_data = file("./userdata.sh")

  connection {
    type   = "ssh"
    host  = self.public_ip
    user   ="ec2-user"
    private_key = file(var.private_key_path)
  } 
}







# OUTPUTS
# Public DNS
output "aws_instance_public_dns" {
    value = aws_instance.server_apache.public_dns 
}

# Public IP
output "op1" {
  value = aws_instance.server_apache.public_ip
}

resource "local_file" "ip" {
  content = aws_instance.server_apache.public_ip
  filename = "ip.txt"
}

# ebs volume created 
resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.server_apache.availability_zone
  size = 1
  tags = {
    name = "myterraebs"
  }
}

# ebs volume attached 
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.ebs.id
  instance_id = aws_instance.server_apache.id
  force_detach = true
}

# Device name of ebs (Amazon Elastic Block Store)
output "op2" {
  value = aws_volume_attachment.ebs_att.device_name
}

# Connecting ansible from local system
resource "null_resource" "nullremote1" {
  depends_on = [ aws_instance.server_apache ]

  connection {
    type   = "ssh"
    host  = aws_instance.server_apache.public_dns
    user   ="ec2-user"
    private_key = file(var.private_key_path)
  } 

  #copying the init script to the aws instance from local system
  provisioner "file" {
    source = "userdata.sh"
    destination = "/home/ec2-user/userdata.sh"
  }

  #copying the playbook to the aws instance from local system
  provisioner "file" {
    source = "playbook.yaml"
    destination = "/home/ec2-user/playbook.yaml"
  }

  #copying ip.txt to the aws instance from local system
  provisioner "file" {
    source = "ip.txt"
    destination = "/home/ec2-user/ip.txt"
  }

}


#connecting to the linux OS having the ansible playbook
resource "null_resource" "nullremote2" {
  depends_on = [aws_volume_attachment.ebs_att]

  connection {
    type   = "ssh"
    host  = aws_instance.server_apache.public_dns
    user   ="ec2-user"
    private_key = file(var.private_key_path)
  } 

  #run the script on remote instance
  provisioner "remote-exec" {
    inline = [
      "sh /home/ec2-user/userdata.sh",
      "echo 'export PATH=\"/home/ec2-user/.local/bin:$PATH\"' >>  ~/.bashrc",
      "source ~/.bashrc"
    ]     
  }


  provisioner "remote-exec" {
    inline = [
      "ansible-playbook /home/ec2-user/playbook.yaml"
    ]    
  }
}