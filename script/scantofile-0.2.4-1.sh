#!/bin/bash
# $1 = scanner device
# $2 = friendly name

#override environment, as brscan is screwing it up:
export $(grep -v '^#' /opt/brother/scanner/env.txt | xargs)

# Resolution (dpi):
# 100,200,300,400,600
resolution=300
device=$1
date=$(date +%Y-%m-%d-%H-%M-%S)

mkdir "/scans/$date"
cd "/scans/$date"
filename_base=/scans/$date/$date"-front-page"
output_file=$filename_base"%04d.pnm"
echo "filename: "$output_file

if [ "`which usleep  2>/dev/null `" != '' ];then
    usleep 100000
else
    sleep  0.1
fi
echo command: scanimage -l 0 -t 0 -x 215 -y 297 --device-name "$device" --source "Automatic Document Feeder(centrally aligned)" --resolution $resolution --batch=$output_file
scanimage -l 0 -t 0 -x 215 -y 297 --device-name "$device" --source "Automatic Document Feeder(centrally aligned)" --resolution $resolution --batch=$output_file
if [ ! -s $filename_base"0001.pnm" ];then
  if [ "`which usleep  2>/dev/null `" != '' ];then
    usleep 1000000
  else
    sleep  1
  fi
  scanimage -l 0 -t 0 -x 215 -y 297 --device-name "$device" --source "Automatic Document Feeder(centrally aligned)" --resolution $resolution --batch=$output_file
fi

#only convert when no back pages are being scanned:
(
	if [ "`which usleep  2>/dev/null `" != '' ];then
		usleep 120000000
	else
		sleep  120
	fi
	
	(
		echo "(scantofile) Converting to PDF for $date..."
		ls -al $filename_base*.pnm

		echo command: gm convert -page A4+0+0 $filename_base*.pnm /scans/$date.pdf
		gm convert -page A4+0+0 $filename_base*.pnm /scans/$date.pdf
		echo gm result: $? /scans/$date.pdf

		if test -n "$SSH_USER"; then
		echo command: /opt/brother/scanner/brscan-skey/script/trigger_inotify.sh $SSH_USER $SSH_PASSWORD $SSH_HOST $SSH_PATH $date.pdf
		/opt/brother/scanner/brscan-skey/script/trigger_inotify.sh $SSH_USER $SSH_PASSWORD $SSH_HOST $SSH_PATH $date.pdf
		echo trigger_notify result: $?
		else
		echo no trigger_notify: no SSH_USER given >&2
		fi

		if test -n "$FTP_USER"; then
		echo command: scp --password ${FTP_PASSWORD} $date.pdf ${FTP_USER}@${FTP_HOST}:${FTP_PATH}
		scp --password ${FTP_PASSWORD} $date.pdf ${FTP_USER}@${FTP_HOST}:${FTP_PATH}
		echo scp result: $?
		else
		echo no scp: no FTP_USER given
		fi
	
		echo "cleaning up for $date..."
		cd /scans
		rm -rf $date

		if test -f /scans/$date.pdf
		then
		echo "starting OCR for $date..."
		(
			curl -F "userfile=@/scans/$date.pdf" -H "Expect:" -o /scans/$date-ocr.pdf localhost:32800/ocr.php
			/opt/brother/scanner/brscan-skey/script/trigger_inotify.sh $SSH_USER $SSH_PASSWORD $SSH_HOST $SSH_PATH $date-ocr.pdf
		) &
		fi
	) &
) &
echo $! > scan_pid
echo "conversion process for $date is running in PID: "$(cat scan_pid)
