
# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA

}

resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.demo-node.name
  image_id = "ami-0eeeef929db40543c"
  instance_type = "t2.large"
  name_prefix = "terraform-eks-demo"
  security_groups = [aws_security_group.demo-node.id]
  user_data_base64 = base64encode(local.demo-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo" {
  desired_capacity = 2
  launch_configuration = aws_launch_configuration.demo.id
  max_size = 2
  min_size = 1
  name = "terraform-eks-demo"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  vpc_zone_identifier = ["subnet-0441e75bd082ee4da", "subnet-0647b9f4903da0b2a", "subnet-094925b6601e292bb"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-main"
    propagate_at_launch = true
  }
  tag {
    key                 = "ApplicationOwner"
    value               = "Pradeep Shinde"
    propagate_at_launch = true
  }
  tag {
    key                 = "Description"
    value               = "EKS cluster using terraform"
    propagate_at_launch = true
  }
  tag {
    key                 = "ProductTower"
    value               = "WU:CCOE_Pune"
    propagate_at_launch = true
  }
  tag {
    key                 = "SupportContact"
    value               = "ioc_ccoe@westernunion.com"
    propagate_at_launch = true
  }
  tag {
    key                 = "privx-ssh-principals"
    value               = "ec2-user=APP-Privx-Proxy"
    propagate_at_launch = true
  }
}

