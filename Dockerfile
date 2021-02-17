FROM ubuntu:xenial

RUN apt-get -y update && apt-get -y install --no-install-recommends sane sane-utils ghostscript netbase netpbm x11-common- wget graphicsmagick curl ssh sshpass && apt-get -y clean && rm -fr /var/lib/apt/lists/*

# brscan doesn't handle when this file doesn't exist so fail-fast (source: netbase.deb)
RUN test -f /etc/protocols

RUN wget --no-check-certificate -O /tmp/brscan.deb https://download.brother.com/welcome/dlf105200/brscan4-0.4.10-1.amd64.deb && \
    dpkg -i /tmp/brscan.deb && \
    rm /tmp/brscan.deb

RUN cd /tmp && \
    wget --no-check-certificate -O /tmp/brscan-skey.deb https://download.brother.com/welcome/dlf006652/brscan-skey-0.3.1-2.amd64.deb && \
    dpkg -i /tmp/brscan-skey.deb && \
    rm /tmp/brscan-skey.deb

ADD files/runScanner.sh /opt/brother/runScanner.sh

ADD script/scanRear.sh            /opt/brother/scanner/brscan-skey/script/scanRear.sh
ADD script/scantoemail-0.2.4-1.sh /opt/brother/scanner/brscan-skey/script/scantoemail-0.2.4-1.sh
ADD script/scantofile-0.2.4-1.sh  /opt/brother/scanner/brscan-skey/script/scantofile-0.2.4-1.sh
ADD script/scantoimage-0.2.4-1.sh /opt/brother/scanner/brscan-skey/script/scantoimage-0.2.4-1.sh
ADD script/scantoocr-0.2.4-1.sh   /opt/brother/scanner/brscan-skey/script/scantoocr-0.2.4-1.sh
ADD script/trigger_inotify.sh     /opt/brother/scanner/brscan-skey/script/trigger_inotify.sh

ENV NAME="Scanner"

# Not checked, must match models provided in brascan4
ENV MODEL="MFC-J985DW"

# IP Address or BRW${MAC} (wireless) or BRN${MACaddr} (wired), MAC = uppercase macaddr, no ":"
ENV IPADDRESS="192.168.12.59"

# This name shows as the destination on the scanner
ENV USERNAME="storageserver"

# Only set these variables if inotify needs to be triggered (e.g., for CloudStation):
#ENV SSH_USER="admin"
#ENV SSH_PASSWORD="admin"
#ENV SSH_HOST="localhost"
#ENV SSH_PATH="/path/to/scans/folder/"

# Only set these variables if you need FTP upload:
#ENV FTP_USER="scanner"
#ENV FTP_PASSWORD="scanner"
#ENV FTP_HOST="ftp.mydomain.com"
#ENV FTP_PATH="/"

# TODO: document WHY
EXPOSE 54925
EXPOSE 54921

# Directory for scans:    TODO: if this is the new /root/brscan directory, fix documentation
VOLUME /scans

#directory for config files:
VOLUME /opt/brother/scanner/brscan-skey

CMD /opt/brother/runScanner.sh
