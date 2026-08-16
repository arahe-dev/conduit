#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, subprocess, sys

raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], text=True)
data = json.loads(raw)
preferred_models = ["iPhone 17", "iPhone 16", "iPhone 16e", "iPhone 17e", "iPhone Air"]

candidates = []
for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime and "iphoneos" not in runtime.lower() and "iOS-" not in runtime:
        # simctl JSON keys look like com.apple.CoreSimulator.SimRuntime.iOS-26-5
        if "iOS-" not in runtime:
            continue
    for device in devices:
        if not device.get("isAvailable", True):
            continue
        name = device.get("name", "")
        udid = device.get("udid")
        if not udid:
            continue
        candidates.append((runtime, name, udid))

def ios_rank(runtime: str) -> tuple:
    # Prefer newest iOS runtime.
    parts = runtime.replace("iOS-", " ").replace("iOS ", " ").split("-")
    nums = []
    for token in runtime.replace(".", "-").split("-"):
        if token.isdigit():
            nums.append(int(token))
    return tuple(nums) if nums else (0,)

def model_rank(name: str) -> int:
    try:
        return preferred_models.index(name)
    except ValueError:
        return 100 if name.startswith("iPhone") else 1000

iphones = [c for c in candidates if c[1].startswith("iPhone")]
if not iphones:
    print("No iPhone simulators found", file=sys.stderr)
    sys.exit(1)

iphones.sort(key=lambda c: (-sum(x * 100 ** i for i, x in enumerate(reversed(ios_rank(c[0])))), model_rank(c[1]), c[1]))
# Prefer preferred model on the newest runtime
best = None
newest = max(ios_rank(c[0]) for c in iphones)
newest_runtime_iphones = [c for c in iphones if ios_rank(c[0]) == newest]
for model in preferred_models:
    match = next((c for c in newest_runtime_iphones if c[1] == model), None)
    if match:
        best = match
        break
if best is None:
    best = newest_runtime_iphones[0] if newest_runtime_iphones else iphones[0]

runtime, name, udid = best
print(f"Selected simulator: {name} ({runtime}) {udid}")
env_path = os.environ.get("GITHUB_ENV")
if env_path:
    with open(env_path, "a", encoding="utf-8") as fh:
        fh.write(f"SIM_NAME={name}\n")
        fh.write(f"SIM_OS={runtime}\n")
        fh.write(f"SIM_UDID={udid}\n")
else:
    print(f"SIM_NAME={name}")
    print(f"SIM_OS={runtime}")
    print(f"SIM_UDID={udid}")
PY
