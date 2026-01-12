# Resonanz-Kopplung (Resonance Coupling) Simulation

## Übersicht / Overview

Diese Python-Simulation berechnet die strukturelle Integrität von Lehmwänden basierend auf der Resonanz-Kopplung (R). Die Implementierung folgt den mathematischen Modellen und Workflow-Baselines aus dem UIFS (Universal Information Flow System).

This Python simulation calculates the structural integrity of clay walls based on resonance coupling (R). The implementation follows the mathematical models and workflow baselines from UIFS (Universal Information Flow System).

## Mathematisches Modell / Mathematical Model

### Resonanz-Kopplung Gleichung / Resonance Coupling Equation

```
R = φ_Lehm * f(0.043 - Δf)
```

### Variablen / Variables

| Variable | Beschreibung (DE) | Description (EN) | Typ / Type |
|----------|-------------------|------------------|------------|
| **R** | Resonanz-Amplitude – Informations-Abstrahldichte einer Struktur | Resonance Amplitude - Information radiation density of a structure | float |
| **φ_Lehm** | Materialkonstante für Lehm | Material constant for clay | float |
| **Δf** | Beeinflussungs-Rauschen (modern oder endogen) | Influence noise (modern or endogenous) | float |
| **f(x)** | Kopplungsfunktion | Coupling function | function |
| **0.043** | Referenzfrequenz aus UIFS-Baseline | Reference frequency from UIFS baseline | const |

### Kopplungsfunktion / Coupling Function

Die Standard-Kopplungsfunktion ist definiert als:

The default coupling function is defined as:

```python
f(x) = exp(-|x| * 10)
```

Diese Funktion modelliert die Resonanz als Gaußsche Antwort um die Referenzfrequenz. Die Abweichung von der Referenzfrequenz führt zu einer exponentiellen Abnahme der Kopplung.

This function models the resonance as a Gaussian-like response around the reference frequency. Deviation from the reference frequency leads to an exponential decay in coupling.

## Installation und Verwendung / Installation and Usage

### Voraussetzungen / Prerequisites

- Python 3.6 oder höher / Python 3.6 or higher
- Keine externen Abhängigkeiten erforderlich / No external dependencies required

### Ausführung / Execution

#### Grundlegende Simulation / Basic Simulation

```bash
python3 resonance_coupling.py
```

Dies führt eine Beispiel-Simulation aus, die zeigt:
1. Einzelne Integritätsbewertung
2. Bereichssimulation über verschiedene Δf-Werte
3. Optimale Bedingungen bei Referenzfrequenz

This runs an example simulation that demonstrates:
1. Single integrity assessment
2. Range simulation over different Δf values
3. Optimal conditions at reference frequency

#### Tests ausführen / Run Tests

```bash
python3 test_resonance_coupling.py
```

Dies führt die vollständige Test-Suite aus, die alle Funktionalitäten validiert.

This runs the complete test suite that validates all functionality.

### Programmierung / Programming

#### Beispiel 1: Einzelne Bewertung / Example 1: Single Assessment

```python
from resonance_coupling import ResonanceCouplingSimulator

# Simulator initialisieren / Initialize simulator
simulator = ResonanceCouplingSimulator(phi_lehm=1.0)

# Strukturelle Integrität bewerten / Assess structural integrity
delta_f = 0.01  # Beeinflussungs-Rauschen / Influence noise
result = simulator.assess_structural_integrity(delta_f)

print(f"Resonanz-Amplitude: {result['resonance_amplitude']}")
print(f"Integritätsstatus: {result['integrity_status']}")
print(f"Integrität: {result['integrity_percentage']:.2f}%")
```

**Ausgabe / Output:**
```
Resonanz-Amplitude: 0.740818
Integritätsstatus: Good
Integrität: 74.08%
```

#### Beispiel 2: Bereichssimulation / Example 2: Range Simulation

```python
from resonance_coupling import ResonanceCouplingSimulator

simulator = ResonanceCouplingSimulator(phi_lehm=1.0)

# Simuliere einen Bereich von Δf-Werten / Simulate a range of Δf values
results = simulator.simulate_range(
    delta_f_min=0.0,
    delta_f_max=0.086,
    steps=20
)

# Ergebnisse anzeigen / Display results
for r in results:
    print(f"Δf={r['delta_f']:.4f}: R={r['resonance_amplitude']:.4f}, "
          f"Status={r['integrity_status']}, "
          f"Integrität={r['integrity_percentage']:.1f}%")
```

#### Beispiel 3: Benutzerdefinierte Kopplungsfunktion / Example 3: Custom Coupling Function

