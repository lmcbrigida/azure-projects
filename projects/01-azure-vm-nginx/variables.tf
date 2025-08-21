variable "resource_group_name" {
  type = string
}
variable "location" {
  type    = string
  default = "eastus"
}
variable "prefix" {
  type    = string
  default = "prj01"
}
variable "admin_username" {
  type    = string
  default = "azureuser"
}
variable "ssh_public_key" {
  type = string
}
