import re
import json
import subprocess

result = subprocess.run(
    ["niri", "msg", "windows"],
    capture_output=True,
    text=True,
    check=True
)

text = result.stdout

windows = []
current = None

for line in text.splitlines():
    line = line.rstrip()

    # Start of a new window block
    m = re.match(r"Window ID (\d+):", line)
    if m:
        if current:
            windows.append(current)
        current = {
            "window_id": int(m.group(1)),
            "title": None,
            "app_id": None,
        }
        continue

    if current is None:
        continue

    if line.strip().startswith("Title:"):
        current["title"] = line.split("Title:", 1)[1].strip().strip('"')

    elif line.strip().startswith("App ID:"):
        current["app_id"] = line.split("App ID:", 1)[1].strip().strip('"')

# append last window
if current:
    windows.append(current)

print(json.dumps(windows, indent=2, ensure_ascii=False))

