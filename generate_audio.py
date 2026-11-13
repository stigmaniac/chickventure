
import math
import wave
import struct
import os
import random

SAMPLE_RATE = 22050

os.makedirs("assets/sounds", exist_ok=True)
os.makedirs("assets/music", exist_ok=True)

def save_wav(path, samples):
    with wave.open(path, "w") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)

        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        audio.writeframes(frames)

def make_tone(notes, duration, volume=0.35, wave_type="sine"):
    samples = []
    total = int(SAMPLE_RATE * duration)

    for i in range(total):
        t = i / SAMPLE_RATE
        note_position = min(
            int(t / duration * len(notes)),
            len(notes) - 1
        )
        frequency = notes[note_position]

        phase = 2 * math.pi * frequency * t
        if wave_type == "square":
            sound = 1 if math.sin(phase) >= 0 else -1
        else:
            sound = math.sin(phase)

        fade_in = min(1, t / 0.02)
        fade_out = max(0, 1 - t / duration)
        envelope = fade_in * fade_out

        samples.append(sound * envelope * volume)

    return samples

def save_sound(name, notes, duration, volume=0.35):
    samples = make_tone(notes, duration, volume)
    save_wav(f"assets/sounds/{name}.wav", samples)
    print(f"Created: {name}.wav")

# 1. Jump
save_sound("jump", [650, 580, 490, 400], 0.22, 0.35)

# 2. Star collection
save_sound("star", [700, 900, 1150, 1450], 0.35, 0.30)

# 3. Hit sound
save_sound("hit", [250, 180, 120], 0.24, 0.38)

# 4. Checkpoint
save_sound("checkpoint", [500, 700, 900, 1100], 0.55, 0.30)

# 5. Gate unlock
save_sound("gate", [350, 500, 750, 1000, 1300], 0.8, 0.28)

# 6. Victory
save_sound("victory", [523, 659, 784, 1046], 1.0, 0.30)

# 7. Cozy meadow background music
music = []
melody = [
    392, 440, 523, 440,
    349, 392, 440, 392,
    330, 392, 494, 392,
    349, 440, 523, 440
]

beat = 0.35

for note in melody:
    length = int(SAMPLE_RATE * beat)

    for i in range(length):
        t = i / SAMPLE_RATE
        envelope = min(1, t / 0.04) * min(1, (beat - t) / 0.08)

        main = math.sin(2 * math.pi * note * t)
        bass = math.sin(2 * math.pi * (note / 2) * t)

        sound = (main * 0.16 + bass * 0.08) * envelope
        music.append(sound)

save_wav("assets/music/meadow.wav", music)

print("\nAll Chickventure audio files created!")
