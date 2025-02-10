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

@description('The subscription ID for p-we1net.')
param pwe1netSubId string

@description('Name of the resource group for.')
param pwe1netnetwork string

@description('The name of the hub virtual network.')
param hubvnetName string

@description('The subscription ID for p-we1waf.')
param pwe1wafSubId string

@description('Name of the resource group for')
param pwe1wafnetwork string

@description('The name of the WAF virtual network.')
param wafVnetName string

@description('Settings for budget configuration.')
param budgetSettings object

@description('Settings for the virtual network configuration and subnets.')
param vnet object

@description('An array of network security groups to be associated with subnets.')
param nsgs array

@description('networkWatcher and flowLogs settings.')
param nw object

@description('An array of route tables to be associated with subnets.')
param routetables array

@description('Settings for security center configuration.')
param securitySettings object

@description('Settings for storage account configuration.')
param storageAccountSettings object


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                            Existing Resources
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@description('Define resources for centralLaw')
resource centralLaw 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: centralLawName
  scope: resourceGroup(pmgtSubId, pmgtmon)
}

@description('Define resources for hubvnet')
resource hubvnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: hubvnetName
  scope: resourceGroup(pwe1netSubId, pwe1netnetwork)
}

@description('Define resources for wafVnet')
resource wafVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: wafVnetName
  scope: resourceGroup(pwe1wafSubId, pwe1wafnetwork)
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         variables
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

var spokeName = '${environment}-${serviceName}'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         resourceGroups
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@description('Define resource group for networkRG')
resource networkRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${spokeName}-network'
  location: location
  tags: tags
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         deployments
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// @description('Tags to be applied to the Azure resources.')
// param subtags object

// resource subscriptionTags 'Microsoft.Resources/subscriptions@2021-04-01' = {
//   scope: subscription()
//   name: 'subscriptionTags'
//   properties: {
//     tags: subtags
//   }
// }

// module budget 'br/public:avm/res/consumption/budget:0.3.3' = {
//   name: 'budgetDeploy'
//   params: {
//     name: spokeName
//     amount: budgetSettings.amount
//     location: location
//     contactEmails: budgetSettings.contactEmails
//     thresholds: budgetSettings.thresholds
//     startDate: budgetSettings.startDate
//   }
// }
module networkSecurityGroups 'br/public:avm/res/network/network-security-group:0.1.3' = [
  for nsg in nsgs: {
    name: '${nsg.name}nsgDeploy'
    scope: networkRG
    params: {
      name: '${networkRG.name}-vnet-${nsg.name}-nsg'
      location: location
      securityRules: nsg.securityRules
      tags: tags
      diagnosticSettings: vnet.diagnosticSettings ? [
        {
          workspaceResourceId: centralLaw.id
        }
      ] : []
    }
  }
]

module routeTables 'br/public:avm/res/network/route-table:0.2.2' = [
  for routetable in routetables: {
    name: '${routetable.name}routetableDeploy'
    scope: networkRG
    params: {
      name: '${networkRG.name}-vnet-${routetable.name}-rt'
      location: location
      routes: routetable.routes
      disableBgpRoutePropagation: routetable.disableBgpRoutePropagation
      tags: tags
    }
  }
]

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.5' = {
  name: 'virtualNetworkDeploy'
  scope: networkRG
  params: {
    name: '${networkRG.name}-vnet'
    location: location
    addressPrefixes: vnet.addressPrefixes
    dnsServers: vnet.dnsServers
    tags: tags
    subnets: [
      for (subnet, i) in vnet.subnets: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        networkSecurityGroupResourceId: networkSecurityGroups[i].outputs.resourceId
        routeTableResourceId: routeTables[i].outputs.resourceId
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: subnet.privateLinkServiceNetworkPolicies
        serviceEndpoints: subnet.serviceEndpoints
        delegations: subnet.delegations
      }
    ]
    peerings: [
      {
        // Hub vnet
        allowVirtualNetworkAccess: true
        allowForwardedTraffic: true
        allowGatewayTransit: false
        useRemoteGateways: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: false
        remotePeeringAllowGatewayTransit: true
        remotePeeringUseRemoteGateways: false
        remotePeeringEnabled: true
        name: hubvnetName
        remotePeeringName: '${networkRG.name}-vnet'
        remoteVirtualNetworkId: hubvnet.id
        doNotVerifyRemoteGateways: true
      }
      {
        // Waf vnet
        allowVirtualNetworkAccess: true
        allowForwardedTraffic: false
        allowGatewayTransit: false
        useRemoteGateways: false
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: false
        remotePeeringAllowGatewayTransit: true
        remotePeeringUseRemoteGateways: false
        remotePeeringEnabled: true
        name: wafVnetName
        remotePeeringName: '${networkRG.name}-vnet'
        remoteVirtualNetworkId: wafVnet.id
        doNotVerifyRemoteGateways: true
      }
    ]
    diagnosticSettings: vnet.diagnosticSettings ? [
      {
        workspaceResourceId: centralLaw.id
      }
    ] : []
  }
  dependsOn: [
    routeTables
    networkSecurityGroups
  ]
}

module networkWatcher 'br/public:avm/res/network/network-watcher:0.1.1' = {
  name: 'networkWatcherDeploy'
  scope: networkRG
  params: {
    name: '${networkRG.name}-networkwatcher'
    location: location
    tags: tags
    flowLogs: [
      for (flowlog, i) in nw.flowLogs: {
        name: '${flowlog.name}-flowlog'
        enabled: flowlog.enabled
        targetResourceId: networkSecurityGroups[i].outputs.resourceId
        storageId: storageAccount.outputs.resourceId
        tags: tags
      }
    ]
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.8.2' = {
  name: 'storageAccountDeploy'
  scope: networkRG
  params: {
    name: take(toLower('${environment}${serviceName}networkdiag${uniqueString(environment)}'), 24)
    location: location
    kind: storageAccountSettings.kind
    skuName: storageAccountSettings.skuName
    allowBlobPublicAccess: storageAccountSettings.allowBlobPublicAccess
    allowSharedKeyAccess: storageAccountSettings.allowSharedKeyAccess
    supportsHttpsTrafficOnly: storageAccountSettings.supportsHttpsTrafficOnly
    minimumTlsVersion: storageAccountSettings.minimumTlsVersion
    accessTier: storageAccountSettings.accessTier
    networkAcls: storageAccountSettings.networkAcls
    publicNetworkAccess: storageAccountSettings.publicNetworkAccess
    tags: tags
  }
}

module security 'br/public:avm/ptn/security/security-center:0.1.0' = if (securitySettings.deploy) {
  name: 'securityDeploy'
  params: {
    scope: subscription().id
    workspaceResourceId: centralLaw.id
    autoProvision: securitySettings.autoProvision
    securityContactProperties: securitySettings.securityContactProperties
  }
}
