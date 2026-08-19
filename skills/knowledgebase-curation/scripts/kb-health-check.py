#!/usr/bin/env python3
"""Deterministic weekly health check for a markdown knowledgebase.

Run standalone or as a fallback when an isolated curator sub-agent fails.
Set KB_ROOT to point at a different knowledgebase (default: /data/knowledge).
"""
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from glob import glob

KB = os.environ.get("KB_ROOT", "/data/knowledge")
if not os.path.isdir(KB):
    print(f"Knowledgebase not found: {KB}", file=sys.stderr)
    sys.exit(1)

NOW = datetime.now(timezone.utc)
FM_RE = re.compile(r"^---\n(.*?)\n---\n", re.S)
LINK_RE = re.compile(r"!?\[([^\]]*)\]\(([^)]+)\)")

wiki_mds = sorted(glob(f"{KB}/wiki/*.md"))
ops_mds = sorted(glob(f"{KB}/ops-guides/*.md"))
wiki_basenames = {os.path.basename(p) for p in wiki_mds}


def frontmatter(text):
    m = FM_RE.match(text)
    return m.group(1) if m else ""


def body_lines(text):
    m = FM_RE.match(text)
    body = text[m.end():].strip() if m else text.strip()
    return [ln for ln in body.splitlines() if ln.strip()]


def updated_date(text):
    fm = frontmatter(text)
    m = re.search(r"^updated:\s*(\d{4}-\d{2}-\d{2})", fm, re.M)
    if not m:
        return None
    return datetime.strptime(m.group(1), "%Y-%m-%d").replace(tzinfo=timezone.utc)


index_text = open(f"{KB}/wiki/index.md", encoding="utf-8").read()
index_links = {f"{name}.md" for name in re.findall(r"\[\[([^\]]+)\]\]", index_text)}

findings = {
    "kb_root": KB,
    "checked_at": NOW.isoformat(),
    "wiki_count": len(wiki_mds),
    "ops_count": len(ops_mds),
    "orphans": [],
    "empty_pages": [],
    "stale_pages": [],
    "broken_links": [],
    "unreferenced_ops_guides": [],
    "unreferenced_uploads": [],
    "action_items_stale": None,
}

# Wiki orphans, empty pages, stale frontmatter.
for path in wiki_mds:
    fn = os.path.basename(path)
    if fn == "index.md":
        continue
    text = open(path, encoding="utf-8").read()
    if fn not in index_links:
        findings["orphans"].append(fn)
    lines = body_lines(text)
    if len(lines) < 5:
        findings["empty_pages"].append({"file": fn, "non_empty_body_lines": len(lines)})
    ud = updated_date(text)
    if ud and NOW - ud > timedelta(days=14):
        findings["stale_pages"].append({"file": fn, "updated": ud.strftime("%Y-%m-%d")})

# Collect full text for reference checks, and validate relative markdown links.
all_text = ""
for path in wiki_mds + ops_mds:
    text = open(path, encoding="utf-8").read()
    all_text += text + "\n"
    bn = os.path.basename(path)
    base_dir = "wiki" if bn in wiki_basenames else "ops-guides"
    for _label, url in LINK_RE.findall(text):
        if not url.endswith(".md"):
            continue
        if url.startswith(("http://", "https://", "#", "mailto:")):
            continue
        clean = url.split("#")[0]
        target = os.path.normpath(os.path.join(KB, base_dir, clean))
        if not os.path.exists(target):
            findings["broken_links"].append({"from": bn, "link": url})

# Ops-guides referenced by name anywhere in the KB text.
for path in ops_mds:
    fn = os.path.basename(path)
    name = fn.replace(".md", "")
    if not re.search(re.escape(name), all_text):
        findings["unreferenced_ops_guides"].append(fn)

# Non-archive uploads referenced anywhere in the KB text.
uploads_dir = f"{KB}/sources/uploads"
if os.path.isdir(uploads_dir):
    for entry in os.listdir(uploads_dir):
        full = os.path.join(uploads_dir, entry)
        if not os.path.isfile(full) or entry == "archive":
            continue
        rel = f"uploads/{entry}"
        if rel not in all_text and entry not in all_text:
            findings["unreferenced_uploads"].append(rel)

# action-items freshness.
ai_text = open(f"{KB}/wiki/action-items.md", encoding="utf-8").read()
ai_updated = updated_date(ai_text)
if ai_updated:
    findings["action_items_stale"] = NOW - ai_updated > timedelta(days=7)

print(json.dumps(findings, indent=2))

has_issue = (
    findings["orphans"]
    or findings["empty_pages"]
    or findings["stale_pages"]
    or findings["broken_links"]
    or findings["unreferenced_ops_guides"]
    or findings["unreferenced_uploads"]
    or findings["action_items_stale"]
)
sys.exit(1 if has_issue else 0)
