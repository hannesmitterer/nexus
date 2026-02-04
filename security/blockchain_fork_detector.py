#!/usr/bin/env python3
"""
Blockchain Fork Detection and Consensus Verification
Implements simultaneous consensus checking to ensure header continuity
Part of Scenario B: Systemstörungen und Sabotage defense
"""

import hashlib
import time
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict


@dataclass
class BlockHeader:
    """Represents a blockchain block header"""
    block_number: int
    timestamp: float
    previous_hash: str
    merkle_root: str
    nonce: int
    difficulty: int
    
    def hash(self) -> str:
        """Calculate block hash"""
        header_data = f"{self.block_number}{self.timestamp}{self.previous_hash}{self.merkle_root}{self.nonce}{self.difficulty}"
        return hashlib.sha256(header_data.encode()).hexdigest()


@dataclass
class ChainInfo:
    """Information about a blockchain"""
    chain_id: str
    headers: List[BlockHeader]
    total_difficulty: int
    is_canonical: bool


class BlockchainForkDetector:
    """
    Detects and validates blockchain forks through simultaneous consensus checking
    """
    
    def __init__(self, max_fork_depth: int = 100):
        """
        Initialize fork detector
        
        Args:
            max_fork_depth: Maximum depth to analyze for fork detection
        """
        self.max_fork_depth = max_fork_depth
        self.canonical_chain: List[BlockHeader] = []
        self.known_forks: Dict[str, ChainInfo] = {}
        self.fork_alerts: List[Dict[str, Any]] = []
    
    def add_block(self, header: BlockHeader) -> Dict[str, Any]:
        """
        Add a block and check for forks
        
        Args:
            header: Block header to add
            
        Returns:
            Analysis result including fork detection
        """
        result = {
            "block_number": header.block_number,
            "block_hash": header.hash(),
            "timestamp": time.time()
        }
        
        # First block
        if not self.canonical_chain:
            self.canonical_chain.append(header)
            result["status"] = "canonical_chain_initialized"
            return result
        
        # Check if block extends canonical chain
        last_block = self.canonical_chain[-1]
        
        if header.previous_hash == last_block.hash() and header.block_number == last_block.block_number + 1:
            # Valid extension
            self.canonical_chain.append(header)
            result["status"] = "canonical_extension"
            result["chain_length"] = len(self.canonical_chain)
        else:
            # Potential fork detected
            fork_result = self._analyze_fork(header)
            result["status"] = "fork_detected"
            result["fork_analysis"] = fork_result
            
            self.fork_alerts.append({
                "block_number": header.block_number,
                "block_hash": header.hash(),
                "fork_type": fork_result["fork_type"],
                "timestamp": time.time()
            })
        
        return result
    
    def verify_header_continuity(self, headers: List[BlockHeader]) -> Dict[str, Any]:
        """
        Verify continuity of block headers (ensures no manipulation)
        
        Args:
            headers: List of consecutive headers to verify
            
        Returns:
            Verification results
        """
        if not headers:
            return {"status": "error", "message": "No headers provided"}
        
        if len(headers) == 1:
            return {"status": "single_block", "valid": True}
        
        discontinuities = []
        
        for i in range(1, len(headers)):
            current = headers[i]
            previous = headers[i-1]
            
            # Check block number continuity
            if current.block_number != previous.block_number + 1:
                discontinuities.append({
                    "type": "block_number_gap",
                    "position": i,
                    "expected": previous.block_number + 1,
                    "actual": current.block_number
                })
            
            # Check hash linkage
            if current.previous_hash != previous.hash():
                discontinuities.append({
                    "type": "hash_mismatch",
                    "position": i,
                    "expected_prev_hash": previous.hash(),
                    "actual_prev_hash": current.previous_hash
                })
            
            # Check timestamp monotonicity
            if current.timestamp < previous.timestamp:
                discontinuities.append({
                    "type": "timestamp_reversal",
                    "position": i,
                    "previous_time": previous.timestamp,
                    "current_time": current.timestamp
                })
        
        return {
            "status": "complete",
            "valid": len(discontinuities) == 0,
            "headers_checked": len(headers),
            "discontinuities": discontinuities,
            "chain_integrity": "intact" if len(discontinuities) == 0 else "compromised"
        }
    
    def simultaneous_consensus_check(self, chains: List[ChainInfo]) -> Dict[str, Any]:
        """
        Check consensus across multiple chains simultaneously
        
        Args:
            chains: List of blockchain chains to compare
            
        Returns:
            Consensus analysis
        """
        if not chains:
            return {"status": "error", "message": "No chains provided"}
        
        # Find longest chain by total difficulty (proof of work)
        chains_by_difficulty = sorted(chains, key=lambda c: c.total_difficulty, reverse=True)
        canonical_candidate = chains_by_difficulty[0]
        
        consensus_result = {
            "total_chains": len(chains),
            "canonical_chain": canonical_candidate.chain_id,
            "canonical_difficulty": canonical_candidate.total_difficulty,
            "forks_detected": [],
            "consensus_strength": 0.0,
            "timestamp": time.time()
        }
        
        # Check for forks
        for chain in chains[1:]:
            if chain.total_difficulty >= canonical_candidate.total_difficulty * 0.9:
                # Competing chain (potential 51% attack or major fork)
                consensus_result["forks_detected"].append({
                    "chain_id": chain.chain_id,
                    "difficulty": chain.total_difficulty,
                    "difficulty_ratio": chain.total_difficulty / canonical_candidate.total_difficulty,
                    "threat_level": "HIGH"
                })
            elif chain.total_difficulty >= canonical_candidate.total_difficulty * 0.5:
                # Significant fork
                consensus_result["forks_detected"].append({
                    "chain_id": chain.chain_id,
                    "difficulty": chain.total_difficulty,
                    "difficulty_ratio": chain.total_difficulty / canonical_candidate.total_difficulty,
                    "threat_level": "MEDIUM"
                })
        
        # Calculate consensus strength (0-1 scale)
        if len(chains) > 1:
            difficulty_sum = sum(c.total_difficulty for c in chains)
            consensus_result["consensus_strength"] = canonical_candidate.total_difficulty / difficulty_sum
        else:
            consensus_result["consensus_strength"] = 1.0
        
        # Determine overall status
        if len(consensus_result["forks_detected"]) == 0:
            consensus_result["status"] = "HEALTHY"
        elif any(f["threat_level"] == "HIGH" for f in consensus_result["forks_detected"]):
            consensus_result["status"] = "CRITICAL"
        else:
            consensus_result["status"] = "WARNING"
        
        return consensus_result
    
    def _analyze_fork(self, header: BlockHeader) -> Dict[str, Any]:
        """
        Analyze detected fork
        
        Args:
            header: Forking block header
            
        Returns:
            Fork analysis
        """
        # Find fork point
        fork_point = None
        for i in range(len(self.canonical_chain) - 1, max(0, len(self.canonical_chain) - self.max_fork_depth), -1):
            if self.canonical_chain[i].hash() == header.previous_hash:
                fork_point = i
                break
        
        if fork_point is None:
            fork_type = "unknown_fork"
            depth = 0
        elif fork_point == len(self.canonical_chain) - 1:
            fork_type = "uncle_block"
            depth = 1
        else:
            fork_type = "deep_reorg"
            depth = len(self.canonical_chain) - fork_point - 1
        
        return {
            "fork_type": fork_type,
            "fork_depth": depth,
            "fork_point": fork_point,
            "canonical_chain_length": len(self.canonical_chain),
            "threat_assessment": "HIGH" if depth > 6 else "MEDIUM" if depth > 1 else "LOW"
        }
    
    def get_fork_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about detected forks
        
        Returns:
            Fork statistics
        """
        if not self.fork_alerts:
            return {
                "total_forks": 0,
                "status": "no_forks_detected"
            }
        
        fork_types = {}
        for alert in self.fork_alerts:
            fork_type = alert.get("fork_type", "unknown")
            fork_types[fork_type] = fork_types.get(fork_type, 0) + 1
        
        return {
            "total_forks": len(self.fork_alerts),
            "fork_types": fork_types,
            "recent_forks": self.fork_alerts[-10:],
            "canonical_chain_length": len(self.canonical_chain)
        }


if __name__ == "__main__":
    # Example usage
    detector = BlockchainForkDetector()
    
    # Create canonical chain
    headers = []
    prev_hash = "0" * 64
    for i in range(10):
        header = BlockHeader(
            block_number=i,
            timestamp=time.time() + i,
            previous_hash=prev_hash,
            merkle_root=hashlib.sha256(f"merkle{i}".encode()).hexdigest(),
            nonce=i * 1000,
            difficulty=1000000
        )
        headers.append(header)
        result = detector.add_block(header)
        print(f"Block {i}: {result['status']}")
        prev_hash = header.hash()
    
    # Verify continuity
    continuity = detector.verify_header_continuity(headers)
    print(f"\nHeader Continuity: {continuity['chain_integrity']}")
    
    # Simulate fork
    fork_header = BlockHeader(
        block_number=8,
        timestamp=time.time() + 8,
        previous_hash=headers[6].hash(),
        merkle_root=hashlib.sha256(b"fork").hexdigest(),
        nonce=8888,
        difficulty=1000000
    )
    fork_result = detector.add_block(fork_header)
    print(f"\nFork Detection: {fork_result}")
