terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }

  # Backend configuration to store the state in Azure Blob Storage
  backend "azurerm" {
    resource_group_name   = "Origen.AI_ResourceGroup"  
    storage_account_name  = "origenaiterraform"      
    container_name        = "terraformstate"           
    key                   = "terraform.tfstate"        
  }
}

provider "azurerm" {
  features {}
  subscription_id            = "80f75c38-5d92-4b55-a1f9-4f39d5a25871"  
  skip_provider_registration = true
}

# Resource Group for AKS Cluster
resource "azurerm_resource_group" "aks" {
  name     = "Origen.AI_ResourceGroup"
  location = "West US"
}

# AKS Cluster creation
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "origen-ai-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "origenaks"

  default_node_pool {
    name              = "default"
    node_count        = 2
    vm_size           = "Standard_D2_v2"
    enable_auto_scaling = true
    min_count         = 2
    max_count         = 5

    node_labels = {
      architecture = "amd64"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
  }
}

# Create kubeconfig file from AKS cluster
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "${path.module}/kubeconfig"
}

# Kubernetes provider to use kubeconfig
provider "kubernetes" {
  config_path = local_file.kubeconfig.filename  
}

# Helm provider to use kubeconfig
provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename  
  }
}

# Helm chart for deploying the Web application (frontend)
resource "helm_release" "frontend" {
  name       = "frontend-app"
  chart      = "./deployrepohelm"  
  namespace  = "default"

  set {
    name  = "image.repository"
    value = "origenai/cloud-engineer-test-sample-app-frontend"
  }

  set {
    name  = "image.tag"
    value = "1.0.0"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]  
}

# Helm chart for deploying the Backend application (API)
resource "helm_release" "api" {
  name       = "api-app"
  chart      = "./deployrepohelm"  
  namespace  = "default"

  set {
    name  = "image.repository"
    value = "origenai/cloud-engineer-test-sample-app-backend"
  }

  set {
    name  = "image.tag"
    value = "1.0.0"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "MONGO_URL"
    value = "mongodb://mongo-service:27017"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]  
}

# Helm chart for MongoDB deployment with hardcoded credentials
resource "helm_release" "mongo" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = "default"

  set {
    name  = "auth.rootPassword"
    value = "myrootpassword"  
  }

  set {
    name  = "auth.username"
    value = "myusername"  
  }

  set {
    name  = "auth.database"
    value = "admin"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]  
}

# Horizontal Pod Autoscaler for Backend
resource "kubernetes_horizontal_pod_autoscaler_v2" "api_hpa" {
  metadata {
    name      = "api-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = helm_release.api.metadata[0].name
    }
    min_replicas = 2
    max_replicas = 10
    metric {
      type = "Resource"
      resource {
        name  = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]  
}

