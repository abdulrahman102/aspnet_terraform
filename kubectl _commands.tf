

# ebs storage class
resource "kubectl_manifest" "ebs-storage-class" {
  yaml_body = file("yaml_files/ebs_storage_class.yaml")
}

# mongodb deployment
resource "kubectl_manifest" "mongodb-secrets" {
  yaml_body = file("yaml_files/mongodb_secrets.yaml")
  depends_on = [ kubectl_manifest.ebs-storage-class ]
}

resource "kubectl_manifest" "mongodb-deployment" {
  yaml_body = file("yaml_files/mongodb_statefulset.yaml")
  depends_on = [ kubectl_manifest.mongodb-secrets]
}

resource "kubectl_manifest" "mongodb-service" {
  yaml_body = file("yaml_files/mongodb_service.yaml")
  depends_on = [ kubectl_manifest.mongodb-deployment ]
}


# redis deployment
resource "kubectl_manifest" "redis-config" {
  yaml_body = file("yaml_files/redis_config_map.yaml")
  depends_on = [ kubectl_manifest.ebs-storage-class ]
}

resource "kubectl_manifest" "redis-deployment" {
  yaml_body = file("yaml_files/redis_statefulset.yaml")
  depends_on = [ kubectl_manifest.redis-config ]
}

resource "kubectl_manifest" "redis-service" {
  yaml_body = file("yaml_files/redis_service.yaml")
  depends_on = [ kubectl_manifest.redis-service ]

}


# mssql deployment
resource "kubectl_manifest" "mssql-secrets" {
  yaml_body = file("yaml_files/redis_config_map.yaml")
  depends_on = [ kubectl_manifest.ebs-storage-class ]

}

resource "kubectl_manifest" "mssql-deployment" {
  yaml_body = file("yaml_files/redis_statefulset.yaml")
  depends_on = [ kubectl_manifest.mssql-secrets ]
}

resource "kubectl_manifest" "mssql-service" {
  yaml_body = file("yaml_files/redis_service.yaml")
  depends_on = [ kubectl_manifest.mssql-deployment ]
}

# aspnet aaplication deployment (make sure that the image in a hub ecr or docker hub)
resource "aws_ebs_volume" "ebs_storage" {
  availability_zone = "us-east-1c"
  size              = 100

  tags = {
    Name = "ebs_storage"
  }
}
resource "kubectl_manifest" "aspnet-pv" {
  yaml_body = file("yaml_files/aspnet_pv.yaml")
  depends_on = [ aws_ebs_volume.ebs_storage ]
}

resource "kubectl_manifest" "aspnet-pvc" {
  yaml_body = file("yaml_files/aspnet_pvc.yaml")
  depends_on = [ kubectl_manifest.aspnet-pv ]
}

resource "kubectl_manifest" "aspnet-secrets" {
  yaml_body = file("yaml_files/aspnet_secrets.yaml")
  epends_on = [ aws_ebs_volume.ebs_storage ]
}

resource "kubectl_manifest" "aspnet-deployment" {
  yaml_body = file("yaml_files/aspnet_deployment.yaml")
  depends_on = [ kubectl_manifest.aspnet-secrets, kubectl_manifest.mongodb-service, kubectl_manifest.mssql-service, kubectl_manifest.kubectl_manifest.redis-service ]

}

resource "kubectl_manifest" "aspnet-service" {
  yaml_body = file("yaml_files/aspnet_service.yaml")
  depends_on = [ kubectl_manifest.aspnet-deployment]

}

# attaching ssl to specific domain name and create lb manifestaion and attach the certificate to the hostname
resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = var.domain_name 
  validation_method = "DNS"
}

resource "kubernetes_ingress_v1" "alb_ingress" {
  depends_on = [ aws_acm_certificate.ssl_cert,kubectl_manifest.aspnet-service ]
  metadata {
    name = "example-ingress"
    namespace = "default"  
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" =  "5"
      "alb.ingress.kubernetes.io/success-codes" = "200"
      "alb.ingress.kubernetes.io/healthy-threshold-count" = "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = "2"
      "alb.ingress.kubernetes.io/certificate-arn"        = aws_acm_certificate.ssl_cert.arn
      "alb.ingress.kubernetes.io/ssl-policy"             = "ELBSecurityPolicy-2016-08"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/actions.ssl-redirect"   = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
      # External DNS - For creating a Record Set in Route53
      "external-dns.alpha.kubernetes.io/hostname" = "dnstest1.kubeoncloud.com, dnstest2.kubeoncloud.com"   
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = "aspnet-service"
              port {
                name = "use-annotation"
              }
            }
          }

          path = "/"
        }
      }
    }
/* 
    tls {
      secret_name = "tls-secret" # another way of confirming the certificate by its credentials 
    } */
  }
} 

resource "aws_route53_zone" "aspnet_domain" {
  name = var.domain_name
}

resource "aws_route53_record" "aspnet_domain_record" {
  depends_on = [ kubernetes_ingress_v1.alb_ingress ]
  zone_id = aws_route53_zone.example_domain.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.example.status.0.load_balancer.0.ingress.0.hostname
    evaluate_target_health = true
  }
}

output "ingress_hostname" {
  value = kubernetes_ingress_v1.example.status.0.load_balancer.0.ingress.0.hostname
}

