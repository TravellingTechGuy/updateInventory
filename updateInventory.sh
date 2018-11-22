#!/bin/bash

############################################################################################################################################
#	QUICK SCRIPT WRITTEN BY TRAVELLING TECH GUY FOR BLOG POST ON: https://travellingtechguy.eu/jamf-api-ios-shortcuts/‎(opens in a new tab)
#	
#	TRAVELLING TECH GUY - 22TH OF NOVEMBER 2018
#	
#	SCRIPT MADE AS PROOF OF CONCEPT - MIGHT NOT BE SUITABLE FOR LARGE DEVICE COUNTS
#
#	USE AT OWN RISK
#
############################################################################################################################################

# add your API username, password and Jamf Pro URL
apiUser='API USERNAME GOES HERE'
apiPW='API PASSWORD GOES HERE'
jamfURL='https://JAMFPRO URL GOES HERE'

############################################################################################################################################
# DO NOT EDIT BELOW 

# GET ALL JAMF PRO DEVICE ID's (all enrolled devices)
jamfIDs=$(curl -H "Accept: text/xml" -s -X GET -u $apiUser:$apiPW $jamfURL/JSSResource/mobiledevices | xmllint --format - | awk -F '>|<' '/<id>/,/<\/id>/{print $3}')

# REFORMAT LIST OF ID's
pushIDs=$(echo $jamfIDs | sed 's/ /,/g')


echo "Pushing command to device ID's:" $pushIDs
echo " "

# CLEAR ALL PENDING and FAILED COMMANDS - OPTIONAL - Just added it to avoid "Command might be pending" error
curl -s -H "Accept: text/xml" -X POST -u $apiUser:$apiPW $jamfURL/JSSResource/commandflush/mobiledevices/id/$pushIDs/status/Pending+Failed > /tmp/JamfReponse1.xml

# PUSH UPDATE INVENTORY COMMAND TO ALL DEVICES
curl -H "Accept: text/xml" -s -X POST -u $apiUser:$apiPW $jamfURL/JSSResource/mobiledevicecommands/command/UpdateInventory/id/$pushIDs > /tmp/JamfReponse2.xml

# CHECK IF SERVER RESPONSE IS XML
checkxml=$(xmllint --format /tmp/JamfReponse2.xml 2> /dev/null)

if [ $? -eq 0 ]
	# IF XML REPORT STATUS FOR EACH ID
then
					echo "Feedback:"
					echo " "

					echo "*** Command sent ***"
					echo " "

					xmllint /tmp/JamfReponse2.xml --xpath "//mobile_device_command/mobile_devices/mobile_device/*" > /tmp/outLog.txt

					sed -i -e 's/<id>/Device: /g; s/<\/id>/ -/g; s/<status>/ /g; s/<\/status>/\'$'\n/g' /tmp/outLog.txt

					cat /tmp/outLog.txt
					rm /tmp/outLog.txt
					rm /tmp/JamfReponse1.xml
					rm /tmp/JamfReponse2.xml


else
	# IF NOT XML (server might be replying with "BAD REQUEST - COMMAND MIGHT BE PENDING - if not cleared above)
	# READ RESPONSE
  cat /tmp/JamfReponse2.xml
  rm /tmp/JamfReponse1.xml
  rm /tmp/JamfReponse2.xml
fi
