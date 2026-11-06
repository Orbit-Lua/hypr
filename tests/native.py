#!/usr/bin/env python3
# pyright: standard
"""A native-command seam used only by isolated helper tests."""

import base64
import json
import os
import re
import sys
import time
from pathlib import Path

# Use only the isolated test root; this fake never connects to a compositor.
ROOT = Path(os.environ["HYPR_TEST_ROOT"])
PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="


def repeated_reply(program, operation, replies):
    history_path = ROOT / "calls.jsonl"
    history = (
        [json.loads(line) for line in history_path.read_text().splitlines()]
        if history_path.exists()
        else []
    )
    count = sum(
        row["program"] == program
        and [value for value in row["args"] if value != "-j"][:1] == [operation]
        for row in history
    )
    return replies[min(count, len(replies) - 1)]


def default_reply(operation, arguments, scenario):
    if operation in ("eval", "reload"):
        return {"stdout": "ok\n"}
    if operation == "configerrors":
        return {"stdout": '[""]'}
    if operation == "devices":
        state_path = ROOT / "device-state"
        enabled = state_path.read_text() == "true" if state_path.exists() else True
        return {
            "stdout": json.dumps(
                {"mice": [{"name": "asue1209:00-04f3:319f-touchpad", "enabled": enabled}]}
            )
        }
    if operation == "getoption" and "stdout" not in scenario:
        defaults = {
            "animations:enabled": 1,
            "decoration:shadow:enabled": 1,
            "decoration:blur:enabled": 1,
            "decoration:rounding": 16,
            "general:gaps_in": 6,
            "general:gaps_out": 12,
            "general:border_size": 1,
        }
        return {"stdout": json.dumps({"int": defaults.get(arguments[1], 0)})}
    return {}


def apply_device_reply(operation, arguments, scenario):
    if operation != "eval" or scenario.get("code", 0) or "hl.device" not in arguments[1]:
        return
    value = re.search(r"enabled\s*=\s*(true|false)", arguments[1])
    if value:
        (ROOT / "device-state").write_text(value.group(1))
        if scenario.get("refuse_receipt"):
            (ROOT / "runtime/touchpad.status").mkdir(exist_ok=True)


def compositor_reply(program, scenario):
    arguments = [value for value in sys.argv[1:] if value != "-j"]
    operation = arguments[0]
    key = " ".join(arguments[:2]) if operation == "getoption" else operation
    overrides = scenario.get("operations", {}).get(key, {})
    if isinstance(overrides, list):
        overrides = repeated_reply(program, operation, overrides)
    scenario = {**scenario, **default_reply(operation, arguments, scenario), **overrides}
    apply_device_reply(operation, arguments, scenario)
    return scenario


def main():
    program = Path(sys.argv[0]).name
    scenario = json.loads((ROOT / "scenario.json").read_text()).get(program, {})
    if program == "hyprctl":
        scenario = compositor_reply(program, scenario)
    with (ROOT / "calls.jsonl").open("a") as log:
        log.write(json.dumps({"program": program, "args": sys.argv[1:]}) + "\n")
    if program == "grim" and "stdout" not in scenario:
        sys.stdout.buffer.write(base64.b64decode(PNG))
    else:
        sys.stdout.write(scenario.get("stdout", ""))
    sys.stderr.write(scenario.get("stderr", ""))
    sys.stdout.flush()
    sys.stderr.flush()
    time.sleep(scenario.get("delay", 0))
    return scenario.get("code", 0)


if __name__ == "__main__":
    sys.exit(main())
