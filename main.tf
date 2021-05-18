provider "azurerm" {
features {}
  #There are different ways to authenticate to Azure, choose what fits best. AVOID committing any sensitive data to Git repository
  subscription_id = "<Subscription ID>"
  client_id       = "<Service principal Application (client) ID>"
  client_secret   = "<Service principal secret>"
  tenant_id       = "<Directory (tenant) ID>"
}

#This resource configures Host pool diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "hostpooldiag" {
  name                       = "hostpooldiag"
  target_resource_id         = var.wvd_hospool_id
  log_analytics_workspace_id = var.loganalytics_workspace_id

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

#This resource configures Log Analytics Windows Events Configuration 
resource "azurerm_log_analytics_datasource_windows_event" "LSMOperational" {
  name                = "LSMOperational"
  resource_group_name = var.resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  event_log_name      = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
  event_types         = ["Error","Warning","Information"]
}

#This resource configures Log Analytics Windows Events Configuration
resource "azurerm_log_analytics_datasource_windows_event" "System" {
  name                = "System"
  resource_group_name = var.resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  event_log_name      = "System"
  event_types         = ["Error","Warning"]
}

#This resource configures Log Analytics Workspace Performance Counters
resource "azurerm_log_analytics_datasource_windows_performance_counter" "FreeSpace" {
  name                = "FreeSpace"
  resource_group_name = var.resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  object_name         = "LogicalDisk"
  instance_name       = "C:"
  counter_name        = "% Free Space"
  interval_seconds    = 60
}

#This resource configures Log Analytics Workspace Performance Counters
resource "azurerm_log_analytics_datasource_windows_performance_counter" "ProcessorTime" {
  name                = "ProcessorTime"
  resource_group_name = var.resource_group_name
  workspace_name      = var.log_analytics_workspace_name
  object_name         = "Processor Information"
  instance_name       = "_Total"
  counter_name        = "% Processor Time"
  interval_seconds    = 20
}

#This technique uses data source to access information about an existing Log Analytics Workspace
data "azurerm_log_analytics_workspace" "logAnalytics_data" {
  name                = "WVDcbWorkspace"
  resource_group_name = "wvdmonitorrg"
}

#Azure Virtual Machine extension resource, which installs Microsoft Monitor Agent and uses workspaceId/workspaceKey from Log Analytics Data captured from the above resource.
#It is important to keep VM up and running during extension resource creation or destroy, as extension needs to connect to VM
resource "azurerm_virtual_machine_extension" "LogAnalytics" {
  name                       = "testvm-LogAnalytics"
  virtual_machine_id         = var.vm_id
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