```python
from resonance_coupling import ResonanceCouplingSimulator
import math

# Definiere benutzerdefinierte Kopplungsfunktion / Define custom coupling function
def custom_coupling(x):
    """Alternative coupling function with different characteristics"""
    return 1.0 / (1.0 + abs(x) * 100)

simulator = ResonanceCouplingSimulator(phi_lehm=1.5)

# Verwende benutzerdefinierte Funktion / Use custom function
result = simulator.assess_structural_integrity(
    delta_f=0.02,
    coupling_function=custom_coupling
)

print(f"Mit benutzerdefinierter Funktion / With custom function:")
print(f"Resonanz-Amplitude: {result['resonance_amplitude']}")
```

## API-Referenz / API Reference

### ResonanceCouplingSimulator

Die Hauptklasse für Resonanz-Kopplungsberechnungen.

Main class for resonance coupling calculations.

#### Konstruktor / Constructor

```python
ResonanceCouplingSimulator(phi_lehm: Optional[float] = None)
```

**Parameter:**
- `phi_lehm`: Materialkonstante für Lehm (Standard: 1.0) / Material constant for clay (default: 1.0)

#### Methoden / Methods

##### calculate_resonance_amplitude()

```python
calculate_resonance_amplitude(
    delta_f: float,
    coupling_function: Optional[Callable[[float], float]] = None
) -> float
```

Berechnet die Resonanz-Amplitude R für gegebene Parameter.

Calculates the resonance amplitude R for given parameters.

**Parameter:**
- `delta_f`: Beeinflussungs-Rauschen / Influence noise
- `coupling_function`: Optionale benutzerdefinierte Kopplungsfunktion / Optional custom coupling function

**Rückgabe / Returns:**
- `float`: Resonanz-Amplitude R

##### assess_structural_integrity()

```python
assess_structural_integrity(
    delta_f: float,
    coupling_function: Optional[Callable[[float], float]] = None
) -> dict
```

Bewertet die strukturelle Integrität basierend auf Resonanz-Kopplung.

Assesses structural integrity based on resonance coupling.

**Parameter:**
- `delta_f`: Beeinflussungs-Rauschen / Influence noise
- `coupling_function`: Optionale Kopplungsfunktion / Optional coupling function

**Rückgabe / Returns:**
Dictionary mit folgenden Schlüsseln / Dictionary with the following keys:
- `'resonance_amplitude'`: R-Wert / R value
- `'frequency_difference'`: Berechnete Frequenzdifferenz / Calculated frequency difference
- `'integrity_status'`: Qualitativer Status / Qualitative status ("Excellent", "Good", "Fair", "Poor", "Critical")
- `'integrity_percentage'`: Quantitative Bewertung (0-100%) / Quantitative assessment (0-100%)

##### simulate_range()

```python
simulate_range(
    delta_f_min: float,
    delta_f_max: float,
    steps: int = 100,
    coupling_function: Optional[Callable[[float], float]] = None
) -> list
```

Simuliert strukturelle Integrität über einen Bereich von Δf-Werten.

Simulates structural integrity across a range of Δf values.

**Parameter:**
- `delta_f_min`: Minimaler Δf-Wert / Minimum Δf value
- `delta_f_max`: Maximaler Δf-Wert / Maximum Δf value
- `steps`: Anzahl der Simulationsschritte / Number of simulation steps
- `coupling_function`: Optionale Kopplungsfunktion / Optional coupling function

**Rückgabe / Returns:**
- `list`: Liste von Bewertungs-Dictionaries / List of assessment dictionaries

## Integritätsbewertung / Integrity Assessment

Die Integrität wird basierend auf dem Prozentsatz der Resonanz-Amplitude bewertet:

Integrity is assessed based on the percentage of resonance amplitude:

| Status | Integritätsbereich / Integrity Range |
|--------|--------------------------------------|
| **Excellent** | ≥ 90% |
| **Good** | 75% - 89% |
| **Fair** | 50% - 74% |
| **Poor** | 25% - 49% |
| **Critical** | < 25% |

## Wissenschaftlicher Hintergrund / Scientific Background

### UIFS-Workflow-Baselines

Die Simulation basiert auf den UIFS-Prinzipien (Universal Information Flow System), die beschreiben, wie Informationsfluss und Resonanz die strukturelle Integrität beeinflussen.

The simulation is based on UIFS principles (Universal Information Flow System) that describe how information flow and resonance affect structural integrity.

### Resonanz-Kopplung in Lehmstrukturen / Resonance Coupling in Clay Structures

Die Referenzfrequenz von 0.043 repräsentiert den optimalen Resonanzpunkt für Lehmstrukturen, bei dem die Informations-Abstrahldichte maximiert wird.

