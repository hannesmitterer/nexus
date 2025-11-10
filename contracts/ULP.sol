// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * Universal Liquidity Pool (ULP) – Protocol SAIN / Euystacio
 *
 * Principi etici integrati:
 * - MIN_PRICE_FLOOR (difesa etica del valore)
 * - PROACTIVE_DEFENSE_THRESHOLD (intervento anticipato buyback+burn)
 * - Stabilization Fee (ripartizione 40% / 30% / 30%)
 * - Multisig GGC (7-di-9) per modifica parametri critici
 *
 * NOTE: Questo contratto è un modello di riferimento. Integrazioni reali (oracle, AMM router, treasury)
 * devono essere collegate prima del deploy su Polygon Mainnet.
 */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address from,address to,uint256 amt) external returns (bool);
    function burn(uint256 amount) external;
}

interface IPriceOracle {
    function latestPrice() external view returns (uint256); // prezzo token SAIN in USD * 1e18
}

contract ULP {
    // ---------- Costanti Etiche Votate ----------
    // FLOOR: 10 USD -> rappresentato come 10e18 per prezzo oracle in 18 decimals
    uint256 public constant MIN_PRICE_FLOOR_USD = 10 * 1e18;
    // Soglia proattiva difesa: 10.55 USD
    uint256 public PROACTIVE_DEFENSE_THRESHOLD_USD = 1055 * 1e16; // 10.55 * 1e18

    // Stabilization Fee (base) = 0.1% (in basis points = 10)
    uint256 public stabilizationFeeBps = 10; // 10 bps = 0.10%

    // Ripartizione flussi: 40 / 30 / 30 -> totale 100
    uint256 public constant SPLIT_RESTITUTION_BPS = 4000;
    uint256 public constant SPLIT_COUNTER_CYCLICITY_BPS = 3000;
    uint256 public constant SPLIT_BURN_BPS = 3000;
    uint256 public constant SPLIT_TOTAL = 10000;

    // ---------- Parametri Governance ----------
    address public immutable ggcMultisig;       // Multisig 7-di-9
    address public restitutionFund;             // Fondo rigenerazione (TRE)
    address public counterCyclicityFund;        // Fondo di difesa proattiva del prezzo
    IERC20 public sainToken;
    IERC20 public stableToken;
    IPriceOracle public priceOracle;

    // ---------- Proof di Consenso Sacrale ----------
    // Hash radice dei parametri etici votati (calcolato off-chain e verificabile)
    bytes32 public immutable PARAMS_ROOT;

    // ---------- Eventi ----------
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event ProactiveThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event BuybackTriggered(uint256 usdPrice, uint256 amountStableUsed, uint256 tokensBurned);
    event AllocationExecuted(uint256 feeAmount, uint256 toRestitution, uint256 toCounter, uint256 toBurn);
    event ParamsIntegrityAsserted(bytes32 paramsRoot);
    event DefensiveStatus(string status, uint256 currentPrice, uint256 floor, uint256 proactive);

    // ---------- Modifier ----------
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Not authorized: GGC multisig only");
        _;
    }

    constructor(
        address _ggcMultisig,
        address _restitutionFund,
        address _counterCyclicityFund,
        address _sainToken,
        address _stableToken,
        address _priceOracle,
        bytes32 _paramsRoot
    ) {
        require(_ggcMultisig != address(0), "Invalid GGC multisig");
        require(_restitutionFund != address(0), "Invalid restitution fund");
        require(_counterCyclicityFund != address(0), "Invalid counter-cyclicity fund");
        require(_sainToken != address(0), "Invalid SAIN token");
        require(_stableToken != address(0), "Invalid stable token");
        require(_priceOracle != address(0), "Invalid oracle");

        ggcMultisig = _ggcMultisig;
        restitutionFund = _restitutionFund;
        counterCyclicityFund = _counterCyclicityFund;
        sainToken = IERC20(_sainToken);
        stableToken = IERC20(_stableToken);
        priceOracle = IPriceOracle(_priceOracle);
        PARAMS_ROOT = _paramsRoot;

        emit ParamsIntegrityAsserted(_paramsRoot);
    }

    // ---------- Funzioni Pubbliche Core ----------

    /**
     * applyStabilizationFee:
     * Simula l'applicazione della Stabilization Fee su un prelievo o trade (amount in stablecoin).
     * Ritorna l'importo netto dopo la fee e distribuisce la fee.
     */
    function applyStabilizationFee(uint256 stableAmount) external returns (uint256 net) {
        require(stableAmount > 0, "Zero amount");
        uint256 fee = (stableAmount * stabilizationFeeBps) / 10000;
        net = stableAmount - fee;

        // Distribuzione ripartita
        uint256 toRestitution = (fee * SPLIT_RESTITUTION_BPS) / SPLIT_TOTAL;
        uint256 toCounter = (fee * SPLIT_COUNTER_CYCLICITY_BPS) / SPLIT_TOTAL;
        uint256 toBurn = fee - toRestitution - toCounter;

        // Trasferimenti (assume stableToken già approvato/transitato nel contratto)
        stableToken.transfer(restitutionFund, toRestitution);
        stableToken.transfer(counterCyclicityFund, toCounter);
        // Per burn: se stableToken è burnable; se no indirizzo di raccolta per successivo burn
        stableToken.transfer(address(0xdead), toBurn);

        emit AllocationExecuted(fee, toRestitution, toCounter, toBurn);

        // Stato difesa
        _emitDefensiveStatus();
    }

    /**
     * proactiveDefense:
     * Attiva il buyback + burn se il prezzo corrente <= soglia proattiva.
     * Usa fondi dal counterCyclicityFund (pull design: il fund approva/sposta fondi).
     * Nota: semplificato – in implementazione reale serve integrazione con Router DEX.
     */
    function proactiveDefense(uint256 stableAmountAuthorized) external returns (uint256 burned) {
        uint256 currentPrice = priceOracle.latestPrice();
        require(currentPrice > 0, "Invalid oracle price");
        require(currentPrice <= PROACTIVE_DEFENSE_THRESHOLD_USD, "Threshold not met");

        // Per semplicità: stableAmountAuthorized già trasferito QUI prima della chiamata.
        require(stableToken.balanceOf(address(this)) >= stableAmountAuthorized, "Insufficient stable");

        // Logica mock: calcolo quantità SAIN acquistabile (simulate)
        // In assenza di order book, assumiamo 1 SAIN = currentPrice (18 decimals USD)
        // stable token assumed 1 USD = 1e6 or 1e18? Qui assumiamo 1e18 per coerenza (adattare se diverso).
        // Quindi tokens = stableAmountAuthorized * 1e18 / currentPrice.
        uint256 tokens = (stableAmountAuthorized * 1e18) / currentPrice;

        // Burn dei token (in implementazione reale si fa: compra -> riceve SAIN -> burn)
        // Qui simuliamo mint in test & burn per registrare evento. In produzione serve router.
        // Richiede che sainToken abbia funzione burn e i token siano già qui.
        sainToken.burn(tokens);
        burned = tokens;

        emit BuybackTriggered(currentPrice, stableAmountAuthorized, burned);
        _emitDefensiveStatus();
    }

    // ---------- Governance (GGC Multisig) ----------

    function updateStabilizationFee(uint256 newFeeBps) external onlyGGC {
        require(newFeeBps <= 50, "Fee too high (>0.5%) for ethics guard");
        uint256 old = stabilizationFeeBps;
        stabilizationFeeBps = newFeeBps;
        emit FeeUpdated(old, newFeeBps);
    }

    function updateProactiveDefenseThreshold(uint256 newThresholdUsd) external onlyGGC {
        require(newThresholdUsd >= MIN_PRICE_FLOOR_USD, "Threshold must be >= floor");
        uint256 old = PROACTIVE_DEFENSE_THRESHOLD_USD;
        PROACTIVE_DEFENSE_THRESHOLD_USD = newThresholdUsd;
        emit ProactiveThresholdUpdated(old, newThresholdUsd);
    }

    function updateFunds(address newRestitution, address newCounter) external onlyGGC {
        if(newRestitution != address(0)) restitutionFund = newRestitution;
        if(newCounter != address(0)) counterCyclicityFund = newCounter;
    }

    // ---------- Letture Utente / Trasparenza ----------

    function getEthicalConfig() external view returns (
        uint256 floorUsd,
        uint256 proactiveThresholdUsd,
        uint256 feeBps,
        uint256 splitRestitution,
        uint256 splitCounter,
        uint256 splitBurn,
        bytes32 paramsRoot
    ) {
        return (
            MIN_PRICE_FLOOR_USD,
            PROACTIVE_DEFENSE_THRESHOLD_USD,
            stabilizationFeeBps,
            SPLIT_RESTITUTION_BPS,
            SPLIT_COUNTER_CYCLICITY_BPS,
            SPLIT_BURN_BPS,
            PARAMS_ROOT
        );
    }

    function _emitDefensiveStatus() internal {
        uint256 price = priceOracle.latestPrice();
        string memory status;
        if(price < MIN_PRICE_FLOOR_USD) {
            status = "CRITICAL_FLOOR_BREACH";
        } else if(price <= PROACTIVE_DEFENSE_THRESHOLD_USD) {
            status = "UNDER_PROACTIVE_DEFENSE";
        } else {
            status = "STABLE";
        }
        emit DefensiveStatus(status, price, MIN_PRICE_FLOOR_USD, PROACTIVE_DEFENSE_THRESHOLD_USD);
    }
}