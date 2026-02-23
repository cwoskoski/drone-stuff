#!/usr/bin/env python3
"""Push DJI waypoint KMZ files to a connected device via ADB.

Automates the process of replacing a DJI GoFly waypoint mission with a
Litchi Hub (or other tool) exported KMZ.  Supports listing existing
missions on the device, interactive mission selection, automatic backup,
and dry-run previews.

Requires: adb on PATH, a single connected Android device with DJI GoFly.
Stdlib only — no pip dependencies.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional

# ── Constants ────────────────────────────────────────────────────────────

WAYPOINT_ROOT = "/sdcard/Android/data/dji.go.v5/files/waypoint"
UUID_PATTERN = re.compile(
    r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-"
    r"[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
)
REQUIRED_KMZ_ENTRIES = ("wpmz/template.kml", "wpmz/waylines.wpml")

# XML namespaces used by DJI and Litchi KMZ files
WPML_NAMESPACES = [
    "http://www.dji.com/wpmz/1.0.6",
    "http://www.uav.com/wpmz/1.0.2",
]
KML_NS = "http://www.opengis.net/kml/2.2"

BACKUP_DIR = Path(__file__).resolve().parent / "backups"


# ── Exceptions ───────────────────────────────────────────────────────────

class PushWaypointsError(Exception):
    """Base error for this tool."""


class AdbError(PushWaypointsError):
    """ADB command failed."""


class KmzError(PushWaypointsError):
    """KMZ file is invalid or missing expected content."""


# ── Dataclasses ──────────────────────────────────────────────────────────

@dataclass
class KmzMetadata:
    author: str = ""
    create_time: str = ""
    waypoint_count: int = 0


@dataclass
class DeviceMission:
    uuid: str = ""
    kmz_size: int = 0
    metadata: KmzMetadata = field(default_factory=KmzMetadata)


# ── ADB helpers ──────────────────────────────────────────────────────────

def _is_wsl() -> bool:
    """Detect Windows Subsystem for Linux."""
    try:
        with open("/proc/version", "r") as f:
            return "microsoft" in f.read().lower()
    except OSError:
        return False


IS_WSL = _is_wsl()


def to_adb_local_path(wsl_path: str) -> str:
    """Convert a WSL Linux path to a Windows path for ADB push/pull.

    ADB on WSL is typically a Windows binary that needs Windows paths for
    local file arguments.  Device-side paths stay as-is.
    """
    if not IS_WSL:
        return wsl_path
    try:
        result = subprocess.run(
            ["wslpath", "-w", wsl_path],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return wsl_path


def adb_run(args: List[str], *, check: bool = True) -> subprocess.CompletedProcess:
    """Run an adb command and return the result."""
    cmd = ["adb"] + args
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        raise AdbError("adb not found on PATH")
    except subprocess.TimeoutExpired:
        raise AdbError(f"adb command timed out: {' '.join(cmd)}")
    if check and result.returncode != 0:
        stderr = result.stderr.strip()
        raise AdbError(f"adb failed (rc={result.returncode}): {stderr}")
    return result


def adb_shell(command: str, *, check: bool = True) -> str:
    """Run a command on the device via adb shell."""
    result = adb_run(["shell", command], check=check)
    return result.stdout.strip()


def adb_pull(device_path: str, local_path: str) -> None:
    """Pull a file from device to local filesystem."""
    adb_run(["pull", device_path, to_adb_local_path(local_path)])


def adb_push(local_path: str, device_path: str) -> None:
    """Push a local file to the device."""
    adb_run(["push", to_adb_local_path(local_path), device_path])


def adb_file_size(device_path: str) -> int:
    """Get file size on device in bytes, or -1 if not found."""
    output = adb_shell(f'stat -c %s "{device_path}" 2>/dev/null', check=False)
    try:
        return int(output)
    except ValueError:
        return -1


# ── KMZ helpers ──────────────────────────────────────────────────────────

def validate_kmz(path: Path) -> None:
    """Verify that *path* is a valid KMZ with the required entries."""
    if not path.is_file():
        raise KmzError(f"File not found: {path}")
    try:
        with zipfile.ZipFile(path, "r") as zf:
            names = zf.namelist()
            for required in REQUIRED_KMZ_ENTRIES:
                if required not in names:
                    raise KmzError(f"Missing required entry '{required}' in {path.name}")
    except zipfile.BadZipFile:
        raise KmzError(f"Not a valid zip/KMZ file: {path}")


def _find_wpml_element(root: ET.Element, local_name: str) -> Optional[ET.Element]:
    """Find an element using any of the known wpml namespace variants."""
    for ns in WPML_NAMESPACES:
        el = root.find(f".//{{{ns}}}{local_name}")
        if el is not None:
            return el
    # Fallback: brute-force scan all tags ending with the local name
    for el in root.iter():
        if el.tag.endswith("}" + local_name) or el.tag == local_name:
            return el
    return None


def _find_all_wpml(root: ET.Element, local_name: str) -> List[ET.Element]:
    """Find all elements matching any wpml namespace variant."""
    results: List[ET.Element] = []
    for ns in WPML_NAMESPACES:
        results.extend(root.findall(f".//{{{ns}}}{local_name}"))
    if not results:
        for el in root.iter():
            if el.tag.endswith("}" + local_name):
                results.append(el)
    return results


def parse_kmz_metadata(kmz_path: Path) -> KmzMetadata:
    """Extract author, create time, and waypoint count from a KMZ."""
    meta = KmzMetadata()
    try:
        with zipfile.ZipFile(kmz_path, "r") as zf:
            # Parse template.kml for author / createTime
            if "wpmz/template.kml" in zf.namelist():
                tree = ET.fromstring(zf.read("wpmz/template.kml"))
                author_el = _find_wpml_element(tree, "author")
                if author_el is not None and author_el.text:
                    meta.author = author_el.text
                time_el = _find_wpml_element(tree, "createTime")
                if time_el is not None and time_el.text:
                    try:
                        ts = int(time_el.text) / 1000
                        dt = datetime.fromtimestamp(ts, tz=timezone.utc)
                        meta.create_time = dt.strftime("%Y-%m-%d %H:%M UTC")
                    except (ValueError, OSError):
                        meta.create_time = time_el.text
            # Parse waylines.wpml for waypoint count
            if "wpmz/waylines.wpml" in zf.namelist():
                tree = ET.fromstring(zf.read("wpmz/waylines.wpml"))
                placemarks = _find_all_wpml(tree, "index")
                if placemarks:
                    meta.waypoint_count = len(placemarks)
                else:
                    # Fallback: count Placemark elements
                    meta.waypoint_count = len(
                        tree.findall(f".//{{{KML_NS}}}Placemark")
                    )
    except (zipfile.BadZipFile, ET.ParseError):
        pass
    return meta


# ── Device operations ────────────────────────────────────────────────────

def list_device_missions() -> List[DeviceMission]:
    """Discover UUID mission folders on the connected device."""
    output = adb_shell(f"ls {WAYPOINT_ROOT}", check=False)
    if not output:
        return []
    missions: List[DeviceMission] = []
    for name in output.splitlines():
        name = name.strip()
        if not UUID_PATTERN.match(name):
            continue
        mission = DeviceMission(uuid=name)
        kmz_device = f"{WAYPOINT_ROOT}/{name}/{name}.kmz"
        mission.kmz_size = adb_file_size(kmz_device)
        # Pull KMZ to temp dir to parse metadata
        with tempfile.TemporaryDirectory() as tmpdir:
            local_tmp = os.path.join(tmpdir, f"{name}.kmz")
            try:
                adb_pull(kmz_device, local_tmp)
                mission.metadata = parse_kmz_metadata(Path(local_tmp))
            except (AdbError, KmzError):
                pass
        missions.append(mission)
    return missions


# ── Commands ─────────────────────────────────────────────────────────────

def cmd_list(args: argparse.Namespace) -> None:
    """List waypoint missions on the device."""
    print("Scanning device for waypoint missions...\n")
    missions = list_device_missions()
    if not missions:
        print("No missions found on device.")
        return
    for i, m in enumerate(missions, 1):
        meta = m.metadata
        size_str = f"{m.kmz_size:,} bytes" if m.kmz_size >= 0 else "unknown size"
        print(f"  [{i}] {m.uuid}")
        print(f"      Author: {meta.author or 'unknown'}")
        print(f"      Created: {meta.create_time or 'unknown'}")
        print(f"      Waypoints: {meta.waypoint_count or 'unknown'}")
        print(f"      Size: {size_str}")
        print()


def cmd_push(args: argparse.Namespace) -> None:
    """Push a local KMZ to replace an existing mission on the device."""
    local_kmz = Path(args.kmz_file).resolve()
    dry_run: bool = args.dry_run
    no_backup: bool = args.no_backup
    target_uuid: Optional[str] = args.uuid

    # 1. Validate local KMZ
    print(f"Validating {local_kmz.name}...")
    validate_kmz(local_kmz)
    local_meta = parse_kmz_metadata(local_kmz)
    print(f"  OK — {local_meta.waypoint_count} waypoints, author: {local_meta.author or 'unknown'}\n")

    # 2. List device missions
    print("Scanning device for waypoint missions...\n")
    missions = list_device_missions()
    if not missions:
        print("No missions found on device. Create a dummy mission in DJI GoFly first.")
        sys.exit(1)

    # 3. Select target UUID
    if target_uuid:
        match = [m for m in missions if m.uuid == target_uuid]
        if not match:
            print(f"UUID not found on device: {target_uuid}")
            sys.exit(1)
        target = match[0]
    elif len(missions) == 1:
        target = missions[0]
        print(f"Only one mission found, using: {target.uuid}\n")
    else:
        print("Select target mission to replace:\n")
        for i, m in enumerate(missions, 1):
            meta = m.metadata
            size_str = f"{m.kmz_size:,} bytes" if m.kmz_size >= 0 else "?"
            wp_str = str(meta.waypoint_count) if meta.waypoint_count else "?"
            print(f"  [{i}] {m.uuid}")
            print(f"      {meta.author or '?'} | {meta.create_time or '?'} | {wp_str} wpts | {size_str}")
            print()
        while True:
            try:
                choice = input("Enter number (or 'q' to quit): ").strip()
                if choice.lower() == "q":
                    sys.exit(0)
                idx = int(choice) - 1
                if 0 <= idx < len(missions):
                    target = missions[idx]
                    break
                print(f"Please enter 1-{len(missions)}")
            except (ValueError, EOFError):
                print(f"Please enter 1-{len(missions)}")
    print(f"Target: {target.uuid}\n")

    uuid = target.uuid
    device_primary = f"{WAYPOINT_ROOT}/{uuid}/{uuid}.kmz"
    device_temp = f"{WAYPOINT_ROOT}/kmzTemp/{uuid}.kmz"

    # 4. Backup existing KMZ
    if not no_backup and target.kmz_size > 0:
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{uuid}_{timestamp}.kmz"
        backup_path = BACKUP_DIR / backup_name
        if dry_run:
            print(f"[DRY RUN] Would back up existing KMZ to {backup_path}")
        else:
            print(f"Backing up existing KMZ to {backup_path}...")
            adb_pull(device_primary, str(backup_path))
            print(f"  Backed up ({backup_path.stat().st_size:,} bytes)\n")

    # 5. Prepare renamed KMZ in temp dir
    with tempfile.TemporaryDirectory() as tmpdir:
        renamed = os.path.join(tmpdir, f"{uuid}.kmz")
        shutil.copy2(str(local_kmz), renamed)
        local_size = os.path.getsize(renamed)

        if dry_run:
            print(f"[DRY RUN] Would push {local_kmz.name} ({local_size:,} bytes) as:")
            print(f"  → {device_primary}")
            print(f"  → {device_temp}")
            print("\nNo changes made to device.")
            return

        # 6. Push to primary location
        print(f"Pushing to {device_primary}...")
        adb_push(renamed, device_primary)

        # 7. Push to kmzTemp
        print(f"Pushing to {device_temp}...")
        adb_push(renamed, device_temp)

    # 8. Verify file sizes on device
    print("\nVerifying...")
    primary_size = adb_file_size(device_primary)
    temp_size = adb_file_size(device_temp)

    ok = True
    if primary_size != local_size:
        print(f"  WARNING: Primary size mismatch — expected {local_size}, got {primary_size}")
        ok = False
    else:
        print(f"  Primary:  {primary_size:,} bytes OK")

    if temp_size != local_size:
        print(f"  WARNING: kmzTemp size mismatch — expected {local_size}, got {temp_size}")
        ok = False
    else:
        print(f"  kmzTemp:  {temp_size:,} bytes OK")

    if ok:
        print(f"\nSuccess! Pushed {local_kmz.name} → {uuid}")
        print("\nNext step: Open DJI GoFly → Waypoint → select the mission → it should")
        print("now contain the new waypoints. If it shows the old mission, restart the app.")
    else:
        print("\nPush completed with warnings — verify the mission in DJI GoFly.")


# ── CLI parser ───────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="push_waypoints.py",
        description="Push waypoint KMZ files to a DJI GoFly device via ADB.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list", help="List waypoint missions on the connected device")

    push_p = sub.add_parser("push", help="Push a KMZ file to replace an existing mission")
    push_p.add_argument("kmz_file", help="Path to the local KMZ file")
    push_p.add_argument("--uuid", help="Target mission UUID (skip interactive picker)")
    push_p.add_argument("--dry-run", action="store_true", help="Preview without modifying the device")
    push_p.add_argument("--no-backup", action="store_true", help="Skip backing up the existing KMZ")

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command == "list":
            cmd_list(args)
        elif args.command == "push":
            cmd_push(args)
    except PushWaypointsError as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nAborted.")
        sys.exit(130)


if __name__ == "__main__":
    main()
