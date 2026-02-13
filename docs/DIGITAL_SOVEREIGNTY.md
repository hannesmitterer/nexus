# Digital Sovereignty Framework

## 🌐 Overview

The **Digital Sovereignty Framework** establishes the architectural principles and implementation strategy for transitioning from traditional client-server models to a distributed, decentralized system. This framework ensures that Internet Organica operates with complete sovereignty, resilience, and alignment with biological principles.

## 🎯 Core Principles

1. **Decentralization**: No single point of failure or control
2. **Data Sovereignty**: Users own and control their data
3. **Peer-to-Peer**: Direct connections without intermediaries
4. **Immutability**: Critical data cannot be altered or censored
5. **Resilience**: System continues functioning despite node failures
6. **Transparency**: All operations are auditable and verifiable

---

## 🏗️ Architecture

### From Centralized to Distributed

```
TRADITIONAL MODEL (Rejected):
┌─────────┐         ┌─────────┐
│ Client  │────────>│ Server  │
│         │<────────│         │
└─────────┘         └─────────┘
         (Single point of control)

INTERNET ORGANICA MODEL (Adopted):
    ┌─────────┐
    │  Node 1 │
    └────┬────┘
         │
┌────────┼────────┐
│        │        │
│   ┌────┴────┐  │
│   │ Node 2  │  │
│   └────┬────┘  │
│        │        │
│   ┌────┴────┐  │
│   │ Node 3  │  │
│   └────┬────┘  │
│        │        │
└────────┴────────┘
  (Distributed mesh)
```

### System Layers

```
┌─────────────────────────────────────────────────┐
│  Layer 5: Application Layer                     │
│  - Resonance School UI                          │
│  - Dashboard Applications                       │
│  - User Interfaces                              │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 4: Sovereignty Layer                     │
│  - Identity Management (DID)                    │
│  - Access Control (NSR-compliant)               │
│  - Consent Management                           │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 3: Urbit Integration Layer               │
│  - Personal Servers (Ships)                     │
│  - Network Communication                        │
│  - State Management                             │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 2: P2P Protocol Layer                    │
│  - IPFS for Content                             │
│  - OrbitDB for State                            │
│  - libp2p for Networking                        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 1: Infrastructure Layer                  │
│  - Distributed Nodes                            │
│  - Backup Systems                               │
│  - Network Infrastructure                       │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Urbit System Prototype

### What is Urbit?

[Urbit](https://urbit.org) is a clean-slate operating system and network designed for personal servers. It provides:

- **Personal Sovereignty**: Each user owns their server (ship)
- **Deterministic Computing**: Reproducible, verifiable computation
- **Peer-to-Peer Networking**: Direct ship-to-ship communication
- **Persistent Identity**: Cryptographic identity tied to your ship

### Urbit Integration Architecture

```
┌─────────────────────────────────────────────────┐
│  Resonance School Assets                        │
│  - index.html                                   │
│  - Educational Content                          │
│  - User Data                                    │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Urbit Application (Gall Agent)                 │
│  - Content Serving                              │
│  - State Management                             │
│  - P2P Distribution                             │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Urbit OS (Arvo)                                │
│  - Networking (Ames)                            │
│  - Storage (Clay)                               │
│  - HTTP Interface (Eyre)                        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Urbit Runtime (Vere)                           │
│  - Virtual Machine                              │
│  - Event Log                                    │
│  - Persistence                                  │
└─────────────────────────────────────────────────┘
```

### Urbit Gall Agent Example

```hoon
::  Resonance School Gall Agent
::  Serves educational content via Urbit
::
|%
+$  state
  $:  %0
      content=(map @t @t)        :: path -> content mapping
      subscribers=(set ship)      :: ships subscribed to updates
      last-update=@da            :: last content update time
  ==
--

=|  state
=*  state  -

