##########################################################################################################
#                                                                                                        #
# CreateOverrideMP.ps1                                                                                   #
#                                                                                                        #
# Creates and imports a new Override Management Pack based on the template 'OverrideMPTemplate.xml'      #
#                                                                                                        #
##########################################################################################################

# Ask for name of Override Management Pack
Write-Host "`nThis script will create a new empty Override Management Pack based on the template 'OverrideMPTemplate.xml'.`n`nPlease provide the name of the Override Management Pack in the form 'Manufacturer Product Version'. Do not add an underscore ('_') or the term 'Overrides' as this will be added by the script.`n`nExample: Microsoft AppServer 2015`n"
$MPName = Read-Host "Name (or <Ctrl-C to quit)"

# Check for template file
$WorkingPath = (Get-Location).Path
$TemplateFile = $WorkingPath + "\OverrideMPTemplate.xml"
If (!(Test-Path $TemplateFile))
   {
   Write-Host "`nError: Template file 'OverrideMPTemplate.xml' not found in current folder. Script aborted!`n" -Foregroundcolor "Red"
   Exit -1
   }

# Build XML Name and ID strings from name of Override Management Pack
$MPName = $MPName -cReplace("å", "a")
$MPName = $MPName -cReplace("ä", "a")
$MPName = $MPName -cReplace("ö", "o")
$MPName = $MPName -cReplace("ü", "u")
$MPName = $MPName -cReplace("Å", "A")
$MPName = $MPName -cReplace("Ä", "A")
$MPName = $MPName -cReplace("Ö", "O")
$MPName = $MPName -cReplace("Ü", "U")
$XMLName = "_" + $MPName.Trim() + " - Overrides"
$XMLID = ($MPName.Trim() -Replace(" ", ".") -Replace("-", ".") -Replace("/", ".")) + ".Overrides"

# Ask for confirmation of data
Write-Host "`nA new Override Management Pack with the following parameters will now be created:`n"
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
$Template = $Template -Replace("\[Manufacturer Product Version\]", $MPName)
$Template = $Template -Replace("_Manufacturer Product Version - Overrides", $XMLName)
$Template = $Template -Replace("Manufacturer.Product.Version.Overrides", $XMLID)

# Save the modified template as an XML file
$ImportFile = $WorkingPath + "\" + $XMLID + ".xml"
Set-Content $ImportFile -Value $Template -Force
Write-Host "`nOverride Management Pack file saved as '$ImportFile'"

# Ask if XML file should be imported into SCOM
$Choise = Read-Host "`nDo you want to import this Override Management Pack into Operations Manager? (Y/N)"
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
   Write-Host "`n`nError: Importing Override Management Pack failed. $Error`n" -Foregroundcolor "Red"
   Exit -1
   }
Write-Host "done. Override Management Pack '$XMLName' successfully imported.`n"
