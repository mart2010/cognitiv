#!/usr/bin/env python3
"""Synthétise les trois sons de L'atelier dans assets/sounds/ (WAV 16 bits mono).

Quotidien sobre (clic, erreur discrète), réussite célébrée fortement (arpège + accord).
Usage : python3 tool/generate_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def note(freq, start, length, volume=0.5, attack=0.005, decay=6.0, harmonics=(1.0, 0.35, 0.12)):
    """Liste de (index, échantillon) pour une note à enveloppe exponentielle."""
    first = int(start * RATE)
    samples = []
    for i in range(int(length * RATE)):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        value = sum(a * math.sin(2 * math.pi * freq * (k + 1) * t) for k, a in enumerate(harmonics))
        samples.append((first + i, volume * env * value))
    return samples


def render(name, notes, total):
    buffer = [0.0] * int(total * RATE)
    for index, value in notes:
        if index < len(buffer):
            buffer[index] += value
    peak = max(1e-9, max(abs(v) for v in buffer))
    scale = 0.85 / peak
    fade = int(0.01 * RATE)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = bytearray()
        for i, v in enumerate(buffer):
            gain = min(1.0, (len(buffer) - i) / fade)
            frames += struct.pack("<h", int(max(-1, min(1, v * scale * gain)) * 32767))
        f.writeframes(bytes(frames))


OUT.mkdir(parents=True, exist_ok=True)

# Clic discret quand on pose une forme ou qu'on choisit une réponse.
render("tap.wav", note(880, 0, 0.06, decay=60, harmonics=(1.0, 0.2)), 0.06)

# Erreur : deux notes descendantes, douces, sans agressivité.
render(
    "wrong.wav",
    note(330, 0, 0.35, decay=7, harmonics=(1.0, 0.15))
    + note(262, 0.16, 0.45, decay=6, harmonics=(1.0, 0.15)),
    0.65,
)

# Réussite : arpège ascendant do-mi-sol-do, puis accord tenu et scintillement.
C5, E5, G5, C6, E6 = 523.25, 659.25, 783.99, 1046.5, 1318.5
notes = []
for i, f in enumerate((C5, E5, G5, C6)):
    notes += note(f, i * 0.1, 0.5, volume=0.45, decay=5)
for f in (C5, E5, G5, C6):
    notes += note(f, 0.42, 1.3, volume=0.3, attack=0.02, decay=2.6)
for i, f in enumerate((C6, E6, C6 * 1.5, E6 * 1.5)):
    notes += note(f, 0.55 + i * 0.09, 0.5, volume=0.16, decay=7, harmonics=(1.0, 0.1))
render("success.wav", notes, 1.8)
