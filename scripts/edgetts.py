#!/usr/bin/env python3
import sys
import asyncio
import edge_tts
import pygame

VOICE = "pt-BR-FranciscaNeural"  # Choose any Edge neural voice

async def speak(text):
    mp3_path = "/tmp/edgetts_output.mp3"
    tts = edge_tts.Communicate(text, VOICE)
    await tts.save(mp3_path)

    pygame.mixer.init()
    pygame.mixer.music.load(mp3_path)
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy():
        pygame.time.Clock().tick(10)

def main():
    for line in sys.stdin:
        line = line.strip()
        if line.startswith("SPEAK"):
            text = line[6:].strip()
            asyncio.run(speak(text))
            print("OK SPEAK")
            sys.stdout.flush()
        elif line == "STOP":
            pygame.mixer.music.stop()
            print("OK STOP")
            sys.stdout.flush()
        elif line == "QUIT":
            print("OK QUIT")
            sys.stdout.flush()
            break

if __name__ == "__main__":
    main()
