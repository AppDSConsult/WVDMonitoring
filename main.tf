provider "azurerm" {
  features {}

  #There are different ways to authenticate to Azure, choose what fits best. AVOID committing "terraform.tfstate" file or any other sensitive data to source control.
  #For demonstration purposes, for most sensitive "client_secret" value we will use empty variable, which means entering secret manualy when running Terraform configuration
  #Strings with angle brackets should be replaced with actual data
  subscription_id = "<My Subscription ID>"
  client_id       = "<My Service principal / Application (client) ID>"
  client_secret   = var.client_secret
  tenant_id       = "<My Directory (tenant) ID>"
}


# To have more flexibility, instead of copying required Resource IDs directly from Azure each time, lets use variable interpolation for string concatenation to form Resource IDs from existing variables
# Unfortunately, Terraform does not support variables inside a variable. If we want to generate a value based on two or more variables then Terraform locals is a good option
# A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it.

locals {

  wvd_hostpool_id           = "/subscriptions/${var.subscription_id}/resourceGroups/${var.wvd_resource_group_name}/providers/Microsoft.DesktopVirtualization/hostpools/${var.wvd_host_pool_name}"
  loganalytics_workspace_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.la_resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/${var.log_analytics_workspace_name}"
  vm_id                     = "/subscriptions/${var.subscription_id}/resourceGroups/${var.wvd_resource_group_name}/providers/Microsoft.Compute/virtualMachines/${var.wvd_session_host_name}"
  wvd_workspace_id          = "/subscriptions/${var.subscription_id}/resourceGroups/${var.wvd_resource_group_name}/providers/Microsoft.DesktopVirtualization/workspaces/${var.wvd_workspace_name}"
}

#This resource configures WVD Host pool diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "hostpooldiag" {
  name                       = "hostpooldiag"
  target_resource_id         = local.wvd_hostpool_id
  log_analytics_workspace_id = local.loganalytics_workspace_id

  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Connection"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "HostRegistration"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AgentHealthStatus"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

}

#This resource configures WVD Workspace diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "wvd_workspace_diag" {
  name                       = "wvd_workspace_diag"
  target_resource_id         = local.wvd_workspace_id
  log_analytics_workspace_id = local.loganalytics_workspace_id

  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Feed"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }


}

#This resource configures Log Analytics Windows Events example Configuration 
resource "azurerm_log_analytics_datasource_windows_event" "LSMOperational" {
  name                = "LSMOperational"
  resource_group_name = var.la_resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  event_log_name      = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
  event_types         = ["Error", "Warning", "Information"]
}

#This resource configures another Log Analytics Windows Events example Configuration
resource "azurerm_log_analytics_datasource_windows_event" "System" {
  name                = "System"
  resource_group_name = var.la_resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  event_log_name      = "System"
  event_types         = ["Error", "Warning"]
}

#This resource configures Log Analytics Workspace Performance example Counter
resource "azurerm_log_analytics_datasource_windows_performance_counter" "FreeSpace" {
  name                = "FreeSpace"
  resource_group_name = var.la_resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "% Free Space"
  interval_seconds    = 60
}

#This resource configures another Log Analytics Workspace Performance example Counter
resource "azurerm_log_analytics_datasource_windows_performance_counter" "ProcessorTime" {
  name                = "ProcessorTime"
  resource_group_name = var.la_resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  object_name         = "Processor Information"
  instance_name       = "_Total"
  counter_name        = "% Processor Time"
  interval_seconds    = 20
}

#This technique uses data source to access information about an existing Log Analytics Workspace
#Use of data sources allows a Terraform configuration to make use of information defined outside of Terraform, or defined by another separate Terraform configuration
data "azurerm_log_analytics_workspace" "logAnalytics_data" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.la_resource_group_name
}

#Azure Virtual Machine extension resource, which installs Microsoft Monitor Agent and uses workspaceId/workspaceKey from Log Analytics Data captured from the above resource.
#It is important to keep VM up and running during extension resource creation or destroy, as extension needs to connect to VM
resource "azurerm_virtual_machine_extension" "LogAnalytics" {
  name                       = "testvm-LogAnalytics"
  virtual_machine_id         = local.vm_id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true


  settings = <<SETTINGS
	{
	    "workspaceId": "${data.azurerm_log_analytics_workspace.logAnalytics_data.workspace_id}"
      
	}
SETTINGS

  protected_settings = <<protectedsettings
  {
      "workspaceKey": "${data.azurerm_log_analytics_workspace.logAnalytics_data.primary_shared_key}"
  }
protectedsettings

}
