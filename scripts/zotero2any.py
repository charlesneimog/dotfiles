#!/usr/bin/env python3

"""Export Zotero highlights as one Anytype page per document.

Defaults to the space named API. Use --space NAME when ready to switch.
Use --input annotations.json to import a saved export. Older exports fetch
missing bibliographic fields from Zotero using their document keys.
Colors other than yellow, red, blue, and green require an interactive replacement.
"""

import argparse
import importlib
import importlib.util
import os
from pathlib import Path
import re
import sys

import requests
import json
import colorsys
import html
from html.parser import HTMLParser

BASE_URL = "http://localhost:23119/api/users/0/items"
OUTPUT_FILE = "annotations.json"
IMPORT_DESCRIPTION = "Annotations imported from Zotero."
ANYTYPE_COLORS = {
    "yellow": "yellow", "red": "red", "blue": "blue", "green": "lime",
}
BIBLIOGRAPHIC_PROPERTIES = {
    "author": ("Author", "text"),
    "year": ("Year", "number"),
    "doi": ("Doi", "text"),
    "journal": ("Journal", "text"),
}

session = requests.Session()
session.headers.update({"Zotero-API-Version": "3"})

item_cache = {}


# --------------------------------------------------
# HTML REMOVAL
# --------------------------------------------------


