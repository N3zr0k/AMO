#!/usr/bin/env python3
"""Prüft die Struktur des Repos, ohne WoW und ohne Lua:

  * jede TOC hat Interface, Title und eine Version X.Y.Z-PHASE.N (PHASE = alpha, beta oder latest)
  * jede in einer TOC oder XML genannte Datei existiert (Groß-/Kleinschreibung zählt, wie unter Linux)
  * jede XML-Datei ist wohlgeformt
  * AlphaMigration.lua gibt es nur, solange die Version eine -alpha-Version ist
  * mit --tag vX.Y.Z-PHASE.N: alle TOC-Versionen sind genau diese Version und im CHANGELOG
    steht ein Abschnitt "## [X.Y.Z]" (bei Alpha reicht auch "## [Unreleased]")
  * mit --version: gibt die gemeinsame TOC-Version aus (Fehler, wenn die TOCs abweichen)
  * mit --current-tag: gibt das vorhandene Tag der höchsten Stufe zur TOC-Version aus (nichts, wenn es keins gibt)
  * mit --next-tag: gibt das Tag aus, das zur TOC-Version gehört und noch nicht existiert (nichts, wenn es keins
    anzulegen gibt). Die Stufe steht in der TOC-Version:
      "0.2.2-alpha.1"   -> Alpha   (v0.2.2-alpha.1)   Prerelease auf GitHub
      "0.2.2-beta.2"    -> Beta    (v0.2.2-beta.2)    GitHub-Release mit Beta im Titel, CurseForge
      "0.2.2-latest.1"  -> Latest  (v0.2.2-latest.1)  GitHub-Release "Latest", CurseForge
    Es entsteht kein Tag, wenn es für die Basisversion schon ein Tag derselben oder einer höheren Stufe
    (alpha < beta < latest) gibt. Eine neue Zahl N allein heißt: nur das Repo hat sich geändert.
    Alte Tags ohne Phase (v0.2.2) zählen wie latest.

Aufruf aus dem Hauptordner des Repos:  python3 tools/check.py [--tag v0.1.0 | --version | --next-tag | --current-tag]
"""
import argparse
import os
import re
import subprocess
import sys
from xml.dom import minidom

SKIP_DIRS = {".git", ".github", "Libs", "tests", "tools"}
errors = []


def error(message):
    errors.append(message)
    print("FEHLER:", message)


def walk(root):
    for folder, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            yield os.path.join(folder, name)


def exists(path):
    """Existenz mit exakter Schreibweise (der Client ist unter Windows egal, Linux-Packager nicht)."""
    folder, name = os.path.split(os.path.normpath(path))
    return os.path.isdir(folder or ".") and name in os.listdir(folder or ".")


def check_toc(path):
    fields = {}
    files = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            match = re.match(r"^##\s*([^:]+):\s*(.*)$", line)
            if match:
                fields[match.group(1).strip()] = match.group(2).strip()
            elif line and not line.startswith("#"):
                files.append(line)

    for field in ("Interface", "Title", "Version"):
        if not fields.get(field):
            error(f"{path}: Feld '## {field}' fehlt")
    version = fields.get("Version", "")
    if version and not VERSION_RE.fullmatch(version):
        error(f"{path}: Version '{version}' ist nicht im Format X.Y.Z-alpha.N, X.Y.Z-beta.N oder X.Y.Z-latest.N")

    base = os.path.dirname(path)
    for name in files:
        if not exists(os.path.join(base, name.replace("\\", "/"))):
            error(f"{path}: Datei '{name}' fehlt")
    return version


def check_xml(path):
    try:
        document = minidom.parse(path)
    except Exception as exc:  # noqa: BLE001 - jede Parser-Meldung ist ein Fehler
        error(f"{path}: kein gültiges XML ({exc})")
        return

    base = os.path.dirname(path)
    for tag in ("Script", "Include"):
        for node in document.getElementsByTagName(tag):
            name = node.getAttribute("file")
            if name and not exists(os.path.join(base, name.replace("\\", "/"))):
                error(f"{path}: Datei '{name}' fehlt")


STAGES = ("alpha", "beta", "latest")
VERSION_RE = re.compile(r"(\d+\.\d+\.\d+)-(alpha|beta|latest)\.(\d+)")


