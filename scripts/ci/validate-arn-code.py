#!/usr/bin/env python3
"""Static checks for the arn-code plugin.

Run from the repository root:  python3 scripts/ci/validate-arn-code.py
Exits non-zero and prints one line per problem.
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLUGIN = os.path.join(ROOT, "plugins", "arn-code")
problems = []


def problem(path, msg):
    problems.append(f"{os.path.relpath(path, ROOT)}: {msg}")


def frontmatter(path):
    text = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        problem(path, "missing YAML frontmatter")
        return None, text
    fm, fields, key = m.group(1), {}, None
    for line in fm.splitlines():
        km = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if km:
            key = km.group(1)
            fields[key] = km.group(2).strip()
        elif key and line.startswith((" ", "\t")):
            fields[key] += " " + line.strip()
    for k, v in fields.items():
        if v.startswith((">-", ">", "|-", "|")):
            fields[k] = v.split(" ", 1)[1] if " " in v else ""
        fields[k] = fields[k].strip().strip('"').strip("'")
    return fields, text


# --- skills ---
skills_dir = os.path.join(PLUGIN, "skills")
skill_names = set()
for name in sorted(os.listdir(skills_dir)):
    path = os.path.join(skills_dir, name, "SKILL.md")
    if not os.path.isfile(path):
        continue
    skill_names.add(name)
    fm, _ = frontmatter(path)
    if fm is None:
        continue
    if fm.get("name") != name:
        problem(path, f"name '{fm.get('name')}' does not match directory '{name}'")
    desc = fm.get("description", "")
    if not desc:
        problem(path, "missing description")
    elif len(desc) > 1024:
        problem(path, f"description is {len(desc)} chars (max 1024)")
    if "version" not in fm:
        problem(path, "missing version")

# --- agents ---
agents_dir = os.path.join(PLUGIN, "agents")
agent_names = set()
for fname in sorted(os.listdir(agents_dir)):
    if not fname.endswith(".md"):
        continue
    path = os.path.join(agents_dir, fname)
    fm, _ = frontmatter(path)
    if fm is None:
        continue
    name = fname[:-3]
    agent_names.add(name)
    if fm.get("name") != name:
        problem(path, f"name '{fm.get('name')}' does not match file name")
    for field in ("description", "tools", "model"):
        if not fm.get(field):
            problem(path, f"missing {field}")

# --- agent model presets list every agent ---
presets = os.path.join(skills_dir, "arn-code-init", "references", "agent-models-presets")
if os.path.isdir(presets):
    for fname in sorted(os.listdir(presets)):
        if not fname.endswith(".md"):
            continue
        path = os.path.join(presets, fname)
        text = open(path, encoding="utf-8").read()
        for agent in sorted(agent_names):
            if not re.search(rf"\b{re.escape(agent)}\b", text):
                problem(path, f"agent '{agent}' has no model entry")

# --- path references inside the plugin ---
ref_re = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+)(?![<{*A-Za-z0-9_./-])")
bare_re = re.compile(r"(?<!\})/?plugins/arn-code/")
home_re = re.compile(r"/home/(?!user/|username/|<)[a-z][a-z0-9_-]*/|/Users/(?!user/|username/|<)[A-Za-z][\w-]*/")
for dirpath, _, files in os.walk(PLUGIN):
    for fname in files:
        if not fname.endswith((".md", ".sh", ".json")):
            continue
        path = os.path.join(dirpath, fname)
        text = open(path, encoding="utf-8").read()
        for ref in sorted(set(ref_re.findall(text))):
            target = ref.rstrip(".")
            if "<" in target or "*" in target:
                continue
            if not os.path.exists(os.path.join(PLUGIN, target)):
                problem(path, f"reference to missing file ${{CLAUDE_PLUGIN_ROOT}}/{target}")
        if fname != "CHANGELOG.md" and bare_re.search(text):
            problem(path, "repo-relative 'plugins/arn-code/' path; use ${CLAUDE_PLUGIN_ROOT}/")
        if home_re.search(text):
            problem(path, "user-specific absolute path")

# --- skills named in "Skill:" invocations exist ---
skill_call = re.compile(r"Skill:\s*`?arn-code:([a-z0-9-]+)")
for dirpath, _, files in os.walk(PLUGIN):
    for fname in files:
        if fname.endswith(".md"):
            path = os.path.join(dirpath, fname)
            for called in skill_call.findall(open(path, encoding="utf-8").read()):
                if called not in skill_names:
                    problem(path, f"invokes unknown skill arn-code:{called}")

# --- hooks ---
hooks_json = os.path.join(PLUGIN, "hooks", "hooks.json")
if os.path.isfile(hooks_json):
    try:
        hooks = json.load(open(hooks_json))
    except ValueError as exc:
        problem(hooks_json, f"invalid JSON: {exc}")
        hooks = {}
    for event, groups in hooks.get("hooks", {}).items():
        for group in groups:
            for hook in group.get("hooks", []):
                for script in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/([\w./-]+\.sh)", hook.get("command", "")):
                    if not os.path.isfile(os.path.join(PLUGIN, script)):
                        problem(hooks_json, f"{event} hook script missing: {script}")

# --- marketplace entry ---
market = json.load(open(os.path.join(ROOT, ".claude-plugin", "marketplace.json")))
entry = next((p for p in market["plugins"] if p["name"] == "arn-code"), None)
if not entry or not re.match(r"^\d+\.\d+\.\d+$", entry.get("version", "")):
    problem(os.path.join(ROOT, ".claude-plugin", "marketplace.json"), "arn-code entry needs a semver version")
plugin_json = json.load(open(os.path.join(PLUGIN, ".claude-plugin", "plugin.json")))
if "version" in plugin_json:
    problem(os.path.join(PLUGIN, ".claude-plugin", "plugin.json"), "must not set version (marketplace entry is authoritative)")

for p in problems:
    print(p)
print(f"{len(skill_names)} skills, {len(agent_names)} agents checked; {len(problems)} problem(s)")
sys.exit(1 if problems else 0)
