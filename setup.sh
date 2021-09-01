#!/bin/bash

# Get Sandbox resource group name
echo '------------------------------------------'
echo 'Copy resource group name for the sandbox'
AccountId=$(az account list --query '[0].id'  --output tsv)
RgName=$(`az group list --query '[0].name'  --output tsv`)
Location=$(`az group list --query '[0].location'  --output tsv`)
# Location=`az group list --query '[0].location' --output tsv`
GaLocation=eastus2

StorageAcctName=mylearnstorageacct

# Create a Storage Account for the Blob
echo '------------------------------------------'
echo 'Creating a Storage Account for the Blob'
echo $StorageAcctName
az storage account create \
    --name $StorageAcctName \
    --resource-group $RgName

StorageConnStr =`az storage account show-connection-string -g $RgName  -n $StorageAcctName '[0].connectionString' --output tsv`

StorageContainerName = "learncontainerstorage" 

# Create a Storage Container in the Storage Account
echo '------------------------------------------'
echo 'Creating a Storage Container in the Storage Account'
az storage container create \
    --account-name $StorageAcctName \
    --name $StorageContainerName

AzIoTHubName = "MyLearnIoTHub" 

# Create an IoT Hub instance
echo '------------------------------------------'
echo 'Creating a IoT Hub instance'
az iot hub create \
    --resource-group $RgName \
    --name $AzIoTHubName

# Create an Azure IoT CLI Extension
echo '------------------------------------------'
echo 'Create an Azure IoT CLI Extension'
az extension add 
    --name azure-iot

az config set extension.use_dynamic_install=yes_without_prompt

DeviceName = "MyPowerSensor"

# Register a device to IoT Hub
echo '------------------------------------------'
echo 'Register a device to IoT Hub'
az iot hub device-identity create \ 
    --device-id $DeviceName \  
    --hub-name $AzIoTHubName

IoTConnStr =`az iot hub connection-string show '[0].connectionString'  --output tsv`

# Create a destination to Route IoT messages
echo '------------------------------------------'
echo 'Creating a destination to Route IoT messages'
az iot hub routing-endpoint create \
    --endpoint-resource-group $RgName \
    --connection-string $StorageConnStr \
    --endpoint-name 'S1' \ 
    --endpoint-subscription-id $AccountId \ 
    --endpoint-type 'azurestoragecontainer' \
    --hub-name $AzIoTHubName \ 
    --container $StorageContainerName \ 
    --resource-group $RgName \
    --encoding "json"

# Create an Anomaly Detector instance
echo '------------------------------------------'
echo 'Creating an Anomaly Detector instance'

AdName = "LearnAnomalyDetector"

az cognitiveservices account create \ 
    --kind "AnomalyDetector" \
    --name $AdName \ 
    --resource-group $RgName \
    --location $GaLocation \ 
    --skuS0 \ 
    --subscription $AccountId

APIKey =`az cognitiveservices account keys list –name $AdName --resource-group $RgName '[0].key'  --output tsv`

echo '--------------------------------------------------------'
echo '             Resource Setup Completed'
echo '--------------------------------------------------------'
