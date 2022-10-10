##########################
# Auto-Updater           #
# By Jacob Bean          #
#                        #
#############################
# Syncro Custom Assets Used #
#                           #
# Field Name: Last-Updated  #
# Type: Custom Text Field   #
#                           #
#########################################################
# Description                                           #
#                                                       #
# Script goes and checks if the Module is installed     #
# if it is then import, if not import then install      #
# Adds all the update names to a variable               #
# then sends and email to itadmin                       #
#                                                       #
#########################################################
# NOTES
# 10-6-22
# Per Gary request I am going to make sure Quality and Feature
# updates are still deferred
# I believe this is take care of in group policy
# and I think the module only invokes the update like as if u clicked
# the button in windows, but I am checking -- see reddit post below
# Post:
# https://www.reddit.com/r/PowerShell/comments/xx9shz/pswindowsupdate_question/

# CHANGE_LOG
# this will be for any changes I implement or am planning
#
# add a workflow feature for auto restart before
# add a switch via syncro for the -whatif tag on the module
##########################
# BEGIN GLOBAL VARIABLES #
##########################
Import-Module $env:SyncroModule
$pcName = hostname
##########################
# END   GLOBAL VARIABLES #
##########################

############################################
# Function:                                #
# Module-Check                             #
# Check if Get-WindowsUpdate Module exists #
#                                          #
############################################

function Module-Check{

    #Restart-Computer -Force -Wait
    #checks if the command is already installed
    if (-not(Get-InstalledModule Get-WindowsUpdate -ErrorAction silentlycontinue)){
        #Write-Verbose for my own debugging
        Write-Verbose "Get-WindowsUpdate does not exists`nInstalling now...`n" -Verbose
        Write-Verbose "     BEGINNING INSTALL`n" -Verbose
        #I am swapping the state of the verbose preferences
        #may be able to just add a -verbose to the Write-Verbose, or -verbose:silent someting like that???
        #setting the repo to trusted and -confirm to auto false. This helps bypass and 'Y' and 'A' needed
        #not sure why I need this shit, but this line below makes it work....
        #upon further investigation it helps with the missing pieces, trusted source
        Install-PackageProvider NuGet -Force;
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        #install module
        #   -Force -AllowClobber    used in conjunction to help bypass confirmations
        #   -Confirm:$false         used to help bypass confirmations
        #   -Repository PSGallery   Grabs the correct repo for installation -- may not need this
        Install-Module PSWindowsUpdate -Force -AllowClobber -Confirm:$false -Repository PSGallery
        #set the repo back to untrust -- this isjust good practice
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted
        Write-Verbose "     INSTALL SUCCESS`n" -Verbose
        Write-Verbose "     BEGINNING IMPORT`n" -Verbose
        #import the PSWindowsUpdate module
        Import-Module PSWindowsUpdate -Force
        Write-Verbose "     IMPORT SUCCESS`n" -Verbose
    }

    else{
        Write-Verbose "Command Exists!... Beginning installs`n"
        Write-Verbose "     BEGINNING IMPORT`n" -Verbose
        #import the PSWindowsUpdate module
        Import-Module PSWindowsUpdate -Force
        Write-Verbose "     IMPORT SUCCESS" -Verbose
    }
}

############################################
# Function:                                #
# Send-Email                               #
# Sends an email to itadmin@itmgr.com      #
#                                          #
############################################
function Send-Email{
    Write-Verbose " beginning of script" -verbose
    #create empty message variable
    $message = ""
    #store updates into variable
    $updates = Get-WindowsUpdate
    #for each update grab the title then join it into $message
    $updates | ForEach-Object {
        $name = $_.title
        $message = -join("$message","`n", "$name")
    }
    #create a count for the number of updates
    $count = $updates.count
    #subject will be the count and the $pcName(hostname)
    $subject = -join("$count ", "updates on " , "$pcName")
    #Write-Verbose " we are above" -verbose
    Write-Verbose " SENDING EMAIL" -Verbose
    #Write-Verbose " we are below" -verbose
    #if the message was blank we respond with vvvvvvvv
    if ($message -eq ""){
        Write-Verbose "No updates found`n" -Verbose
        $message = "No updates found"
        
    }
    #Write-Verbose " POST IF STATEMENT" -verbose
    #Send-Email -To "itadmin@itmgr.com" -Subject $subject -Body $message
    Write-Verbose " EMAIL SENT" -Verbose
}

################
#    -MAIN-    #
#              #
################

#invoke Module-CHeck function
Module-Check
#invoke Send-Email function
Send-Email
#invoke Get-WindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot -verbose

#quick date grab for syncro Asset field
$date = get-date -format "MM:dd:yy"
$date = $date.replace(':','.')
Set-Asset-Field -Name "Last-Updated" -Value $date
