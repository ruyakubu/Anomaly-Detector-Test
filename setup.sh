#!/bin/bash

echo '--------------------------------------------------------'
echo '             Resource Setup Started'
echo '--------------------------------------------------------'

# Set enviroment variables
AccountId=$(az account list --query '[0].id'  --output tsv)
RgName=$(az group list --query '[0].name'  --output tsv)
Location=$(az group list --query '[0].location'  --output tsv)
UUID=$(cat /proc/sys/kernel/random/uuid | sed 's/[-]//g' | head -c 14);
stName='store'

GaLocation=eastus2
StorageAcctName=$stName$UUID
StorageContainerName=learninputcontainer
OuputStorageContainerName=learnoutputcontainer
MultiADStorageContainerName=mvadlearninputcontainer
AzIoTHubName=myLearnIoTHub
DeviceName=myPowerSensor
condition='level="storage"'
endpointName=storageEndpoint
endpointType=azurestoragecontainer
routeName=storageRoute
AdName=learnAnomalyDetector

# Create a Storage Account for the Blob
echo '------------------------------------------'
echo 'Creating a Storage Account for the Blob...'
az storage account create -n $StorageAcctName --resource-group="$RgName"
echo 'Storage acount created'

StorageConnStr=$(az storage account show-connection-string -g $RgName  -n $StorageAcctName --query connectionString --output tsv)

# Create a Storage Container for for data in the Storage Account
echo '------------------------------------------'
echo 'Creating a Storage Container in the Storage Account for univariant AD raw data...'
az storage container create \
    --account-name $StorageAcctName \
    --name $StorageContainerName
echo 'Storage container created'   

# Create a Storage Container for processed data in the Storage Account
echo '------------------------------------------'
echo 'Creating a Storage Container in the Storage Account for univariant AD processed data...'
az storage container create \
    --account-name $StorageAcctName \
    --name $OuputStorageContainerName
echo 'Storage container created'   

# Create a Storage Container for multi-variant data in the Storage Account
echo '------------------------------------------'
echo 'Creating a Storage Container in the Storage Account for multi-variant AD input data...'
az storage container create \
    --account-name $StorageAcctName \
    --name $MultiADStorageContainerName
echo 'Storage container created'   


# Add an Azure IoT CLI Extension
echo '------------------------------------------'
echo 'Adding an Azure IoT CLI Extension (OPTIONAL)...'
az extension add --name azure-iot
az config set extension.use_dynamic_install=yes_without_prompt
echo 'IoT Hub Azure CLI extension added' 

# Create an IoT Hub instance
echo '------------------------------------------'
echo 'Creating a IoT Hub instance...'
az iot hub create \
    --name $AzIoTHubName \
    --resource-group $RgName   
echo 'IoT Hub created'    

# Register a device to IoT Hub
echo '------------------------------------------'
echo 'Registering a device in IoT Hub...'
az iot hub device-identity create --device-id $DeviceName --hub-name $AzIoTHubName   
echo 'IoT Device created' 

IoTConnStr=$(az iot hub device-identity connection-string show  --device-id $DeviceName --hub-name $AzIoTHubName --resource-group $RgName --query 'connectionString' -o tsv)


# Create a destination to Route endpoint IoT messages
echo '------------------------------------------'
echo 'Creating a destination to Route IoT messages...'
az iot hub routing-endpoint create --endpoint-name=S1 --hub-name $AzIoTHubName --endpoint-resource-group $RgName --endpoint-subscription-id $AccountId --endpoint-type azurestoragecontainer --connection-string $StorageConnStr --container $StorageContainerName --encoding=avro
echo 'IoT routing endpoint storage created' 

# Create a destination to Route IoT messages
echo '------------------------------------------'
echo 'Creating a destination to Route IoT messages...'
az iot hub route create --name $routeName --hub-name $AzIoTHubName --source devicemessages --resource-group $RgName --endpoint-name=S1 --enabled --condition $condition
echo 'IoT routing storage created' 


# Create an Anomaly Detector instance
echo '------------------------------------------'
echo 'Creating an Anomaly Detector instance...'
az cognitiveservices account create --kind AnomalyDetector --name $AdName --resource-group $RgName --location $GaLocation --sku S0 --subscription $AccountId
echo 'Anomaly Detector instance created' 

# Get Anomaly Detector instance name
echo ' ::: '
echo '------------------------------------------'
echo 'Copy ANOMALY_DETECTOR_NAME'
echo '------------------------------------------'
echo $AdName
echo '------------------------------------------'
echo ' ::: '

APIKey=$(az cognitiveservices account keys list --name $AdName --resource-group $RgName --query key1  --output tsv)

# Get API Key for Anomaly Detector
echo ' ::: '
echo '------------------------------------------'
echo 'Copy API_KEY_ANOMALY_DETECTOR'
echo '------------------------------------------'
echo $APIKey
echo '------------------------------------------'
echo ' ::: '

# Get Blob connection string
echo ' ::: '
echo '------------------------------------------'
echo 'Copy BLOB_CONNECTION_STRING'
echo '------------------------------------------'
echo $StorageConnStr
echo '------------------------------------------'
echo ' ::: '

# Get IoT Hub Device connection string
echo ' ::: '
echo '------------------------------------------'
echo 'Copy IOTHUB_DEVICE_CONNECTION_STRING'
echo '------------------------------------------'
echo $IoTConnStr
echo '------------------------------------------'
echo ' ::: '

echo '--------------------------------------------------------'
echo '             Resource Setup Completed'
echo '--------------------------------------------------------'
