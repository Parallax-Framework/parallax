#!/usr/bin/env python3
"""
Generate MkDocs documentation for Parallax from Lua doc comments.
"""

from __future__ import annotations

import argparse
import re
import shutil
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple


DEFAULT_SOURCE_DIRS = ("gamemode/framework", "gamemode/modules")
DEFAULT_DOCS_DIR = "docs"
DEFAULT_API_SUBDIR = "api"
DEFAULT_MANUALS_SOURCE_DIR = "manuals"
DEFAULT_MANUALS_SUBDIR = "manuals"
DEFAULT_MKDOCS_FILE = "mkdocs.yml"
DEFAULT_SITE_NAME = "Parallax Framework Documentation"
DEFAULT_SITE_DESCRIPTION = "Parallax manuals and generated API reference."
DEFAULT_INDEX_CONTENT = """# Parallax Documentation

Welcome to the Parallax documentation site.

- Use the left sidebar to browse the API tree.
- Use search (`/`) to quickly jump to symbols.
"""
DEFAULT_EXTRA_CSS_CONTENT = """:root {
  --md-primary-fg-color: #4a2574;
  --md-primary-fg-color--light: #6a3ea4;
  --md-primary-fg-color--dark: #2a1541;
  --md-accent-fg-color: #a86bff;
}
"""

FUNCTION_DEF_RE = re.compile(
    r"^\s*(?:local\s+)?function\s+([A-Za-z_][\w\.:]*)\s*\(([^)]*)\)"
)
ASSIGN_FUNCTION_DEF_RE = re.compile(
    r"^\s*([A-Za-z_][\w\.:]*)\s*=\s*function\s*\(([^)]*)\)"
)
HEADER_RE = re.compile(r"^\s*#\s+(.+)\s*$")

PARAM_TAG_RE = re.compile(r"^@param\s+(\.\.\.|[A-Za-z_][\w]*)\s+([^\s]+)\s*(.*)$")
RETURN_TAG_RE = re.compile(r"^@return\s+([^\s]+)\s*(.*)$")
TRETURN_TAG_RE = re.compile(r"^@treturn\s+([^\s]+)\s*(.*)$")
REALM_TAG_RE = re.compile(r"^@realm\s+([^\s]+)\s*$")
USAGE_TAG_RE = re.compile(r"^@usage\s*(.*)$")
MODULE_TAG_RE = re.compile(r"^@module\s+([^\s]+)\s*$")
SECTION_TAG_RE = re.compile(r"^@section\s+([^\s]+)\s*$")
GENERIC_TAG_RE = re.compile(r"^@([A-Za-z_][\w\[\]=\.]*)\s+([A-Za-z_][\w]*)\s*(.*)$")

PARAM_FALLBACK_TAGS = {
    "player",
    "entity",
    "string",
    "number",
    "bool",
    "boolean",
    "table",
    "vector",
    "angle",
    "color",
    "function",
    "any",
    "int",
    "float",
    "panel",
    "material",
}


@dataclass
class ParamDoc:
    name: str
    type_name: str
    description: str


@dataclass
class ReturnDoc:
    type_name: str
    description: str


@dataclass
class ParsedComment:
    description: str = ""
    module: Optional[str] = None
    section: Optional[str] = None
    realm: Optional[str] = None
    params: List[ParamDoc] = field(default_factory=list)
    returns: List[ReturnDoc] = field(default_factory=list)
    usage: List[str] = field(default_factory=list)

    @property
    def has_content(self) -> bool:
        return bool(
            self.description
            or self.module
            or self.section
            or self.realm
            or self.params
            or self.returns
            or self.usage
        )


@dataclass
class FunctionDoc:
    name: str
    signature: str
    line: int
    description: str
    realm: Optional[str]
    params: List[ParamDoc]
    returns: List[ReturnDoc]
    usage: List[str]


