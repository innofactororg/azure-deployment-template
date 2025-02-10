
using 'main.bicep'
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Changes needed for each deployment
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 1. Change serviceName
// 2. Change environment
// 3. Update tags
// 4. Add new IP range to var addressPrefix
// 5. Update start date for budget format '2024-12-01'

var addressPrefix = '0.0.0.0/24'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Essentials
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// param subtags = {
//   environment: 'Test'
//   owner: 'billy.petersson.ext@alecta.se'
//   team: 'AWF/CCoE'
//   technicalContact: 'billy.petersson.ext@alecta.se'
//   purpose: 'infrastructure'
// }

param serviceName = ''
param environment = 'p'
param location = 'westeurope'
param tags = {
  environment: 'Produktion'
  owner: 'AWF/CCoE'
  team: 'AWF/CCoE'
  technicalContact: 'AWF/CCoE'
  purpose: 'infrastructure'
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                            Existing Resources
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param pmgtSubId = '073bb2b0-6d02-44af-a257-d4b6139e2593'
param pmgtmon = 'p-mgt-mon'
param centralLawName = 'p-mgt-monh4bqqvga5r-ws'
param pwe1netSubId = '2e1f698d-ed24-485c-a8c2-d77328e9326d'
param pwe1netnetwork = 'p-we1net-network'
param hubvnetName = 'p-we1net-network-vnet'
param pwe1wafSubId = 'c9ab2280-5d0b-4dd1-b143-482a27460065'
param pwe1wafnetwork = 'p-we1waf-network'
param wafVnetName = 'p-we1waf-network-vnet'

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Budget
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param budgetSettings = {
  name: 'Budget'
  amount: 10000
  category: 'Cost'
  resetPeriod: 'Monthly'
  contactEmails: [
   'peder.gustavsson@alecta.se'
   'fredric.adell@alecta.se'
      ]
   thresholds: [
   85
   100
 ]
   startDate: ''
 }

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         networkSecurityGroups
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param nsgs = [
  {
    name: 'FrontendSubnet'
    securityRules: [
      {
        name: 'AllowProbeFromAzureloadbalancerToFrontendSubnet'
        properties: {
          description: 'Allow probe from Azure Load Balancer to the FrontendSubnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: cidrSubnet(addressPrefix, 26, 0)
          access: 'Allow'
          priority: 3900
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAll'
        properties: {
          description: 'Deny all other traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
        }
      }
    ]
  }
  {
    name: 'BackendSubnet'
    securityRules: [
      {
        name: 'AllowProbeFromAzureloadbalancerToBackendsubnet'
        properties: {
          priority: 3900
          description: 'Allow probe from Azure Load Balancer to the Backend Subnet'
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: cidrSubnet(addressPrefix, 26, 1)
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyAll'
        properties: {
          priority: 4000
          description: 'Deny All'
          access: 'Deny'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
]
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         routeTables
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param routetables = [
  {
    name: 'FrontendSubnet'
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'Everywhere'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.55.1.4'
        }
      }
    ]
  }
  {
    name: 'BackendSubnet'
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'Everywhere'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.55.1.4'
        }
      }
    ]
  }
]

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         virtualNetworks & subnets
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param vnet = {
  addressPrefixes: [addressPrefix]
  dnsServers: [
    '10.55.1.4'
  ]
  useRemoteGateways: false
  allowForwardedTraffic: false
  subnets: [
    {
      name: 'FrontendSubnet'
      addressPrefix: cidrSubnet(addressPrefix, 26, 0)
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: []
      serviceEndpoints: []
    }
    {
      name: 'BackendSubnet'
      addressPrefix: cidrSubnet(addressPrefix, 26, 1)
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: []
      serviceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
        {
          service: 'Microsoft.KeyVault'
        }
      ]
    }
  ]
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         networkWatcher
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param nw = {
  flowLogs: [
    {
      name: 'FrontendSubnet'
      enabled: true
    }
    {
      name: 'BackendSubnet'
      enabled: true
    }
  ]
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         StorageAccount
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param storageAccountSettings = {
  kind: 'StorageV2'
  skuName: 'Standard_ZRS'
  allowBlobPublicAccess: false
  publicNetworkAccess: 'Disabled'
  supportsHttpsTrafficOnly: true
  minimumTlsVersion: 'TLS1_2'
  accessTier: 'Hot'
  allowSharedKeyAccess: true
  networkAcls: {
    bypass: 'AzureServices, Logging, Metrics'

    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                         Security Center
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
param securitySettings = {
  autoProvision: 'On'
  securityContactProperties: {
    alertNotifications: 'On'
    alertsToAdmins: 'On'
    email: 'CloudSeverityNotifications@alecta.se'
    phone: ''
  }
}
