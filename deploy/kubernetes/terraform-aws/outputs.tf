output "node_addresses" {
  value = ["${aws_instance.ci-microserv-k8s-node.*.public_dns}"]
}

output "master_address" {
  value = "${aws_instance.ci-microserv-k8s-master.public_dns}"
}

output "micro_serv_address" {
  value = "${aws_elb.ci-microserv-k8s-elb.dns_name}"
}