@dataclass
class FileDoc:
    source_path: Path
    source_group: str
    relative_path: Path
    output_relative: Path
    module: Optional[str]
    section: Optional[str]
    summary: Optional[str]
    functions: List[FunctionDoc]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate MkDocs docs for Parallax.")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Parallax project root.",
    )
    parser.add_argument(
        "--source",
        action="append",
        default=None,
        help=(
            "Source directory to scan (relative to --root unless absolute). "
            "Repeat for multiple paths."
        ),
    )
    parser.add_argument(
        "--docs-dir",
        default=DEFAULT_DOCS_DIR,
        help="MkDocs docs_dir path (relative to --root unless absolute).",
    )
    parser.add_argument(
        "--api-subdir",
        default=DEFAULT_API_SUBDIR,
        help="API output subdirectory under docs_dir.",
    )
    parser.add_argument(
        "--manuals-source",
        default=DEFAULT_MANUALS_SOURCE_DIR,
        help="Manuals source directory (relative to --root unless absolute).",
    )
    parser.add_argument(
        "--manuals-subdir",
        default=DEFAULT_MANUALS_SUBDIR,
        help="Manuals output subdirectory under docs_dir.",
    )
    parser.add_argument(
        "--mkdocs-file",
        default=DEFAULT_MKDOCS_FILE,
        help="mkdocs config file path (relative to --root unless absolute).",
    )
    parser.add_argument(
        "--site-name",
        default=DEFAULT_SITE_NAME,
        help="site_name value written to mkdocs.yml.",
    )
    parser.add_argument(
        "--site-description",
        default=DEFAULT_SITE_DESCRIPTION,
        help="site_description value written to mkdocs.yml.",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the generated API directory before writing.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be written without changing files.",
    )
    return parser.parse_args()


def normalize_path(root: Path, path_str: str) -> Path:
    path = Path(path_str)
    if path.is_absolute():
        return path.resolve()
    return (root / path).resolve()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8-sig")
    except UnicodeDecodeError:
        return path.read_text(encoding="latin-1", errors="replace")


def find_function_definition(line: str) -> Optional[Tuple[str, str]]:
    match = FUNCTION_DEF_RE.match(line)
    if match:
        return match.group(1), match.group(2)

    match = ASSIGN_FUNCTION_DEF_RE.match(line)
    if match:
        return match.group(1), match.group(2)

    return None


def infer_realm_from_filename(file_path: Path) -> Optional[str]:
    lower = file_path.stem.lower()
    if lower.startswith("cl_"):
        return "client"
    if lower.startswith("sv_"):
        return "server"
    if lower.startswith("sh_"):
        return "shared"
    return None


def collect_doc_lines_above(lines: Sequence[str], index: int) -> List[str]:
    cursor = index - 1

    while cursor >= 0 and lines[cursor].strip() == "":
        cursor -= 1

    if cursor < 0:
        return []

    block: List[str] = []
    while cursor >= 0:
        stripped = lines[cursor].lstrip()
        if stripped.startswith("--") or stripped == "":
            block.append(lines[cursor])
            cursor -= 1
            continue
        break

    block.reverse()
    cleaned: List[str] = []
    has_doc_signal = False
    for raw_line in block:
        stripped = raw_line.lstrip()
        if stripped.startswith("--[[") or stripped.startswith("]]"):
            continue
        if stripped.startswith("---"):
            text = stripped[3:]
            if text.startswith(" "):
                text = text[1:]
            cleaned.append(text.rstrip())
            has_doc_signal = True
            continue
        if stripped.startswith("--"):
            text = stripped[2:]
            if text.startswith(" "):
                text = text[1:]
            cleaned.append(text.rstrip())
            if text.lstrip().startswith("@"):
                has_doc_signal = True
            continue
        cleaned.append("")

    if not has_doc_signal:
        return []

    return cleaned