|_  =bowl:gall
++  on-init
  ^-  (quip card _this)
  ::  Initialize with default content
  =/  initial-content
    %-  my
    :~  ['/index.html' (load-content %/index/html)]
        ['/style.css' (load-content %/style/css)]
    ==
  `this(content initial-content)

++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  ?=(%resonance-action mark)
  =/  action  !<(action vase)
  ?-    -.action
      %get-content
    ::  Return requested content
    =/  path  path.action
    =/  content  (~(get by content) path)
    ?~  content
      `this
    :_  this
    [%give %fact ~[/content] %resonance-content !>(u.content)]~
    
      %update-content
    ::  Update content (OLF-validated)
    ?>  (validate-olf update.action)
    =/  new-content  (~(put by content) path.action content.action)
    :_  this(content new-content, last-update now.bowl)
    ::  Notify subscribers
    %+  turn  ~(tap in subscribers)
    |=(=ship [%give %fact ~[/updates] %resonance-update !>([path.action])])
    
      %subscribe
    ::  Add subscriber
    `this(subscribers (~(put in subscribers) src.bowl))
  ==

++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  ~
      [%x %content @ ~]
    ::  Serve content via scry
    =/  content-path  (cat 3 '/' i.t.t.path)
    =/  content  (~(get by content) content-path)
    ?~  content
      [~ ~]
    ``[%resonance-content !>(u.content)]
  ==

++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%updates ~]
    ::  Allow subscription to updates
    `this(subscribers (~(put in subscribers) src.bowl))
  ==

++  on-leave
  |=  =path
  ^-  (quip card _this)
  `this(subscribers (~(del in subscribers) src.bowl))

++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--

::  Helper functions
|%
++  validate-olf
  |=  update=*
  ^-  ?
  ::  Validate update against OLF principles
  ::  - Life alignment
  ::  - Coherence
  ::  - Sovereignty
  ::  - Sustainability
  ::  - Beauty
  %.y  ::  Simplified - always true for now

++  load-content
  |=  file=@tas
  ^-  @t
  ::  Load content from Clay filesystem
  .^(@t %cx /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)/[file])
--
```

### Deployment Guide

```bash
# 1. Install Urbit
curl -L https://urbit.org/install/linux64/latest | tar xzk --strip=1

# 2. Boot your ship
./urbit -w myship -F zod  # Development ship

# 3. Install Resonance School application
|install ~sampel-palnet %resonance-school

# 4. Configure application
:resonance-school|config [initial-settings]

# 5. Upload content
:resonance-school|update-content '/index.html' (read-file 'index.html')

# 6. Start serving
:resonance-school|start

# 7. Access via browser
# http://localhost:8080/apps/resonance-school
```

---

## 📦 Decentralized Backup System

### Multi-Layer Backup Strategy

```
┌─────────────────────────────────────────────────┐
│  Layer 1: IPFS Distributed Storage              │
│  - Content-addressed files                      │
│  - Multiple pinning services                    │
│  - Global accessibility                         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 2: Blockchain Anchoring                  │
│  - CID storage on-chain                         │
│  - Immutable record                             │
│  - Verification mechanism                       │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 3: Urbit Clay Filesystem                 │
│  - Version-controlled storage                   │
│  - Deterministic state                          │
│  - Ship-to-ship replication                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Layer 4: Distributed Node Network              │
│  - Geographic distribution                      │
│  - Redundant copies                             │
│  - Auto-healing                                 │
└─────────────────────────────────────────────────┘
```

### Backup Implementation

