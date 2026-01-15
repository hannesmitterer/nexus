"""
Decentralized Peer-to-Peer Communication System
Blockchain-based P2P network for Risonanza Seed Distribution
Implements Euystacio Framework decentralization principles
"""

import hashlib
import json
import time
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict


@dataclass
class Peer:
    """Represents a peer in the Risonanza network"""
    peer_id: str
    address: str
    port: int
    public_key: str
    last_seen: str
    reputation_score: float
    euystacio_field_agent: bool = False
    
    def to_dict(self):
        return asdict(self)


@dataclass
class RisonanzaSeed:
    """Represents a Risonanza seed for distribution"""
    seed_id: str
    content_hash: str
    timestamp: str
    creator_id: str
    sentimento_score: float
    encrypted: bool
    metadata: Dict
    
    def to_dict(self):
        return asdict(self)


class BlockchainNode:
    """
    Simplified blockchain node for P2P seed tracking
    Implements immutable ledger for Risonanza distribution
    """
    
    def __init__(self, node_id: str):
        self.node_id = node_id
        self.chain: List[Dict] = []
        self.pending_seeds: List[RisonanzaSeed] = []
        self.difficulty = 2  # Mining difficulty
        
        # Create genesis block
        self._create_genesis_block()
    
    def _create_genesis_block(self):
        """Create the genesis block"""
        genesis_block = {
            'index': 0,
            'timestamp': datetime.now().isoformat(),
            'seeds': [],
            'previous_hash': '0',
            'nonce': 0
        }
        genesis_block['hash'] = self._calculate_hash(genesis_block)
        self.chain.append(genesis_block)
    
    def _calculate_hash(self, block: Dict) -> str:
        """Calculate SHA-256 hash of a block"""
        block_string = json.dumps(block, sort_keys=True)
        return hashlib.sha256(block_string.encode()).hexdigest()
    
    def add_seed(self, seed: RisonanzaSeed):
        """Add a new seed to pending seeds"""
        self.pending_seeds.append(seed)
    
    def mine_block(self) -> Dict:
        """
        Mine a new block with pending seeds
        Uses proof-of-work consensus
        """
        if not self.pending_seeds:
            return None
        
        previous_block = self.chain[-1]
        
        new_block = {
            'index': len(self.chain),
            'timestamp': datetime.now().isoformat(),
            'seeds': [seed.to_dict() for seed in self.pending_seeds],
            'previous_hash': previous_block['hash'],
            'nonce': 0
        }
        
        # Proof of work
        while not self._is_valid_proof(new_block):
            new_block['nonce'] += 1
        
        new_block['hash'] = self._calculate_hash(new_block)
        
        self.chain.append(new_block)
        self.pending_seeds = []
        
        return new_block
    
    def _is_valid_proof(self, block: Dict) -> bool:
        """Check if block hash meets difficulty requirement"""
        block_hash = self._calculate_hash(block)
        return block_hash.startswith('0' * self.difficulty)
    
    def validate_chain(self) -> bool:
        """Validate the entire blockchain"""
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i - 1]
            
            # Check hash
            if current_block['hash'] != self._calculate_hash(current_block):
                return False
            
            # Check previous hash
            if current_block['previous_hash'] != previous_block['hash']:
                return False
            
            # Check proof of work
            if not current_block['hash'].startswith('0' * self.difficulty):
                return False
        
        return True
    
    def get_chain_data(self) -> List[Dict]:
        """Get full blockchain data"""
        return self.chain


