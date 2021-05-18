variable "resource_group_name" {
    default =  "<Log Analytics Resource Group name>"
}

 variable "log_analytics_workspace_name" {
    default =  "<Log Analytics workspace name>"
}

 variable "wvd_hospool_id" {
    default = "/subscriptions/<Subscription ID>/resourceGroups/<WVD Host pool Resource Group name>/providers/Microsoft.DesktopVirtualization/hostpools/<WVD Host pool name>"
}

 variable "loganalytics_workspace_id" {
    #Log Analytics Workspace ID can be consused with this one, but we need Log Analytics Resource ID at this case
    default = "/subscriptions/<Subscription ID>/resourceGroups/<Log Analytics Resource Group name>/providers/Microsoft.OperationalInsights/workspaces/<Log Analytics workspace name>"
}

 variable "vm_id" {
    default = "/subscriptions/<Subscription ID>/resourceGroups/<WVD Host pool Resource Group name>/providers/Microsoft.Compute/virtualMachines/<WVD session host name>"
}