def parse_comment_lines(comment_lines: Sequence[str]) -> ParsedComment:
    parsed = ParsedComment()
    description_lines: List[str] = []
    context: Optional[str] = None

    for text in comment_lines:
        raw_line = text.rstrip()
        line = raw_line.strip()

        if not line:
            if context == "usage" and parsed.usage:
                parsed.usage[-1] += "\n"
            elif context == "description":
                description_lines.append("")
            continue

        if line.startswith("@"):
            context = None

            module_match = MODULE_TAG_RE.match(line)
            if module_match:
                parsed.module = module_match.group(1).strip()
                continue

            section_match = SECTION_TAG_RE.match(line)
            if section_match:
                parsed.section = section_match.group(1).strip()
                continue

            realm_match = REALM_TAG_RE.match(line)
            if realm_match:
                parsed.realm = realm_match.group(1).strip()
                continue

            usage_match = USAGE_TAG_RE.match(line)
            if usage_match:
                parsed.usage.append(usage_match.group(1).rstrip())
                context = "usage"
                continue

            param_match = PARAM_TAG_RE.match(line)
            if param_match:
                name = param_match.group(1).strip()
                type_name = param_match.group(2).rstrip(":")
                description = param_match.group(3).lstrip("-: ").strip()

                # Support description-first varargs style:
                # @param ... A variable number of KEY_* constants.
                if name == "..." and type_name.casefold() in {"a", "an", "the"}:
                    description = f"{type_name} {description}".strip()
                    type_name = "any"

                parsed.params.append(
                    ParamDoc(
                        name=name,
                        type_name=type_name.strip(),
                        description=description,
                    )
                )
                context = "param"
                continue

            return_match = RETURN_TAG_RE.match(line)
            if return_match:
                type_name = return_match.group(1).rstrip(":")
                description = return_match.group(2).lstrip("-: ").strip()
                parsed.returns.append(ReturnDoc(type_name=type_name.strip(), description=description))
                context = "return"
                continue

            treturn_match = TRETURN_TAG_RE.match(line)
            if treturn_match:
                type_name = treturn_match.group(1).rstrip(":")
                description = treturn_match.group(2).lstrip("-: ").strip()
                parsed.returns.append(ReturnDoc(type_name=type_name.strip(), description=description))
                context = "return"
                continue

            generic_match = GENERIC_TAG_RE.match(line)
            if generic_match:
                raw_tag = generic_match.group(1).strip()
                base_tag = raw_tag.split("[", 1)[0].lower()
                name = generic_match.group(2).strip()
                description = generic_match.group(3).lstrip("-: ").strip()
                if base_tag in PARAM_FALLBACK_TAGS:
                    parsed.params.append(
                        ParamDoc(name=name, type_name=base_tag, description=description)
                    )
                    context = "param"
                continue

            continue

        if context == "usage" and parsed.usage:
            parsed.usage[-1] += ("\n" + raw_line)
            continue

        if context == "param" and parsed.params:
            if parsed.params[-1].description:
                parsed.params[-1].description += " " + line
            else:
                parsed.params[-1].description = line
            continue

        if context == "return" and parsed.returns:
            if parsed.returns[-1].description:
                parsed.returns[-1].description += " " + line
            else:
                parsed.returns[-1].description = line
            continue

        description_lines.append(line)
        context = "description"

    parsed.description = "\n".join(description_lines).strip()
    parsed.usage = [entry.strip("\r\n") for entry in parsed.usage if entry.strip()]
    return parsed


def parse_file_metadata(lines: Sequence[str], first_function_index: int) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    prelude = lines[:first_function_index] if first_function_index > 0 else lines
    module: Optional[str] = None
    section: Optional[str] = None
    summary: Optional[str] = None

    for line in prelude:
        stripped = line.lstrip()
        if stripped.startswith("---"):
            text = stripped[3:].strip()
            if text and not text.startswith("@"):
                summary = text
                break

    joined = "\n".join(prelude)
    module_match = re.search(r"@module\s+([^\s]+)", joined)
    if module_match:
        module = module_match.group(1).strip()

    section_match = re.search(r"@section\s+([^\s]+)", joined)
    if section_match:
        section = section_match.group(1).strip()

    return module, section, summary


