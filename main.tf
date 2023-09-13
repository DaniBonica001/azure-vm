# Definición del provider que ocuparemos
provider "azurerm" {
  features {}
}

# Se crea el grupo de recursos, al cual se asociarán los demás recursos
resource "azurerm_resource_group" "vm" {
  name     = var.name_machine
  location = var.location
}

# Se crea un Storage Account, para asociarlo al function app (recomendación de la documentación).
resource "azurerm_storage_account" "sa" {
  name                     = var.name_machine
  resource_group_name      = azurerm_resource_group.vm.name
  location                 = azurerm_resource_group.vm.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Se crea el recurso Service Plan para especificar el nivel de servicio 
# (por ejemplo, "Consumo", "Functions Premium" o "Plan de App Service"), en este caso "Y1" hace referencia a plan consumo 
resource "azurerm_service_plan" "sp" {
  name                = var.name_machine
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

#Se crea la red
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_machine}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
}

#Se crea la subred
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.name_machine}-public-ip"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Static"
}


#Se crea la interfaz de red
resource "azurerm_network_interface" "main" {
  name                = "${var.name_machine}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Se crea el grupo de seguridad
resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix  = "*"
    }


  tags = {
    environment = "Production"
  }
}

#Asociar interfaz con el grupo de seguridad
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.example.id
}

#Se crea la máquina virtual
resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/danie/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}