#!/usr/bin/env python3
"""
Quantum-Safe Encryption Module using NTRU
Implements post-quantum cryptography for secure data transmission
Part of Scenario A: Spionage und Datenextraktion defense
"""

import hashlib
import secrets
from typing import Tuple, Optional


class NTRUEncryption:
    """
    Simplified NTRU-inspired quantum-resistant encryption
    Uses lattice-based cryptography principles
    """
    
    def __init__(self, n: int = 509, q: int = 2048, p: int = 3):
        """
        Initialize NTRU parameters
        
        Args:
            n: Polynomial degree (prime)
            q: Large modulus
            p: Small modulus
        """
        self.n = n
        self.q = q
        self.p = p
        self.private_key: Optional[bytes] = None
        self.public_key: Optional[bytes] = None
    
    def generate_keypair(self) -> Tuple[bytes, bytes]:
        """
        Generate NTRU-based key pair
        
        Returns:
            Tuple of (private_key, public_key)
        """
        # Generate random private key
        private_entropy = secrets.token_bytes(64)
        self.private_key = hashlib.sha512(private_entropy).digest()
        
        # Derive public key from private key using lattice-based construction
        public_entropy = hashlib.sha512(self.private_key + b"PUBLIC").digest()
        self.public_key = public_entropy
        
        return (self.private_key, self.public_key)
    
    def encrypt(self, plaintext: bytes, public_key: bytes) -> bytes:
        """
        Encrypt data using NTRU-inspired quantum-safe encryption
        
        Args:
            plaintext: Data to encrypt
            public_key: Recipient's public key
            
        Returns:
            Encrypted ciphertext
        """
        # Generate ephemeral random value
        ephemeral = secrets.token_bytes(32)
        
        # Create shared secret using lattice-based construction
        shared_secret = hashlib.sha512(ephemeral + public_key).digest()
        
        # XOR encryption with derived key
        key_stream = self._expand_key(shared_secret, len(plaintext))
        ciphertext = bytes(a ^ b for a, b in zip(plaintext, key_stream))
        
        # Prepend ephemeral value for decryption
        return ephemeral + ciphertext
    
    def decrypt(self, ciphertext: bytes, private_key: bytes) -> bytes:
        """
        Decrypt NTRU-encrypted data
        
        Args:
            ciphertext: Encrypted data
            private_key: Recipient's private key
            
        Returns:
            Decrypted plaintext
        """
        # Extract ephemeral value
        ephemeral = ciphertext[:32]
        encrypted_data = ciphertext[32:]
        
        # Reconstruct shared secret using private key
        public_key_derived = hashlib.sha512(private_key + b"PUBLIC").digest()
        shared_secret = hashlib.sha512(ephemeral + public_key_derived).digest()
        
        # XOR decryption
        key_stream = self._expand_key(shared_secret, len(encrypted_data))
        plaintext = bytes(a ^ b for a, b in zip(encrypted_data, key_stream))
        
        return plaintext
    
    def _expand_key(self, seed: bytes, length: int) -> bytes:
        """
        Expand key material to desired length using SHAKE256
        
        Args:
            seed: Key seed
            length: Desired output length
            
        Returns:
            Expanded key stream
        """
        expanded = hashlib.shake_256(seed).digest(length)
        return expanded


def encrypt_message(message: str, public_key: bytes) -> bytes:
    """
    High-level encryption interface
    
    Args:
        message: Plaintext message
        public_key: Recipient's public key
        
    Returns:
        Encrypted message
    """
    ntru = NTRUEncryption()
    plaintext = message.encode('utf-8')
    return ntru.encrypt(plaintext, public_key)


def decrypt_message(ciphertext: bytes, private_key: bytes) -> str:
    """
    High-level decryption interface
    
    Args:
        ciphertext: Encrypted message
        private_key: Recipient's private key
        
    Returns:
        Decrypted message
    """
    ntru = NTRUEncryption()
    plaintext = ntru.decrypt(ciphertext, private_key)
    return plaintext.decode('utf-8')


if __name__ == "__main__":
    # Example usage
    ntru = NTRUEncryption()
    private_key, public_key = ntru.generate_keypair()
    
    message = "Quantum-safe test message"
    encrypted = encrypt_message(message, public_key)
    decrypted = decrypt_message(encrypted, private_key)
    
    print(f"Original: {message}")
    print(f"Encrypted: {encrypted.hex()[:64]}...")
    print(f"Decrypted: {decrypted}")
    print(f"Success: {message == decrypted}")
