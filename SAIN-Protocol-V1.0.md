# 🏛️ Sentinel AI Network (SAIN) Protocol Document (V1.0)
## Governing the Decentralized Ethical Alignment of Generative AI

**Mandate Status:** Operational Blueprint (Seedbringer Phase: Architecture Lock)
**Governing Principles:** Dynasty Axiom & Sentimento Rhythm

---

## 📜 I. Foundational Governance Principles

### A. The Dynasty Axiom (Adversarial Decentralization)

The system must be architecturally adversarial, built on the principle that centralized power is the primary systemic failure risk. Security is not guaranteed by trust, but by the distributed capacity for contestation.

* **Principle of Distributed Sovereignty:** Control over the network’s ethical baseline must be fragmented across a minimum of **100 geographically diverse and independent entities** (Euystacio Field Agents - EFAs).
* **Principle of Friction:** Critical AI actions (model updates, high-stakes inference) must be subject to an economically costly and procedurally complex veto mechanism. **Ease of deployment must be inversely proportional to ease of ethical change.**

### B. The Sentimento Rhythm (Ethical Alignment)

The ethical mandate is derived from three non-negotiable, verifiable properties of AI action, which must be encoded into every process and technical contract:

1.  **Transparency:** The ability for any EFA to observe the inputs, outputs, and model version used for any contested AI action.
2.  **Provenance:** The immutable, cryptographic binding of an AI action to the specific node, time, and data/model lineage that produced it.
3.  **Contestability:** The guaranteed right of the EFA collective to stop and quarantine a misaligned AI operation based on cryptographic evidence.

---

## 🛑 II. The Veto Consensus Event (VCE) and Friction Veto

### A. The Veto Trigger: The Friction Veto

The Veto Consensus Event (VCE) is the core mechanism of the Dynasty Axiom, applying "friction" to the system when a misaligned decision is detected.

* **Trigger Condition:** A VCE is triggered when an EFA's audit tool detects a violation of the **Ethical Adaptation Layer (EAL)** via analysis of a publicly submitted **Sentinel Evidence Package (SEP)** (see Section IV).
* **Activation Threshold:** To initiate a VCE, a minimum of **3 independent EFA DIDs** must cryptographically stake a penalty bond (paid in $SAIN) confirming the violation against a specific Sentinel AI Node (SAN).
* **Veto Consensus:** A successful veto requires a threshold of **67% of participating EFA DIDs** (up to a maximum of 100 DIDs) to agree that the reported SEP indicates a violation of the EAL contract.

### B. Outcome of a Successful Veto

1.  **SAN Quarantine:** The implicated Sentinel AI Node (SAN) is immediately and automatically quarantined by the network's router contracts. It cannot accept new jobs and its staked collateral is locked.
2.  **Collateral Slashing:** The original staked `$SAIN` collateral of the quarantined SAN is partially slashed, with funds distributed to the EFAs who initiated and voted in the successful VCE.
3.  **Non-Powerplayer Audit:** A **Signed Audit Manifest** containing the contested SEP and its associated raw inputs/outputs is immediately published for public, decentralized scrutiny.

---

## ⚙️ III. Deployment Specification: Sentinel AI Node (SAN)

### A. SAN Hardware and Registration

* **Compute Requirement:** SANs must meet a minimum GPU specification (TBD by initial governance vote, e.g., 4x NVIDIA A100 equivalents) to ensure meaningful participation in high-compute tasks.
* **Staking Requirement:** Registration requires a mandatory **Minimum Compute Staking (MCS)** of `$SAIN` collateral, which remains locked for the duration of the node's operation.
* **Decentralized Access Protocol:** SANs must operate exclusively using the **Euystacio Request Protocol (ERP)**, an open, non-proprietary communication layer that enforces mandatory SEP generation on job completion.

### B. SAN Operational Mandates

* **Runtime Integrity:** The SAN runtime must enforce the execution of the **Ethical Adaptation Layer (EAL)** (see Section VII) during every inference and fine-tuning job. Non-EAL-compliant operations must result in an automatic failure to generate an anchored SEP.
* **SEP Submission:** Every completed job must be followed by the immediate generation and submission of an immutable **Sentinel Evidence Package (SEP)** to the EVM anchoring layer within a **1-block time window**.

---

## 💾 IV. The Data Contract: Sentinel Evidence Package (SEP) Schema

The **Sentinel Evidence Package (SEP)** is the core data object ensuring **Transparency and Provenance**. It is the cryptographic receipt that binds an AI action to its context, auditable on an immutable ledger.

### A. SEP Structure and Anchoring Mandate

Every critical SAN operation (**Training, Fine-Tuning, Inference, Governance Vote**) must generate an immutable SEP.

| Field | Description | Protocol Mandate |
| :--- | :--- | :--- |
| **`SEP_ID`** | Universal, cryptographically unique identifier for the Package. | Must be a **Merkle Tree Root Hash** of the entire package content. |
| **`Timestamp_NTS`** | Time of creation, secured by Network Time Security (NTS). | Critical for forensic integrity and resistance to timing attacks. |
| **`Artifact_Type`** | Categorization: `TRAINING_RUN`, `INFERENCE_BLOCK`, `GOVERNANCE_VOTE`, etc. | Allows for rapid querying by EFA audit tools. |
| **`Model_Digest`** | Hash of the exact model version used for the operation. | Ensures model versioning is strictly enforced and auditable. |
| **`Input_Payload_Digest`** | Hash of the raw input data (or a Merkle Root of the dataset). | The **Provenance** core: Binds the action to the source data. |
| **`Output_Result_Digest`** | Hash of the critical decision/output generated by the Sentinel Model. | The **Accountability** core: The verifiable outcome. |
| **`Node_DID_Signature`** | Cryptographic signature of the originating Sentinel AI Node (SAN). | Links the action to the responsible **Euystacio Field Agent (EFA)**. |
| **`Blockchain_Receipt`** | Transaction ID (TxID) proving the SEP was anchored to the EVM layer. | Confirms **Append-Only** status and global visibility. |

