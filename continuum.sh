#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------
# CONFIGURAZIONE
# -----------------------------------------------------------------
REPO="https://github.com/hannesmitterer/nexus.git"
BRANCH="main"
WORKDIR="/tmp/omega_lex_continuum"
CONTRACT_ADDR="0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEF"   # testnet
WEB3_PROVIDER="https://sepolia.infura.io/v3/<<YOUR_INFURA_KEY>>"
IPFS_GATEWAY="https://ipfs.io/ipfs"

# -----------------------------------------------------------------
# 1️⃣ Clona (o aggiorna) il repository
# -----------------------------------------------------------------
if [[ -d "$WORKDIR" ]]; then
  echo "🔄 Aggiornamento repo..."
  cd "$WORKDIR"
  git fetch origin
  git reset --hard "origin/$BRANCH"
else
  echo "📦 Clonazione repo..."
  git clone --depth 1 "$REPO" "$WORKDIR"
  cd "$WORKDIR"
fi

# -----------------------------------------------------------------
# 2️⃣ Build dei container Docker
# -----------------------------------------------------------------
echo "🛠️ Build dei servizi..."
docker compose -f docker-compose.yml build

# -----------------------------------------------------------------
# 3️⃣ Deploy su IPFS (solo i file della directory /src)
# -----------------------------------------------------------------
echo "🚀 Caricamento su IPFS..."
IPFS_HASH=$(ipfs add -qr ./src | tail -n1)
echo "📡 IPFS hash: $IPFS_HASH"
# Salva il riferimento per il contract
echo "$IPFS_HASH" > .ipfs_hash

# -----------------------------------------------------------------
# 4️⃣ Registrazione su blockchain (smart‑contract ΩLexRegistry)
# -----------------------------------------------------------------
echo "🔏 Scrittura della hash nel contract..."
python3 <<PY
import json, os
from web3 import Web3
w3 = Web3(Web3.HTTPProvider("$WEB3_PROVIDER"))
acct = w3.eth.account.from_key(os.getenv("PRIVATE_KEY"))
with open('.ipfs_hash') as f:
    ipfs_hash = f.read().strip()
# ABI minimale: function register(bytes32 ipfsHash) public
abi = [{"inputs":[{"internalType":"bytes32","name":"ipfsHash","type":"bytes32"}],
        "name":"register","outputs":[],"stateMutability":"nonpayable","type":"function"}]
contract = w3.eth.contract(address="$CONTRACT_ADDR", abi=abi)
tx = contract.functions.register(Web3.toBytes(hexstr=ipfs_hash)).buildTransaction({
    "from": acct.address,
    "nonce": w3.eth.get_transaction_count(acct.address),
    "gas": 200000,
    "gasPrice": w3.toWei("10","gwei")
})
signed = acct.sign_transaction(tx)
tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)
print(f"📜 TX hash: {tx_hash.hex()}")
PY

# -----------------------------------------------------------------
# 5️⃣ Avvio dei nodi (LLM, RL, IoT) con OLF heartbeat
# -----------------------------------------------------------------
echo "⚡ Avvio di tutti i micro‑servizi..."
docker compose -f docker-compose.yml up -d

# -----------------------------------------------------------------
# 6️⃣ Verifica della continuità
# -----------------------------------------------------------------
echo "🔎 Controllo stato dei container..."
docker ps --filter "name=omega_lex"

echo "✅ Processo di continuità avviato con successo!"
echo "🔗 Il codice è disponibile su IPFS: $IPFS_GATEWAY/$IPFS_HASH"
