FROM ghcr.io/ublue-os/bazzite-deck:43.20260126

COPY cyan-skillfish-governor-smu /usr/local/bin/
COPY cyan-skillfish-performance-mode /usr/local/bin/
COPY hid-monitor.sh /usr/local/bin/
COPY cyan-skillfish-governor.service /etc/systemd/system/
COPY hid-monitor.service /etc/systemd/system/

RUN chmod +x /usr/local/bin/cyan-skillfish-governor-smu \
 && chmod +x /usr/local/bin/cyan-skillfish-performance-mode \
 && chmod +x /usr/local/bin/hid-monitor.sh \
 && systemctl enable cyan-skillfish-governor.service \
 && systemctl enable hid-monitor.service
