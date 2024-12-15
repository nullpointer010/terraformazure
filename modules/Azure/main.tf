# Crear red virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Crear subred
resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Crear instancia denominada mysql conectada a la red del proyecto e inicializada
# con el archivo install_mysql.sh
# Asignarle una dirección IP flotante
# **********************

# Crear dirección IP pública para MySQL
resource "azurerm_public_ip" "pip_mysql" {
  name                = "pip-mysql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" # Cambiado a Static para facilitar acceso
}

# Crear interfaz de red para MySQL con dirección IP pública
resource "azurerm_network_interface" "nic_mysql" {
  name                = "nic-mysql"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "mysql-ip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_mysql.id # Asignar IP pública
  }
}

# Crear máquina virtual para MySQL
resource "azurerm_linux_virtual_machine" "mysql" {
  name                = "mysql"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Tamaño ajustado para pruebas
  admin_username      = var.azure_user_name
  admin_password      = var.azure_password
  network_interface_ids = [azurerm_network_interface.nic_mysql.id] # Conexión a red

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Script para inicializar MySQL
  custom_data = file("install_mysql.sh")
}

# Salida para mostrar la IP pública asignada
output "mysql_public_ip" {
  value = azurerm_public_ip.pip_mysql.ip_address
  description = "Dirección IP pública de la instancia MySQL"
}


data "template_file" "setup-api-docker" {
  template = file("setup-api-docker.tpl")
  vars = {
    mysql_ip = azurerm_network_interface.nic_mysql.private_ip_address
  }
  depends_on = [azurerm_linux_virtual_machine.mysql]
}

# Configura el archivo de plantilla para la API

# Espera 5 minutos a que se configure la instancia MySQL
# para que no falle el contenedor de la API al conectar a la BD

resource "time_sleep" "wait_5_minutes" {
  depends_on = [azurerm_linux_virtual_machine.mysql] # Garantiza que espere a que MySQL esté creado

  create_duration = "300s" # 5 minutos en segundos
}

resource "azurerm_linux_virtual_machine" "book_api" {
  name                = "book-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Tamaño ajustado para pruebas
  admin_username      = var.azure_user_name
  admin_password      = var.azure_password
  network_interface_ids = [azurerm_network_interface.nic_api.id] # Conectar a la red

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Inicialización con el archivo de plantilla
  custom_data = data.template_file.setup-api-docker.rendered

  # Espera 5 minutos después de que MySQL esté listo
  depends_on = [time_sleep.wait_5_minutes]
}

# Crear dirección IP pública para la API
resource "azurerm_public_ip" "pip_api" {
  name                = "pip-api"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" # Cambiar a Static para acceso constante
}

# Crear interfaz de red para la API con IP pública
resource "azurerm_network_interface" "nic_api" {
  name                = "nic-api"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "api-ip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_api.id # Asociar IP pública
  }
}

output "book_api_public_ip" {
  value       = azurerm_public_ip.pip_api.ip_address
  description = "Dirección IP pública de la instancia book-api"
}

# Configura el archivo de plantilla para la aplicación
data "template_file" "setup-app-docker" {
  template = file("setup-app-docker.tpl")
  vars = {
    book_api_ip = azurerm_linux_virtual_machine.book_api.private_ip_address
  }
  depends_on = [azurerm_linux_virtual_machine.book_api] # Garantizar que la API esté lista
}

#Crear nodo APP
resource "azurerm_linux_virtual_machine" "book_app" {
  name                = "book-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Tamaño ajustado para pruebas
  admin_username      = var.azure_user_name
  admin_password      = var.azure_password
  network_interface_ids = [azurerm_network_interface.nic_app.id] # Conectar a la red

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Inicialización con el archivo de plantilla
  custom_data = data.template_file.setup-app-docker.rendered
}

# Asignarle una dirección IP flotante
# **********************

# Crear dirección IP pública para la aplicación
resource "azurerm_public_ip" "pip_app" {
  name                = "pip-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" # Cambiar a Static para acceso constante
}

# Crear interfaz de red para la aplicación con IP pública
resource "azurerm_network_interface" "nic_app" {
  name                = "nic-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "app-ip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_app.id # Asociar IP pública
  }
}

output "book_app_public_ip" {
  value       = azurerm_public_ip.pip_app.ip_address
  description = "Dirección IP pública de la instancia book-app"
}

# Mostrar las direcciones IP generadas
# **********************