```python
class DecentralizedBackupSystem:
    """
    Multi-layer decentralized backup system.
    
    Ensures data sovereignty and resilience through
    distributed storage and verification.
    """
    
    def __init__(self):
        self.ipfs = IPFSStorage()
        self.blockchain = BlockchainAnchor()
        self.urbit = UrbitInterface()
        self.nodes = DistributedNodeNetwork()
        
    def backup_asset(self, asset_path: str, asset_data: bytes) -> dict:
        """
        Backup asset across all layers.
        
        Args:
            asset_path: Path/identifier for asset
            asset_data: Asset content
            
        Returns:
            dict: Backup locations and verification data
        """
        backup_info = {
            'asset_path': asset_path,
            'timestamp': datetime.now().isoformat(),
            'size_bytes': len(asset_data),
            'locations': {}
        }
        
        # Layer 1: IPFS
        ipfs_cid = self.ipfs.add(asset_data, pin=True)
        backup_info['locations']['ipfs'] = {
            'cid': ipfs_cid,
            'gateways': self.ipfs.get_gateways(ipfs_cid)
        }
        
        # Layer 2: Blockchain
        tx_hash = self.blockchain.anchor_cid(ipfs_cid, asset_path)
        backup_info['locations']['blockchain'] = {
            'tx_hash': tx_hash,
            'block_number': self.blockchain.get_block_number()
        }
        
        # Layer 3: Urbit
        urbit_path = self.urbit.upload(asset_path, asset_data)
        backup_info['locations']['urbit'] = {
            'ship': self.urbit.get_ship_name(),
            'path': urbit_path
        }
        
        # Layer 4: Distributed Nodes
        node_copies = self.nodes.distribute(asset_data, min_copies=3)
        backup_info['locations']['nodes'] = {
            'count': len(node_copies),
            'node_ids': node_copies
        }
        
        # Log to Wall of Entropy
        wall_of_entropy.log_event(
            event_type='BACKUP_CREATED',
            description=f'Asset backed up: {asset_path}',
            severity='INFO',
            metadata=backup_info
        )
        
        return backup_info
    
    def verify_backup(self, asset_path: str, backup_info: dict) -> dict:
        """
        Verify backup integrity across all layers.
        
        Args:
            asset_path: Asset identifier
            backup_info: Backup location info
            
        Returns:
            dict: Verification results
        """
        results = {
            'asset_path': asset_path,
            'verified': True,
            'layers': {}
        }
        
        # Verify IPFS
        ipfs_cid = backup_info['locations']['ipfs']['cid']
        ipfs_exists = self.ipfs.verify(ipfs_cid)
        results['layers']['ipfs'] = {
            'verified': ipfs_exists,
            'accessible': self.ipfs.is_accessible(ipfs_cid)
        }
        
        # Verify Blockchain
        tx_hash = backup_info['locations']['blockchain']['tx_hash']
        blockchain_verified = self.blockchain.verify_transaction(tx_hash)
        results['layers']['blockchain'] = {
            'verified': blockchain_verified
        }
        
        # Verify Urbit
        urbit_path = backup_info['locations']['urbit']['path']
        urbit_exists = self.urbit.file_exists(urbit_path)
        results['layers']['urbit'] = {
            'verified': urbit_exists
        }
        
        # Verify Node Distribution
        node_ids = backup_info['locations']['nodes']['node_ids']
        node_count = self.nodes.count_available(node_ids)
        results['layers']['nodes'] = {
            'verified': node_count >= 2,  # At least 2 of 3 copies
            'available_count': node_count,
            'required_count': 3
        }
        
        # Overall verification
        results['verified'] = all(
            layer.get('verified', False) 
            for layer in results['layers'].values()
        )
        
        return results
    
    def restore_asset(self, asset_path: str, backup_info: dict) -> bytes:
        """
        Restore asset from most available layer.
        
        Args:
            asset_path: Asset identifier
            backup_info: Backup location info
            
        Returns:
            bytes: Restored asset data
        """
        # Try layers in order of speed/reliability
        try:
            # Try Urbit first (fastest for local ship)
            urbit_path = backup_info['locations']['urbit']['path']
            return self.urbit.download(urbit_path)
        except Exception as e:
            print(f"Urbit restore failed: {e}")
        
        try:
            # Try distributed nodes
            node_ids = backup_info['locations']['nodes']['node_ids']
            return self.nodes.retrieve(node_ids[0])
        except Exception as e:
            print(f"Node restore failed: {e}")
        
        try:
            # Try IPFS
            ipfs_cid = backup_info['locations']['ipfs']['cid']
            return self.ipfs.get(ipfs_cid)
        except Exception as e:
            print(f"IPFS restore failed: {e}")
        
        raise Exception(f"Failed to restore asset from any layer: {asset_path}")
```

---

## 🌊 P2P Protocol Integration

### IPFS Integration

Already implemented. See [IPFS_Integration_Guide.md](IPFS_Integration_Guide.md)

### Additional P2P Protocols

