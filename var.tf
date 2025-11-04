variable "tenant_id" {
  type    = string
  default = "44b79a67-d972-49ba-9167-8eb05f754a1a"
}
 
variable "subscription_id" {
  type    = string
  #default = "706dae49-e373-4a40-a643-312fc7abe3a0" # sb resource group
  #default = "eda0df6b-e358-4bb0-8cc7-cd7281d92301" # prod 
  default = "c17137a4-ecb2-48fe-8c4f-3a597bdcceaf" # cloudops sb 
}
 
variable "client_id" {
  type    = string
  default = "f6bbf5dc-cff0-4748-b251-50bc41eb83c3"
}
 
