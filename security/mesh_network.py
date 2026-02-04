#!/usr/bin/env python3
"""
Mesh-Based Network Architecture for Decentralization
Implements distributed mesh networking for resilience
Part of Scenario C: Globale Angriffe und Koordination defense
"""

import time
import hashlib
import json
from typing import Dict, List, Any, Optional, Set
from dataclasses import dataclass, asdict
from enum import Enum


class NodeStatus(Enum):
    """Status of a mesh node"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPECTED = "suspected"
    COMPROMISED = "compromised"


@dataclass
class MeshNode:
    """Represents a node in the mesh network"""
    node_id: str
    ip_address: str
    public_key: str
    status: NodeStatus
    reputation: float  # 0.0 to 1.0
    connected_peers: List[str]
    last_seen: float
    capabilities: List[str]
    location: Optional[str] = None


@dataclass
class Message:
    """Represents a message in the mesh network"""
    message_id: str
    sender_id: str
    recipient_id: Optional[str]  # None for broadcast
    payload: Dict[str, Any]
    timestamp: float
    ttl: int  # Time to live (hop count)
    signature: str


class MeshNetwork:
    """
    Decentralized mesh network architecture
    """
    
    def __init__(self, node_id: str, min_peer_count: int = 3):
        """
        Initialize mesh network
        
        Args:
            node_id: This node's identifier
            min_peer_count: Minimum number of peers to maintain
        """
        self.node_id = node_id
        self.min_peer_count = min_peer_count
        self.nodes: Dict[str, MeshNode] = {}
        self.routing_table: Dict[str, List[str]] = {}  # node_id -> path
        self.message_cache: Dict[str, Message] = {}
        self.processed_messages: Set[str] = set()
        
        # Initialize self as a node
        self.self_node = MeshNode(
            node_id=node_id,
            ip_address="self",
            public_key=self._generate_keypair(),
            status=NodeStatus.ACTIVE,
            reputation=1.0,
            connected_peers=[],
            last_seen=time.time(),
            capabilities=["routing", "storage", "validation"]
        )
        self.nodes[node_id] = self.self_node
    
    def add_peer(self, node: MeshNode) -> Dict[str, Any]:
        """
        Add a peer to the mesh network
        
        Args:
            node: Peer node to add
            
        Returns:
            Result of adding peer
        """
        # Verify node is not already connected
        if node.node_id in self.nodes:
            return {
                "status": "already_connected",
                "node_id": node.node_id
            }
        
        # Add node
        self.nodes[node.node_id] = node
        
        # Add to own peer list
        if node.node_id not in self.self_node.connected_peers:
            self.self_node.connected_peers.append(node.node_id)
        
        # Update routing table
        self._update_routing_table()
        
        return {
            "status": "connected",
            "node_id": node.node_id,
            "peer_count": len(self.self_node.connected_peers),
            "timestamp": time.time()
        }
    
    def remove_peer(self, node_id: str, reason: str) -> Dict[str, Any]:
        """
        Remove a peer from the network
        
        Args:
            node_id: Node to remove
            reason: Reason for removal
            
        Returns:
            Removal result
        """
        if node_id not in self.nodes:
            return {"status": "error", "message": "Node not found"}
        
        # Remove from nodes
        removed_node = self.nodes.pop(node_id)
        
        # Remove from peer list
        if node_id in self.self_node.connected_peers:
            self.self_node.connected_peers.remove(node_id)
        
        # Update routing
        self._update_routing_table()
        
        # Check if we have enough peers
        if len(self.self_node.connected_peers) < self.min_peer_count:
            return {
                "status": "removed",
                "node_id": node_id,
                "reason": reason,
                "warning": "Below minimum peer count",
                "action_required": "discover_more_peers"
            }
        
        return {
            "status": "removed",
            "node_id": node_id,
            "reason": reason,
            "remaining_peers": len(self.self_node.connected_peers)
        }
    
    def route_message(self, message: Message) -> Dict[str, Any]:
        """
        Route a message through the mesh network
        
        Args:
            message: Message to route
            
        Returns:
            Routing result
        """
        # Check if already processed
        if message.message_id in self.processed_messages:
            return {
                "status": "duplicate",
                "message_id": message.message_id
            }
        
        # Check TTL
        if message.ttl <= 0:
            return {
                "status": "expired",
                "message_id": message.message_id
            }
        
        # Mark as processed
        self.processed_messages.add(message.message_id)
        self.message_cache[message.message_id] = message
        
        # If message is for this node
        if message.recipient_id == self.node_id:
            return {
                "status": "delivered",
                "message_id": message.message_id,
                "payload": message.payload
            }
        
        # If broadcast
        if message.recipient_id is None:
            # Forward to all peers
            forwarded_to = []
            for peer_id in self.self_node.connected_peers:
                if peer_id != message.sender_id:  # Don't send back to sender
                    forwarded_to.append(peer_id)
            
            return {
                "status": "broadcast",
                "message_id": message.message_id,
                "forwarded_to": forwarded_to,
                "hop_count": message.ttl
            }
        
        # Route to specific recipient
        if message.recipient_id in self.routing_table:
            next_hop = self.routing_table[message.recipient_id][0]
            
            return {
                "status": "forwarded",
                "message_id": message.message_id,
                "next_hop": next_hop,
                "hops_remaining": message.ttl - 1
            }
        else:
            return {
                "status": "no_route",
                "message_id": message.message_id,
                "recipient_id": message.recipient_id
            }
    
    def detect_network_partition(self) -> Dict[str, Any]:
        """
        Detect if the network is partitioned
        
        Returns:
            Partition detection results
        """
        # Check connectivity
        reachable = self._find_reachable_nodes()
        total_nodes = len(self.nodes)
        
        is_partitioned = len(reachable) < total_nodes - 1  # -1 for self
        
        unreachable = set(self.nodes.keys()) - reachable - {self.node_id}
        
        return {
            "is_partitioned": is_partitioned,
            "total_nodes": total_nodes,
            "reachable_nodes": len(reachable),
            "unreachable_nodes": list(unreachable),
            "network_health": len(reachable) / max(1, total_nodes - 1),
            "timestamp": time.time()
        }
    
    def heal_network(self) -> Dict[str, Any]:
        """
        Attempt to heal network partitions
        
        Returns:
            Healing results
        """
        partition_info = self.detect_network_partition()
        
        if not partition_info["is_partitioned"]:
            return {
                "status": "healthy",
                "message": "No partition detected"
            }
        
        # Attempt to reconnect to unreachable nodes
        reconnected = []
        
        for node_id in partition_info["unreachable_nodes"]:
            if node_id in self.nodes:
                node = self.nodes[node_id]
                
                # Try to find alternative route through active peers
                for peer_id in self.self_node.connected_peers:
                    peer = self.nodes.get(peer_id)
                    if peer and node_id in peer.connected_peers:
                        # Found indirect connection
                        reconnected.append(node_id)
                        break
        
        return {
            "status": "healing_attempted",
            "total_unreachable": len(partition_info["unreachable_nodes"]),
            "reconnected": reconnected,
            "still_unreachable": list(set(partition_info["unreachable_nodes"]) - set(reconnected)),
            "timestamp": time.time()
        }
    
    def assess_node_reputation(self, node_id: str) -> Dict[str, Any]:
        """
        Assess reputation of a node
        
        Args:
            node_id: Node to assess
            
        Returns:
            Reputation assessment
        """
        if node_id not in self.nodes:
            return {"status": "error", "message": "Node not found"}
        
        node = self.nodes[node_id]
        
        # Factors affecting reputation
        factors = {
            "base_reputation": node.reputation,
            "uptime_score": 1.0 if (time.time() - node.last_seen) < 300 else 0.5,
            "peer_count_score": min(1.0, len(node.connected_peers) / 5.0),
            "status_penalty": 0.0 if node.status == NodeStatus.ACTIVE else -0.5
        }
        
        # Calculate overall score
        overall_score = sum(factors.values()) / len(factors)
        
        # Determine trust level
        if overall_score >= 0.8:
            trust_level = "HIGH"
        elif overall_score >= 0.5:
            trust_level = "MEDIUM"
        else:
            trust_level = "LOW"
        
        return {
            "node_id": node_id,
            "reputation_score": overall_score,
            "trust_level": trust_level,
            "factors": factors,
            "recommendation": "trust" if overall_score >= 0.6 else "monitor" if overall_score >= 0.3 else "disconnect",
            "timestamp": time.time()
        }
    
    def get_network_topology(self) -> Dict[str, Any]:
        """
        Get current network topology
        
        Returns:
            Network topology information
        """
        topology = {
            "total_nodes": len(self.nodes),
            "active_nodes": sum(1 for n in self.nodes.values() if n.status == NodeStatus.ACTIVE),
            "edges": [],
            "partitions": []
        }
        
        # Build edge list
        for node_id, node in self.nodes.items():
            for peer_id in node.connected_peers:
                if peer_id in self.nodes:
                    topology["edges"].append([node_id, peer_id])
        
        return topology
    
    def _update_routing_table(self):
        """Update routing table using simplified distance vector"""
        # Clear old routes
        self.routing_table = {}
        
        # Build routing table from connected peers
        for peer_id in self.self_node.connected_peers:
            if peer_id in self.nodes:
                # Direct route
                self.routing_table[peer_id] = [peer_id]
                
                # Indirect routes through this peer
                peer = self.nodes[peer_id]
                for peer_peer_id in peer.connected_peers:
                    if peer_peer_id != self.node_id and peer_peer_id not in self.routing_table:
                        self.routing_table[peer_peer_id] = [peer_id, peer_peer_id]
    
    def _find_reachable_nodes(self) -> Set[str]:
        """Find all reachable nodes using BFS"""
        reachable = set()
        queue = list(self.self_node.connected_peers)
        
        while queue:
            node_id = queue.pop(0)
            
            if node_id in reachable:
                continue
            
            reachable.add(node_id)
            
            if node_id in self.nodes:
                node = self.nodes[node_id]
                for peer_id in node.connected_peers:
                    if peer_id not in reachable and peer_id != self.node_id:
                        queue.append(peer_id)
        
        return reachable
    
    def _generate_keypair(self) -> str:
        """Generate a simple public key"""
        random_data = f"{self.node_id}{time.time()}"
        return hashlib.sha256(random_data.encode()).hexdigest()
    
    def get_network_statistics(self) -> Dict[str, Any]:
        """Get network statistics"""
        active_count = sum(1 for n in self.nodes.values() if n.status == NodeStatus.ACTIVE)
        avg_peer_count = sum(len(n.connected_peers) for n in self.nodes.values()) / max(1, len(self.nodes))
        
        return {
            "total_nodes": len(self.nodes),
            "active_nodes": active_count,
            "own_peer_count": len(self.self_node.connected_peers),
            "average_peer_count": avg_peer_count,
            "minimum_peers_met": len(self.self_node.connected_peers) >= self.min_peer_count,
            "messages_processed": len(self.processed_messages),
            "routing_table_size": len(self.routing_table),
            "timestamp": time.time()
        }


if __name__ == "__main__":
    # Example usage
    mesh = MeshNetwork(node_id="node_alpha", min_peer_count=3)
    
    # Add peers
    peer1 = MeshNode(
        node_id="node_beta",
        ip_address="10.0.0.2",
        public_key="pub_key_beta",
        status=NodeStatus.ACTIVE,
        reputation=0.9,
        connected_peers=["node_alpha", "node_gamma"],
        last_seen=time.time(),
        capabilities=["routing"]
    )
    
    peer2 = MeshNode(
        node_id="node_gamma",
        ip_address="10.0.0.3",
        public_key="pub_key_gamma",
        status=NodeStatus.ACTIVE,
        reputation=0.85,
        connected_peers=["node_alpha", "node_beta"],
        last_seen=time.time(),
        capabilities=["routing", "storage"]
    )
    
    print("Adding peers...")
    print(mesh.add_peer(peer1))
    print(mesh.add_peer(peer2))
    
    # Send message
    msg = Message(
        message_id="msg_001",
        sender_id="node_alpha",
        recipient_id=None,  # Broadcast
        payload={"type": "hello", "data": "test"},
        timestamp=time.time(),
        ttl=5,
        signature="sig_001"
    )
    
    print("\nRouting message...")
    print(mesh.route_message(msg))
    
    # Get statistics
    print("\nNetwork Statistics:")
    print(json.dumps(mesh.get_network_statistics(), indent=2))
    
    # Check for partitions
    print("\nPartition Check:")
    print(json.dumps(mesh.detect_network_partition(), indent=2))
