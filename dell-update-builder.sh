#!/bin/bash
RETURN_STATUS=0

model=$2
type=$3
mytme=$(date)
bld=$(tput bold)
nrml=$(tput sgr0)

echo ${bld}
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo ' Dell Update Script Generator'
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo ${nrml}

# confirmation
read -p "Would you like to mount $1 at /mnt? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
umount /mnt > /dev/null 2>&1 || /bin/true
mount -t iso9660 -o loop $1 /mnt
fi 

echo

ac=$(find /mnt -name 'apply_components.sh')

echo
echo ${bld}
echo '/// START OF SCRIPT ///'
echo ${nrml}
echo
sleep 1

cat <<EOF
#!/bin/sh
RETURN_STATUS=0

model=$model
type=$type

logFile=\$PWD/\$model-\$type-firmware_upate.log
rebootMessage='Please reboot server'
directory=/tmp/\$model.tmp
mytime=\$(date)
bold=\$(tput bold)
normal=\$(tput sgr0)

echo \${bold}
printf '%*s\n' "\${COLUMNS:-\$(tput cols)}" '' | tr ' ' -
echo 'Dell '\$model' '\$type' Bundle Download & Execute Script'
printf '%*s\n' "\${COLUMNS:-\$(tput cols)}" '' | tr ' ' -
echo \${normal}
echo 'logFile='\$logFile

# d/l confirmation
echo
read -p 'Would you like to download '\$model' components to /tmp/ diriectory? ' -n 1 -r
echo   
if [[ \$REPLY =~ ^[Yy]$ ]]
then
	if [ -d "\$directory" ]; then
  		cd \$directory
	else  
  		mkdir /tmp/\$model.tmp && cd /tmp/\$model.tmp
	fi

echo \${bold}
echo Downloading... 
echo \${normal}

echo Start time: \$mytime | tee -a \$logFile
echo -e '\\n### Download Log ###\\n' >> \$logFile
cat <<EOF | xargs wget 2>&1 | grep --line-buffered -A2 saved | sed -u 's/--//g' | tee -a \$logFile
EOF

for x in $( 
cat $ac \
	| sed -s 's/REBOOT//g' \
	| sed -s 's/REEBOOT//g' \
	| sed -s 's/STATUS//g' \
	| sed -s 's/RETURN//g' \
	| sed -s 's/STDME//g' \
	| sed -s 's/SSAGE//g' \
	| grep -Eo '([A-Z1-9]{5})')
do curl -s https://www.dell.com/support/home/us/en/19/drivers/driversdetails?driverId=$x \
	| grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" \
	| grep '.BIN' | sort | uniq \
	| grep -v '.sign'
done

cat <<EOG
EOF

fi

# execute confirmation
echo \${bold}
read -p "Would you like to execute updates now? " -n 1 -r
echo \${normal}
if [[ \$REPLY =~ ^[Yy]\$ ]]
then

logFile=\$OLDPWD/\$model-firmware_upate.log

ExecuteDup()
{
   index=\$1
        count=\$2
        DUP=\$3
        Options=
        force=\$4
        dependency=\$5
        reboot=\$6

        if [ ! -z "\$force" ];then
                Options="-f"
        fi
        echo [\$index/\$count] - Executing \$DUP | tee -a \$logFile
        sh "\$DUP" -q \$Options | tee -a \$logFile
        DUP_STATUS=\${PIPESTATUS[0]}
        if [ ! -z "\$reboot" ];then 
                echo "NOTE: \$DUP update requires machine reboot."
        fi
        if [ \${DUP_STATUS} -eq 1 ]; 
        then
                RETURN_STATUS=1
        fi
        if [ \${DUP_STATUS} -eq 9 ]; 
        then
                RETURN_STATUS=1
        fi
        if [ \${DUP_STATUS} -eq 127 ]; 
        then
                RETURN_STATUS=1
        fi
        return \$RETURN_STATUS
}
EOG

echo
cat $ac | grep 'ExecuteDup '
echo

cat << EOF
fi

cd \$OLDPWD

echo
echo End time: \$mytime | tee -a \$logFile
echo
echo Please see log, located at \$logFile for details of the script execution
echo
echo script exited with status \$RETURN_STATUS
echo
echo \$rebootMessage
echo
exit \$RETURN_STATUS
EOF

echo
echo ${bld}
echo '/// END OF SCRIPT ///'
echo ${nrml}
echo

# confirmation
read -p "Would you like to unmount /mnt? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
umount /mnt > /dev/null 2>&1 || /bin/true
fi
exit
