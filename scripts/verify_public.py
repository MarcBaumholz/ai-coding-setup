#!/usr/bin/env python3
"""Validate the public documentation snapshot without reading source workspaces."""
import hashlib
import json
from pathlib import Path
import re
import sys


def verify(root):
    errors = []
    allowed = {'.md', '.json', '.csv', '.py', '.sh', '.mjs', '.cjs', '.yaml', '.yml', '.css', '.html', '.tsv', '.txt', '.png'}
    export = None
    known_links = set()
    export_path = root / 'skills/manifest.json'
    if export_path.exists():
        try:
            export = json.loads(export_path.read_text())
            known_links = {(item['file'], item['target']) for item in export['known_unbundled_links']}
        except (ValueError, KeyError):
            errors.append('skills/manifest.json: invalid export manifest')
    patterns = {
        'absolute home path': re.compile(r'/(?:Users|home)/[A-Za-z0-9_-]+/'),
        'GitHub credential': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b'),
        'provider credential': re.compile(r'\b(?:sk-[A-Za-z0-9_-]{24,}|glpat-[A-Za-z0-9_-]{16,}|AIza[A-Za-z0-9_-]{30,})\b'),
        'private key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
        'private service address': re.compile(r'https?://[^\s)"<>]*(?:\.coachbot\.ai|\.internal)\b'),
        'email address': re.compile(r'\b[\w.+-]+@[\w-]+(?:\.[\w-]+)+\b'),
    }
    files = [p for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts]
    for p in files:
        rel = p.relative_to(root)
        if p.is_symlink():
            errors.append(f'{rel}: symlink is not allowed')
        if p.name not in {'.gitignore', 'LICENSE', 'NOTICE', 'COPYRIGHT'} and p.suffix.lower() not in allowed:
            errors.append(f'{rel}: unexpected file type')
        if p.name.startswith('.env') or any(part in {'private', 'captures', 'sessions', 'coachbot-design', 'inventory'} for part in rel.parts):
            errors.append(f'{rel}: forbidden publication path')
        try:
            body = p.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            if p.suffix.lower() == '.png' and p.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'):
                continue
            errors.append(f'{rel}: non-text file')
            continue
        for label, pattern in patterns.items():
            scan_body = body
            if label == 'email address':
                if p.name.lower() in {'license', 'license.txt', 'license.md', 'notice', 'copyright'}:
                    continue
                scan_body = re.sub(r'\b[\w.+-]+@(?:[\w.-]+\.(?:test|example)|example\.(?:com|org|net))\b', '', body)
            if pattern.search(scan_body):
                errors.append(f'{rel}: {label}')
        if p.suffix == '.json':
            try:
                json.loads(body)
            except ValueError:
                errors.append(f'{rel}: invalid JSON')
        if p.suffix == '.md':
            if body.count('```') % 2:
                errors.append(f'{rel}: unmatched code fence')
            for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)', body):
                if '://' in target or target.startswith('#'):
                    continue
                local = (p.parent / target.split('#')[0]).resolve()
                if not local.is_relative_to(root.resolve()) or not local.exists():
                    if (str(rel), target) not in known_links:
                        errors.append(f'{rel}: broken local link {target}')
    if export is not None:
        try:
            if len(export['bundles']) != export['bundle_count'] or len(export['files']) != export['file_count']:
                errors.append('skills/manifest.json: inconsistent counts')
            declared = set()
            for item in export['files']:
                path = (root / item['path']).resolve()
                if not path.is_relative_to((root / 'skills').resolve()) or not path.is_file():
                    errors.append(f"skills/manifest.json: missing or invalid file {item['path']}")
                    continue
                declared.add(path)
                if hashlib.sha256(path.read_bytes()).hexdigest() != item['published_sha256']:
                    errors.append(f"{item['path']}: differs from export manifest")
            actual = {p.resolve() for p in files if 'skills' == p.relative_to(root).parts[0]}
            actual -= {export_path.resolve(), (root / 'skills/README.md').resolve()}
            if actual != declared:
                errors.append('skills: exported files differ from manifest listing')
            for bundle in export['bundles']:
                path = (root / bundle['path']).resolve()
                if not path.is_relative_to((root / 'skills').resolve()) or not (path / 'SKILL.md').is_file():
                    errors.append(f"skills/manifest.json: invalid bundle {bundle['path']}")
            for file_name, target in known_links:
                path = root / file_name
                if not path.is_file() or f']({target})' not in path.read_text():
                    errors.append('skills/manifest.json: obsolete unresolved-link record')
        except (KeyError, TypeError, OSError) as exc:
            errors.append(f'skills/manifest.json: incomplete manifest ({type(exc).__name__})')
    return files, errors


if __name__ == '__main__':
    base = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    checked, failures = verify(base)
    for failure in failures:
        print(f'FAIL: {failure}')
    print(f'{len(checked)} files checked; {len(failures)} failures')
    sys.exit(bool(failures))
