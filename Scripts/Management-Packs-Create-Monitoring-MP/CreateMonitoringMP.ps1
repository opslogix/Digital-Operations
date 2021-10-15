##########################################################################################################
#                                                                                                        #
# CreateMonitoringMP.ps1                                                                                 #
#                                                                                                        #
# Creates and imports a new Monitoring Management Pack based on the template 'MonitoringMPTemplate.xml'  #
#                                                                                                        #
#                                                                                                        #
##########################################################################################################

# Ask for name of Monitoring Management Pack
Write-Host "`nThis script will create a new empty Monitoring Management Pack based on the template 'MonitoringMPTemplate.xml'.`n`nPlease provide the name of the Monitoring Management Pack in the form 'Company Service X.X'.`n`nExample: Approved Corporate Web 1.0`n"
$MPName = Read-Host "Name (or <Ctrl-C> to quit)"

# Check for template file
$WorkingPath = (Get-Location).Path
$TemplateFile = $WorkingPath + "\MonitoringMPTemplate.xml"

If (!(Test-Path $TemplateFile))
   {
   Write-Host "`nError: Template file 'MonitoringMPTemplate.xml' not found in current folder. Script aborted!`n" -Foregroundcolor "Red"
   Exit -1
   }

# Build XML Name and ID strings from name of Monitoring Management Pack
$MPName = $MPName -cReplace("å", "a")
$MPName = $MPName -cReplace("ä", "a")
$MPName = $MPName -cReplace("ö", "o")
$MPName = $MPName -cReplace("ü", "u")
$MPName = $MPName -cReplace("Å", "A")
$MPName = $MPName -cReplace("Ä", "A")
$MPName = $MPName -cReplace("Ö", "O")
$MPName = $MPName -cReplace("Ü", "U")
$XMLName = $MPName.Trim()
$XMLID = ($MPName.Trim() -Replace(" ", ".") -Replace("-", ".") -Replace("/", "."))

# Ask for confirmation of data
Write-Host "`nA new Monitoring Management Pack with the following parameters will now be created:`n"
Write-Host "Management Pack Name: $XMLName"
Write-Host "Management Pack ID: $XMLID"
$Choise = Read-Host "`nContinue? (Y/N)"
If ($Choise -NotLike "Y" -OR $Choise -NotLike "y")
   {
   Write-Host "`nScript aborted`n"
   Exit 0
   }

# Open template file and replace strings
$Template = Get-Content $TemplateFile
$Template = $Template -Replace("\[Company Service X.X\]", $MPName)
$Template = $Template -Replace("Company Service X.X", $XMLName)
$Template = $Template -Replace("Company.Service.X.X", $XMLID)

# Save the modified template as an XML file
$ImportFile = $WorkingPath + "\" + $XMLID + ".xml"
Set-Content $ImportFile -Value $Template -Force
Write-Host "`nMonitoring Management Pack file saved as '$ImportFile'"

# Ask if XML file should be imported into SCOM
$Choise = Read-Host "`nDo you want to import this Monitoring Management Pack into Operations Manager? (Y/N)"
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
   Write-Host "`nError: Importing Monitoring Management Pack failed. $Error`n" -Foregroundcolor "Red"
   Exit -1
   }
Write-Host "done. Monitoring Management Pack '$XMLName' successfully imported.`n"
