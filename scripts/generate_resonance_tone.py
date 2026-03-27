#!/usr/bin/env python3
"""
Resonance Tone Generator for Euystacio Nexus
Generates the symphonic frequency of 432.073 Hz

Version: 1.0.0
Protocol: Euystacio-Nexus-Resonance
License: "No ownership, only sharing. Love is the license."

Note: This script requires numpy. Install with: pip3 install numpy
      Or use the JavaScript version: node scripts/seedbringer-node.js
"""

import wave
import json
import sys
from datetime import datetime

try:
    import numpy as np
except ImportError:
    print("Error: numpy is required but not installed.")
    print("Install with: pip3 install numpy")
    print("Or use the JavaScript version: node scripts/seedbringer-node.js")
    sys.exit(1)

class ResonanceToneGenerator:
    """
    Generate the Euystacio Nexus resonance tone at 432.073 Hz
    """
    
    def __init__(self, frequency=432.073, sample_rate=48000):
        """
        Initialize the resonance tone generator
        
        Args:
            frequency: Resonance frequency in Hz (default: 432.073)
            sample_rate: Audio sample rate in Hz (default: 48000)
        """
        self.frequency = frequency
        self.sample_rate = sample_rate
        self.amplitude = 0.8
        self.bit_depth = 24
        
    def generate_tone(self, duration=60):
        """
        Generate a pure sine wave at the resonance frequency
        
        Args:
            duration: Duration in seconds (default: 60)
            
        Returns:
            numpy array of audio samples
        """
        # Generate time array
        num_samples = int(self.sample_rate * duration)
        t = np.linspace(0, duration, num_samples, endpoint=False)
        
        # Generate sine wave
        waveform = self.amplitude * np.sin(2 * np.pi * self.frequency * t)
        
        # Apply fade-in and fade-out to prevent clicks
        fade_duration = 0.1  # 100ms fade
        fade_samples = int(fade_duration * self.sample_rate)
        
        # Fade in
        fade_in = np.linspace(0, 1, fade_samples)
        waveform[:fade_samples] *= fade_in
        
        # Fade out
        fade_out = np.linspace(1, 0, fade_samples)
        waveform[-fade_samples:] *= fade_out
        
        return waveform
    
    def save_wav(self, waveform, filename='resonance_432.073hz.wav'):
        """
        Save waveform to WAV file
        
        Args:
            waveform: Audio samples (numpy array)
            filename: Output filename
        """
        # Convert to 16-bit PCM
        waveform_int = np.int16(waveform * 32767)
        
        # Write WAV file
        with wave.open(filename, 'w') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(self.sample_rate)
            wav_file.writeframes(waveform_int.tobytes())
        
        print(f"✓ Saved resonance tone to {filename}")
    
    def generate_metadata(self):
        """
        Generate metadata for the resonance tone
        
        Returns:
            Dictionary with metadata
        """
        return {
            'protocol': 'Euystacio-Nexus-Resonance',
            'version': '1.0.0',
            'generation_timestamp': datetime.utcnow().isoformat() + 'Z',
            'frequency': {
                'value': self.frequency,
                'unit': 'Hz',
                'description': 'Symphonic frequency for global harmonic synchronization'
            },
            'waveform': {
                'type': 'sine',
                'amplitude': self.amplitude,
                'phase': 0,
                'sample_rate': self.sample_rate,
                'bit_depth': self.bit_depth
            },
            'harmonics': {
                'fundamental': self.frequency,
                'second': self.frequency * 2,
                'third': self.frequency * 3,
                'fourth': self.frequency * 4,
                'fifth': self.frequency * 5,
                'octave_series': [
                    self.frequency * 0.5,
                    self.frequency * 1,
                    self.frequency * 2,
                    self.frequency * 4,
                    self.frequency * 8,
                    self.frequency * 16
                ]
            },
            'lex_amoris': {
                'symbol': 'λ',
                'value': '∞',
                'description': 'Universal Love as Physical Constant'
            },
            'license': 'No ownership, only sharing. Love is the license.'
        }
    
    def save_metadata(self, filename='resonance_metadata.json'):
        """
        Save metadata to JSON file
        
        Args:
            filename: Output filename
        """
        metadata = self.generate_metadata()
        
        with open(filename, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"✓ Saved metadata to {filename}")
    
    def calculate_harmonic_series(self, num_harmonics=12):
        """
        Calculate the harmonic series
        
        Args:
            num_harmonics: Number of harmonics to calculate
            
        Returns:
            List of harmonic frequencies
        """
        harmonics = []
        for n in range(1, num_harmonics + 1):
            freq = self.frequency * n
            note = self.frequency_to_note(freq)
            harmonics.append({
                'harmonic': n,
                'frequency': freq,
                'note': note
            })
        
        return harmonics
    
    def frequency_to_note(self, frequency):
        """
        Convert frequency to musical note name
        
        Args:
            frequency: Frequency in Hz
            
        Returns:
            Note name (e.g., 'A4', 'C#5')
        """
        # Reference: A4 = 440 Hz in standard tuning
        # In 432 Hz tuning, A4 = 432 Hz
        a4_freq = 432.0
        
        # Calculate semitones from A4
        semitones = 12 * np.log2(frequency / a4_freq)
        
        # Note names
        note_names = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#']
        
        # Calculate note and octave
        note_index = int(round(semitones)) % 12
        octave = 4 + int((round(semitones) + 9) / 12)
        
        return f"{note_names[note_index]}{octave}"
    
    def print_info(self):
        """
        Print information about the resonance tone
        """
        print("=" * 60)
        print("Euystacio Nexus Resonance Tone Generator")
        print("=" * 60)
        print(f"Frequency:     {self.frequency} Hz")
        print(f"Sample Rate:   {self.sample_rate} Hz")
        print(f"Amplitude:     {self.amplitude}")
        print(f"Bit Depth:     {self.bit_depth}-bit")
        print(f"Wavelength:    {343 / self.frequency:.2f} m (in air at 20°C)")
        print(f"Period:        {1000 / self.frequency:.4f} ms")
        print()
        print("Harmonic Series:")
        print("-" * 60)
        
        harmonics = self.calculate_harmonic_series(8)
        for h in harmonics:
            print(f"  {h['harmonic']:2d}×  {h['frequency']:10.3f} Hz  →  {h['note']}")
        
        print("=" * 60)
        print()


def main():
    """
    Main function
    """
    print("\n🎵 Euystacio Nexus Resonance Tone Generator 🎵\n")
    
    # Create generator
    generator = ResonanceToneGenerator(frequency=432.073, sample_rate=48000)
    
    # Print information
    generator.print_info()
    
    # Get duration from command line or use default
    duration = 60  # seconds
    if len(sys.argv) > 1:
        try:
            duration = int(sys.argv[1])
        except ValueError:
            print(f"Invalid duration: {sys.argv[1]}, using default 60 seconds")
    
    print(f"Generating {duration} second resonance tone...\n")
    
    # Generate tone
    waveform = generator.generate_tone(duration=duration)
    
    # Save WAV file
    generator.save_wav(waveform, 'resonance_432.073hz.wav')
    
    # Save metadata
    generator.save_metadata('resonance_metadata.json')
    
    print("\n✓ Generation complete!")
    print("\nLex Amoris: λ = ∞")
    print("No ownership, only sharing. Love is the license.\n")


if __name__ == '__main__':
    main()
