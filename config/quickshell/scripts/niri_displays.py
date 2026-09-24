#!/usr/bin/env python3
"""Temporary Niri output modes; never edits compositor configuration."""
import json
import shutil
import signal
import subprocess
import sys
import time


def msg(*args):
    result = subprocess.run(["niri", "msg", "-j", *args], capture_output=True,
                            text=True, timeout=10)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Niri command failed")
    return json.loads(result.stdout)


def outputs():
    return list(msg("outputs").values())


def internal(output):
    return output["name"].startswith(("eDP", "LVDS", "DSI"))


def configure(name, *args):
    reply = msg("output", name, *args)
    if reply != "Applied":
        raise RuntimeError(f"Output {name} is no longer connected")


def restore(before):
    # Bring back the previously lit outputs before disabling anything.
    connected = {o["name"] for o in outputs()}
    before = [o for o in before if o["name"] in connected]
    if before and not any(o["current_mode"] is not None for o in before):
        # The previously active external monitor may have been unplugged.
        configure(before[0]["name"], "on")
        return
    for output in before:
        if output["current_mode"] is not None:
            configure(output["name"], "on")
    for output in before:
        logical = output.get("logical")
        if logical:
            configure(output["name"], "position", "set",
                      "--", str(logical["x"]), str(logical["y"]))
        elif output["current_mode"] is None:
            configure(output["name"], "off")


def apply(mode):
    before = sorted(outputs(), key=lambda o: (not internal(o), o["name"]))
    panels = [o for o in before if internal(o)]
    external = [o for o in before if not internal(o)]
    if mode not in ("notebook", "external", "extend", "duplicate"):
        raise RuntimeError("Unknown monitor mode")
    if mode == "notebook" and not panels:
        raise RuntimeError("No notebook monitor is connected")
    if mode in ("external", "extend", "duplicate") and not external:
        raise RuntimeError("Connect an external monitor first")
    if mode == "duplicate" and (not panels or not shutil.which("wl-mirror")):
        raise RuntimeError("Duplicate requires a notebook monitor and wl-mirror")
    enabled = panels if mode == "notebook" else external if mode == "external" else before
    names = [o["name"] for o in enabled]
    try:
        for name in names:
            configure(name, "on")
        # Confirm the destination is lit before turning off another output.
        for _ in range(20):
            current = {o["name"]: o for o in outputs()}
            if all(current.get(name, {}).get("logical") for name in names):
                break
            time.sleep(0.1)
        if not all(current.get(name, {}).get("logical") for name in names):
            raise RuntimeError("The selected monitors could not be enabled")
        x = 0
        for name in names:
            configure(name, "position", "set", str(x), "0")
            x += current[name]["logical"]["width"]
        for output in before:
            if output["name"] not in names:
                configure(output["name"], "off")
    except Exception as error:
        try:
            restore(before)
        except Exception as recovery_error:
            raise RuntimeError(f"{error}; could not restore layout: {recovery_error}") from error
        raise
    return {"source": panels[0]["name"] if panels else "",
            "targets": [o["name"] for o in external]}


def mirror(source, targets):
    children = []

    def stop(*_):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        for target in targets:
            children.append(subprocess.Popen([
                "wl-mirror", "--fullscreen-output", target, source]))
        while children:
            if any(child.poll() is not None for child in children):
                raise RuntimeError("Mirroring stopped; select Duplicate to try again")
            time.sleep(0.25)
    finally:
        for child in children:
            if child.poll() is None:
                child.terminate()
        for child in children:
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()


def main():
    if sys.argv[1] == "get":
        print(json.dumps({"outputs": outputs(), "canMirror": bool(shutil.which("wl-mirror"))}))
    elif sys.argv[1] == "apply":
        print(json.dumps(apply(sys.argv[2])))
    elif sys.argv[1] == "mirror":
        mirror(sys.argv[2], sys.argv[3:])


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
