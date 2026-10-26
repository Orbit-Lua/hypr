"""Parse each shipped profile with the native compositor, without a session."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="hypr-profiles-") as directory:
    sandbox = Path(directory)
    config = sandbox / "config"
    shutil.copytree(ROOT, config, ignore=shutil.ignore_patterns(".git", "__pycache__"))
    shutil.copyfile(ROOT / "tests/fixtures/noctalia.lua", config / "noctalia.lua")
    runtime = sandbox / "runtime"
    runtime.mkdir(mode=0o700)
    for category in ("animation", "monitor"):
        for profile in sorted((config / "profiles" / category).glob("*.lua")):
            state = sandbox / "state"
            shutil.rmtree(state, ignore_errors=True)
            selected = state / "profiles/selected" / category
            selected.parent.mkdir(parents=True)
            selected.write_text(profile.stem)
            wrapper = config / "verify.lua"
            wrapper.write_text(
                f'dofile("{config}/hyprland.lua")\n'
                f'assert(require("hyprconf.profile").loaded.{category} == "{profile.stem}", '
                '"selected profile did not load")\n'
            )
            result = subprocess.run(
                ["hyprland", "--verify-config", "--config", str(wrapper)],
                env={
                    "HOME": str(sandbox), "PATH": os.environ["PATH"],
                    "XDG_RUNTIME_DIR": str(runtime), "HYPR_CONFIG_DIR": str(config),
                    "HYPR_STATE_DIR": str(state),
                },
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode:
                raise AssertionError(f"{category}/{profile.name}:\n{result.stdout}\n{result.stderr}")
    print("All shipped profiles passed native configuration parsing")
