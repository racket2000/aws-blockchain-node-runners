#!/bin/bash

echo "[LOG] script start"

set +e

{
  echo "AWS_REGION=${_AWS_REGION_}"
  echo "STACK_NAME=${_STACK_NAME_}"
  echo "STACK_ID=${_STACK_ID_}"
  echo "RESOURCE_ID=${_NODE_CF_LOGICAL_ID_}"

  echo "DATA_VOLUME_TYPE=${_DATA_VOLUME_TYPE_}"
  echo "DATA_VOLUME_SIZE=${_DATA_VOLUME_SIZE_}"
  echo "NETWORK_ID=${_NETWORK_ID_}"

} >> /etc/environment

source /etc/environment

# via https://github.com/Contribution-DAO/sui-node-setup
# Modifications made by yinalaws in 2024
# ASCII art removed for brevity, silenced interactions, added testnet p2p, Ubuntu 24.04 LTS tests

# 1. Updating packages
echo "[LOG] updating packages"
sudo apt-get -qq update && sudo apt upgrade -y
sudo apt-get -qq install -y build-essential
sudo apt-get -qq install -y libclang-dev
sudo apt-get -qq install -y pkg-config libssl-dev

# emitting cfn-signal event
sudo apt-get -qq install -y python3-pip
sudo pip3 install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
cfn-signal --stack $STACK_NAME --resource $RESOURCE_ID --region $AWS_REGION

# Check if GCC is installed silently
if ! command -v gcc &> /dev/null; then
    exit 1
fi

# Create symlink for cc to gcc if not exists
if ! command -v cc &> /dev/null; then
    sudo ln -sf /usr/bin/gcc /usr/bin/cc
fi

# Add /usr/bin to PATH if not already in PATH
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
    export PATH=$PATH:/usr/bin
    # Add to ~/.bashrc or ~/.bash_profile to make it permanent
    echo 'export PATH=$PATH:/usr/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# 2. Install dependencies
echo "[LOG] Install dependencies"

sudo apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates curl cmake jq
sudo apt install -y libprotobuf-dev protobuf-compiler

# 3. Install Rust
echo "[LOG] install rust"
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# 4. Download Sui Binaries
# echo "[LOG] sui binaries"
# cd $HOME
# git clone https://github.com/MystenLabs/sui.git --branch testnet --single-branch
# cd sui
# # git remote add upstream https://github.com/MystenLabs/sui
# # git fetch upstream
# # git checkout -B testnet --track upstream/testnet

# cargo build -p sui-node -p sui --release
# sudo mv ~/sui/target/release/sui-node /usr/local/bin/
# sudo mv ~/sui/target/release/sui /usr/local/bin/

# Downloading sui binaries from Github
wget https://github.com/MystenLabs/sui/releases/download/mainnet-v1.27.4/sui-mainnet-v1.27.4-ubuntu-x86_64.tgz
tar -xvzf sui-mainnet-v1.27.4-ubuntu-x86_64.tgz
sudo mv ./sui-node /usr/local/bin/
sudo mv ./sui /usr/local/bin/


# 5. Update Configs
echo "[LOG] update configs"
mkdir -p $HOME/.sui/
cd $HOME/.sui/

# Genesis for Testnet
wget -O genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob

# Genesis for Mainnet
# wget -O genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/mainnet/genesis.blob

# Genesis for Devnet
# wget -O genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob

cp $HOME/sui/crates/sui-config/data/fullnode-template.yaml $HOME/.sui/fullnode.yaml
sed -i 's/127.0.0.1/0.0.0.0/'  $HOME/.sui/fullnode.yaml
sed -i "s|db-path:.*|db-path: $HOME/.sui/db|g" $HOME/.sui/fullnode.yaml
sed -i "s|genesis-file-location:.*|genesis-file-location: $HOME/.sui/genesis.blob|g" $HOME/.sui/fullnode.yaml

# Testnet p2p peers
echo "[LOG] testnet p2p peers"

cat << EOF >> $HOME/.sui/fullnode.yaml