class HTMLStripper(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def remove_html(value):
    if not isinstance(value, str):
        return value

    parser = HTMLStripper()
    parser.feed(value)

    return html.unescape("".join(parser.parts)).strip()


# --------------------------------------------------
# ZOTERO API
# --------------------------------------------------


def get_item(key):
    if not key:
        return None

    if key not in item_cache:
        response = session.get(
            f"{BASE_URL}/{key}",
            timeout=30,
        )

        if response.status_code == 404:
            item_cache[key] = None
        else:
            response.raise_for_status()
            item_cache[key] = response.json()["data"]

    return item_cache[key]


def get_bibliographic_item(annotation):
    """
    Follow:
    annotation -> PDF attachment -> book/article
    """
    parent_key = annotation.get("parentItem")
    parent = get_item(parent_key)

    if not parent:
        return None

    if parent.get("itemType") == "attachment":
        bibliographic_key = parent.get("parentItem")

        if bibliographic_key:
            return get_item(bibliographic_key)

    return parent


# --------------------------------------------------
# AUTHORS
# --------------------------------------------------


def get_authors(item):
    if not item:
        return []

    creators = item.get("creators", [])

    authors = [
        creator for creator in creators if creator.get("creatorType") == "author"
    ]

    if not authors:
        authors = [
            creator for creator in creators if creator.get("creatorType") == "editor"
        ]

    names = []

    for author in authors:
        if "name" in author:
            name = author["name"]
        else:
            first = author.get("firstName", "")
            last = author.get("lastName", "")
            name = f"{first} {last}".strip()

        name = remove_html(name)

        if name:
            names.append(name)

    return names


def bibliographic_metadata(item):
    item = item or {}
    match = re.search(r"(?<!\d)(\d{4})(?!\d)", str(item.get("date") or ""))
    return {
        "author": get_authors(item),
        "year": int(match.group(1)) if match else None,
        "doi": remove_html(item.get("DOI") or ""),
        "journal": remove_html(item.get("publicationTitle") or ""),
    }


def enrich_annotations(annotations):
    """Backfill old JSON exports, preserving explicitly saved metadata values."""
    for note in annotations:
        missing = BIBLIOGRAPHIC_PROPERTIES.keys() - note.keys()
        if not missing:
            continue
        key = note.get("document_key")
        metadata = bibliographic_metadata(get_item(key) if key else None)
        for field in missing:
            note[field] = metadata[field]
    return annotations


# --------------------------------------------------
# COLOR NORMALIZATION
# --------------------------------------------------


def normalize_color(hex_color):
    """
    Convert color shades into:
    red, orange, yellow, green, blue, purple,
    neutral, or unknown.
    """
    if not hex_color:
        return "unknown"

    try:
        color = hex_color.lstrip("#")

        if len(color) != 6:
            return "unknown"

        r, g, b = (int(color[i : i + 2], 16) / 255 for i in (0, 2, 4))

        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        hue = h * 360

        if s < 0.15:
            return "neutral"

        if hue < 15 or hue >= 345:
            return "red"
        elif hue < 45:
            return "orange"
        elif hue < 75:
            return "yellow"
        elif hue < 165:
            return "green"
        elif hue < 255:
            return "blue"
        else:
            return "purple"

    except (ValueError, TypeError):
        return "unknown"


# --------------------------------------------------
# FETCH ALL ANNOTATIONS
# --------------------------------------------------


def fetch_annotations():
    all_items = []
    start = 0
    limit = 100

    while True:
        response = session.get(
            BASE_URL,
            params={
                "itemType": "annotation",
                "start": start,
                "limit": limit,
            },
            timeout=60,
        )

        response.raise_for_status()
        items = response.json()

        if not items:
            break

        all_items.extend(items)
        start += len(items)

        print(
            f"\rFetched {len(all_items)} annotations",
            end="",
            flush=True,
        )

        if len(items) < limit:
            break

    print()
    return all_items


# --------------------------------------------------
# EXPORT
# --------------------------------------------------


def collect_annotations():
    raw_annotations = fetch_annotations()

    annotations = []
    seen = set()

    duplicates = 0
    empty = 0

    for index, item in enumerate(raw_annotations, 1):
        data = item["data"]

        # Clean highlighted text
        text = remove_html(data.get("annotationText", ""))

        # Ignore empty annotations
        if not text or not text.strip():
            empty += 1
            continue

        # Find bibliographic information
        bibliographic = get_bibliographic_item(data)

        if bibliographic:
            name = remove_html(bibliographic.get("title", ""))

            authors = get_authors(bibliographic)
            document_key = bibliographic.get("key")

        else:
            # Standalone PDF fallback
            attachment = get_item(data.get("parentItem"))

            name = remove_html(attachment.get("title", "")) if attachment else ""

            authors = []
            document_key = data.get("parentItem")

        # Page
        page = str(data.get("annotationPageLabel") or "").strip()

        # Normalize colors
        color = normalize_color(data.get("annotationColor"))

        # Remove duplicates
        # Same document + page + normalized text
        duplicate_key = (
            document_key,
            page,
            " ".join(text.split()).casefold(),
        )

        if duplicate_key in seen:
            duplicates += 1
            continue

        seen.add(duplicate_key)

        annotations.append(
            {
                "name": name,
                **bibliographic_metadata(bibliographic),
                "author": authors,
                "text": text,
                "page": page,
                "color": color,
                "document_key": document_key,
                "annotation_key": data.get("key"),
            }
        )

        if index % 100 == 0:
            print(f"Processed {index}/{len(raw_annotations)}")

    # Sort by book/article name and page
    annotations.sort(
        key=lambda x: (
            x["name"].casefold(),
            page_sort_key(x["page"]),
        )
    )

    print(f"Total retrieved: {len(raw_annotations)}")
    print(f"Exported: {len(annotations)}")
    print(f"Duplicates ignored: {duplicates}")
    print(f"Empty ignored: {empty}")
    return annotations


def load_client(client_path=None):
    """Use an installed client, or the user's sibling anytype-client checkout."""
    if client_path:
        sys.path.insert(0, str(Path(client_path).expanduser().resolve()))
    elif importlib.util.find_spec("anytype") is None:
        checkout = Path(__file__).resolve().parents[2] / "anytype-client"
        if (checkout / "anytype" / "__init__.py").is_file():
            sys.path.insert(0, str(checkout))
    try:
        return importlib.import_module("anytype")
    except ModuleNotFoundError as exc:
        if exc.name != "anytype":
            raise
        raise RuntimeError(
            "Install anytype-client or pass --client-path /path/to/anytype-client"
        ) from exc


def literal_text(value):
    # AnyBlock parses inline formatting even in typed text/quote blocks.
    return re.sub(r"([\\`*_\[\]~<])", r"\\\1", str(value))


def page_sort_key(page):
    try:
        return (0, int(page))
    except ValueError:
        return (1, page)


def choose_color(note, replacements):
    """Ask once per unsupported source color for this import run."""
    source = str(note.get("color") or "unknown").strip().casefold() or "unknown"
    if source in ANYTYPE_COLORS:
        return ANYTYPE_COLORS[source]
    if source not in replacements:
        print(f"\nWhat color do you want to use for {source!r} highlights?")
        print(f"Example: {note.get('name') or 'Untitled Zotero document'}, "
              f"page {note.get('page') or 'unknown'}")
        print(str(note["text"])[:200])
        choices = list(ANYTYPE_COLORS)
        for index, color in enumerate(choices, 1):
            print(f"{index}) {color}")
        while True:
            try:
                answer = input("Choose 1–4 (or a color name): ").strip().casefold()
            except EOFError as exc:
                raise RuntimeError(
                    f"A replacement for {source!r} is required. "
                    "Run in an interactive terminal to choose a color."
                ) from exc
            if answer in ("1", "2", "3", "4"):
                answer = choices[int(answer) - 1]
            if answer in ANYTYPE_COLORS:
                replacements[source] = ANYTYPE_COLORS[answer]
                print(f"Using {answer} for all {source} highlights in this run.")
                break
            print("Please choose 1) yellow, 2) red, 3) blue, or 4) green.")
    return replacements[source]


def build_pages(annotations, client):
    documents = {}
    for annotation in annotations:
        if not isinstance(annotation, dict) or not isinstance(annotation.get("text"), str):
            raise ValueError("Each annotation must be an object with a text string")
        if not annotation["text"].strip():
            continue
        authors = annotation.get("author") or []
        if not isinstance(authors, list) or any(not isinstance(a, str) for a in authors):
            raise ValueError("Annotation author must be a list of names")
        name = annotation.get("name") or "Untitled Zotero document"
        identity = annotation.get("document_key") or (name, tuple(authors))
        documents.setdefault(identity, []).append(annotation)

    print(f"Found {len(documents)} papers containing "
          f"{sum(len(notes) for notes in documents.values())} highlights.", flush=True)
    pages = []
    replacements = {}
    for notes in documents.values():
        obj = client.Object(notes[0].get("name") or "Untitled Zotero document", type="page")
        obj.description = IMPORT_DESCRIPTION
        obj.icon = "📚"
        authors = list(dict.fromkeys(a for note in notes for a in (note.get("author") or [])))
        if authors:
            obj.properties["author"] = "; ".join(authors)
        for field in ("year", "doi", "journal"):
            values = [note.get(field) for note in notes if note.get(field) not in (None, "")]
            if values:
                value = values[0]
                if field == "year":
                    value = int(value)
                if any(str(v) != str(value) for v in values):
                    raise ValueError(f"Conflicting {field} values for {obj.name!r}")
                obj.properties[field] = value
        previous_page = None
        for note in sorted(notes, key=lambda n: page_sort_key(str(n.get("page") or ""))):
            page = str(note.get("page") or "").strip()
            if page != previous_page:
                obj.add_title2(literal_text(f"Page {page}" if page else "Unnumbered page"))
                previous_page = page
            color = choose_color(note, replacements)
            text = literal_text(note["text"])
            if color:
                text = f'<font color="{color}">{text}</font>'
            obj.add_quote(text)
        pages.append(obj)
    return sorted(pages, key=lambda p: p.name.casefold())


def paginated(fetch):
    offset = 0
    while True:
        batch = fetch(offset=offset, limit=100)
        yield from batch
        if len(batch) < 100:
            return
        offset += len(batch)


def content_signature(obj):
    # Compare visible content; the server adds block IDs and may normalize escapes.
    return [
        (b.type, re.sub(r"\\([\\`*_\[\]~<])", r"\1", getattr(b, "text", "")),
         getattr(b, "background_color", "") or "")
        for b in obj.blocks if b.type not in ("title", "description", "featured_properties")
    ]


def find_page_property(properties, field, name, fmt, space_name):
    matches = [p for p in properties
               if p.key in (field, f"zotero_{field}") or p.name.casefold() == name.casefold()]
    if len(matches) > 1:
        raise RuntimeError(f"Multiple properties match {name!r} in {space_name!r}")
    if not matches:
        return None
    prop = matches[0]
    if prop.format != fmt:
        raise RuntimeError(f"Property {name!r} must use {fmt!r}, found {prop.format!r}")
    return prop


def bind_page_properties(space, pages, client, dry_run=False):
    """Resolve space-specific property keys without modifying the shared Page type."""
    properties = list(paginated(space.get_properties))
    resolved = {}
    for field, (name, fmt) in BIBLIOGRAPHIC_PROPERTIES.items():
        prop = find_page_property(properties, field, name, fmt, space.name)
        resolved[field] = prop.key if prop else None
    missing = [BIBLIOGRAPHIC_PROPERTIES[f][0] for f, key in resolved.items() if key is None]
    if missing and dry_run:
        raise RuntimeError(
            "Dry run cannot create missing page properties: " + ", ".join(missing)
            + ". Run without --dry-run to create them."
        )
    for field, key in resolved.items():
        if key is None:
            name, fmt = BIBLIOGRAPHIC_PROPERTIES[field]
            definition = client.Property.from_format(name, fmt)
            definition.key = f"zotero_{field}"
            try:
                prop = space.create_property(definition)
            except Exception as exc:
                if "property key already exists" not in str(exc).casefold():
                    raise
                properties = list(paginated(space.get_properties))
                prop = find_page_property(properties, field, name, fmt, space.name)
                if prop is None:
                    raise RuntimeError(
                        f"Anytype reports key {definition.key!r} already exists, "
                        "but did not return it in the property list."
                    ) from exc
            resolved[field] = prop.key
    for page in pages:
        page.properties = {resolved.get(key, key): value for key, value in page.properties.items()}
    return resolved


def metadata_matches(current, expected):
    values = current._property_values()
    return all(values.get(key) == value for key, value in expected.properties.items())


def update_operations(current, expected, client, author_key):
    old_blocks = [b for b in current.blocks if b.type not in
                  ("title", "description", "featured_properties")]
    ops = []
    # Migrate only the known author paragraph emitted by previous script versions.
    author = expected.properties.get(author_key)
    if author and old_blocks and old_blocks[0].type == "paragraph":
        paragraph = client.Object(blocks=[old_blocks[0]])
        legacy = client.Object(blocks=[client.Text(literal_text("Authors: " + author))])
        if content_signature(paragraph) == content_signature(legacy):
            ops.append({"op": "delete_block", "id": old_blocks.pop(0).id})
    if ([b.type for b in old_blocks] != [b.type for b in expected.blocks]
        or any(a.type != "quote" and content_signature(client.Object(blocks=[a]))
               != content_signature(client.Object(blocks=[b]))
               for a, b in zip(old_blocks, expected.blocks))):
        raise RuntimeError(f"Page structure changed for {expected.name!r}; refusing to overwrite")
    changed = {key: value for key, value in expected.properties.items()
               if current._property_values().get(key) != value}
    if changed:
        ops.append({"op": "set_properties", "set": changed})
    ops.extend({"op": "update_block", "id": old.id,
                "set": {"text": new.text, "background_color": ""}}
               for old, new in zip(old_blocks, expected.blocks) if old.type == "quote"
               and (old.text != new.text or getattr(old, "background_color", "")))
    return ops


def export_pages(pages, client, args):
    anytype = client.Anytype()
    # Read existing credentials without asking the client to create directories.
    api_key = os.environ.get("ANYTYPE_API_KEY")
    anytype.auth()
    
    if args.space_id:
        space = anytype.get_space(args.space_id)
    else:
        matches = [s for s in paginated(anytype.get_spaces) if s.name == args.space]
        if len(matches) != 1:
            raise RuntimeError(
                f"Expected exactly one space named {args.space!r}; found {len(matches)}. "
                "Use --space-id to select an existing space explicitly."
            )
        space = matches[0]
    print(f"Destination: {space.name} ({space.id})", flush=True)
    property_keys = bind_page_properties(space, pages, client, dry_run=args.dry_run)
    existing = {}
    def imported_objects(offset, limit):
        # Descriptions are omitted from the API's default list projection.
        return space.get_objects(offset=offset, limit=limit,
                                 filters={"fields": "id,name,description"})

    for obj in paginated(imported_objects):
        if obj.description == IMPORT_DESCRIPTION:
            existing.setdefault(obj.name, []).append(obj)

    created = skipped = updated = 0
    for index, obj in enumerate(pages, 1):
        candidates = existing.get(obj.name, [])
        if candidates:
            fetched = [space.get_object(c.id) for c in candidates]
            matching = [c for c in fetched if content_signature(c) == content_signature(obj)
                        and metadata_matches(c, obj)]
            if not matching:
                if args.update_existing and len(fetched) == 1:
                    current = fetched[0]
                    ops = update_operations(current, obj, client, property_keys["author"])
                    if ops:
                        if args.dry_run:
                            current.patch(ops, dry_run="true")
                        else:
                            current.patch(ops)
                            if (content_signature(current) != content_signature(obj)
                                or not metadata_matches(current, obj)):
                                raise RuntimeError(f"Updated content verification failed for {obj.name!r}")
                    updated += 1
                    print(f"[{index}/{len(pages)}] {'Validated update' if args.dry_run else 'Updated'}: {obj.name}", flush=True)
                    continue
                raise RuntimeError(
                    f"An imported page named {obj.name!r} has different content. "
                    "Stopped to preserve existing edits. Use --update-existing to apply current metadata, quotes, and colors."
                )
            skipped += 1
            print(f"[{index}/{len(pages)}] Already imported: {obj.name}", flush=True)
            continue
        if args.dry_run:
            # requests encodes Python True as "True"; this API requires "true".
            space.create_object(obj, dry_run="true")
            print(f"[{index}/{len(pages)}] Validated: {obj.name}", flush=True)
        else:
            result = space.create_object(obj)
            if content_signature(result) != content_signature(obj) or not metadata_matches(result, obj):
                raise RuntimeError(f"Content verification failed for {obj.name!r} ({result.id})")
            existing.setdefault(obj.name, []).append(result)
            created += 1
            print(f"[{index}/{len(pages)}] Created: {obj.name} ({result.id})", flush=True)
    print(f"Papers: {len(pages)} total; {created} created; {updated} "
          f"{'updates validated' if args.dry_run else 'updated'}; {skipped} already imported.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--space", default="API", help="Exact destination space name (default: API)")
    parser.add_argument("--space-id", help="Explicit space ID, overriding --space")
    parser.add_argument("--input", type=Path, help="Read an existing annotations JSON export")
    parser.add_argument("--output", type=Path, default=Path(OUTPUT_FILE), help="JSON output path")
    parser.add_argument("--client-path", type=Path, help="Path to an anytype-client checkout")
    parser.add_argument("--json-only", action="store_true", help="Save JSON without contacting Anytype")
    parser.add_argument("--dry-run", action="store_true", help="Validate pages in Anytype without creating them")
    parser.add_argument("--update-existing", action="store_true", help="Update metadata, quotes, and colors; move legacy author text into properties")
    parser.add_argument("--limit", type=int, help="Export only the first N document pages")
    args = parser.parse_args(argv)
    if args.limit is not None and args.limit < 1:
        parser.error("--limit must be positive")
    if args.input:
        annotations = json.loads(args.input.read_text(encoding="utf-8"))
        if not isinstance(annotations, list):
            raise ValueError("Input must be a JSON list of annotations")
        enrich_annotations(annotations)
    else:
        annotations = collect_annotations()

    # Preserve the JSON export alongside the Anytype import.
    with open(
        args.output,
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(
            annotations,
            f,
            ensure_ascii=False,
            indent=2,
        )

    print(f"Saved {len(annotations)} annotations to {args.output}", flush=True)
    if args.json_only:
        return
    client = load_client(args.client_path)
    pages = build_pages(annotations, client)
    if args.limit:
        print(f"Selected {min(args.limit, len(pages))} of {len(pages)} papers (--limit).", flush=True)
        pages = pages[:args.limit]
    if pages:
        export_pages(pages, client, args)
    else:
        print("No annotations to import.")


if __name__ == "__main__":
    main()
