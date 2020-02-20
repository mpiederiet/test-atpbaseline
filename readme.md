# Test-ATPBaseline
A script to generate a report on ATP component settings in Microsoft Azure, Intune and Office 365.

## Introduction
Test-ATPBaseline is a report that you can run in your environment which can highlight known configuration issues and improvements which can impact your experience with
* Office 365 Advanced Threat Protection (ATP);
* Microsoft Azure ATP (storage/SQL/Cosmos DB);
* Microsoft Intune (Defender ATP Security Baseline Policies).

## How the idea was born
The Office 365 ATP checks were taken from the excellent Office 365 ATP Recommended Configuration Analyzer (ORCA) PowerShell module, by Cam Murray (https://github.com/cammurray/orca). I really liked the layout of the resulting report and the general thinking of checking settings like that.
I've created this module to make it more modular. There shouldn't be too many code changes necessary in the main module; tests can be easily added by creating a test definition in the TestDefinitions folder (just copy one to get the general idea of how it works). If the test requires a connection to another module, please make sure that you use the proper "#InputRequired" comment as the first line in the .ps1 file. Make sure that you are also adding a corresponding file in the ConnectModules folder (also just copy on of the existing files to see how it works).

## What's in scope
Currently, the following objects can be checked by Test-ATPBaseline:
* Configuration in EOP which can impact ATP;
* SafeLinks configuration;
* SafeAttachments configuration;
* Antiphish and antispoof policies;
* Microsoft Azure Storage blobs;
* Microsoft Azure SQL DB;
* Microsoft Azure Cosmos DB;
* Microsoft Intune Defender ATP Security Baseline policies.

## How do I run it?

You will need the modern Exchange Online Management Shell first up, so get it at https://www.powershellgallery.com/packages/ExchangeOnlineManagement - we use this to connect to Exchange Online and look at your configuration.
Next, you will need the AZ module, to be found at https://www.powershellgallery.com/packages/Az.
For the Intune/MS Graph connection, you will need the Microsoft.Graph.Intune module, which is here: https://www.powershellgallery.com/packages/Microsoft.Graph.Intune

This module (Test-ATPBaseline) is not (yet) published to the PowerShell gallery, so you will need to clone it from git. Create a new folder, go into that folder and enter the following command:

`git clone https://github.com/mpiederiet/test-atpbaseline.git .`

Next, import this module in PowerShell:

`import-module .\Test-ATPBaseLine.psm1`

and run the command which will generate the report:

`Test-ATPBaseline`

You will be prompted for some logons (Azure, Exchange Online and Intune). If you have permissions on several Azure subscriptions, you will be prompted to select which subscriptions to check. To run against Exchange Online and Intune, you need at least Global Reader permissions in Office 365.

# License

The module is based on the Office 365 ATP Recommended Configuration Analyzer (ORCA) PowerShell module, by Cam Murray (https://github.com/cammurray/orca). This module is open source too, so feel free to copy it and improve or change it to your likings :-)

The following components are used in order to generate the report
* Bootstrap, MIT License - https://getbootstrap.com/docs/4.0/about/license/
* Fontawesome, CC BY 4.0 License - https://fontawesome.com/license/free