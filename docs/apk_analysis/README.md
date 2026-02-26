# DJI Fly APK Analysis

Reverse-engineering how DJI Fly (dji.go.v5) discovers, loads, and manages
waypoint missions on the filesystem.

## Goal

Determine whether we can create new waypoint missions by writing files
directly, or if DJI Fly maintains an internal database/registry.

## Tools

- **jadx** v1.5.5 — installed at `~/tools/jadx/bin/jadx`
- **adb** — for pulling APK from device

## How to Run

1. Connect phone via USB
2. Run: `bash extract_and_decompile.sh <device_serial>`
3. Decompiled Java source lands in `decompiled/sources/`

## Findings

### Complete filesystem layout (from device inspection)

```
/sdcard/Android/data/dji.go.v5/files/waypoint/
  {UUID}/
    {UUID}.kmz                    # primary KMZ file (rw-rw-rw-)
    image/
      ShotSnap.json               # action snapshot metadata (rw-rw----)
  kmzTemp/
    {UUID}.kmz                    # copy of the KMZ (rw-rw----)
  map_preview/
    {UUID}/
      {UUID}.jpg                  # map thumbnail screenshot (rw-rw----)
  capability/
    SPEEDCapability.json
    GIMBAL_PITCHCapability.json
    GIMBAL_ROLLCapability.json
    LOST_ACTIONCapability.json
    ZOOMCapability.json
```

### No database for waypoint tracking

- Only database on external storage: `cache/diskcache/map_cache.db` (map tiles)
- No SQLite, SharedPreferences, or registry file found for waypoint missions
- Internal app data (`/data/data/dji.go.v5/`) is inaccessible (non-debuggable)
  but the complete waypoint structure lives on external storage

### Native library `libwpmz_jni.so` handles all KMZ logic

The waypoint mission code lives in a C++ native library, not Java. Key symbols:

```
native_CheckWPMZValid          # validates KMZ structure
native_GenerateKMZFile         # creates KMZ from mission data
native_GetWaylineMission       # parses mission from KMZ
native_GetWaylineMissionConfig # parses config from KMZ
native_GetWaylineTemplates     # parses wayline templates
native_GetWaylines             # extracts waylines
native_GenerateWaylineTrajectory  # generates flight trajectory
```

Internal C++ namespaces: `uav::wpmz::*`, `kmldom::*`, `kmlengine::*`
- Uses libkml for KML/KMZ parsing (open-source Google library)
- Classes: `WaylineMission`, `WaylineWaypoint`, `WaylineMissionConfig`
- Waypoint params: `YawParam`, `TurnParam`, `GimbalHeadingParam`

### ShotSnap.json

Empty action snapshot metadata for the mission:
```json
{"POI_POINT":{},"WAY_POINT":{}}
```

### Java layer is fully obfuscated

- DJI package at `dji/p005go/p006v5/` contains only `R.java` (resources)
- All business logic class names are scrambled
- String literals are encrypted/loaded at runtime
- The `System.loadLibrary("wpmz_jni")` call is in obfuscated code

### Conclusions

1. **No waypoint database exists on external storage.** Mission discovery is
   almost certainly filesystem-based — scanning UUID folders under `waypoint/`.

2. **Full mission folder structure has 3 parts:**
   - `{UUID}/{UUID}.kmz` — the mission file itself
   - `kmzTemp/{UUID}.kmz` — a duplicate (possibly for upload to drone)
   - `map_preview/{UUID}/{UUID}.jpg` — thumbnail for the mission list

3. **`image/ShotSnap.json`** is created inside the mission folder for action
   metadata. Can be empty `{"POI_POINT":{},"WAY_POINT":{}}`.

4. **The map preview JPG** is likely optional for discovery but needed for
   the mission list to show a thumbnail. Missing = probably blank thumbnail.

5. **To test creating a new mission**, we need:
   - Generate a new UUID
   - Write a valid KMZ to `{UUID}/{UUID}.kmz`
   - Copy KMZ to `kmzTemp/{UUID}.kmz`
   - Optionally: create `image/ShotSnap.json` and `map_preview/{UUID}/{UUID}.jpg`
   - Open DJI Fly and check the waypoint mission list
