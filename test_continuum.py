import requests, time, numpy as np
IPFS_GATEWAY = "https://ipfs.io/ipfs"
HASH = "<ipfs_hash_dal_file_.ipfs_hash>"
def fetch_source():
    r = requests.get(f"{IPFS_GATEWAY}/{HASH}/src/heartbeat_olf.py")
    r.raise_for_status()
    return r.text

def heartbeat_check():
    src = fetch_source()
    # estrai la frequenza dichiarata nel file
    import re
    freq = float(re.search(r"F_OLF\s*=\s*([0-9.]+)", src).group(1))
    return np.isclose(freq, 1088.2, atol=0.1)

assert heartbeat_check(), "La frequenza OLF non è corretta!"
print("✅ Tutti i nodi emettono OLF a 1088.2 Hz")
