@description('Unique Suffix')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 4)
@description('The name of the Azure Function App.')
param functionAppName string = 'datagenerator${uniqueSuffix}'
@description('The location of the resources in Azure.')
param location string = resourceGroup().location
@description('The name of the Azure Storage Account for the Azure Function App.')
param storageAccountName string = 'datagenerator${uniqueSuffix}'
@description('The SKU of the Azure Storage Account for the Azure Function App.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param storageAccountSku string = 'Standard_LRS'
@description('The name of the Azure Event Hubs Namespace.')
param eventHubNamespaceName string = 'datagenerator${uniqueSuffix}'
@description('The name of the Azure Event Hub receiving the telemetry.')
param eventHubName string = 'iotdata'

@description('The name of the authorization rule for the Azure Event Hub.')
var eventHubAuthRuleName = 'FunctionAppSendKey'

@description('The Azure Event Hubs Namespace.')
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

@description('The Azure Event Hub receiving the telemetry data.')
resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    partitionCount: 2
    messageRetentionInDays: 1
  }
}

@description('The authorization rule for the Azure Event Hub.')
resource eventHubSendRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2023-01-01-preview' = {
  parent: eventHub
  name: eventHubAuthRuleName
  properties: {
    rights: [
      'Send'
    ]
  }
}

@description('The App Service Plan for the Azure Function App.')
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

@description('The Azure Storage Account used by the Azure Function App.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
}

@description('The Azure Function App generating the telemetry data.')
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};'
        }
        {
          name: 'EventHubConnection'
          value: eventHubSendRule.listKeys().primaryConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://github.com/olafwrieden/telemetry-data-generator/releases/download/v1.0/function.zip'
        }
      ]
    }
  }
}
