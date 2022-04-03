@description('The name of the size of the virtual machine to deploy.')
param virtualMachineSizeName string 

@description('The name of the storage account SKU to use for the virtual machine\'s managed disk.')
param virtualMachineManagedDiskStorageAccountType string 

@description('The administrator username for the virtual machine.')
param virtualMachineAdminUsername string 

@description('The administrator password for the virtual machine.')
@secure()
param virtualMachineAdminPassword string

@description('The name of the SKU of the public IP address to deploy.')
param publicIPAddressSkuName string = 'Basic'

@description('The virtual network address range.')
param virtualNetworkAddressPrefix string

@description('The default subnet address range within the virtual network')
param virtualNetworkDefaultSubnetAddressPrefix string

@description('The location into which the resources should be depolyed.')
param location string = resourceGroup().location

// Variables
var virtualNetworkName = 'ToyTruck-vnet'
var virtualMachineName = 'ToyTruckServer'
var networkInterfaceName = 'toytruckserver787'
var publicIPAddressName = 'ToyTruckServer-ip'
var networkSecurityGroupName = 'ToyTruckServer-nsg'
var virtualNetworkDefaultSubnetName = 'default'
var virtualMachineImageReference = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts'
  version: 'latest'
}
var virtualMachineOSDiskName = '${virtualMachineName}_OsDisk_1_2a556be6f97f412ab0c85ccb97f700d5'

// resources
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: networkSecurityGroupName
  location: location
  // properties:
  //   securityRules: []
  // }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: publicIPAddressSkuName
    tier: 'Regional'
  }
  properties: {
    // ipAddress: '104.42.218.21'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    // ipTags: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: virtualNetworkDefaultSubnetName
        properties: {
          addressPrefix: virtualNetworkDefaultSubnetAddressPrefix
          // delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    // virtualNetworkPeerings: []
    enableDdosProtection: false
  }
  resource defaultSubnet 'subnets' existing = {
    name: virtualNetworkDefaultSubnetName
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSizeName
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Linux'
        name: virtualMachineOSDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: virtualMachineManagedDiskStorageAccountType
          // id: resourceId('Microsoft.Compute/disks', '${virtualMachineName}_OsDisk_1_2a556be6f97f412ab0c85ccb97f700d5')
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
      // dataDisks: []
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: virtualMachineAdminUsername
      adminPassword: virtualMachineAdminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      // secrets: []
      allowExtensionOperations: true
      // requireGuestProvisionSignal: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-07-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: virtualNetwork::defaultSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    // dnsSettings: {
    //   dnsServers: []
    // }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}