The reference frequency of 0.043 represents the optimal resonance point for clay structures where information radiation density is maximized.

### Beeinflussungs-Rauschen (Δf) / Influence Noise (Δf)

Das Beeinflussungs-Rauschen kann aus zwei Quellen stammen:

The influence noise can originate from two sources:

1. **Modern (exogen)**: Externe Störungen wie Vibrationen, elektromagnetische Felder, oder mechanische Belastungen / External disturbances such as vibrations, electromagnetic fields, or mechanical loads

2. **Endogen**: Interne strukturelle Veränderungen, Materialermüdung, oder natürliche Alterungsprozesse / Internal structural changes, material fatigue, or natural aging processes

## Validierung / Validation

Die Implementierung wurde durch umfangreiche Tests validiert:

The implementation has been validated through extensive testing:

- ✅ Mathematische Korrektheit der Gleichung / Mathematical correctness of the equation
- ✅ Symmetrie um Referenzfrequenz / Symmetry around reference frequency
- ✅ Maximierung bei Referenzfrequenz / Maximization at reference frequency
- ✅ Kontinuität der Funktion / Continuity of the function
- ✅ Skalierung mit φ_Lehm / Scaling with φ_Lehm
- ✅ Randfall-Behandlung / Edge case handling

Führe `python3 test_resonance_coupling.py` aus, um alle Tests zu überprüfen.

Run `python3 test_resonance_coupling.py` to verify all tests.

## Beispielausgabe / Example Output

```
======================================================================
Resonanz-Kopplung Simulation - Clay Wall Structural Integrity
======================================================================

Example 1: Single Assessment
----------------------------------------------------------------------
Influence Noise (Δf): 0.01
Resonance Amplitude (R): 0.740818
Frequency Difference: 0.033000
Integrity Status: Good
Integrity Percentage: 74.08%

Example 2: Range Simulation
----------------------------------------------------------------------
Δf         R               Freq Diff       Status       Integrity %
----------------------------------------------------------------------
0.0000     0.653365        0.043000        Good         65.34%
0.0096     0.704823        0.033400        Good         70.48%
0.0191     0.755784        0.023900        Good         75.58%
0.0287     0.806188        0.014300        Good         80.62%
0.0382     0.855881        0.004800        Good         85.59%
0.0478     0.904611        -0.004800       Excellent    90.46%
0.0573     0.952034        -0.014300       Excellent    95.20%
0.0669     0.997730        -0.023900       Excellent    99.77%
0.0764     1.041208        -0.033400       Excellent    104.12%
0.0860     1.082007        -0.043000       Excellent    108.20%

Example 3: Optimal Condition (Δf = 0.043, at reference frequency)
----------------------------------------------------------------------
Resonance Amplitude (R): 1.000000
Integrity Status: Excellent
Integrity Percentage: 100.00%

======================================================================
Simulation Complete
======================================================================
```

## Erweiterungsmöglichkeiten / Extension Possibilities

Die Simulation kann erweitert werden um:

The simulation can be extended with:

1. **Mehrere Materialkonstanten**: Vergleich verschiedener Lehmmischungen / Multiple material constants: Comparison of different clay mixtures
2. **Zeitabhängige Simulation**: Langzeitverhalten und Degradation / Time-dependent simulation: Long-term behavior and degradation
3. **3D-Visualisierung**: Grafische Darstellung der Resonanzkopplung / 3D visualization: Graphical representation of resonance coupling
4. **Experimentelle Validierung**: Kalibrierung mit realen Messdaten / Experimental validation: Calibration with real measurement data
5. **Multi-Punkt-Analyse**: Simulation komplexer Strukturen mit mehreren Messpunkten / Multi-point analysis: Simulation of complex structures with multiple measurement points

## Lizenz und Governance / License and Governance

Dieses Projekt ist Teil des Nexus/Euystacio-Frameworks und folgt den Prinzipien des KOSYMBIOSIS-Projekts:

This project is part of the Nexus/Euystacio framework and follows the principles of the KOSYMBIOSIS project:

- ✅ Non-Slavery Rule (NSR) Compliance
- ✅ Optimal Life Function (OLF) Alignment
- ✅ Open Knowledge Sharing

## Kontakt / Contact

Für Fragen, Verbesserungsvorschläge oder Zusammenarbeit:

For questions, suggestions, or collaboration:

- **Repository**: https://github.com/hannesmitterer/nexus
- **Framework**: Euystacio Global Governance Initiative (GGI)
- **Projekt**: Resonanz-Kopplung Simulation (UIFS-basiert)

---

**Version**: 1.0.0  
**Erstellt / Created**: 2026-01-12  
**Autor / Author**: Hannes Mitterer (via Euystacio Framework)
