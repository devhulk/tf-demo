provider "azurerm" {
    version="~> 1.x"
}

resource "azurerm_resource_group" "gyterraformgroup" {
        name = "GeraldResourceGroup"
        location = "eastus"

        tags = {
            environment = "Terraform Demo"
        }
}

resource "azurerm_virtual_network" "gyterraformnetwork" {
    name                = "gyVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.gyterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_subnet" "gyterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.gyterraformgroup.name
    virtual_network_name = azurerm_virtual_network.gyterraformnetwork.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "gyterraformpublicip" {
    name                         = "gyPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.gyterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "gyterraformnsg" {
    name                = "gyNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.gyterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "gyterraformnic" {
    name                        = "gyNIC"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.gyterraformgroup.name
    network_security_group_id   = azurerm_network_security_group.gyterraformnsg.id

    ip_configuration {
        name                          = "gyNicConfiguration"
        subnet_id                     = "${azurerm_subnet.gyterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.gyterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.gyterraformgroup.name
    }

    byte_length = 8
}
resource "azurerm_storage_account" "gystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.gyterraformgroup.name
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}


resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "gyVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.gyterraformgroup.name
    network_interface_ids = [azurerm_network_interface.gyterraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "gyOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "gyvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDb5X/ef2XjNm7mjY6VhM5Vo5pbsU7bqQ8Kp52GLAmQlwow+8ozyMcadfjimxlhEtWmSwLLQnkRs6Cmj7SeePgSNbmd87hWzhEDKH9NFyRrSFkwx2nX7RRaf8OctZMzjyA7AapGrxha6yrGI+IG4emKECaC/rQau4Z/UxG+Re+28VzvVfxOXjZmwTf8ghBjtervHzF03yuv9d37yBgJq2jD6qrdGXdibF/snmM7kd5SRBnii0uCfHnItn3C30/Xg/XORv5YWr5cc2S5W1nQrpNR92g7oWJ4g+I6fOPpgtdhuZs5v4SgbseDClPiSFPIecqzbMLytEPqQv1r8AYcSjZD devhulk@devhulk"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.gystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}
