#!/usr/bin/env python3
"""Build a new .app; never overwrite a running or existing application bundle."""
import argparse
import json
import math
import os
from pathlib import Path
import platform
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile


def validate(c):
    for key in ('app_name', 'nickname', 'bundle_id'):
        if not isinstance(c.get(key), str) or not c[key].strip() or any(ord(x) < 32 for x in c[key]):
            raise ValueError(f'invalid {key}')
    if any(x in c['app_name'] for x in '/\\') or c['app_name'] in ('.', '..'):
        raise ValueError('app_name is not a filename')
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*)+', c['bundle_id']):
        raise ValueError('invalid bundle_id')
    for key, low, high in [('scale', 0.5, 1.0), ('reminder_minutes', 1, 1440)]:
        value = c.get(key)
        if isinstance(value, bool) or not isinstance(value, (float, int)) or not math.isfinite(value) or not low <= value <= high:
            raise ValueError(f'{key} must be {low}–{high}')
    if not isinstance(c.get('reminders_enabled'), bool):
        raise ValueError('reminders_enabled must be true or false')
    pets = c.get('pets', [])
    if not isinstance(pets, list) or not 1 <= len(pets) <= 4:
        raise ValueError('configure 1–4 pets')
    ids = set()
    for pet in pets:
        if not re.fullmatch(r'[a-z0-9-]+', pet.get('id', '')) or pet['id'] in ids:
            raise ValueError('pet IDs must be unique lowercase slugs')
        ids.add(pet['id'])
        if not isinstance(pet.get('name'), str) or not pet['name'].strip():
            raise ValueError('pet name is required')
        if pet.get('motion') not in ('sway', 'bounce'):
            raise ValueError('motion must be sway or bounce')
        if not isinstance(pet.get('images'), dict) or 'calm' not in pet['images']:
            raise ValueError('provide an images map with calm')
        for value in pet['images'].values():
            if not isinstance(value, str) or Path(value).name != value or '\\' in value or not value.endswith('.png'):
                raise ValueError('images must be PNG filenames inside Resources')


def build(output=None):
    if sys.platform != 'darwin':
        raise RuntimeError('This native template must be built on macOS with Apple Command Line Tools')
    root = Path(__file__).resolve().parent
    config = json.loads((root / 'config.json').read_text(encoding='utf-8'))
    validate(config)
    app = Path(output).expanduser().absolute() if output else root / 'dist' / (config['app_name'] + '.app')
    if app.exists() or app.is_symlink():
        raise FileExistsError(f'Output exists: {app}. Use --output with a new .app path, then back up and replace after verification.')
    if app.suffix != '.app':
        raise ValueError('output must end in .app')
    app.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='pet-build-', dir=app.parent) as temp:
        staging = Path(temp) / app.name
        executable = staging / 'Contents' / 'MacOS' / 'DesktopPets'
        resources = staging / 'Contents' / 'Resources'
        executable.parent.mkdir(parents=True)
        resources.mkdir(parents=True)
        subprocess.run(['xcrun', 'swiftc', '-O', '-target', platform.machine()+'-apple-macosx13.0',
                        '-module-cache-path', str(Path(temp) / 'cache'),
                        '-framework', 'AppKit', str(root/'Source'/'Models.swift'), str(root/'Source'/'main.swift'),
                        '-o', str(executable)], check=True)
        (resources/'config.json').write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding='utf-8')
        for notice in ('LICENSE', 'NOTICE'):
            (resources/notice).write_bytes((root/notice).read_bytes())
        for file in (root/'Resources').glob('*.png'):
            if file.is_symlink():
                raise ValueError(f'Resources must contain actual image files: {file.name}')
            shutil.copy2(file, resources/file.name)
        info = dict(CFBundleName=config['app_name'], CFBundleDisplayName=config['app_name'],
                    CFBundleExecutable='DesktopPets', CFBundleIdentifier=config['bundle_id'],
                    CFBundlePackageType='APPL', CFBundleShortVersionString='0.1.0', CFBundleVersion='1',
                    LSUIElement=True, LSMinimumSystemVersion='13.0', NSHighResolutionCapable=True)
        (staging/'Contents'/'Info.plist').write_bytes(plistlib.dumps(info))
        subprocess.run(['codesign', '--force', '--sign', '-', str(staging)], check=True)
        subprocess.run([str(executable), '--self-test'], check=True)
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(staging)], check=True)
        os.rename(staging, app)
    print(f'Built: {app}\nNormal launch and --smoke-test still need verification.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output')
    try:
        build(parser.parse_args().output)
    except (ValueError, OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        parser.exit(2, f'Build failed: {exc}\n')
