#!/usr/bin/env python3
"""Create a portable native pet project without touching existing projects."""
import argparse
import json
from pathlib import Path
import re
import shutil
import uuid


def clean_text(value, label, max_length=64):
    if not value.strip() or len(value) > max_length or any(ord(c) < 32 for c in value):
        raise ValueError(f'{label} must be nonempty, under {max_length} characters, without control characters')
    return value


def create(args):
    name = clean_text(args.app_name, 'app name')
    if '/' in name or '\\' in name or name in ('.', '..'):
        raise ValueError('app name cannot contain path separators')
    nickname = clean_text(args.nickname, 'nickname')
    pets = args.pet or ['伙伴一', '伙伴二']
    if not 1 <= len(pets) <= 4:
        raise ValueError('starter supports 1–4 pets in one group')
    for pet in pets:
        clean_text(pet, 'pet name')
    bundle_id = args.bundle_id or 'local.desktoppet.p' + uuid.uuid4().hex[:12]
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*)+', bundle_id):
        raise ValueError('bundle ID must use reverse-domain components')
    output = Path(args.output).expanduser().absolute()
    if output.exists() or output.is_symlink():
        raise FileExistsError(f'Not overwriting existing destination: {output}')
    template = Path(__file__).resolve().parents[1] / 'assets' / 'macos-starter'
    config = dict(app_name=name, bundle_id=bundle_id, nickname=nickname, scale=0.65,
                  reminder_minutes=60, reminders_enabled=True, pets=[])
    for index, pet in enumerate(pets):
        key = f'pet-{index+1}'
        config['pets'].append(dict(id=key, name=pet, motion='sway' if index % 2 == 0 else 'bounce',
            images={state: f'{key}-{state}.png' for state in ['calm','happy','sleepy','concerned']}))
    shutil.copytree(template, output)
    (output / 'Resources').mkdir()
    (output / 'config.json').write_text(json.dumps(config, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Created {output}\nBundle ID: {bundle_id}\nBuild on Mac: python3 "{output / "build.py"}"')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--app-name', default='桌面伙伴')
    parser.add_argument('--nickname', default='朋友')
    parser.add_argument('--pet', action='append')
    parser.add_argument('--bundle-id')
    try:
        create(parser.parse_args())
    except (ValueError, OSError) as exc:
        parser.exit(2, f'Error: {exc}\n')
