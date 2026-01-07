# Triple-Signature Process Instructions

## Overview
The KOSYMBIOSIS archive requires three independent GPG signatures from the project co-creators to ensure authenticity and consensus.

## Prerequisites
- GPG (GnuPG) installed on your system
- Private key for signing (or public keys for verification)
- The `kosymbiosis-archive.zip` file

## Signature Creation

### For Co-Creator 1 (Primary)
```bash
gpg --detach-sign --armor -o signatures/kosymbiosis.sig kosymbiosis-archive.zip
```

### For Co-Creator 2
```bash
gpg --detach-sign --armor -o signatures/kosymbiosis-co1.sig kosymbiosis-archive.zip
```

### For Co-Creator 3
```bash
gpg --detach-sign --armor -o signatures/kosymbiosis-co2.sig kosymbiosis-archive.zip
```

## Signature Verification

### Import Public Keys (if needed)
```bash
gpg --import co-creator-1-public.key
gpg --import co-creator-2-public.key
gpg --import co-creator-3-public.key
```

### Verify Signatures
```bash
gpg --verify signatures/kosymbiosis.sig kosymbiosis-archive.zip
gpg --verify signatures/kosymbiosis-co1.sig kosymbiosis-archive.zip
gpg --verify signatures/kosymbiosis-co2.sig kosymbiosis-archive.zip
```

### Expected Output
For each signature, you should see:
```
gpg: Signature made [DATE] using [ALGORITHM] key ID [KEY_ID]
gpg: Good signature from "[NAME] <[EMAIL]>"
```

## Signature File Format

Each `.sig` file is an ASCII-armored detached signature that looks like:
```
-----BEGIN PGP SIGNATURE-----

[Base64-encoded signature data]

-----END PGP SIGNATURE-----
```

## Verification Checklist

Before accepting the archive as final:
- [ ] All three signature files exist
- [ ] Each signature verifies successfully against the archive
- [ ] Signatures are from the expected co-creator keys
- [ ] Archive checksum matches the published SHA-256 hash
- [ ] No warnings or errors during GPG verification

## Public Key Distribution

Co-creators should publish their public keys via:
1. GPG key servers (e.g., keys.openpgp.org)
2. GitHub profile or repository
3. Project documentation

### Export Public Key
```bash
gpg --armor --export [KEY_ID] > co-creator-public.key
```

## Security Notes

- **Never share private keys** - Each co-creator signs with their own private key
- **Verify key fingerprints** - Confirm key authenticity through multiple channels
- **Check signature dates** - Ensure signatures were created at the expected time
- **Archive immutability** - Any change to the archive invalidates all signatures

## Troubleshooting

### "No public key" error
```bash
gpg: Can't check signature: No public key
```
**Solution:** Import the co-creator's public key first

### "Bad signature" error
```bash
gpg: BAD signature from ...
```
**Solution:** The archive file has been modified. Do not trust this archive.

### Key trust warnings
```bash
gpg: WARNING: This key is not certified with a trusted signature!
```
**Solution:** This is normal if you haven't personally signed the co-creator's key. Verify the key fingerprint through alternative channels.

## Integration with Archive Creation

The complete process:
1. Create archive: `./scripts/create_archive.sh`
2. Verify checksum: `sha256sum -c checksum.sha256`
3. Each co-creator signs: `gpg --detach-sign --armor -o signatures/kosymbiosis-[X].sig kosymbiosis-archive.zip`
4. Collect all signatures in `signatures/` directory
5. Verify all signatures: `./scripts/verify_archive.sh`
6. Upload to IPFS
7. Create GitHub release with archive + checksum + all signatures

## Contact

For questions about the signature process:
- Email: governance@euystacio.example
- GitHub: https://github.com/hannesmitterer/nexus/issues