def read_changelog():
    try:
        with open("CHANGELOG.md", encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        error("CHANGELOG.md fehlt")
        return ""


def split_version(version):
    """"0.2.2-beta.2" -> ("0.2.2", "beta", 2). Ohne Phase (alte Tags) gilt latest."""
    match = VERSION_RE.fullmatch(version)
    if not match:
        return version, "latest", 0
    base, stage, number = match.groups()
    return base, stage, int(number)


def existing_tags(base):
    """Die Tags zur Basisversion als Liste von (Stufe, Nummer, Tag)."""
    out = subprocess.run(["git", "tag", "-l", f"v{base}", f"v{base}-*"],
                         capture_output=True, text=True, check=False).stdout.split()
    found = []
    for tag in out:
        if tag == f"v{base}":
            found.append(("latest", 0, tag))
        else:
            match = re.fullmatch(re.escape(f"v{base}") + r"-(alpha|beta|latest)\.(\d+)", tag)
            if match:
                found.append((match.group(1), int(match.group(2)), tag))
    return found


def current_tag(version):
    """Das vorhandene Tag der höchsten Stufe (bei gleicher Stufe die höchste Nummer), sonst ""."""
    found = existing_tags(split_version(version)[0])
    if not found:
        return ""
    return max(found, key=lambda item: (STAGES.index(item[0]), item[1]))[2]


def next_tag(version):
    """Das Tag, das jetzt angelegt werden soll, oder "" wenn keins fällig ist.
    Gibt es die Basisversion schon in dieser oder einer höheren Stufe, ist keins fällig: eine neue Suffix-Zahl
    (N) heißt, nur das Repo hat sich geändert, nicht das Addon."""
    base, stage, _ = split_version(version)
    for other, _, _ in existing_tags(base):
        if STAGES.index(other) >= STAGES.index(stage):
            return ""
    return f"v{version}"


def suffix_only(tag):
    """Ein älteres Tag mit gleicher Basisversion und Stufe, nur andere Suffix-Zahl, sonst ""."""
    base, stage, number = split_version(tag.lstrip("v"))
    older = [t for other, n, t in existing_tags(base) if other == stage and n != number]
    return sorted(older)[0] if older else ""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", help="Release-Tag, z. B. v0.1.0")
    parser.add_argument("--version", action="store_true", help="gemeinsame TOC-Version ausgeben")
    parser.add_argument("--next-tag", action="store_true", help="das jetzt fällige Tag ausgeben (leer: keins)")
    parser.add_argument("--current-tag", action="store_true", help="das vorhandene Tag der höchsten Stufe ausgeben")
    parser.add_argument("--suffix-only", metavar="TAG", help="älteres Tag ausgeben, das sich nur in der Suffix-Zahl unterscheidet (leer: keins)")
    args = parser.parse_args()

    if args.suffix_only:
        print(suffix_only(args.suffix_only))
        return

    versions = {}
    for path in walk("."):
        if path.endswith(".toc"):
            versions[path] = check_toc(path)
        elif path.endswith(".xml"):
            check_xml(path)

    if not versions:
        error("keine TOC-Datei gefunden")

    # Die Alpha-Migration alter Exporte fliegt vor der ersten Beta raus (Datei und XML-Zeile löschen)
    for path in walk("."):
        if os.path.basename(path) == "AlphaMigration.lua":
            for toc, version in versions.items():
                if version and "-alpha." not in version:
                    error(f"{path}: nur in Alpha-Versionen erlaubt ({toc} hat {version})")
                    break

    if args.version:
        found = set(versions.values())
        if errors or len(found) != 1:
            if len(found) > 1:
                error("die TOC-Dateien haben unterschiedliche Versionen: " + ", ".join(sorted(found)))
            sys.exit(1)
        print(found.pop())
        return

    if args.current_tag:
        found = set(versions.values())
        if errors or len(found) != 1:
            sys.exit(1)
        print(current_tag(found.pop()))
        return

    if args.next_tag:
        found = set(versions.values())
        if errors or len(found) != 1:
            if len(found) > 1:
                error("die TOC-Dateien haben unterschiedliche Versionen: " + ", ".join(sorted(found)))
            sys.exit(1)
        print(next_tag(found.pop()))
        return

    if args.tag:
        wanted = args.tag.lstrip("v")
        match = VERSION_RE.fullmatch(wanted)
        if not match:
            error(f"Tag {args.tag}: muss vX.Y.Z-alpha.N, vX.Y.Z-beta.N oder vX.Y.Z-latest.N heißen")
        base, kind = (match.group(1), match.group(2)) if match else (wanted, None)
        for path, version in versions.items():
            if version != wanted:
                error(f"{path}: Version {version} passt nicht zum Tag {args.tag}")
        changelog = read_changelog()
        if changelog and not re.search(r"^##\s*\[?" + re.escape(base) + r"\]?", changelog, re.M):
            if not (kind == "alpha" and re.search(r"^##\s*\[?Unreleased\]?", changelog, re.M | re.I)):
                error(f"CHANGELOG.md hat keinen Abschnitt für {base}")

    if errors:
        print(f"{len(errors)} Fehler")
        sys.exit(1)
    print(f"OK: {len(versions)} TOC-Datei(en) geprüft")


if __name__ == "__main__":
    main()
