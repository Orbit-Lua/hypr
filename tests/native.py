#!/usr/bin/env python3
# pyright: standard
"""A native-command seam used only by isolated helper tests."""

import json
import os
from pathlib import Path
import sys
import base64
import time
import re


root = Path(os.environ["HYPR_TEST_ROOT"])
program = Path(sys.argv[0]).name
scenario = json.loads((root / "scenario.json").read_text()).get(program, {})
if program == "hyprctl":
    arguments = [value for value in sys.argv[1:] if value != "-j"]
    operation = arguments[0]
    key = " ".join(arguments[:2]) if operation == "getoption" else operation
    overrides = scenario.get("operations", {}).get(key, {})
    if isinstance(overrides, list):
        history = [json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()] if (root / "calls.jsonl").exists() else []
        count = sum(row["program"] == program and [value for value in row["args"] if value != "-j"][:1] == [operation] for row in history)
        overrides = overrides[min(count, len(overrides) - 1)]
    if operation in ("eval", "reload"):
        scenario = {**scenario, "stdout": "ok\n"}
    elif operation == "configerrors":
        scenario = {**scenario, "stdout": '[""]'}
    elif operation == "devices":
        enabled = (root / "device-state").read_text() == "true" if (root / "device-state").exists() else True
        scenario = {**scenario, "stdout": json.dumps({"mice": [{"name": "asue1209:00-04f3:319f-touchpad", "enabled": enabled}]})}
    elif operation == "getoption" and "stdout" not in scenario:
        defaults = {"animations:enabled": 1, "decoration:shadow:enabled": 1, "decoration:blur:enabled": 1, "decoration:rounding": 16, "general:gaps_in": 6, "general:gaps_out": 12, "general:border_size": 1}
        scenario = {**scenario, "stdout": json.dumps({"int": defaults.get(arguments[1], 0)})}
    scenario = {**scenario, **overrides}
    if operation == "eval" and not scenario.get("code", 0) and "hl.device" in arguments[1]:
        value = re.search(r"enabled\s*=\s*(true|false)", arguments[1])
        if value:
            (root / "device-state").write_text(value.group(1))
            if scenario.get("refuse_receipt"):
                (root / "runtime/touchpad.status").mkdir(exist_ok=True)
with (root / "calls.jsonl").open("a") as log:
    log.write(json.dumps({"program": program, "args": sys.argv[1:]}) + "\n")
if program == "grim" and "stdout" not in scenario:
    sys.stdout.buffer.write(base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="))
else:
    sys.stdout.write(scenario.get("stdout", ""))
sys.stderr.write(scenario.get("stderr", ""))
sys.stdout.flush()
sys.stderr.flush()
time.sleep(scenario.get("delay", 0))
sys.exit(scenario.get("code", 0))
