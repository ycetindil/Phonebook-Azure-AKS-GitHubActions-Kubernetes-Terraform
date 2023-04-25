terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.39.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ycetindil"
    storage_account_name = "ycetindil"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}

provider "github" {
}

######################
### RESOURCE GROUP ###
######################
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

###########
### AKS ###
###########
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "${var.prefix}"

  default_node_pool {
    name       = var.prefix
    node_count = 1
    vm_size    = "Standard_D2as_v4"
  }

  identity {
     type = "SystemAssigned"
  }
}

# ###########
# ### NSG ###
# ###########
# data "azurerm_resources" "nsg" {
#   resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
#   type                = "Microsoft.Network/networkSecurityGroups"
#   depends_on = [
#     azurerm_kubernetes_cluster.aks
#   ]
# }

# resource "azurerm_network_security_rule" "nsg" {
#   name                        = "AllowNodePorts"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "30000-32767"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_kubernetes_cluster.aks.node_resource_group
#   network_security_group_name = data.azurerm_resources.nsg.resources.0.name
# }

#####################
### LOAD BALANCER ###
#####################
data "azurerm_lb" "lb" {
  name                = "Kubernetes"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_lb_probe" "hp30001" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "hp-30001"
  port            = 30001
}

resource "azurerm_lb_probe" "hp30002" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "hp-30002"
  port            = 30002
}

data "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "kubernetes"
  loadbalancer_id = data.azurerm_lb.lb.id
}

resource "azurerm_lb_rule" "lbrule30001" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "lbrule-30001"
  protocol                       = "Tcp"
  frontend_port                  = 30001
  backend_port                   = 30001
  frontend_ip_configuration_name = "${data.azurerm_lb.lb.frontend_ip_configuration.0.name}"
  backend_address_pool_ids       = [data.azurerm_lb_backend_address_pool.backend_pool.id]
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "lbrule30002" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "lbrule-30002"
  protocol                       = "Tcp"
  frontend_port                  = 30002
  backend_port                   = 30002
  frontend_ip_configuration_name = "${data.azurerm_lb.lb.frontend_ip_configuration.0.name}"
  backend_address_pool_ids       = [data.azurerm_lb_backend_address_pool.backend_pool.id]
  disable_outbound_snat          = true
}

##################
### PUBLIC IPS ###
##################
data "azurerm_public_ips" "pips" {
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  attachment_status   = "Attached"
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

################################
### GITHUB ACTIONS VARIABLES ###
################################
resource "github_actions_variable" "rg_name" {
  repository       = var.github_repo
  variable_name    = "RG_NAME"
  value            = azurerm_resource_group.rg.name
}

resource "github_actions_variable" "aks_name" {
  repository       = var.github_repo
  variable_name    = "AKS_NAME"
  value            = azurerm_kubernetes_cluster.aks.name
}

resource "github_actions_variable" "aks_node_rg_name" {
  repository       = var.github_repo
  variable_name    = "AKS_NODE_RG_NAME"
  value            = azurerm_kubernetes_cluster.aks.node_resource_group
}