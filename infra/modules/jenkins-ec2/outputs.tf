# infra/modules/jenkins-ec2/outputs.tf
output "jenkins_public_ip" {
  description = "IP pública de la instancia Jenkins (EIP)"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "DNS público asignado a la instancia"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "URL HTTP de Jenkins"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_elastic_ip" {
  description = "Elastic IP fija asociada a Jenkins"
  value       = aws_eip.jenkins.public_ip
}
