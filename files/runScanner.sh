set -x
adduser $USERNAME --disabled-password --force-badname --gecos ""
mkdir -p /scans
chmod 777 /scans
env > /opt/brother/scanner/env.txt
case ${IPADDRESS} in
    BR[NW]*)
	ADDRESS="nodename=${IPADDRESS}" ;;
    *)
	ADDRESS="ip=${IPADDRESS}" ;;
esac

# log the scanner destination name -- brscan-skey for some reason uses username as destination description
id ${USERNAME}

/usr/bin/brsaneconfig4 -a name=${NAME} model=${MODEL} ${ADDRESS}
# log the configured device from the user's env config
/usr/bin/brsaneconfig4 -q| awk '/Devices on network/ {seen=1} (seen) {print}'

# Run brscan-skey as the user (ie the destination description)
su - ${USERNAME} -c '/usr/bin/brscan-skey -f'

while true;
do
  sleep 1000
done
exit 0
