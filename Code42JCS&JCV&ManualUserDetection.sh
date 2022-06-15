#!/bin/bash


###########################################################################################
########################################## INFO ###########################################

# Written by Rhio
# Written on July 30th, 2020
# Revamped on: April 28th, 2022 by Jamie Piperberg&#13;
# Revamped because: python 2.7 was removed from macOS 12.3&#13;
# AppleScript section written by Code42
# Script will reference the email address assigned via
# 	Jamf Connect Sync or Jamf Connect Verify and use
#	that as our login email address. These values
#	should be passed to JCS or JCV from Jamf Connect Login
#	on first login/account creation after DEP imaging
#	You will also need a PPPC for Code42.app to utilize
#	SystemUIServer otherwise the manual popup will be
#	blocked.
	
###########################################################################################




###########################################################################################
######################################## VARIABLES ########################################

# Logged in User detection
user=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Logged in User directory
userHome=$(dscl . -read "/users/$user" NFSHomeDirectory | cut -d ' ' -f 2)

# Plist location for Jamf Connect Sync
syncPlist="$userHome/Library/Preferences/com.jamf.connect.sync.plist"

# Plist Field Label for Jamf Connect Sync
syncLabel="UserLoginName"

# Plist location for Jamf Connect Verify
verifyPlist="$userHome/Library/Preferences/com.jamf.connect.verify.plist"

# Plist Field Label for Jamf Connect Verify
verifyLabel="LastUser"

# Company email suffix (excluding @ symbol), if not present, will be added
emailSuffix="fico.com"

# The question to ask your end-user if neither exists is housed and should be edited 
#	below inside of the AppleScript section (marker placed there)
# 	You also need to whitelist (PPPC) Code42.app to use SystemUIServer & have that
# 	Config Profile installed on the machine otherwise the popup will be blocked

###########################################################################################




###########################################################################################
########################################## LOGIC ##########################################

# Will check if the Jamf Connect Sync Plist exists
if [[ -e $syncPlist ]]; then
	# Reads the value of the Jamf Connect Sync plist & defines the value as a variable
	syncValue=$(defaults read "$syncPlist" "$syncLabel")
	# Converts the email address to full lowercase for ensured compatibility
	syncValue=`echo $syncValue | tr '[:upper:]' '[:lower:]'`
	
	
	# Will check if the value contains the email suffix
	if [[ "$syncValue" == *"$emailSuffix"* ]]; then
		# Reads valid email from PLIST & write the values needed by Code42 to register
		echo "C42_USERNAME=$syncValue"
		echo "C42_USER_HOME=$userHome"
	
	# Will append the email suffix & write the values needed by Code42 to register
	else
		echo "C42_USERNAME=$syncValue@$emailSuffix"
		echo "C42_USER_HOME=$userHome"			
	fi

# Will check if the Jamf Connect Verify Plist exists
elif [[ -e $verifyPlist ]]; then
	# Reads the value of the Jamf Connect Verify plist & defines the value as a variable
	verifyValue=$(defaults read "$verifyPlist" "$verifyLabel")
	# Converts the email address to full lowercase for ensured compatibility
	verifyValue=`echo $verifyValue | tr '[:upper:]' '[:lower:]'`

	# Will check if the value contains the email suffix
	if [[ "$verifyValue" == *"$emailSuffix"* ]]; then
		# Reads valid email from PLIST & write the values needed by Code42 to register
		echo "C42_USERNAME=$verifyValue"
		echo "C42_USER_HOME=$userHome"
	
	# Will append the email suffix and write the values needed by Code42 to register
	else
		echo "C42_USERNAME=$verifyValue@$emailSuffix"
		echo "C42_USER_HOME=$userHome"			
	fi

# If neither JCS or JCV exist, ask the end user for their email address
else
	function main () {
		if [[ "$user" =~ ^(localadmin|admin|test)$ ]]; then
			exit
			elif [[ -z "$user" ]]; then
			exit
		else
			ask () {
osascript <<EOF - 2>/dev/null
tell application "SystemUIServer"
activate
text returned of (display dialog "$1" default answer "")
end tell
EOF
			}
############################################################################################
# Edit in between the '' with preferred verbiage in case of manual entry being required
############################################################################################

			name=$(ask 'Code42 - Please verify your email address to initialize your backup:')
			
			# Converts the email address to full lowercase for ensured compatibility
			name=`echo $name | tr '[:upper:]' '[:lower:]'`
			
			# Writes the values needed by Code42 to register
			echo "C42_USERNAME=$name"
			echo "C42_USER_HOME=$userHome"
		fi
	}
	main "$@"
fi

############################################################################################

exit 0