import whisper

model = whisper.load_model("base")  # tiny, base, small, medium, large
result = model.transcribe("/home/neimog/Downloads/audio.mp3")

print(result["text"])