def sanitize_signature_args(args: str) -> str:
    parts = [part.strip() for part in args.split(",")]
    parts = [part for part in parts if part]
    return ", ".join(parts)


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", value).strip("-").lower()
    return slug or "section"


def nav_sort_key(value: str) -> str:
    return value.casefold()


def normalize_nav_path(path: str) -> str:
    return path.replace("\\", "/")


def pretty_nav_label(name: str) -> str:
    text = name.replace("_", " ").replace("-", " ").strip()
    return text.title() if text else name


def make_nav_node() -> Dict[str, object]:
    return {"dirs": {}, "pages": []}


def build_api_nav_tree(file_docs: Sequence[FileDoc], api_subdir: str) -> Dict[str, object]:
    root = make_nav_node()
    for file_doc in sorted(file_docs, key=lambda item: nav_sort_key(item.output_relative.as_posix())):
        rel = file_doc.output_relative.relative_to(api_subdir)
        node = root
        for part in rel.parts[:-1]:
            dirs = node["dirs"]
            if part not in dirs:
                dirs[part] = make_nav_node()
            node = dirs[part]

        page_label = rel.stem
        pages = node["pages"]
        pages.append((page_label, normalize_nav_path(file_doc.output_relative.as_posix())))

    return root


def render_api_nav_lines(node: Dict[str, object], indent: int) -> List[str]:
    lines: List[str] = []
    dirs: Dict[str, Dict[str, object]] = node["dirs"]
    pages: List[Tuple[str, str]] = node["pages"]

    for dir_name in sorted(dirs.keys(), key=nav_sort_key):
        lines.append(f'{" " * indent}- {yaml_quote(pretty_nav_label(dir_name))}:')
        lines.extend(render_api_nav_lines(dirs[dir_name], indent + 4))

    for page_label, page_path in sorted(pages, key=lambda item: nav_sort_key(item[0])):
        lines.append(f'{" " * indent}- {yaml_quote(page_label)}: {page_path}')

    return lines


def escape_table_cell(value: str) -> str:
    escaped = value.replace("|", "\\|")
    return escaped.replace("\n", "<br>")


def build_file_doc(
    root: Path,
    source_dir: Path,
    api_subdir: str,
    file_path: Path,
) -> Optional[FileDoc]:
    content = read_text(file_path)
    lines = content.splitlines()

    functions: List[FunctionDoc] = []
    first_function_index = len(lines)

    for index, line in enumerate(lines):
        parsed_def = find_function_definition(line)
        if not parsed_def:
            continue

        if index < first_function_index:
            first_function_index = index

        function_name, raw_args = parsed_def
        doc_lines = collect_doc_lines_above(lines, index)
        if not doc_lines:
            continue

        parsed_comment = parse_comment_lines(doc_lines)
        if not parsed_comment.has_content:
            continue

        args = sanitize_signature_args(raw_args)
        signature = f"{function_name}({args})"
        realm = parsed_comment.realm or infer_realm_from_filename(file_path)
        functions.append(
            FunctionDoc(
                name=function_name,
                signature=signature,
                line=index + 1,
                description=parsed_comment.description,
                realm=realm,
                params=parsed_comment.params,
                returns=parsed_comment.returns,
                usage=parsed_comment.usage,
            )
        )

    if not functions:
        return None

    module, section, summary = parse_file_metadata(lines, first_function_index)
    source_group = source_dir.name
    relative_path = file_path.relative_to(source_dir)
    output_relative = Path(api_subdir) / source_group / relative_path.with_suffix(".md")

    return FileDoc(
        source_path=file_path,
        source_group=source_group,
        relative_path=relative_path,
        output_relative=output_relative,
        module=module,
        section=section,
        summary=summary,
        functions=functions,
    )


