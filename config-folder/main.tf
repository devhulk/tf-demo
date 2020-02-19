resource "azurerm_resource_group" "testgroup" {
    name     = "gyTestGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}
