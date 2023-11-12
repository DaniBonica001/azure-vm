
# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.name_machine}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

#Se crea la interfaz de red
resource "azurerm_network_interface" "network_interface" {
  name                = "${var.name_machine}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Se crea el grupo de seguridad y las reglas
resource "azurerm_network_security_group" "security_group" {
  name                = "acceptanceTestSecurityGroup1"
  location            = var.location
  resource_group_name = var.resource_group_name

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

resource "azurerm_network_security_rule" "rule_icmp" {
  name                       = "PING"
  priority                   = 1000
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Icmp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "rule_tcp9000" {
  name                       = "Sonarqube"
  priority                   = 1002
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "9000"
  source_address_prefix      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "rule_tcp8080" {
  name                       = "Tcp8080"
  priority                   = 1003
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}


#Asociar interfaz con el grupo de seguridad
resource "azurerm_network_interface_security_group_association" "association_interface_security" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.security_group.id
}

#Se crea la máquina virtual de linux
resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  name                = "modular-virtual-machine"
  location            = var.location
  resource_group_name = var.resource_group_name
  size               = "Standard_F2"
  admin_username      = "adminuser"                                   # 
  admin_password      = "P@$$w0rd1234!"  
  disable_password_authentication = false  
  network_interface_ids = [
    azurerm_network_interface.network_interface.id
  ]

  # Configuración del disco del sistema operativo
  os_disk {
    caching              = "ReadWrite"                                # Caché de disco en modo lectura/escritura
    storage_account_type = "Standard_LRS"                             # Tipo de cuenta de almacenamiento
  }

  # Especificación de la imagen del sistema operativo
  source_image_reference {
    publisher = "Canonical"                                            # Editor de la imagen
    offer     = "0001-com-ubuntu-server-focal"                         # Oferta de la imagen
    sku       = "20_04-lts"                                            # SKU de la imagen
    version   = "latest"                                               # Versión de la imagen
  }

  
}