#!/usr/bin/env python3
"""Package compiled Krypton as an iOS app; no generated Swift/ObjC app code."""
import argparse
import hashlib
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
    if animal.get('artwork'):
        artwork = animal['artwork']
        if Path(artwork).name != artwork or not (ROOT / 'resources' / artwork).is_file():
            raise ValueError(f'Missing or invalid animal artwork: {artwork}')
    if 'artworkHeight' in animal and (type(animal['artworkHeight']) is not int or not 100 <= animal['artworkHeight'] <= 500):
        raise ValueError('artworkHeight must be an integer from 100 to 500')
    for sound in animal['sounds']:
        for key in ('id', 'title', 'description', 'filename', 'credit', 'sourceURL', 'licenseURL', 'category'):
            if not sound.get(key):
                raise ValueError(f'Recording is missing {key}')
        if sound['id'] in seen or sound['id'] == 'personal-recording':
            raise ValueError(f'Duplicate/reserved recording ID: {sound["id"]}')
        seen.add(sound['id'])
        if Path(sound['filename']).name != sound['filename']:
            raise ValueError('Audio filenames must not contain directories')
        audio = ROOT / 'resources' / sound['filename']
        if not audio.is_file():
            raise ValueError(f'Missing bundled audio: {audio.name}')
        if sound.get('sha256') and hashlib.sha256(audio.read_bytes()).hexdigest() != sound['sha256']:
            raise ValueError(f'Bundled audio checksum mismatch: {audio.name}')

photos = json.loads((ROOT / 'resources/photos.json').read_text())
photo_ids = set()
for photo in photos:
    if any(not photo.get(key) for key in ('id', 'filename', 'title', 'description', 'credit')):
        raise ValueError('Gallery photo is missing metadata')
    if photo['id'] in photo_ids:
        raise ValueError(f'Duplicate gallery photo ID: {photo["id"]}')
    photo_ids.add(photo['id'])
    filename = photo['filename']
    if Path(filename).name != filename or not (ROOT / 'resources' / filename).is_file():
        raise ValueError(f'Missing or invalid gallery photo: {filename}')

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
    'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': '0.5.0', 'CFBundleVersion': '5',
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
