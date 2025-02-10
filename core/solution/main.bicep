//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                                  Main.bicep
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
targetScope = 'subscription'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                                  Parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


@description('The name of the service.')
param serviceName string

@description('Environments are used to separate resources by the environment.')
@allowed(['p', 'u', 't', 'a'])
param environment string

@allowed(['westeurope'])
@description('The Azure region where the resources will be deployed.')
param location string

@description('Tags to be applied to the Azure resources.')
param tags object

@description('The subscription ID for p-mgt.')
param pmgtSubId string 

@description('Name of the resource group for')
param pmgtmon string 

@description('The name of the Log Analytics workspace central law.')
param centralLawName string

@description('The subscription ID for p-dns.')
param pdnsSubId string

@description('Name of the resource group for')
param pdnspri string

@description('Specifies the name of the .')
param storageprivateLinks string

@description('Specifies the name of the .')
param kvprivateLinks string

@description('Settings for storage account configuration.')
param storageAccountSettings object

@description('Settings for key vault configuration.')
param keyvaultSettings object

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                            Existing Resources
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource centralLaw 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: centralLawName
  scope: resourceGroup(pmgtSubId, pmgtmon)
}

resource networkRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${spokeName}-network'
  location: location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: '${networkRG.name}-vnet'
  scope: networkRG
}

resource BackendSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'BackendSubnet'
  parent: virtualNetwork
}

resource storageprivateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: storageprivateLinks
  scope: resourceGroup(pdnsSubId, pdnspri)
}

resource keyvaultprivateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: kvprivateLinks
  scope: resourceGroup(pdnsSubId, pdnspri)
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         variables
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

var spokeName = '${environment}-${serviceName}'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         resourceGroups
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@description('Define resource group for networkRG')
resource spokeRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: spokeName
  location: location
  tags: tags
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         deployments
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
module storageAccount 'br/public:avm/res/storage/storage-account:0.8.2' = {
  name: 'storageAccountDeploy'
  scope: spokeRG
  params: {
    name: take(toLower('${environment}${serviceName}${uniqueString(environment)}'), 24)
    location: location
    allowBlobPublicAccess: storageAccountSettings.allowBlobPublicAccess
    allowSharedKeyAccess: storageAccountSettings.allowSharedKeyAccess
    supportsHttpsTrafficOnly: storageAccountSettings.supportsHttpsTrafficOnly
    minimumTlsVersion: storageAccountSettings.minimumTlsVersion
    accessTier: storageAccountSettings.accessTier
    networkAcls: storageAccountSettings.networkAcls
    publicNetworkAccess: storageAccountSettings.publicNetworkAccess
    tags: tags
    privateEndpoints: [
      {
        name:  toLower('${environment}${serviceName}${uniqueString(environment)}privateendpoint')
        service: storageAccountSettings.service
        subnetResourceId: BackendSubnet.id
        privateDnsZoneResourceIds:  [ 
          storageprivateDNS.id
        ]
       }
    ]
  }
}

module keyvault 'br/public:avm/res/key-vault/vault:0.5.1' = {
  name: 'keyVaultDeploy'
  scope: spokeRG
  params: {
    name: '${spokeName}${uniqueString(serviceName)}-kv'
    location: location
    enablePurgeProtection: keyvaultSettings.enablePurgeProtection
    enableSoftDelete: keyvaultSettings.enableSoftDelete
    sku: keyvaultSettings.sku
    publicNetworkAccess: keyvaultSettings.publicNetworkAccess
    networkAcls: keyvaultSettings.networkAcls
    privateEndpoints: [
      {
        name: '${spokeName}${uniqueString(serviceName)}-kv-privateendpoint'
        subnetResourceId: BackendSubnet.id
        service: keyvaultSettings.service
        privateDnsZoneResourceIds: [
          keyvaultprivateDNS.id
        ]
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: centralLaw.id
      }
    ]
    tags: tags
  }
}