def render_file_markdown(file_doc: FileDoc, root: Path) -> str:
    display_name = file_doc.module or file_doc.relative_path.with_suffix("").as_posix()
    source_rel = file_doc.source_path.relative_to(root).as_posix()
    functions = sorted(file_doc.functions, key=lambda item: (nav_sort_key(item.name), item.line))

    lines: List[str] = []
    lines.append(f"# {display_name}")
    lines.append("")
    lines.append(f"Source: `{source_rel}`")
    if file_doc.summary:
        lines.append("")
        lines.append(file_doc.summary)
    if file_doc.section:
        lines.append("")
        lines.append(f"Section: `{file_doc.section}`")

    lines.append("")
    lines.append(f"Documented functions: **{len(functions)}**")
    lines.append("")
    lines.append("## Functions")
    lines.append("")

    for function in functions:
        anchor = slugify(f"{function.name}-{function.line}")
        lines.append(f"- [`{function.signature}`](#{anchor})")

    lines.append("")
    lines.append("---")
    lines.append("")

    for function in functions:
        anchor = slugify(f"{function.name}-{function.line}")
        lines.append(f'<a id="{anchor}"></a>')
        lines.append(f"### `{function.signature}`")
        lines.append("")

        if function.description:
            lines.append(function.description)
            lines.append("")

        if function.realm:
            lines.append(f"Realm: `{function.realm}`")
            lines.append("")

        if function.params:
            lines.append("**Parameters**")
            lines.append("")
            lines.append("| Name | Type | Description |")
            lines.append("| --- | --- | --- |")
            for param in function.params:
                description = param.description or "-"
                lines.append(
                    "| `{}` | `{}` | {} |".format(
                        escape_table_cell(param.name),
                        escape_table_cell(param.type_name),
                        escape_table_cell(description),
                    )
                )
            lines.append("")

        if function.returns:
            lines.append("**Returns**")
            lines.append("")
            for return_doc in function.returns:
                if return_doc.description:
                    lines.append(
                        f"- `{return_doc.type_name}`: {return_doc.description}"
                    )
                else:
                    lines.append(f"- `{return_doc.type_name}`")
            lines.append("")

        if function.usage:
            lines.append("**Usage**")
            lines.append("")
            for snippet in function.usage:
                lines.append("```lua")
                lines.append(snippet.rstrip())
                lines.append("```")
                lines.append("")

        lines.append("---")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def render_api_index(file_docs: Sequence[FileDoc], api_subdir: str) -> str:
    grouped: Dict[str, List[FileDoc]] = defaultdict(list)
    for file_doc in file_docs:
        grouped[file_doc.source_group].append(file_doc)

    lines: List[str] = []
    lines.append("# API Reference")
    lines.append("")
    lines.append("Auto-generated from Lua annotations by `tools/generate_docs.py`.")
    lines.append("")
    lines.append(f"Pages: **{len(file_docs)}**")
    lines.append("")

    for group_name in sorted(grouped):
        lines.append(f"## {group_name.title()}")
        lines.append("")

        entries = sorted(
            grouped[group_name],
            key=lambda item: nav_sort_key(item.module or item.relative_path.with_suffix("").as_posix()),
        )
        for entry in entries:
            link = entry.output_relative.relative_to(api_subdir).as_posix()
            label = entry.module or entry.relative_path.with_suffix("").as_posix()
            count = len(entry.functions)
            suffix = "function" if count == 1 else "functions"
            lines.append(f"- [`{label}`]({link}) ({count} documented {suffix})")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def extract_markdown_title(path: Path) -> str:
    content = read_text(path)
    for line in content.splitlines():
        match = HEADER_RE.match(line)
        if match:
            return match.group(1).strip()
    return path.stem.replace("_", " ").replace("-", " ").strip().title()


def yaml_quote(value: str) -> str:
    return '"' + value.replace('"', '\\"') + '"'


