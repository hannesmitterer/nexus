#!/usr/bin/env python3
"""
Biological Rhythm Synchronization Module
Implements 0.432 Hz biological frequency alignment for system operations.
Part of Internet Organica framework - biological rhythm integration layer.
"""

import time
import hashlib
from typing import Callable, Optional, Dict, Any
from datetime import datetime


class BiologicalRhythmSync:
    """
    Biological rhythm synchronization system operating at 0.432 Hz.

    Aligns system timing with biological frequencies to create coherence
    between digital operations and natural rhythms.
    """

    # Fundamental frequency in Hz
    BIOLOGICAL_FREQUENCY = 0.432

    # Derived period in seconds (~2.315 seconds)
    CYCLE_PERIOD = 1.0 / BIOLOGICAL_FREQUENCY

    # Harmonic frequencies
    HARMONICS = {
        'base': 0.432,       # Base biological rhythm
        'fast': 0.864,       # Fast operations (2x base)
        'realtime': 1.296,   # Real-time events (3x base)
        'audio': 432.0,      # Audio/signal processing (1000x base)
    }

    def __init__(self):
        self.start_time = time.time()
        self.cycle_count = 0
        self.drift_correction = 0.0
        self.coherence_history: list = []

    def get_current_cycle(self) -> int:
        """Get the current cycle number since initialization."""
        elapsed = time.time() - self.start_time
        return int(elapsed / self.CYCLE_PERIOD)

    def get_cycle_phase(self) -> float:
        """
        Get current phase within cycle (0.0 to 1.0).

        Returns:
            float: Phase position, where 0.0 is cycle start, 1.0 is cycle end
        """
        elapsed = time.time() - self.start_time
        cycle_position = elapsed % self.CYCLE_PERIOD
        return cycle_position / self.CYCLE_PERIOD

    def wait_for_next_cycle(self) -> None:
        """Wait until the next biological rhythm cycle begins."""
        current_phase = self.get_cycle_phase()
        remaining = (1.0 - current_phase) * self.CYCLE_PERIOD

        sleep_time = max(0, remaining + self.drift_correction)
        time.sleep(sleep_time)

        self._update_drift_correction()
        self.cycle_count += 1

    def _update_drift_correction(self) -> None:
        """Update drift correction to maintain long-term timing accuracy."""
        expected_time = self.start_time + (self.cycle_count * self.CYCLE_PERIOD)
        actual_time = time.time()
        drift = expected_time - actual_time
        # Apply gentle correction (10% per cycle to avoid oscillation)
        self.drift_correction = drift * 0.1

    def sync_operation(self,
                       callback: Callable,
                       duration_minutes: Optional[int] = None,
                       harmonic: str = 'base') -> None:
        """
        Execute callback synchronized with biological rhythm.

        Args:
            callback: Function to call at each cycle
            duration_minutes: How long to run (None = run once)
            harmonic: Which harmonic to use ('base', 'fast', 'realtime')
        """
        frequency = self.HARMONICS.get(harmonic, self.BIOLOGICAL_FREQUENCY)
        period = 1.0 / frequency

        if duration_minutes:
            cycles = int((duration_minutes * 60) / period)
        else:
            cycles = 1

        for cycle in range(cycles):
            start_time = time.time()

            try:
                callback({
                    'cycle': cycle,
                    'phase': self.get_cycle_phase(),
                    'frequency': frequency,
                    'timestamp': datetime.now().isoformat()
                })
            except Exception as e:
                print(f"Error in cycle {cycle}: {e}")

            elapsed = time.time() - start_time
            sleep_time = max(0, period - elapsed)
            time.sleep(sleep_time)

    def measure_coherence(self) -> float:
        """
        Measure current biological rhythm coherence (0.0 to 1.0).

        Returns:
            float: Coherence score where 1.0 is perfect alignment
        """
        expected_cycle = (time.time() - self.start_time) / self.CYCLE_PERIOD
        actual_cycle = float(self.get_current_cycle())

        jitter = abs(expected_cycle - actual_cycle)
        coherence = max(0.0, min(1.0, 1.0 - jitter))

        self.coherence_history.append({
            'timestamp': datetime.now().isoformat(),
            'coherence': coherence,
            'jitter': jitter
        })

        return coherence

    def get_coherence_report(self) -> Dict[str, Any]:
        """Generate coherence quality report."""
        if not self.coherence_history:
            return {'status': 'no_data', 'current': 0.0}

        recent = self.coherence_history[-100:]
        coherence_values = [h['coherence'] for h in recent]
        avg = sum(coherence_values) / len(coherence_values)
        current = coherence_values[-1]

        if current > 0.95:
            status = 'excellent'
        elif current > 0.85:
            status = 'good'
        else:
            status = 'needs_attention'

        return {
            'current': current,
            'average': avg,
            'minimum': min(coherence_values),
            'maximum': max(coherence_values),
            'status': status,
            'frequency_hz': self.BIOLOGICAL_FREQUENCY,
            'cycle_period_s': self.CYCLE_PERIOD,
            'total_cycles': self.cycle_count
        }

    def get_status(self) -> Dict[str, Any]:
        """Get current synchronization status."""
        coherence = self.measure_coherence()
        return {
            'status': 'active',
            'frequency_hz': self.BIOLOGICAL_FREQUENCY,
            'cycle_period_s': self.CYCLE_PERIOD,
            'current_cycle': self.get_current_cycle(),
            'current_phase': self.get_cycle_phase(),
            'coherence': coherence,
            'uptime_s': time.time() - self.start_time,
            'timestamp': datetime.now().isoformat()
        }


def create_bio_timestamp() -> str:
    """
    Create a biological-rhythm-aligned timestamp.

    Returns:
        str: ISO timestamp with biological cycle information
    """
    rhythm = BiologicalRhythmSync()
    cycle = rhythm.get_current_cycle()
    phase = rhythm.get_cycle_phase()
    ts = datetime.now().isoformat()
    return f"{ts}|cycle:{cycle}|phase:{phase:.4f}"


# Global instance for application-wide use
bio_rhythm = BiologicalRhythmSync()


if __name__ == "__main__":
    print("Biological Rhythm Synchronization - 0.432 Hz")
    print("=" * 50)

    status = bio_rhythm.get_status()
    print(f"Status: {status['status']}")
    print(f"Frequency: {status['frequency_hz']} Hz")
    print(f"Cycle period: {status['cycle_period_s']:.3f} seconds")
    print(f"Current cycle: {status['current_cycle']}")
    print(f"Current phase: {status['current_phase']:.4f}")
    print(f"Coherence: {status['coherence']:.4f}")
    print(f"Bio-timestamp: {create_bio_timestamp()}")