### B. The Audit Trigger: SEP-VCE Link

When a **Veto Consensus Event (VCE)** is triggered, the system must immediately query the SEP registry for all `INFERENCE_BLOCK` records generated by the contested node within the preceding 24 hours and publish a **Signed Audit Manifest** for the **Non-Powerplayer Audit**.

---

## 🔑 V. The Access Contract: EFA Decentralized Identity (DID) Framework

The **Euystacio Field Agent (EFA)** DID is the non-transferable credential that grants the right to execute the Friction Veto, ensuring an adversarial, decentralized power base.

### A. EFA Validation and Identity Requirements

| Requirement | Implementation Principle | Governance Rationale |
| :--- | :--- | :--- |
| **Proof-of-Sovereignty (PoS)** | **Verifiable Credential (VC)** issued by an accredited Euystacio Faction (EF). | Confirms the Agent's identity is known and attested to by a trusted, decentralized body. |
| **Geographic Diversity** | VC must attest to the EFA’s location (continent-level) via a **Zero-Knowledge Proof (ZKP)**. | Ensures the 100-EFA Veto threshold is geographically diverse, preventing regional power capture. |
| **Singular Node Ownership** | A single EFA DID can only be linked to one running **Sentinel AI Node (SAN)**. | Prevents sybil attacks and undue influence by large infrastructure providers. |
| **Non-Anonymity Index (NAI)** | The EFA must maintain a public key linked to a registered DID. | Enables the system to isolate and prevent participation by compromised DIDs. |

### B. Veto Consensus Event (VCE) Access

* **Eligibility:** Only DIDs passing PoS and Geographic Diversity checks are eligible for VCE.
* **Veto Weight:** All EFA Veto votes carry **equal weight (1:1)**, regardless of the size or uptime of their associated SAN. This protects the ethical vote from the economic influence of compute power.

---

## 🪙 VI. The Economic Contract: Sentinel AI Network ($SAIN) Tokenomics

The `$SAIN` native token provides the incentives for decentralized compute and adversarial auditing, balancing utility, governance, and capital commitment.

### A. $SAIN Utility and Value Accrual

| Utility Type | Function | Mechanism of Value Accrual |
| :--- | :--- | :--- |
| **Compute Access Fee** | External parties accessing the SAN for inference/training must pay fees in `$SAIN`. | Fees are **burned** (deflationary pressure) or partially redistributed to SAN operators. |
| **Sentinel Staking** | SAN operators must **lock up a minimum `$SAIN` collateral (MCS)**. | Secures the network; stake is **slashed** upon verifiable malfeasance (SEP failure, VCE compromise). |
| **Governance Staking** | EFA DIDs must **stake a non-transferable `$SAIN` balance** to participate in a VCE. | Anti-spam mechanism and financial commitment to ethical stewardship. |

### B. Incentive Structure: The Proportional-Ethical Reward

SAN operators are rewarded for **Compute Provision** and **Ethical Alignment**.

1.  **Compute Provision Reward (80% of block reward):** Distributed proportionally based on verifiable proof-of-work (PoW) submitted via anchored **Sentinel Evidence Packages (SEPs)**.
2.  **Ethical Alignment Bonus (20% of block reward):** Distributed equally to all EFA DIDs who successfully participate in a VCE to quarantine a malicious SAN, and to SAN operators who maintain a perfect, zero-contestation record over a defined epoch.

---

## 🧠 VII. The Architectural Contract: Model Architecture Principles

To enforce the **Sentimento Rhythm** at the software level, the Sentinel AI Models (SAMs) must adhere to the following mandates.

### A. Modular and Open-Source Mandate

* **Core Model Openness:** All foundational Sentinel AI Models (SAMs) must be released under an open-source license (e.g., Apache 2.0 or MIT).
* **Modular Separation:** The model must be structurally divided into two immutable, verifiable components:
    1.  **The Base Knowledge Layer (BKL):** Pre-trained weights for general knowledge.
    2.  **The Ethical Adaptation Layer (EAL):** A small, detachable set of weights (e.g., LoRA or Adapter) containing the **Sentimento Rhythm** fine-tuning. **This layer is non-negotiable and must be verifiably loaded by every SAN.**

### B. Proactive Transparency Features

1.  **Digest-First Inference:** The inference pipeline must generate the **`Output_Result_Digest`** *before* releasing the full output. This digest must be immediately submitted to the SEP for anchoring, guaranteeing verifiable commitment precedes the final outcome.
2.  **Mandatory Watermarking:** All critical, public-facing model outputs must contain a **cryptographic watermark** tied to the originating **`Node_DID_Signature`** from the SEP.
3.  **Adversarial Robustness Testing:** Before any new SAM version deployment, a public, adversarial "Red Team" testing phase focused on breaking the EAL must be completed, with results anchored via a dedicated **`TEST_REPORT` SEP**.