def build_mkdocs_yaml(
    docs_dir_relative: str,
    site_name: str,
    site_description: str,
    root_pages: Sequence[Tuple[str, str]],
    manuals_nav_lines: Sequence[str],
    file_docs: Sequence[FileDoc],
    api_subdir: str,
    logo_path: Optional[str] = None,
    favicon_path: Optional[str] = None,
    extra_css_path: Optional[str] = None,
) -> str:
    api_tree = build_api_nav_tree(file_docs, api_subdir)
    lines: List[str] = []
    lines.append(f"site_name: {yaml_quote(site_name)}")
    lines.append(f"site_description: {yaml_quote(site_description)}")
    lines.append("site_author: Riggs")
    lines.append("site_url: https://parallax-framework.github.io/")
    lines.append("repo_url: https://github.com/Parallax-Framework/parallax")
    lines.append("repo_name: Parallax-Framework/parallax")
    lines.append(f"copyright: \"&copy; 2025-{datetime.now().year}, Parallax Contributors\"")
    lines.append(f"docs_dir: {normalize_nav_path(docs_dir_relative)}")
    lines.append("use_directory_urls: true")
    lines.append("theme:")
    lines.append("  name: material")
    lines.append("  language: en")
    if logo_path:
        lines.append(f"  logo: {normalize_nav_path(logo_path)}")
    if favicon_path:
        lines.append(f"  favicon: {normalize_nav_path(favicon_path)}")
    lines.append("  font:")
    lines.append("    text: IBM Plex Sans")
    lines.append("    code: IBM Plex Mono")
    lines.append("  features:")
    lines.append("    - navigation.footer")
    lines.append("    - navigation.instant")
    lines.append("    - navigation.instant.progress")
    lines.append("    - navigation.tracking")
    lines.append("    - navigation.sections")
    lines.append("    - navigation.expand")
    lines.append("    - navigation.indexes")
    lines.append("    - navigation.top")
    lines.append("    - search.suggest")
    lines.append("    - search.highlight")
    lines.append("    - content.code.copy")
    lines.append("  palette:")
    lines.append("    - scheme: slate")
    lines.append("      primary: deep purple")
    lines.append("      accent: purple")
    lines.append("plugins:")
    lines.append("  - search")
    if extra_css_path:
        lines.append("extra_css:")
        lines.append(f"  - {normalize_nav_path(extra_css_path)}")
    lines.append("extra:")
    lines.append("  social:")
    lines.append("    - icon: fontawesome/brands/github")
    lines.append("      link: https://github.com/Parallax-Framework")
    lines.append("    - icon: fontawesome/brands/discord")
    lines.append("      link: https://discord.gg/yekEvSszW3")
    lines.append("markdown_extensions:")
    lines.append("  - admonition")
    lines.append("  - attr_list")
    lines.append("  - def_list")
    lines.append("  - footnotes")
    lines.append("  - tables")
    lines.append("  - fenced_code")
    lines.append("  - pymdownx.details")
    lines.append("  - pymdownx.superfences")
    lines.append("  - pymdownx.inlinehilite")
    lines.append("  - pymdownx.snippets")
    lines.append("  - pymdownx.highlight:")
    lines.append("      anchor_linenums: true")
    lines.append("  - pymdownx.tabbed:")
    lines.append("      alternate_style: true")
    lines.append("  - toc:")
    lines.append("      permalink: true")
    lines.append("nav:")

    for title, page in root_pages:
        lines.append(f"  - {yaml_quote(title)}: {normalize_nav_path(page)}")

    if manuals_nav_lines:
        lines.append("  - Manuals:")
        lines.extend(manuals_nav_lines)

    lines.append("  - API:")
    lines.append(f"      - Overview: {normalize_nav_path(f'{api_subdir}/index.md')}")
    lines.extend(render_api_nav_lines(api_tree, 6))

    return "\n".join(lines).rstrip() + "\n"


def write_if_changed(path: Path, content: str, dry_run: bool) -> bool:
    existing = None
    if path.exists():
        existing = read_text(path)
    if existing == content:
        return False
    if dry_run:
        return True
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def ensure_docs_scaffold(docs_dir: Path, dry_run: bool) -> None:
    if not docs_dir.exists():
        if dry_run:
            print(f"[dry-run] Would create directory: {docs_dir}")
        else:
            docs_dir.mkdir(parents=True, exist_ok=True)
            print(f"Created docs directory: {docs_dir}")

    defaults: List[Tuple[Path, str]] = [
        (docs_dir / "index.md", DEFAULT_INDEX_CONTENT),
        (docs_dir / "assets" / "stylesheets" / "extra.css", DEFAULT_EXTRA_CSS_CONTENT),
    ]

    for path, content in defaults:
        if path.exists():
            continue

        if dry_run:
            print(f"[dry-run] Would create file: {path}")
            continue

        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print(f"Created file: {path}")


