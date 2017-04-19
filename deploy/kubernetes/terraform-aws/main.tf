provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_security_group" "k8s-security-group" {
  name        = "md-k8s-security-group"
  description = "allow all internal traffic, ssh, http from anywhere"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = "true"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9411
    to_port     = 9411
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30002
    to_port     = 30002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
   from_port   = 31601
   to_port     = 31601
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ci-microserv-k8s-master" {
  instance_type   = "${var.master_instance_type}"
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.k8s-security-group.name}"]
  tags {
    Name = "ci-microserv-k8s-master"
  }

  connection {
    user = "ubuntu"
    private_key = "${file("${var.private_key_path}")}"
  }

#  provisioner "file" {
#    source = "deploy/kubernetes/manifests"
#    destination = "/tmp/"
#  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni",
      "sudo curl -s -o /usr/bin/kubeadm https://heptio-aws-quickstart-test.s3.amazonaws.com/heptio/kubernetes/ken-test/kubeadm && sudo chmod 0755 /usr/bin/kubeadm", #quick fix for kubeadm v1.6
      "sudo systemctl daemon-reload && sudo systemctl enable docker && sudo systemctl enable kubelet && sudo systemctl start docker",
      "sudo kubeadm init --token ${var.k8s_token}",
      "sudo systemctl daemon-reload && sudo systemctl restart kubelet",
      "sudo cp /etc/kubernetes/admin.conf $HOME/ && sudo chown $(id -u):$(id -g) $HOME/admin.conf && export KUBECONFIG=$HOME/admin.conf && echo 'export KUBECONFIG=$HOME/admin.conf' >> $HOME/.profile",
      "echo 'Waiting 10 sec...' && sleep 10 && kubectl apply -f https://git.io/weave-kube-1.6"
    ]
  }
}

resource "aws_instance" "ci-microserv-k8s-node" {
  instance_type   = "${var.node_instance_type}"
  count           = "${var.node_count}"
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.k8s-security-group.name}"]
  tags {
    Name = "ci-microserv-k8s-node"
  }

  connection {
    user = "ubuntu"
    private_key = "${file("${var.private_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee --append /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni",
      "sudo curl -s -o /usr/bin/kubeadm https://heptio-aws-quickstart-test.s3.amazonaws.com/heptio/kubernetes/ken-test/kubeadm && sudo chmod 0755 /usr/bin/kubeadm", #quick fix for kubeadm v1.6
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo systemctl daemon-reload && sudo systemctl enable docker && sudo systemctl enable kubelet && sudo systemctl start docker",
      "echo 'Waiting 30 sec...' && sleep 30 && for i in $(seq 10); do echo 'kubeadm join $i' && sudo kubeadm join --token ${var.k8s_token} ${aws_instance.ci-microserv-k8s-master.private_ip}:6443 && break || sleep 15; done"
    ]
  }
}

resource "aws_elb" "ci-microserv-k8s-elb" {
  depends_on = [ "aws_instance.ci-microserv-k8s-node" ]
  name = "ci-microserv-k8s-elb"
  instances = ["${aws_instance.ci-microserv-k8s-node.*.id}"]
  availability_zones = ["${data.aws_availability_zones.available.names}"]
  security_groups = ["${aws_security_group.k8s-security-group.id}"] 
  listener {
    lb_port = 80
    instance_port = 30001
    lb_protocol = "http"
    instance_protocol = "http"
  }

  listener {
    lb_port = 9411
    instance_port = 30002
    lb_protocol = "http"
    instance_protocol = "http"
  }

}

