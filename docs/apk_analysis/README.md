# DJI Fly APK Analysis

Reverse-engineering how DJI Fly (dji.go.v5) discovers, loads, and manages
waypoint missions on the filesystem.

## Goal

Determine whether we can create new waypoint missions by writing files
directly, or if DJI Fly maintains an internal database/registry.

## What We Know

### Filesystem layout
```
/sdcard/Android/data/dji.go.v5/files/waypoint/
  {uuid}/
    {uuid}.kmz          # primary KMZ file
  kmzTemp/
    {uuid}.kmz          # cached/temp copy
  capability/
    *.json              # drone capability files
```

### Observed behavior
- Push provider writes KMZ to both `{uuid}/{uuid}.kmz` AND `kmzTemp/{uuid}.kmz`
- DJI Fly lists missions by scanning UUID folders under `waypoint/`
- UUID folders match pattern `[0-9a-f]{8}-[0-9a-f]{4}-...-[0-9a-f]{12}`

### Open questions
1. Does DJI Fly discover missions purely from filesystem, or does it use a
   SQLite database / SharedPreferences / protobuf registry?
2. What is `kmzTemp/` for — cache, staging area, or required for discovery?
3. Are there any additional metadata files (manifest, index) needed?
4. What happens if we create a new UUID folder with a valid KMZ — does the
   app pick it up?
5. Does the app validate KMZ signatures or checksums?

## Tools

- **jadx** v1.5.5 — installed at `~/tools/jadx/bin/jadx`
- **adb** — for pulling APK from device

## How to Run

1. Connect phone via USB
2. Run: `bash extract_and_decompile.sh <device_serial>`
3. Decompiled Java source lands in `decompiled/sources/`

## Search Strategy

Priority grep targets once decompiled:

```bash
# How does it find/list waypoint missions?
grep -r 'waypoint' sources/ --include='*.java' -l | head -30
grep -r 'kmzTemp' sources/ --include='*.java' -l
grep -r 'WaypointMission' sources/ --include='*.java' -l

# Does it use a database for mission tracking?
grep -r 'waypoint.*database\|waypoint.*dao\|waypoint.*db' sources/ -il
grep -r 'mission.*table\|mission.*entity' sources/ -il

# SharedPreferences or config files?
grep -r 'SharedPreferences.*waypoint\|waypoint.*pref' sources/ -il

# File discovery / directory scanning
grep -r 'listFiles.*waypoint\|waypoint.*list' sources/ --include='*.java' -l
```

## Findings

<!-- Document findings below as we analyze the decompiled code -->
