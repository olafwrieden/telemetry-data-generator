@description('Unique Suffix')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 4)
@description('The name of the function app')
param functionAppName string = 'datagenerator${uniqueSuffix}'
@description('The location of the resources')
param location string = resourceGroup().location
@description('The name of the Storage Account')
param storageAccountName string = 'datagenerator${uniqueSuffix}'
@description('The SKU of the Storage Account')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param storageAccountSku string = 'Standard_LRS'
@description('The name of the Event Hub Namespace')
param eventHubNamespaceName string = 'datagenerator${uniqueSuffix}'
@description('The name of the Event Hub')
param eventHubName string = 'iotdata'

@description('The name of the authorization rule for the Event Hub')
var eventHubAuthRuleName = 'FunctionAppSendKey'

@description('The Event Hub Namespace')
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

@description('The Event Hub')
resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    partitionCount: 2
    messageRetentionInDays: 1
  }
}

@description('The authorization rule for the Event Hub')
resource eventHubSendRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  parent: eventHub
  name: eventHubAuthRuleName
  properties: {
    rights: [
      'Send'
    ]
  }
}

@description('The App Service Plan for the Function App')
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

@description('The Storage Account for the Function App')
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

@description('The Function App')
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      nodeVersion: '20'

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
          value: '4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
  }
}

@description('The source control for the Function App project')
resource functionAppProject 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    repoUrl: 'https://github.com/olafwrieden/telemetry-data-generator.git'
    branch: 'main'
    isManualIntegration: true
  }
}
