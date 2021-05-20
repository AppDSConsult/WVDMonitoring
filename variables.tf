#Strings with angle brackets should be replaced with actual data

variable "la_resource_group_name" {
  default     = "<My Log Analytics Resource Group name>"
  description = "Resource Group name containing Log Analytics Workspace"

}

variable "log_analytics_workspace_name" {
  default     = "<My Log Analytics workspace name>"
  description = "Existing Log Analytics Workspace name"

}

variable "wvd_resource_group_name" {
  default     = "<My WVD Resource Group name>"
  description = "Resource Group name containing Windows Virtual Desktop host Pool"
}

variable "wvd_host_pool_name" {
  default     = "<My WVD host pool name>"
  description = "Windows Virtual Desktop host pool name"
}

variable "wvd_workspace_name" {
  default     = "<My WVD workspace name>"
  description = "Windows Virtual Desktop workspace name"
}

variable "wvd_session_host_name" {
  default     = "<My WVD session host name>"
  description = "Windows Virtual Desktop session host name"
}

variable "client_secret" {
  sensitive   = true
  description = "Service Principal secret credential"
}