def sync_manuals_to_docs(manuals_source_dir: Path, manuals_docs_dir: Path, dry_run: bool) -> None:
    if not manuals_source_dir.exists():
        print(f"Skipping manuals sync, missing source path: {manuals_source_dir}")
        return

    source_files = sorted(
        manuals_source_dir.rglob("*.md"),
        key=lambda path: path.relative_to(manuals_source_dir).as_posix().casefold(),
    )

    expected_outputs: set[str] = set()
    for source_file in source_files:
        relative = source_file.relative_to(manuals_source_dir)
        output_file = manuals_docs_dir / relative
        expected_outputs.add(str(output_file.resolve()))

        content = read_text(source_file)
        if write_if_changed(output_file, content, dry_run):
            status = "[dry-run] Would sync manual" if dry_run else "Synced manual"
            print(f"{status}: {output_file}")

    if manuals_docs_dir.exists():
        stale_files = sorted(
            (
                path
                for path in manuals_docs_dir.rglob("*.md")
                if str(path.resolve()) not in expected_outputs
            ),
            key=lambda path: path.as_posix().casefold(),
        )

        for stale_file in stale_files:
            if dry_run:
                print(f"[dry-run] Would remove stale manual: {stale_file}")
                continue

            stale_file.unlink()
            print(f"Removed stale manual: {stale_file}")

    if not dry_run and manuals_docs_dir.exists():
        for directory in sorted(
            (path for path in manuals_docs_dir.rglob("*") if path.is_dir()),
            key=lambda path: len(path.parts),
            reverse=True,
        ):
            try:
                directory.rmdir()
            except OSError:
                pass


def build_manuals_nav_lines(manuals_docs_dir: Path, manuals_subdir: str, indent: int = 6) -> List[str]:
    if not manuals_docs_dir.exists():
        return []

    def file_sort_key(path: Path) -> Tuple[int, str]:
        name = path.name.casefold()
        return (0 if name == "readme.md" else 1, name)

    def render_dir(directory: Path, level_indent: int) -> List[str]:
        lines: List[str] = []

        markdown_files = sorted(
            (path for path in directory.glob("*.md") if path.is_file()),
            key=file_sort_key,
        )
        for markdown_file in markdown_files:
            relative = markdown_file.relative_to(manuals_docs_dir).as_posix()
            nav_path = normalize_nav_path(f"{manuals_subdir}/{relative}")
            title = "Overview" if markdown_file.name.casefold() == "readme.md" else extract_markdown_title(markdown_file)
            lines.append(f'{" " * level_indent}- {yaml_quote(title)}: {nav_path}')

        subdirectories = sorted(
            (path for path in directory.iterdir() if path.is_dir()),
            key=lambda path: path.name.casefold(),
        )
        for subdirectory in subdirectories:
            nested_lines = render_dir(subdirectory, level_indent + 4)
            if not nested_lines:
                continue

            lines.append(f'{" " * level_indent}- {yaml_quote(pretty_nav_label(subdirectory.name))}:')
            lines.extend(nested_lines)

        return lines

    return render_dir(manuals_docs_dir, indent)


def collect_root_pages(docs_dir: Path) -> List[Tuple[str, str]]:
    pages: List[Tuple[str, str]] = []

    index_page = docs_dir / "index.md"
    readme = docs_dir / "README.md"

    if index_page.exists():
        pages.append(("Home", "index.md"))
    elif readme.exists():
        pages.append(("Home", "README.md"))

    root_pages = [
        path
        for path in docs_dir.glob("*.md")
        if path.name not in {"README.md", "index.md"} and path.name.lower() != "index.md"
    ]
    titled_pages = [(extract_markdown_title(path), path.name) for path in root_pages]
    for title, page in sorted(titled_pages, key=lambda item: nav_sort_key(item[0])):
        pages.append((title, page))

    return pages


