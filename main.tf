provider "azurerm" {
  features {
    storage {
      data_plane_access_on_create_enabled = false
    }
  }
}

resource "azurerm_resource_group" "main" {
  name     = "storage-account-no-dataplane"
  location = "sweden central"
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "web" {
  name                = "privatelink.web.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "web" {
  name                  = "test"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.web.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "test"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "testqueue"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.main.id
}


resource "azurerm_virtual_network" "main" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
}

resource "azurerm_subnet" "main" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "dns" {
  name                 = "example-subnet-2"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "examplepip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "example" {
  name                = "examplebastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.example.id
  }
}



resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dns.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  lifecycle {
    ignore_changes = [
           identity,
            patch_assessment_mode,
            patch_mode,
             bypass_platform_safety_checks_on_user_schedule_enabled
    ]
  }
}



resource "azurerm_storage_account" "main" {
  name                     = "lab2468790"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  allow_nested_items_to_be_public = false

  public_network_access_enabled = false
}


resource "azurerm_private_endpoint" "storageep" {
  name                = "lab2468790-private-endpoint" 
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = "lab2468790-private-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  
  

  private_dns_zone_group {
    name                  = "storage-private-endpoint-dns-zone-group"
    private_dns_zone_ids  = [azurerm_private_dns_zone.main.id]
    //visibility            = "Private"
  }
  //tags = azurerm_resource_group.main.tags
}

resource "azurerm_private_endpoint" "storageepq" {
  name                = "lab2468790-private-endpoint-q" 
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = "lab2468790-private-endpoint-connection-q"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
  
  

  private_dns_zone_group {
    name                  = "storage-private-endpoint-dns-zone-group-q"
    private_dns_zone_ids  = [azurerm_private_dns_zone.queue.id]
    //visibility            = "Private"
  }
  //tags = azurerm_resource_group.main.tags
}

resource "azurerm_private_endpoint" "storageepweb" {
  name                = "lab2468790-private-endpoint-web" 
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = "lab2468790-private-endpoint-connection-web"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  
  

  private_dns_zone_group {
    name                  = "storage-private-endpoint-dns-zone-group-q"
    private_dns_zone_ids  = [azurerm_private_dns_zone.web.id]
    //visibility            = "Private"
  }
  //tags = azurerm_resource_group.main.tags
}
