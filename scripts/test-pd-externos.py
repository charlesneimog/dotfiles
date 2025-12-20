import os
import shutil
import sys
import platform
import subprocess

# Detect Pd executable
PDBIN = ""
if platform.system() in ("Linux", "Darwin"):
    PDBIN = shutil.which("pd")
elif platform.system() == "Windows":
    PDBIN = r"C:\Program Files\Pd\bin\pd.com"

if not PDBIN:
    raise RuntimeError("Pd executable not found")

# Get library path from command line or input
libpath = None
try:
    i = sys.argv.index("--library")
    libpath = sys.argv[i + 1]
except ValueError:
    pass
except IndexError:
    raise RuntimeError("--library requires a value")

if libpath is None:
    libpath = input("Complete path to library (or use --library): ")

if not os.path.isdir(libpath):
    raise RuntimeError(f"Library path does not exist: {libpath}")

# List patches
patches = [f for f in os.listdir(libpath) if f.endswith("-help.pd")]

for patch in patches:
    patch_path = os.path.join(libpath, patch)
    print(f"Running patch: {patch_path}")

    cmd = [PDBIN, "-stderr", "-nogui", patch_path]

    try:
        # Run Pd and capture stderr
        result = subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,  # ignore stdout
            stderr=subprocess.PIPE,
            timeout=0.2,  # 200ms
            text=True,
        )
        # Save stderr to a file
        log_file = os.path.join(libpath, f"{patch}-stderr.log")
        with open(log_file, "w") as f:
            f.write(result.stderr)

    except subprocess.TimeoutExpired:
        print(f"Timeout: {patch_path} ran longer than 200ms, terminating.")
    except Exception as e:
        print(f"Error running {patch_path}: {e}")
