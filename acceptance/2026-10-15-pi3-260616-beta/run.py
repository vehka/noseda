#!/usr/bin/env python3
"""Reproducible device acceptance transport; every operation is logged.

Use the websocket-client dependency from skills/noseda/scripts/requirements.txt.
Run from any directory. See REPORT.md for the actual sequence and limitations.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

import websocket

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / "evidence"
OUT.mkdir(exist_ok=True)
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument("--host", default="10.0.0.138")
ap.add_argument("--wait", type=float, default=2)
ap.add_argument("action", choices=["inventory", "deploy", "upload", "lua", "sc", "shell", "load", "cycles", "collect"])
ap.add_argument("code", nargs="?", default="")
args = ap.parse_args()
TARGET = f"we@{args.host}"


def record(kind, command, output, **extra):
    entry = dict(time=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                 kind=kind, command=command, output=output, **extra)
    with (OUT / "commands.jsonl").open("a") as f:
        f.write(json.dumps(entry) + "\n")
    if len(output) > 6000:
        print(f"{kind}: captured {len(output)} characters in evidence/commands.jsonl", flush=True)
    else:
        print(output, end="" if output.endswith("\n") else "\n", flush=True)


def shell(command, check=True):
    p = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
                        TARGET, command], text=True, capture_output=True, timeout=90)
    record("ssh", command, p.stdout + p.stderr, returncode=p.returncode)
    if check and p.returncode:
        raise RuntimeError(f"SSH command failed ({p.returncode})")
    return p.stdout


def repl(code, sc=False, wait=None):
    port = 5556 if sc else 5555
    ws = websocket.create_connection(f"ws://{args.host}:{port}/",
                                    subprotocols=["bus.sp.nanomsg.org"], timeout=10)
    ws.settimeout(0.2)
    ws.send(code + ("\x0c" if sc else "\n"))
    output = ""
    deadline = time.monotonic() + (args.wait if wait is None else wait)
    while time.monotonic() < deadline:
        try:
            data = ws.recv()
            if not data:
                break
            output += data if isinstance(data, str) else data.decode(errors="replace")
        except websocket.WebSocketTimeoutException:
            pass
        except websocket.WebSocketConnectionClosedException:
            output += "\n[transport disconnected; verify restart separately]\n"
            break
    ws.close()
    record("sclang" if sc else "lua", code, output)
    return output


def scp(source, destination):
    p = subprocess.run(["scp", "-q", str(source), str(destination)],
                       text=True, capture_output=True, timeout=90)
    record("scp", [str(source), str(destination)], p.stdout + p.stderr,
           returncode=p.returncode)
    p.check_returncode()


def blocks(path, lang):
    text = (ROOT / "skills/noseda/references" / path).read_text()
    return re.findall(r"```" + lang + r"\n(.*?)```", text, re.S)


if args.action == "inventory":
    inventory = shell("date -u; hostname; uname -a; cat ~/version.txt; "
                      "cat /proc/device-tree/model; cat /etc/os-release; "
                      "git -C ~/norns rev-parse HEAD; git -C ~/norns status --short; "
                      "git -C ~/norns diff --stat; cat /proc/asound/cards; lsusb; "
                      "systemctl cat norns-main norns-sclang norns-jack; "
                      "cat /etc/systemd/logind.conf.d/10-norns-removeipc.conf; "
                      "jack_lsp -c; vcgencmd get_throttled; uptime")
    (OUT / "inventory.txt").write_text(inventory)
    for name in ["system.mods", "system.state"]:
        (OUT / ("original-" + name)).write_text(shell(f"cat ~/dust/data/{name}"))
    repl('print("TARGET", norns.version.update, norns.platform, norns.is_shield, _norns.adc_rev(), norns.state.script); local m=require "core/mods"; print("LOADED",table.concat(m.loaded_mod_names(),",")); for k,v in pairs(midi.devices) do print("MIDI",k,v.name) end; for k,v in pairs(grid.devices) do print("GRID",k,v.name) end; print("MENU",_menu.mode)')
elif args.action == "deploy":
    shell("ls -ld ~/dust/code ~/dust/data; "
          "test ! -e ~/dust/code/modern_steps && test ! -e ~/dust/code/modern_counter && "
          "test ! -e ~/dust/code/modern_tone && test ! -e ~/dust/code/noseda_acceptance && "
          "test ! -e ~/dust/data/noseda_acceptance")
    files = {
        "modern_steps/modern_steps.lua": blocks("components/script.md", "lua")[0],
        "modern_counter/lib/mod.lua": blocks("components/mod.md", "lua")[0],
        "modern_tone/lib/Engine_NoSEDATone.sc": blocks("components/engine.md", "supercollider")[0],
        "modern_tone/lib/noseda_tone_engine.lua": blocks("components/engine.md", "lua")[0],
        "modern_tone/modern_tone.lua": blocks("components/engine.md", "lua")[1],
        "noseda_acceptance/checks.lua": (HERE / "checks.lua").read_text(),
        "noseda_acceptance/probe.lua": (HERE / "probe.lua").read_text(),
    }
    # Fault fixtures add one explicit failure to otherwise verbatim bodies.
    files["modern_steps/fail_init.lua"] = files["modern_steps/modern_steps.lua"] + "\nlocal original_init = init\nfunction init() original_init(); error('ACCEPT intentional partial init') end\n"
    files["modern_steps/fail_top.lua"] = files["modern_steps/modern_steps.lua"] + "\nerror('ACCEPT intentional top-level failure')\n"
    manifest = {}
    for name, content in files.items():
        path = OUT / "deployed" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        manifest[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    shell("mkdir -p ~/dust/data/noseda_acceptance ~/dust/code/modern_steps "
          "~/dust/code/modern_counter/lib ~/dust/code/modern_tone/lib ~/dust/code/noseda_acceptance; "
          "cp -p ~/dust/data/system.mods ~/dust/data/noseda_acceptance/original-system.mods; "
          "cp -p ~/dust/data/system.state ~/dust/data/noseda_acceptance/original-system.state")
    for name in files:
        scp(OUT / "deployed" / name, f"{TARGET}:dust/code/{name}")
    # Expose the state fragment's lexical values only to the diagnostic harness.
    fragment = blocks("patterns/state.md", "lua")[0]
    sidecar = OUT / "deployed" / "noseda_acceptance/sidecar.lua"
    sidecar.write_text(fragment + "\nreturn {install = install_pset_hooks, get = function() return steps end, set = function(v) steps = v end}\n")
    scp(sidecar, f"{TARGET}:dust/code/noseda_acceptance/sidecar.lua")
    shell("sha256sum ~/dust/code/modern_steps/modern_steps.lua ~/dust/code/modern_counter/lib/mod.lua ~/dust/code/modern_tone/modern_tone.lua ~/dust/code/modern_tone/lib/*; "
          "luac -p ~/dust/code/modern_steps/*.lua ~/dust/code/modern_counter/lib/mod.lua ~/dust/code/modern_tone/*.lua ~/dust/code/modern_tone/lib/*.lua ~/dust/code/noseda_acceptance/*.lua")
elif args.action == "lua":
    repl(args.code)
elif args.action == "upload":
    path = HERE / args.code
    record("harness-revision", args.code, hashlib.sha256(path.read_bytes()).hexdigest())
    scp(path, f"{TARGET}:dust/code/noseda_acceptance/{path.name}")
elif args.action == "sc":
    repl(args.code, sc=True)
elif args.action == "shell":
    shell(args.code)
elif args.action == "load":
    repl(f'norns.script.load("code/{args.code}")', wait=args.wait)
elif args.action == "cycles":
    for i in range(3):
        for path in ["modern_tone/modern_tone.lua", "modern_tone/modern_tone.lua",
                     "modern_steps/modern_steps.lua"]:
            result = repl(f'norns.script.load("code/{path}")', wait=2)
            if "# script init" not in result:
                raise RuntimeError("script did not initialize")
            if "modern_tone" in path:
                repl('_norns.key(3,1)', wait=0.3)
            else:
                repl('clock.transport.start()', wait=0.5)
            repl(f'["CYCLE",{i},Crone.engine.class.name,Crone.server.numSynths,Crone.server.numGroups,Crone.server.numUGens].postln;', sc=True, wait=1)
        repl('norns.script.clear(); dofile(_path.code.."noseda_acceptance/checks.lua").cleanup_check()', wait=1)
        repl(f'["CLEARED",{i},Crone.engine,Crone.server.numSynths,Crone.server.numGroups,Crone.server.numUGens].postln;', sc=True, wait=1)
elif args.action == "collect":
    for name in ["results.jsonl", "probe.json"]:
        scp(f"{TARGET}:dust/data/noseda_acceptance/{name}", OUT / name)
    scp(f"{TARGET}:dust/data/noseda_acceptance/*.png", OUT)
    scp(f"{TARGET}:dust/data/noseda_acceptance/audio-*.txt", OUT)
    for service in ["main", "sclang", "jack"]:
        text = shell(f"journalctl -u norns-{service} --since '2026-10-15 00:00:00' --no-pager -o short-iso", check=False)
        (OUT / f"journal-{service}.txt").write_text(text)