class P2PNetwork:
    """
    Peer-to-Peer Network Manager for Risonanza
    Manages peer discovery, communication, and seed distribution
    """
    
    def __init__(self, node_id: str, is_efa: bool = False):
        self.node_id = node_id
        self.is_efa = is_efa
        self.peers: Dict[str, Peer] = {}
        self.blockchain = BlockchainNode(node_id)
        self.local_seeds: List[RisonanzaSeed] = []
        self.reputation_threshold = 60.0
    
    def register_peer(self, peer: Peer) -> bool:
        """Register a new peer in the network"""
        if peer.peer_id == self.node_id:
            return False  # Don't register self
        
        # Verify peer reputation
        if peer.reputation_score < self.reputation_threshold:
            print(f"Peer {peer.peer_id} rejected: Low reputation score")
            return False
        
        self.peers[peer.peer_id] = peer
        print(f"Peer {peer.peer_id} registered successfully")
        return True
    
    def discover_peers(self, bootstrap_nodes: List[str]) -> List[Peer]:
        """
        Discover peers through bootstrap nodes
        In production, this would use DHT or gossip protocol
        """
        discovered_peers = []
        
        # Simulated peer discovery
        for node_address in bootstrap_nodes:
            # In production, query bootstrap node for peer list
            # For now, create simulated peers
            peer_id = hashlib.sha256(node_address.encode()).hexdigest()[:16]
            
            peer = Peer(
                peer_id=peer_id,
                address=node_address.split(':')[0],
                port=int(node_address.split(':')[1]) if ':' in node_address else 8333,
                public_key=f"pubkey_{peer_id}",
                last_seen=datetime.now().isoformat(),
                reputation_score=85.0,
                euystacio_field_agent=False
            )
            
            if self.register_peer(peer):
                discovered_peers.append(peer)
        
        return discovered_peers
    
    def create_seed(self, content: str, metadata: Dict = None) -> RisonanzaSeed:
        """Create a new Risonanza seed"""
        content_hash = hashlib.sha256(content.encode()).hexdigest()
        
        seed = RisonanzaSeed(
            seed_id=f"SEED-{int(time.time())}-{content_hash[:8]}",
            content_hash=content_hash,
            timestamp=datetime.now().isoformat(),
            creator_id=self.node_id,
            sentimento_score=self._calculate_sentimento_score(content),
            encrypted=False,
            metadata=metadata or {}
        )
        
        self.local_seeds.append(seed)
        return seed
    
    def _calculate_sentimento_score(self, content: str) -> float:
        """
        Calculate Sentimento alignment score for content
        In production, use AI model for ethical analysis
        """
        # Simplified scoring based on content characteristics
        score = 50.0
        
        # Positive indicators
        positive_keywords = ['love', 'harmony', 'peace', 'collaboration', 'equality', 'sustainability']
        for keyword in positive_keywords:
            if keyword in content.lower():
                score += 8.0
        
        # Negative indicators
        negative_keywords = ['violence', 'exploitation', 'scarcity', 'inequality']
        for keyword in negative_keywords:
            if keyword in content.lower():
                score -= 10.0
        
        return min(max(score, 0.0), 100.0)
    
    def distribute_seed(self, seed: RisonanzaSeed) -> Dict:
        """
        Distribute seed to network peers and add to blockchain
        """
        # Add to blockchain
        self.blockchain.add_seed(seed)
        
        # Mine block to persist seed
        new_block = self.blockchain.mine_block()
        
        if new_block:
            # Broadcast to peers (simulated)
            distributed_to = []
            for peer_id, peer in self.peers.items():
                # In production, send via network protocol
                distributed_to.append(peer_id)
            
            distribution_result = {
                'seed_id': seed.seed_id,
                'block_index': new_block['index'],
                'block_hash': new_block['hash'],
                'distributed_to': distributed_to,
                'peer_count': len(distributed_to),
                'timestamp': datetime.now().isoformat()
            }
            
            print(f"Seed {seed.seed_id} distributed to {len(distributed_to)} peers")
            return distribution_result
        
        return {'error': 'Failed to mine block'}
    
    def sync_blockchain(self, peer_id: str) -> bool:
        """
        Synchronize blockchain with a peer
        In production, request full chain and validate
        """
        if peer_id not in self.peers:
            return False
        
        # Simulated sync - in production, request peer's chain
        print(f"Syncing blockchain with peer {peer_id}")
        
        # Validate own chain
        if not self.blockchain.validate_chain():
            print("Local chain validation failed")
            return False
        
        return True
    
    def get_network_status(self) -> Dict:
        """Get current network status"""
        return {
            'node_id': self.node_id,
            'is_euystacio_field_agent': self.is_efa,
            'peer_count': len(self.peers),
            'blockchain_height': len(self.blockchain.chain) - 1,
            'pending_seeds': len(self.blockchain.pending_seeds),
            'local_seeds': len(self.local_seeds),
            'chain_valid': self.blockchain.validate_chain()
        }
    
    def export_peers(self, filepath: str):
        """Export peer list to file"""
        peer_data = {
            peer_id: peer.to_dict()
            for peer_id, peer in self.peers.items()
        }
        
        with open(filepath, 'w') as f:
            json.dump(peer_data, f, indent=2)
    
    def export_blockchain(self, filepath: str):
        """Export blockchain to file"""
        chain_data = {
            'node_id': self.node_id,
            'chain': self.blockchain.get_chain_data(),
            'exported_at': datetime.now().isoformat()
        }
        
        with open(filepath, 'w') as f:
            json.dump(chain_data, f, indent=2)


# Example usage
if __name__ == "__main__":
    # Create P2P network node
    network = P2PNetwork(node_id="NODE-ALPHA-001", is_efa=True)
    
    # Discover peers
    bootstrap = ["192.168.1.100:8333", "192.168.1.101:8333", "192.168.1.102:8333"]
    discovered = network.discover_peers(bootstrap)
    
    # Create and distribute Risonanza seed
    seed = network.create_seed(
        content="Harmony and collaboration for planetary flourishing",
        metadata={
            'type': 'sentimento_message',
            'priority': 'high',
            'category': 'ethical_alignment'
        }
    )
    
    # Distribute seed
    result = network.distribute_seed(seed)
    
    # Get network status
    status = network.get_network_status()
    
    print("=" * 60)
    print("RISONANZA P2P NETWORK STATUS")
    print("=" * 60)
    print(json.dumps(status, indent=2))
    print("=" * 60)
    print("\nSeed Distribution Result:")
    print(json.dumps(result, indent=2))
    print("=" * 60)
