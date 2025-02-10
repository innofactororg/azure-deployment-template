using './main.bicep'
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Changes needed for each deployment
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 1. Change serviceName
// 2. Change environment
// 3. Update tags
// 4. Uncomment desired privatelink you want to use


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Essentials
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param serviceName = ''
param environment = 'u'
param location = 'westeurope'
param tags = {
  environment: 'Utveckling'
  owner: ''
  team: ''
  technicalContact: ''
  purpose: 'solution'
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                            Existing Resources
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param pmgtSubId = '073bb2b0-6d02-44af-a257-d4b6139e2593'
param pmgtmon = 'p-mgt-mon'
param centralLawName = 'p-mgt-monh4bqqvga5r-ws'
param pdnsSubId = 'cec84459-e7a7-4cf1-abc9-42ea9e7d2acf'
param pdnspri = 'p-dns-pri'
param storageprivateLinks =  'privatelink.blob.core.windows.net' 
param kvprivateLinks =  'privatelink.vaultcore.azure.net'
 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         storgaeAccount
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param storageAccountSettings = {
  allowBlobPublicAccess: false
  publicNetworkAccess: 'Disabled'
  supportsHttpsTrafficOnly: true
  minimumTlsVersion: 'TLS1_2'
  accessTier: 'Hot'
  allowSharedKeyAccess: false
  service: 'blob' // 'web' 'queue' 'table' 'file' 'dfs' 'blob' associated with the storageLink
  networkAcls: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
  }
}

// //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// //                         keyvault
// //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param keyvaultSettings = {
  enablePurgeProtection: true
  enableSoftDelete: true
  sku: 'standard'
  publicNetworkAccess: 'Disabled'
  service: 'vault' 
  networkAcls: {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
  }
}




