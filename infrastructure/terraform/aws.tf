provider "aws" {
	region = "us-west-2"
}

resource "aws_ecr_repository" "service" {
  name = "magic-8-ball"
}

resource "aws_ecs_cluster" "cluster" {
  name = "magic-8-ball-cluster"
}

resource "aws_ecs_task_definition" "service" {
  family = "start-magic-8-ball"
  container_definitions = "${file("task-definitions/service.json")}"

  volume {
    name = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2]"
  }
}

resource "aws_instance" "web" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    tags {
        Name = "magic-8-ball"
    }
}

# Generate SSL cert
resource "aws_iam_server_certificate" "test_cert" {
  name = "some_test_cert"
  certificate_body = "${file("cert.pem")}"
  private_key = "${file("key.pem")}"
	lifecycle {
    create_before_destroy = true
  }
}

# Create a new load balancer
resource "aws_elb" "foo" {
  name = "magic-8-ball-elb"
  availability_zones = ["us-west-2"]

  access_logs {
    bucket = "foo"
    bucket_prefix = "bar"
    interval = 60
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
		ssl_certificate_id = "${aws_iam_server_certificate.test_cert.arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8000/"
    interval = 30
  }

  instances = ["${aws_instance.web.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "magic-8-ball-elb"
  }
}

resource "aws_ecs_service" "magic-8-ball-service" {
  name = "magic-8-ball-service"
  cluster = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.service.id}"
  desired_count = 1
  iam_role = "ecsInstanceRole"

  placement_strategy {
    type = "binpack"
    field = "cpu"
  }

	load_balancer {
    elb_name = "${aws_elb.foo.name}"
    container_name = "magic-8-ball"
    container_port = 8080
  }

  placement_constraints {
    type = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2]"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
    name = "web_config"
    image_id = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
}