p2p-config:
  seed-peers:
    - address: /dns/yto-tnt-ssfn-01.testnet.sui.io/udp/8084
      peer-id: 2ed53564d5581ded9b6773970ac2f1c84d39f9edf01308ff5a1ffe09b1add7b3
    - address: /dns/yto-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: 6563732e5ab33b4ae09c73a98fd37499b71b8f03c27b5cc51acc26934974aff2
    - address: /dns/nrt-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: 23a1f7cd901b6277cbedaa986b3fc183f171d800cabba863d48f698f518967e1
    - address: /dns/ewr-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: df8a8d128051c249e224f95fcc463f518a0ebed8986bbdcc11ed751181fecd38
    - address: /dns/lax-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: f9a72a0a6c17eed09c27898eab389add704777c03e135846da2428f516a0c11d
    - address: /dns/lhr-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: 9393d6056bb9c9d8475a3cf3525c747257f17c6a698a7062cbbd1875bc6ef71e
    - address: /dns/mel-tnt-ssfn-00.testnet.sui.io/udp/8084
      peer-id: c88742f46e66a11cb8c84aca488065661401ef66f726cb9afeb8a5786d83456e

EOF

# Mainnet peer configuration
# p2p-config:
#   seed-peers:
#     - address: /dns/mel-00.mainnet.sui.io/udp/8084
#       peer-id: d32b55bdf1737ec415df8c88b3bf91e194b59ee3127e3f38ea46fd88ba2e7849
#     - address: /dns/ewr-00.mainnet.sui.io/udp/8084
#       peer-id: c7bf6cb93ca8fdda655c47ebb85ace28e6931464564332bf63e27e90199c50ee
#     - address: /dns/ewr-01.mainnet.sui.io/udp/8084
#       peer-id: 3227f8a05f0faa1a197c075d31135a366a1c6f3d4872cb8af66c14dea3e0eb66
#     - address: /dns/lhr-00.mainnet.sui.io/udp/8084
#       peer-id: c619a5e0f8f36eac45118c1f8bda28f0f508e2839042781f1d4a9818043f732c
#     - address: /dns/sui-mainnet-ssfn-1.nodeinfra.com/udp/8084
#       peer-id: 0c52ca8d2b9f51be4a50eb44ace863c05aadc940a7bd15d4d3f498deb81d7fc6
#     - address: /dns/sui-mainnet-ssfn-2.nodeinfra.com/udp/8084
#       peer-id: 1dbc28c105aa7eb9d1d3ac07ae663ea638d91f2b99c076a52bbded296bd3ed5c
#     - address: /dns/sui-mainnet-ssfn-ashburn-na.overclock.run/udp/8084
#       peer-id: 5ff8461ab527a8f241767b268c7aaf24d0312c7b923913dd3c11ee67ef181e45
#     - address: /dns/sui-mainnet-ssfn-dallas-na.overclock.run/udp/8084
#       peer-id: e1a4f40d66f1c89559a195352ba9ff84aec28abab1d3aa1c491901a252acefa6
#     - address: /dns/ssn01.mainnet.sui.rpcpool.com/udp/8084
#       peer-id: fadb7ccb0b7fc99223419176e707f5122fef4ea686eb8e80d1778588bf5a0bcd
#     - address: /dns/ssn02.mainnet.sui.rpcpool.com/udp/8084
#       peer-id: 13783584a90025b87d4604f1991252221e5fd88cab40001642f4b00111ae9b7e


# Devnet peer configuration
# Don't need to configure peers for devnet

# 6. Make Sui Service
echo "[LOG] make Sui service"

sudo tee /etc/systemd/system/suid.service > /dev/null <<EOF
[Unit]
Description=Sui node
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/sui-node --config-path $HOME/.sui/fullnode.yaml
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/journald.conf > /dev/null <<EOF
Storage=persistent
EOF

sudo systemctl daemon-reload
sudo systemctl enable suid
sudo systemctl restart suid

# Check Sui status
if systemctl is-active --quiet suid; then
  echo "Sui node installed and running normally."
else
  echo "Sui node installation failed. Please re-install."
fi

# Display Sui version
echo "[LOG] Sui Version: $(sui -V)"

echo "Sui Version: $(sui -V)"



# Useful commands (added as comments)
# Check your node logs: journalctl -fu suid -o cat
# Check your node status: sudo service suid status
# Restart your node: sudo systemctl restart suid
# Stop your node: sudo systemctl stop suid
# Start your node: sudo systemctl start suid
