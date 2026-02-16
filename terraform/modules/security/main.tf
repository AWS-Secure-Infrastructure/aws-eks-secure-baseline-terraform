# Secure Namespace (Pod Security Admission - restricted)

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

# Default Deny Network Policy

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

# OPA Gatekeeper Installation

resource "helm_release" "gatekeeper" {
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  namespace        = "gatekeeper-system"
  create_namespace = true
}

# Constraint Template (Require CPU & Memory Limits)

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

# Constraint Instance

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
