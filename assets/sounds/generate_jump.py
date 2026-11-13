
import math
import wave
import struct

sample_rate = 22050
duration = 0.25

with wave.open("jump.wav", "w") as audio:
    audio.setnchannels(1)
    audio.setsampwidth(2)
    audio.setframerate(sample_rate)

    samples = []

    for i in range(int(sample_rate * duration)):
        t = i / sample_rate

        frequency = 650 - (350 * t / duration)
        envelope = (1 - t / duration) ** 2

        sound = math.sin(2 * math.pi * frequency * t)
        sound *= envelope * 0.45

        samples.append(struct.pack("<h", int(sound * 32767)))

    audio.writeframes(b"".join(samples))

print("Pippo's jump sound created!")
