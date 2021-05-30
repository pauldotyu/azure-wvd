provider "azurerm" {
  features {}
}

resource "random_pet" "wvd" {
  length    = 2
  separator = ""
}

data "azurerm_subscription" "current" {}

##############################################
# AZURE IMAGE BUILDER
##############################################

resource "azurerm_resource_group" "wvd" {
  name     = "rg-${random_pet.wvd.id}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "wvd" {
  name                = "mi-${random_pet.wvd.id}"
  resource_group_name = azurerm_resource_group.wvd.name
  location            = azurerm_resource_group.wvd.location
  tags                = var.tags
}

resource "azurerm_role_definition" "wvd" {
  name        = "role-${random_pet.wvd.id}"
  scope       = data.azurerm_subscription.current.id
  description = "Azure Image Builder access to create resources for the image build"

  permissions {
    actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
    azurerm_resource_group.wvd.id
  ]
}

resource "azurerm_role_assignment" "wvd" {
  scope              = azurerm_resource_group.wvd.id
  role_definition_id = azurerm_role_definition.wvd.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.wvd.principal_id
}

resource "azurerm_shared_image_gallery" "wvd" {
  name                = "sig${random_pet.wvd.id}"
  resource_group_name = azurerm_resource_group.wvd.name
  location            = azurerm_resource_group.wvd.location
  tags                = var.tags
}

resource "azurerm_shared_image" "wvd" {
  name                = "windows-${random_pet.wvd.id}"
  gallery_name        = azurerm_shared_image_gallery.wvd.name
  resource_group_name = azurerm_resource_group.wvd.name
  location            = azurerm_resource_group.wvd.location
  os_type             = "Windows"

  identifier {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
  }
}