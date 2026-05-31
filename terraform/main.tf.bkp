
#---------------------------------------------
#                 TARGET GROUP               |
#---------------------------------------------
resource "aws_lb_target_group" "catalogue" {
  name     = "${local.name}-${var.tags.Component}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value

health_check {
  enabled             = true
  path                = "/health"       # The endpoint to ping
  port                = "8080"   # Use the same port traffic is sent to
  protocol            = "HTTP"
  healthy_threshold   = 2               # Consecutive passes to be 'Healthy'
  unhealthy_threshold = 3                # Consecutive failures to be 'Unhealthy'
  timeout             = 5                # Seconds to wait for a response
  interval            = 10               # Seconds between health checks
  matcher             = "200-299"        # Expected HTTP response codes
}
}

#---------------------------------------------
#                 INSTANCE CREATION           |
#---------------------------------------------
module "catalogue" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.rhel-9.id
  name = "${var.project}-${var.environment}-${var.tags.Component}-AMI"

  instance_type = "t3.micro"
  subnet_id     = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value),0)
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  create_security_group = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name = "${var.project}-${var.environment}-${var.tags.Component}"
  }
}

#---------------------------------------------
#                 INSTANCE PROVISIONING           |
#---------------------------------------------
resource "terraform_data" "catalogue" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers_replace = {
    instance_id = module.catalogue.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = module.catalogue.private_ip
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    bastion_host = data.aws_ssm_parameter.bastion_public_ip.value
    bastion_user = "ec2-user"
    bastion_password = "DevOps321"
    
  }
  
  provisioner "file" {
    source = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }


  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh ${var.tags.Component} ${var.environment} ${var.app_version}",
    ]
  }
}

# Stopping the instance 
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = module.catalogue.id
  state       = "stopped"
  depends_on = [terraform_data.catalogue]
}


#---------------------------------------------
#                 AMI CREATION               |
#---------------------------------------------

resource "aws_ami_from_instance" "catalogue" {
  name               = "${var.project}-${var.environment}-${var.tags.Component}-${local.timestamp}"
  source_instance_id = module.catalogue.id
  depends_on = [ aws_ec2_instance_state.catalogue ]
}

#---------------------------------------------
#               Launch Template              |
#---------------------------------------------

resource "aws_launch_template" "catalogue" {
  name = "${var.project}-${var.environment}-${var.tags.Component}"

  image_id = aws_ami_from_instance.catalogue.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-${var.environment}-${var.tags.Component}"
    }
  }
}

#---------------------------------------------
#               Autoscaling Group            |
#---------------------------------------------
resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project}-${var.environment}-${var.tags.Component}"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier       = [local.private_subnet_id]
  target_group_arns = [aws_lb_target_group.catalogue.arn]


  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  launch_template {
    id      = aws_launch_template.catalogue.id
    version = aws_launch_template.catalogue.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-${var.tags.Component}"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}


#---------------------------------------------
#           Autoscaling Group Policy         |
#---------------------------------------------
resource "aws_autoscaling_policy" "catalogue" {
 autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name                   = "${var.project}-${var.environment}-${var.tags.Component}"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 120

target_tracking_configuration {
    
    predefined_metric_specification {
    predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
}
}

#---------------------------------------------
#           Loadbalancer rule creation       |
#---------------------------------------------
resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value
  priority = 10

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }
  condition {
    host_header {
      values   = ["catalogue.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}

#---------------------------------------------
#              INSTANCE DELETION             |
#---------------------------------------------
resource "terraform_data" "catalogue_delete" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers_replace =  [module.catalogue.id]
  depends_on = [aws_autoscaling_policy.catalogue]

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "aws ec2 terminate-instances --instance-ids ${module.catalogue.id}"
  }
}



