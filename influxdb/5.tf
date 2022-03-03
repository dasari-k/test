resource "azurerm_resource_group" "influx" {
  name     = "euw-prod-123-dcp-influxdb-rg"
  location = "West Europe"
}


data "azurerm_subnet" "influx" {
  name                 = var.influx_subnet_id
  resource_group_name  = var.vnet_resource_groupname 
  virtual_network_name = var.influx_vnet_name
}

resource "azurerm_network_interface" "influx" {
  name                = "influx-nic"
  location            = azurerm_resource_group.influx.location
  resource_group_name = azurerm_resource_group.influx.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.influx.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "influx" {
    name = "influx-nsg"
    location = azurerm_resource_group.influx.location  
    resource_group_name = azurerm_resource_group.influx.name
    security_rule {
        access = "Allow"
        direction = "Inbound"
        name = "influx-inbound"
        priority = 100
        protocol = "TCP"
        source_port_range          = "*"
        destination_port_range     = "8086"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        access = "Allow"
        direction = "Outbound"
        name = "influx-outbound"
        priority = 100
        protocol = "TCP"
        source_port_range          = "*"
        destination_port_range     = "8086"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        access = "Allow"
        direction = "Inbound"
        name = "ssh-inbound"
        priority = 101
        protocol = "TCP"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface_security_group_association" "influx" {
    network_interface_id  = azurerm_network_interface.influx.id
    network_security_group_id = azurerm_network_security_group.influx.id
}

resource "azurerm_linux_virtual_machine" "influx" {
  name                = "influx-machine"
  resource_group_name = azurerm_resource_group.influx.name
  location            = azurerm_resource_group.influx.location
  size                = "Standard_DS2_v2"
  admin_username      = "adminuser"
  admin_password      = var.vm_password
  network_interface_ids = [
    azurerm_network_interface.influx.id,
  ]

  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "null_resource" "install-influxDb" {
  provisioner "local-exec" {
    command = <<EOT
    az login --service-principal --username "${var.service_principal_id}" --password "${var.service_principal_secret}" --tenant "${var.tenant_id}"
    az vm run-command invoke -g "${azurerm_resource_group.influx.name}" -n "influx-machine" --command-id RunShellScript \
    --scripts 'sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -' \
    'source /etc/lsb-release' \
    'sudo echo "deb https://repos.influxdata.com/ubuntu bionic stable" | sudo tee /etc/apt/sources.list.d/influxdb.list' \
    'sudo apt-get update && sudo apt-get install influxdb' \
    'sudo systemctl start influxdb'
EOT
  }
  depends_on = [
    azurerm_linux_virtual_machine.influx
  ]
}