```python
class VacuumBridgeProtocol:
    """
    Vacuum-Bridge P2P protocol for direct peer connections.
    
    Establishes direct, encrypted connections between peers
    without centralized coordination.
    """
    
    def __init__(self):
        self.libp2p = LibP2PNode()
        self.dht = DistributedHashTable()
        self.peer_discovery = PeerDiscovery()
        
    def initialize(self) -> None:
        """Initialize Vacuum-Bridge protocol."""
        # Start libp2p node
        self.libp2p.start()
        
        # Join DHT network
        self.dht.join(bootstrap_peers=self.get_bootstrap_peers())
        
        # Start peer discovery
        self.peer_discovery.start(protocols=['mdns', 'dht'])
        
    def connect_to_peer(self, peer_id: str) -> bool:
        """
        Establish direct connection to peer.
        
        Args:
            peer_id: Peer identifier
            
        Returns:
            bool: Connection successful
        """
        # Look up peer in DHT
        peer_info = self.dht.find_peer(peer_id)
        
        if not peer_info:
            return False
        
        # Establish encrypted connection
        connection = self.libp2p.connect(
            peer_info['multiaddr'],
            protocol='/vacuum-bridge/1.0.0'
        )
        
        return connection is not None
    
    def publish_content(self, content_id: str, content: bytes) -> None:
        """
        Publish content to P2P network.
        
        Args:
            content_id: Content identifier
            content: Content data
        """
        # Store in DHT
        self.dht.put(content_id, content)
        
        # Announce to peers
        self.libp2p.pubsub.publish('content-announcements', {
            'content_id': content_id,
            'publisher': self.libp2p.peer_id,
            'timestamp': datetime.now().isoformat()
        })
    
    def retrieve_content(self, content_id: str) -> Optional[bytes]:
        """
        Retrieve content from P2P network.
        
        Args:
            content_id: Content identifier
            
        Returns:
            Optional[bytes]: Content data if found
        """
        # Try local cache first
        cached = self.dht.get_local(content_id)
        if cached:
            return cached
        
        # Query DHT
        content = self.dht.get(content_id)
        if content:
            # Cache locally
            self.dht.put_local(content_id, content)
            return content
        
        # Request from peers
        return self.request_from_peers(content_id)
    
    def request_from_peers(self, content_id: str) -> Optional[bytes]:
        """Request content from connected peers."""
        peers = self.libp2p.get_connected_peers()
        
        for peer in peers:
            try:
                response = self.libp2p.request(
                    peer,
                    '/vacuum-bridge/1.0.0',
                    {'action': 'get', 'content_id': content_id}
                )
                
                if response and response.get('content'):
                    return response['content']
            except Exception as e:
                continue
        
        return None
```

---

## 📋 Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [x] Document architecture and principles
- [ ] Set up IPFS infrastructure
- [ ] Configure blockchain anchoring
- [ ] Deploy initial distributed nodes

### Phase 2: Urbit Integration (Weeks 3-4)
- [ ] Develop Resonance School Gall agent
- [ ] Test Urbit deployment
- [ ] Implement content serving
- [ ] Set up ship-to-ship replication

### Phase 3: P2P Protocols (Weeks 5-6)
- [ ] Integrate libp2p
- [ ] Implement Vacuum-Bridge protocol
- [ ] Set up DHT network
- [ ] Test peer discovery

### Phase 4: Backup Systems (Weeks 7-8)
- [ ] Implement multi-layer backup
- [ ] Set up verification mechanisms
- [ ] Test restore procedures
- [ ] Deploy monitoring

### Phase 5: Production (Weeks 9-10)
- [ ] Security audit
- [ ] Performance testing
- [ ] Documentation completion
- [ ] Production deployment

---

## 🔐 Security Considerations

### Sovereign Identity

```python
class SovereignIdentity:
    """
    Decentralized identity management using DIDs.
    
    Users control their own identity without
    centralized authority.
    """
    
    def __init__(self):
        self.did_resolver = DIDResolver()
        
    def create_identity(self) -> dict:
        """
        Create new sovereign identity.
        
        Returns:
            dict: DID document and keys
        """
        # Generate key pair
        private_key, public_key = generate_key_pair()
        
        # Create DID
        did = f"did:internet-organica:{public_key_hash(public_key)}"
        
        # Create DID document
        did_document = {
            'id': did,
            'publicKey': [{
                'id': f"{did}#key-1",
                'type': 'Ed25519VerificationKey2018',
                'publicKeyHex': public_key.hex()
            }],
            'authentication': [f"{did}#key-1"],
            'service': []
        }
        
        return {
            'did': did,
            'document': did_document,
            'private_key': private_key
        }
```

---

## ✅ Status

**Implementation Status**: 🔄 IN PROGRESS  
**Version**: 1.0.0  
**Last Updated**: 2026-02-13  
**Framework**: Internet Organica  
**Sovereignty Level**: FULL
