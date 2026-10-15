#!/usr/bin/env python3
"""Derive summary.json from preserved device samples; no device connection."""
import hashlib
import json
import math
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent
OUT = HERE / "evidence"


def stats(values):
    values = sorted(values)
    if not values:
        return {"count": 0}
    return dict(count=len(values), mean=statistics.mean(values),
                p50=values[math.ceil(len(values)*0.5)-1],
                p95=values[math.ceil(len(values)*0.95)-1], max=max(values), min=min(values))


records = [json.loads(line) for line in (OUT / "results.jsonl").read_text().splitlines()]
summary = {"performance": {}, "refresh": {}, "raw_failed_assertions": [], "observations": []}
for record in records:
    name, result = record["name"], record["result"]
    if not record["ok"]:
        summary["raw_failed_assertions"].append(record)
    if name.startswith("performance-"):
        samples = result["samples"]
        dsp = [v["dsp"] if isinstance(v, dict) else v for v in samples]
        item = {"dsp_percent": stats(dsp), "xruns": result["xruns"], "seconds": result["seconds"]}
        events = result.get("events", [])
        if events:
            lateness = [(e["beat"]-e["target"])*60000/result["bpm"] for e in events]
            item["lateness_ms"] = stats(lateness)
            item["events"] = len(events)
            item["max_inter_event_ms"] = max((b["time"]-a["time"])*1000 for a,b in zip(events,events[1:]))
        draws = result.get("draws", [])
        if draws:
            item["draws_per_second"] = len(draws)/result["seconds"]
            item["draw_interval_ms"] = stats([(b-a)*1000 for a,b in zip(draws,draws[1:])])
        summary["performance"][name] = item
    elif name.startswith("human-") or name in ["restoration", "mod-disable-restart", "core-only-cancel-race"]:
        summary["observations"].append(record)

probe = json.loads((OUT / "probe.json").read_text())
assert probe["callbacks"] == {"accept": "accepted", "fileselect": "cancel", "textentry": "nil"}
for phase, times in probe["refresh"].items():
    if times:
        summary["refresh"][phase] = {
            "events": len(times), "hz": (len(times)-1)/(times[-1]-times[0]),
            "interval_ms": stats([(b-a)*1000 for a,b in zip(times,times[1:])])}
summary["refresh"]["menu"] = {"events": len(probe["refresh"].get("menu", []))}
summary["modal_callbacks"] = probe["callbacks"]

manifest = json.loads((OUT / "manifest.json").read_text())
for name, expected in manifest.items():
    actual = hashlib.sha256((OUT / "deployed" / name).read_bytes()).hexdigest()
    assert actual == expected, name
summary["manifest_verified"] = True
(OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2))
