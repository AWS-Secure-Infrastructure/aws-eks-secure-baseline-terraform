resource "kubernetes_namespace" "secure_apps" {
  metadata {
    name = "secure-apps"

    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_network_policy" "default_deny" {
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.secure_apps.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
  }
}

resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  namespace  = "gatekeeper-system"

  create_namespace = true
}

resource "aws_iam_role" "example_irsa_role" {
  name = "example-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${replace(module.eks.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:secure-apps:example-sa"
        }
      }
    }]
  })
}

resource "kubernetes_manifest" "constraint_template" {
  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1beta1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8srequiredresources"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sRequiredResources"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<EOF
package k8srequiredresources

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.resources.limits.cpu
  msg := "CPU limit is required"
}

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.resources.limits.memory
  msg := "Memory limit is required"
}
EOF
      }]
    }
  }

  depends_on = [helm_release.gatekeeper]
}

resource "kubernetes_manifest" "require_limits" {
  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sRequiredResources"
    metadata = {
      name = "require-resource-limits"
    }
    spec = {
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.constraint_template]
}
