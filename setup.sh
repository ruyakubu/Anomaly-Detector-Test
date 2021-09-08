#!/bin/bash

# Get Sandbox resource group name
echo '------------------------------------------'
echo 'Copy resource group name for the sandbox'
AccountId=$(az account list --query '[0].id'  --output tsv)
RgName=$(az group list --query '[0].name'  --output tsv)
Location=$(az group list --query '[0].location'  --output tsv)
# Location=`az group list --query '[0].location' --output tsv`
GaLocation=eastus2

StorageAcctName=mylearnstorageacct

# Create a Storage Account for the Blob
echo '------------------------------------------'
echo 'Creating a Storage Account for the Blob'
echo $StorageAcctName
echo $RgName
az storage account create -n $StorageAcctName --resource-group="$RgName"

echo 'Storage acount created'

StorageConnStr=$(az storage account show-connection-string -g $RgName  -n $StorageAcctName --query connectionString --output tsv)

StorageContainerName=learncontainerstorage 


echo $StorageConnStr
echo $StorageContainerName

# Create a Storage Container in the Storage Account
echo '------------------------------------------'
echo 'Creating a Storage Container in the Storage Account'
az storage container create \
    --account-name $StorageAcctName \
    --name $StorageContainerName
    
echo 'Storage container created'    

AzIoTHubName=myLearnIoTHub

# Create an IoT Hub instance
echo '------------------------------------------'
echo 'Creating a IoT Hub instance'
az iot hub create \
    --name $AzIoTHubName \
    --resource-group $RgName 
      
echo 'IoT Hub created'    

# Create an Azure IoT CLI Extension
echo '------------------------------------------'
echo 'Create an Azure IoT CLI Extension'
az extension add --name azure-iot

az config set extension.use_dynamic_install=yes_without_prompt

DeviceName=myPowerSensor

echo $DeviceName
echo $AzIoTHubName

# Register a device to IoT Hub
echo '------------------------------------------'
echo 'Register a device to IoT Hub'
az iot hub device-identity create --device-id $DeviceName --hub-name $AzIoTHubName
    
echo 'IoT Device created' 

IoTConnStr=$(az iot hub connection-string show --query '[0].connectionString'  --output tsv)


echo $AccountId

# Create a destination to Route IoT messages
echo '------------------------------------------'
echo 'Creating a destination to Route IoT messages'
az iot hub routing-endpoint create --name S1 --hub-name $AzIoTHubName --endpoint-resource-group $RgName -s $AccountId --endpoint-type azurestoragecontainer --connection-string $StorageConnStr --container $StorageContainerName  


echo 'IoT routing storage created' 

# Create an Anomaly Detector instance
echo '------------------------------------------'
echo 'Creating an Anomaly Detector instance'

AdName=learnAnomalyDetector

az cognitiveservices account create --kind AnomalyDetector --name $AdName --resource-group $RgName --location $GaLocation --sku S0 --subscription $AccountId

APIKey=$(az cognitiveservices account keys list --name $AdName --resource-group $RgName --query '[0].key'  --output tsv)

echo $APIKey

echo '--------------------------------------------------------'
echo '             Resource Setup Completed'
echo '--------------------------------------------------------'
