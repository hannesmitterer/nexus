#!/usr/bin/env python3
"""
Vacuum-Bridge - IPFS/P2P Integration Module
Implements decentralized content distribution and sovereign data preservation.
Part of Internet Organica framework - distributed sovereignty layer.
"""

import hashlib
import json
import os
import time
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple


class VacuumBridge:
    """
    Vacuum-Bridge P2P/IPFS integration for decentralized content distribution.

    Provides content-addressed storage, peer discovery, and decentralized
    backup capabilities aligned with the Digital Sovereignty Framework.
    When a live IPFS node is available the bridge delegates to it; otherwise
    it operates in local-simulation mode so the module remains functional
    without external dependencies.
    """

    def __init__(self,
                 ipfs_api: str = '/ip4/127.0.0.1/tcp/5001',
                 storage_dir: str = '.vacuum_bridge'):
        """
        Initialize Vacuum-Bridge.

        Args:
            ipfs_api: IPFS API multiaddr (used when ipfshttpclient is available)
            storage_dir: Local storage directory for offline/simulation mode
        """
        self.ipfs_api = ipfs_api
        self.storage_dir = storage_dir
        self._ipfs_client = None
        self._mode = 'local'

        os.makedirs(storage_dir, exist_ok=True)

        # Attempt to connect to a live IPFS node
        try:
            import ipfshttpclient  # type: ignore
            self._ipfs_client = ipfshttpclient.connect(ipfs_api)
            self._mode = 'ipfs'
        except Exception:
            # Fall back to local-simulation mode (stdlib only)
            self._mode = 'local'

        self._local_store: Dict[str, Dict[str, Any]] = {}
        self._peers: List[str] = []
        self._load_local_store()

    # ------------------------------------------------------------------
    # Content Storage
    # ------------------------------------------------------------------

    def add_content(self, content: bytes, name: str = '') -> str:
        """
        Add content to the distributed store.

        In IPFS mode the content is added to the connected IPFS node.
        In local mode a deterministic content-addressed identifier is
        generated from the SHA-256 hash of the content (Qm-prefixed to
        mimic IPFS CID v0 format without external dependencies).

        Args:
            content: Raw bytes to store
            name: Optional human-readable label

        Returns:
            str: Content identifier (CID in IPFS mode, Qm-hash in local mode)
        """
        if self._mode == 'ipfs' and self._ipfs_client:
            try:
                result = self._ipfs_client.add_bytes(content)
                cid = result if isinstance(result, str) else result['Hash']
                self._record_local(cid, content, name)
                return cid
            except Exception:
                pass

        # Local simulation: derive a deterministic CID
        cid = self._simulate_cid(content)
        self._record_local(cid, content, name)
        return cid

    def add_json(self, data: Dict[str, Any], name: str = '') -> str:
        """
        Add JSON data to the distributed store.

        Args:
            data: Dictionary to serialise and store
            name: Optional human-readable label

        Returns:
            str: Content identifier
        """
        content = json.dumps(data, sort_keys=True).encode('utf-8')
        return self.add_content(content, name=name)

    def get_content(self, cid: str) -> Optional[bytes]:
        """
        Retrieve content by its identifier.

        Args:
            cid: Content identifier

        Returns:
            bytes or None if not found
        """
        if self._mode == 'ipfs' and self._ipfs_client:
            try:
                return self._ipfs_client.cat(cid)
            except Exception:
                pass

        # Fall back to local store
        record = self._local_store.get(cid)
        if record:
            return record.get('content_bytes')

        # Try reading from disk
        path = os.path.join(self.storage_dir, cid + '.bin')
        if os.path.exists(path):
            with open(path, 'rb') as f:
                return f.read()

        return None

    # ------------------------------------------------------------------
    # Decentralised Backup
    # ------------------------------------------------------------------

    def backup_file(self, file_path: str) -> Tuple[str, Dict[str, Any]]:
        """
        Create a decentralised backup of a local file.

        Args:
            file_path: Path to the file to back up

        Returns:
            Tuple of (cid, backup_manifest)
        """
        with open(file_path, 'rb') as f:
            content = f.read()

        name = os.path.basename(file_path)
        cid = self.add_content(content, name=name)

        manifest = {
            'cid': cid,
            'name': name,
            'size_bytes': len(content),
            'sha256': hashlib.sha256(content).hexdigest(),
            'backed_up_at': datetime.now().isoformat(),
            'mode': self._mode,
        }

        manifest_cid = self.add_json(manifest, name=f'{name}.manifest')
        manifest['manifest_cid'] = manifest_cid

        return cid, manifest

    def backup_directory(self, dir_path: str,
                         extensions: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Back up all files in a directory to the distributed store.

        Args:
            dir_path: Directory to back up
            extensions: Optional list of file extensions to include (e.g. ['.html', '.md'])

        Returns:
            dict: Summary of backed-up files
        """
        backed_up = []
        errors = []

        for root, _, files in os.walk(dir_path):
            for fname in files:
                if extensions and not any(fname.endswith(ext) for ext in extensions):
                    continue
                fpath = os.path.join(root, fname)
                try:
                    cid, manifest = self.backup_file(fpath)
                    backed_up.append({'path': fpath, 'cid': cid})
                except Exception as exc:
                    errors.append({'path': fpath, 'error': str(exc)})

        return {
            'backed_up': backed_up,
            'errors': errors,
            'total': len(backed_up),
            'mode': self._mode,
            'timestamp': datetime.now().isoformat(),
        }

    # ------------------------------------------------------------------
    # Peer Management
    # ------------------------------------------------------------------

    def register_peer(self, peer_id: str) -> None:
        """Register a peer node."""
        if peer_id not in self._peers:
            self._peers.append(peer_id)
            self._save_peers()

    def get_peers(self) -> List[str]:
        """Return list of registered peers."""
        return list(self._peers)

    def _save_peers(self) -> None:
        """Persist peer list to disk."""
        peers_file = os.path.join(self.storage_dir, 'peers.json')
        try:
            with open(peers_file, 'w', encoding='utf-8') as f:
                json.dump(self._peers, f)
        except IOError:
            pass

    # ------------------------------------------------------------------
    # Metadata Validation
    # ------------------------------------------------------------------

    def validate_content(self, cid: str, expected_sha256: str) -> bool:
        """
        Validate content integrity by SHA-256 hash.

        Args:
            cid: Content identifier to validate
            expected_sha256: Expected SHA-256 hex digest

        Returns:
            bool: True if content hash matches
        """
        content = self.get_content(cid)
        if content is None:
            return False
        actual = hashlib.sha256(content).hexdigest()
        return actual == expected_sha256

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _simulate_cid(self, content: bytes) -> str:
        """
        Generate a deterministic CID-like identifier from content hash.

        Returns a 'Qm'-prefixed hex string derived from SHA-256, matching
        the visual form of an IPFS CIDv0 without requiring external deps.
        """
        digest = hashlib.sha256(content).hexdigest()
        return f"Qm{digest[:44]}"

    def _record_local(self, cid: str, content: bytes, name: str) -> None:
        """Store content in local index and on disk."""
        self._local_store[cid] = {
            'cid': cid,
            'name': name,
            'size_bytes': len(content),
            'sha256': hashlib.sha256(content).hexdigest(),
            'added_at': datetime.now().isoformat(),
            'content_bytes': content,
        }
        # Persist to disk (binary blob)
        path = os.path.join(self.storage_dir, cid + '.bin')
        try:
            with open(path, 'wb') as f:
                f.write(content)
        except IOError:
            pass

        # Persist index
        self._save_local_store()

    def _load_local_store(self) -> None:
        """Load local content index from disk."""
        index_path = os.path.join(self.storage_dir, 'index.json')
        if not os.path.exists(index_path):
            return
        try:
            with open(index_path, 'r', encoding='utf-8') as f:
                index = json.load(f)
            # Restore metadata without in-memory content bytes
            for cid, meta in index.items():
                self._local_store[cid] = meta
        except (IOError, json.JSONDecodeError):
            pass

    def _save_local_store(self) -> None:
        """Persist content index to disk (without raw bytes)."""
        index_path = os.path.join(self.storage_dir, 'index.json')
        serialisable = {
            cid: {k: v for k, v in meta.items() if k != 'content_bytes'}
            for cid, meta in self._local_store.items()
        }
        try:
            with open(index_path, 'w', encoding='utf-8') as f:
                json.dump(serialisable, f, indent=2)
        except IOError:
            pass

    def get_status(self) -> Dict[str, Any]:
        """Return current bridge status."""
        return {
            'mode': self._mode,
            'ipfs_api': self.ipfs_api,
            'storage_dir': self.storage_dir,
            'stored_items': len(self._local_store),
            'registered_peers': len(self._peers),
            'timestamp': datetime.now().isoformat(),
        }


# Global instance for application-wide use
vacuum_bridge = VacuumBridge(storage_dir='/tmp/.vacuum_bridge')


if __name__ == "__main__":
    print("Vacuum-Bridge - IPFS/P2P Integration")
    print("=" * 50)

    bridge = VacuumBridge(storage_dir='/tmp/.vacuum_bridge_test')

    status = bridge.get_status()
    print(f"Mode: {status['mode']}")
    print(f"Storage: {status['storage_dir']}")

    # Store example content
    content = b"Internet Organica - Lex Amoris framework content"
    cid = bridge.add_content(content, name="test_document")
    print(f"\nStored content CID: {cid}")

    # Retrieve and verify
    retrieved = bridge.get_content(cid)
    sha256 = hashlib.sha256(content).hexdigest()
    valid = bridge.validate_content(cid, sha256)
    print(f"Content retrieved: {retrieved == content}")
    print(f"Integrity valid: {valid}")

    # JSON data
    data = {'framework': 'Internet Organica', 'principles': ['Lex Amoris', 'NSR', 'OLF']}
    json_cid = bridge.add_json(data)
    print(f"\nStored JSON CID: {json_cid}")

    print(f"\nFinal status: {json.dumps(bridge.get_status(), indent=2)}")