def main() -> None:
    args = parse_args()

    root = args.root.resolve()
    source_inputs = args.source or list(DEFAULT_SOURCE_DIRS)
    source_dirs = [normalize_path(root, source) for source in source_inputs]
    manuals_source_dir = normalize_path(root, args.manuals_source)

    docs_dir = normalize_path(root, args.docs_dir)
    api_dir = docs_dir / args.api_subdir
    manuals_docs_dir = docs_dir / args.manuals_subdir
    mkdocs_path = normalize_path(root, args.mkdocs_file)

    ensure_docs_scaffold(docs_dir, args.dry_run)
    sync_manuals_to_docs(manuals_source_dir, manuals_docs_dir, args.dry_run)

    if args.clean and api_dir.exists():
        if args.dry_run:
            print(f"[dry-run] Would remove: {api_dir}")
        else:
            shutil.rmtree(api_dir)
            print(f"Removed: {api_dir}")

    file_docs: List[FileDoc] = []
    scanned_files = 0

    for source_dir in source_dirs:
        if not source_dir.exists():
            print(f"Skipping missing source path: {source_dir}")
            continue

        lua_files = sorted(source_dir.rglob("*.lua"))
        scanned_files += len(lua_files)
        for lua_file in lua_files:
            file_doc = build_file_doc(
                root=root,
                source_dir=source_dir,
                api_subdir=args.api_subdir,
                file_path=lua_file,
            )
            if file_doc:
                file_docs.append(file_doc)

    file_docs.sort(key=lambda item: item.output_relative.as_posix())

    changed_api_files = 0
    for file_doc in file_docs:
        output_path = docs_dir / file_doc.output_relative
        markdown = render_file_markdown(file_doc, root)
        if write_if_changed(output_path, markdown, args.dry_run):
            changed_api_files += 1
            status = "[dry-run] Would write" if args.dry_run else "Wrote"
            print(f"{status}: {output_path.relative_to(root)}")

    api_index_path = api_dir / "index.md"
    api_index_content = render_api_index(file_docs, args.api_subdir)
    if write_if_changed(api_index_path, api_index_content, args.dry_run):
        status = "[dry-run] Would write" if args.dry_run else "Wrote"
        print(f"{status}: {api_index_path.relative_to(root)}")

    root_pages = collect_root_pages(docs_dir)
    manuals_nav_lines = build_manuals_nav_lines(manuals_docs_dir, args.manuals_subdir)
    logo_relative = "assets/images/parallax-logo.png"
    favicon_relative = "assets/images/favicon.png"
    extra_css_relative = "assets/stylesheets/extra.css"

    logo_path = logo_relative if (docs_dir / logo_relative).exists() else None
    favicon_path = favicon_relative if (docs_dir / favicon_relative).exists() else None
    extra_css_path = extra_css_relative if (docs_dir / extra_css_relative).exists() else None

    mkdocs_content = build_mkdocs_yaml(
        docs_dir_relative=args.docs_dir,
        site_name=args.site_name,
        site_description=args.site_description,
        root_pages=root_pages,
        manuals_nav_lines=manuals_nav_lines,
        file_docs=file_docs,
        api_subdir=args.api_subdir,
        logo_path=logo_path,
        favicon_path=favicon_path,
        extra_css_path=extra_css_path,
    )
    if write_if_changed(mkdocs_path, mkdocs_content, args.dry_run):
        status = "[dry-run] Would write" if args.dry_run else "Wrote"
        print(f"{status}: {mkdocs_path.relative_to(root)}")

    print(
        "Done. Scanned {} Lua files, documented {} files, changed {} API pages{}.".format(
            scanned_files,
            len(file_docs),
            changed_api_files,
            " (dry-run)" if args.dry_run else "",
        )
    )


if __name__ == "__main__":
    main()
