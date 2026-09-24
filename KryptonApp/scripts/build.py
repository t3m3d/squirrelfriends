#!/usr/bin/env python3
"""Package compiled Krypton as an iOS app; no generated Swift/ObjC app code."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--target', choices=['simulator', 'device'], default='simulator')
parser.add_argument('--krypton-root', type=Path, default=Path(os.environ.get('KRYPTON_ROOT', ROOT.parents[1] / 'krypton')))
parser.add_argument('--bundle-id', default='org.squirrelfriends.app')
args = parser.parse_args()
krypton = args.krypton_root.resolve()
compiler = krypton / 'bootstrap/kcc_driver_macos_aarch64'
if not compiler.is_file():
    parser.error('Set --krypton-root to the Krypton checkout (macOS Apple Silicon required).')

# Reject broken catalog references before packaging a build.
animals = json.loads((ROOT / 'resources/animals.json').read_text())
seen = set()
for animal in animals:
    for key in ('id', 'name', 'scientificName', 'sounds'):
        if not animal.get(key):
            raise ValueError(f'Animal is missing {key}')
    for sound in animal['sounds']:
        for key in ('id', 'title', 'description', 'filename', 'credit', 'sourceURL', 'licenseURL'):
            if not sound.get(key):
                raise ValueError(f'Recording is missing {key}')
        if sound['id'] in seen or sound['id'] == 'personal-recording':
            raise ValueError(f'Duplicate/reserved recording ID: {sound["id"]}')
        seen.add(sound['id'])
        if Path(sound['filename']).name != sound['filename']:
            raise ValueError('Audio filenames must not contain directories')

app = ROOT / 'build' / args.target / 'SquirrelFriends.app'
app.mkdir(parents=True, exist_ok=True)
environment = dict(os.environ, KRYPTON_ROOT=str(krypton))
subprocess.run([str(compiler), '--target', 'ios-sim-arm64' if args.target == 'simulator' else 'ios-device-arm64',
                str(ROOT / 'src/main.ks'), '-o', str(app / 'SquirrelFriends')], env=environment, cwd=krypton, check=True)
for resource in (ROOT / 'resources').iterdir():
    if resource.is_file():
        shutil.copy2(resource, app / resource.name)
plist = {
    'CFBundleDisplayName': 'Squirrel Friends', 'CFBundleExecutable': 'SquirrelFriends',
    'CFBundleIdentifier': args.bundle_id, 'CFBundleName': 'SquirrelFriends',
    'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': '0.2.0', 'CFBundleVersion': '2',
    'CFBundleSupportedPlatforms': ['iPhoneSimulator' if args.target == 'simulator' else 'iPhoneOS'],
    'MinimumOSVersion': '15.0', 'UIDeviceFamily': [1, 2], 'UILaunchScreen': {},
    'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
    'UIFileSharingEnabled': True, 'LSSupportsOpeningDocumentsInPlace': True,
}
with (app / 'Info.plist').open('wb') as output:
    plistlib.dump(plist, output)
if args.target == 'simulator':
    subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
print(app)
if args.target == 'device':
    print('Device binary only: a provisioning profile and Apple development/distribution signing are still required.')
