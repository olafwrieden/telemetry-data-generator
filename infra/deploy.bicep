@description('Unique Suffix')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 6)

@description('The name of the function app')
param functionAppName string = 'datagenerator${uniqueSuffix}'
@description('The location of the resources')
param location string = resourceGroup().location
@description('The name of the storage account')
param storageAccountName string = 'datagenerator${uniqueSuffix}'
@description('The SKU of the storage account')
param storageAccountSku string = 'Standard_GRS'
@description('The name of the Event Hub namespace')
param eventHubNamespaceName string = 'evnamespace${uniqueSuffix}'
@description('The name of the Event Hub')
param eventHubName string = 'iotdata'

@description('The name of the authorization rule for the Event Hub')
var eventHubAuthRuleName = 'FunctionAppSendKey'

@description('The Event Hub namespace')
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

@description('The App Service Plan for the function app')
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${functionAppName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

@description('The storage account for the function app')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

@description('The function app')
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
        }, {
          name: 'EventHubConnection'
          value: eventHubSendRule.listKeys().primaryConnectionString
        }, {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '4'
        }, {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
  }
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    repoUrl: 'https://github.com/olafwrieden/telemetry-data-generator.git'
    branch: 'main'
    isManualIntegration: true
  }
}
