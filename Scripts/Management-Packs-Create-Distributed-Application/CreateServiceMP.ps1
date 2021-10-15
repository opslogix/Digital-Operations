##########################################################################################################
#                                                                                                        #
# CreateServiceMP.ps1                                                                                    #
#                                                                                                        #
# Creates and imports a new Monitoring Management Pack based on the templates                            #
#                                                                                                        #
# Version history:                                                                                       #
#                                                                                                        #
#  1.1    2020-11-23   Jonas Lenntun - OpsLogix BV                                                       #
#  1.0    2018-11-25   Jonas Lenntun - OpsLogix BV                                                       #
#   - Original version                                                                                   #
#                                                                                                        #
##########################################################################################################

# Ask for name of Service Management Pack
Write-Host "`nThis script will create a new empty Service Management Pack based on the template 'ServiceMPTemplate.xml'.`n`nPlease provide the name of the Service Management Pack in the form 'Name | Name | Name'.`n`nExample: Windows Server | Operating System | Prod`n"
$MPName = Read-Host "Name (or <Ctrl-C> to quit)"

# Check for template file
$WorkingPath = (Get-Location).Path
$TemplateFile = $WorkingPath + "\ServiceMPTemplate.xml"

If (!(Test-Path $TemplateFile))
   {
   Write-Host "`nError: Template file 'ServiceMPTemplate.xml' not found in current folder. Script aborted!`n" -Foregroundcolor "Red"
   Exit -1
   }

# Build XML Name and ID strings from name of Monitoring Management Pack
$MPName = $MPName -cReplace("�", "a")
$MPName = $MPName -cReplace("�", "a")
$MPName = $MPName -cReplace("�", "o")
$MPName = $MPName -cReplace("�", "u")
$MPName = $MPName -cReplace("�", "A")
$MPName = $MPName -cReplace("�", "A")
$MPName = $MPName -cReplace("�", "O")
$MPName = $MPName -cReplace("�", "U")
$ServiceName = $MPName
$XMLName = "Service "+$MPName.Trim()
$XMLID = ($MPName.Trim() -Replace(" ", "#") -Replace("-", ".") -Replace("/", ".") -Replace("\|", ""))
$XMLID = ($XMLID.Trim() -Replace("##", "#"))
$XMLID = ($XMLID.Trim() -Replace("#", "."))
#$XMLID = "Service.$XMLID"
[string]$XMLGUID = New-Guid
$XMLGUID = ($XMLGUID.Trim() -Replace("-", ""))
$XMLID = "Service.$XMLGUID"


# Ask for confirmation of data
Write-Host "`nA new Service Management Pack with the following parameters will now be created:`n"
Write-Host "Management Pack Name: $XMLName"
Write-Host "Management Pack ID: $XMLID"
Write-Host "Service Name: $ServiceName"
Write-Host "Service GUID:" $XMLGUID 
$Choise = Read-Host "`nContinue? (Y/N)"
If ($Choise -NotLike "Y" -OR $Choise -NotLike "y")
   {
   Write-Host "`nScript aborted`n"
   Exit 0
   }

# Open template file and replace strings
$Template = Get-Content $TemplateFile
$Template = $Template -Replace("##ServiceName##", $ServiceName)
$Template = $Template -Replace("##XMLName##", $XMLName)
$Template = $Template -Replace("##XMLID##", $XMLID)
$Template = $Template -Replace("##GUID##", $XMLGUID)

# Save the modified template as an XML file
$ImportFile = $WorkingPath + "\" + $XMLID + ".xml"
Set-Content $ImportFile -Value $Template -Force
Write-Host "`nService Management Pack file saved as '$ImportFile'"

# Ask if XML file should be imported into SCOM
$Choise = Read-Host "`nDo you want to import this Service Management Pack into Operations Manager? (Y/N)"
If ($Choise -NotLike "Y" -OR $Choise -NotLike "y")
   {
   Write-Host ""
   Exit 0
   }

# Check if running in a SCOM environment and import the XML file into SCOM
$ErrorActionPreference = 'Stop'
$Error.Clear()
Try
   {
   Import-Module OperationsManager
   }
Catch
   {
   Write-Host "`nError: Operations Manager module not found. This script must be run on a computer where the Operations Console is installed. Script aborted!`n" -Foregroundcolor "Red"
   Exit -1
   }
Write-Host "`nImporting... " -NoNewline
$Error.Clear()
Try
   {
   Import-SCOMManagementPack -Fullname $ImportFile
   }
Catch
   {
   Write-Host "`nError: Importing Service Management Pack failed. $Error`n" -Foregroundcolor "Red"
   Exit -1
   }
Write-Host "done. Service Management Pack '$XMLName' successfully imported.`n"

Write-Host "Reading information about newly created service groups. Please wait.....`n"
Start-Sleep -s 15
# Read MP and Replace for DA Component replacement

$Class = Get-SCOMClass -Name Microsoft.SystemCenter.InstanceGroup
$SCOMMonitoringObjects = Get-SCOMMonitoringObject -Class $Class
$FunctionalGroupMonitoringClassID = (($SCOMMonitoringObjects | Where-Object {$_.FullName -eq "Service_"+$XMLGUID+"_Functional.Group"} | select FullName, DisplayName, LeastDerivedNonAbstractMonitoringClassId).LeastDerivedNonAbstractMonitoringClassId).Guid
$ComponentsGroupMonitoringClassID = (($SCOMMonitoringObjects | Where-Object {$_.FullName -eq "Service_"+$XMLGUID+"_Components.Group"} | select FullName, DisplayName, LeastDerivedNonAbstractMonitoringClassId).LeastDerivedNonAbstractMonitoringClassId).Guid
$InfrastructureGroupMonitoringClassID = (($SCOMMonitoringObjects | Where-Object {$_.FullName -eq "Service_"+$XMLGUID+"_Infrastructure.Group"} | select FullName, DisplayName, LeastDerivedNonAbstractMonitoringClassId).LeastDerivedNonAbstractMonitoringClassId).Guid

$TemplateFile = $WorkingPath + "\ServiceMPTemplateExtended.xml"

# Open template file once again and replace strings
$Template = Get-Content $TemplateFile
$Template = $Template -Replace("##ServiceName##", $ServiceName)
$Template = $Template -Replace("##XMLName##", $XMLName)
$Template = $Template -Replace("##XMLID##", $XMLID)
$Template = $Template -Replace("##GUID##", $XMLGUID)
$Template = $Template -Replace("##FunctionalGroupMonitoringClassID##", $FunctionalGroupMonitoringClassID)
$Template = $Template -Replace("##ComponentsGroupMonitoringClassID##", $ComponentsGroupMonitoringClassID)
$Template = $Template -Replace("##InfrastructureGroupMonitoringClassID##", $InfrastructureGroupMonitoringClassID)

# Save the modified template as an XML file
$ImportFile = $WorkingPath + "\" + $XMLID + ".xml"
Set-Content $ImportFile -Value $Template -Force
Write-Host "`nUpdated Service Management Pack file saved as '$ImportFile'"

Write-Host "`nImporting newly updated Management Pack... " -NoNewline
Import-SCOMManagementPack -Fullname $ImportFile

