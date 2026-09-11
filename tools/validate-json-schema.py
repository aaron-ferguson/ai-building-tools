#!/usr/bin/env python3
"""Validate a JSON document against a JSON Schema, for the subset this repo's schemas use.

WHY THIS EXISTS RATHER THAN `pip install jsonschema`. The suite is portable POSIX `sh` plus
python3's standard library, and `dependency-conventions.md` asks first whether we could write it
in under ~100 lines. This is that: the keywords below are the ones
`skills/sprint/outcome.schema.json` actually uses, and nothing else is supported --
an unknown keyword is IGNORED, which is what JSON Schema itself specifies.

WHAT IT IS NOT. It is not a general validator and must not be used as evidence that a document
would pass a real one. The authority for the outcome schema is the `claude` CLI's own
`--json-schema` enforcement, which `tests/sprint.test.sh` exercises directly against the
live CLI; this validator is what makes the OFFLINE cases deterministic and free.

It is deliberately NOT written by reading the schema the way the skill reads it
(`testing-conventions.md`, a helper that reimplements the logic under test): it knows nothing
about stages, verdicts or tickets, only about JSON Schema keywords.

Usage:  validate-json-schema.py <schema.json> <document.json>
Exit:   0 valid, 1 invalid (reasons on stdout, one per line), 2 usage/parse error.
"""
# Annotations are postponed so the hints below can use `dict[str, ...]` and `X | Y` on the
# python3 this repo actually meets -- 3.9 evaluates neither at runtime, and the suite is meant
# to run wherever python3 does (`dependency-conventions.md`). Hints are required rather than
# optional here: `CONVENTIONS_CORE.md` makes "Python with full type hints" a principle.
from __future__ import annotations

import json
import re
import sys
from typing import Any

TYPES: dict[str, type | tuple[type, ...]] = {
    "object": dict, "array": list, "string": str,
    "number": (int, float), "integer": int, "boolean": bool, "null": type(None),
}


def type_ok(value: Any, name: str) -> bool:
    if name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if name == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if name == "boolean":
        return isinstance(value, bool)
    expected = TYPES.get(name)
    if expected is None:
        return True
    return isinstance(value, expected) and not isinstance(value, bool)


def validate(doc: Any, schema: dict[str, Any], path: str = "$") -> list[str]:
    """Return a list of human-readable reasons the document fails the schema."""
    errors = []

    declared = schema.get("type")
    if declared is not None:
        names = declared if isinstance(declared, list) else [declared]
        if not any(type_ok(doc, n) for n in names):
            errors.append(f"{path}: expected type {'|'.join(names)}, got {type(doc).__name__}")
            return errors

    if "enum" in schema and doc not in schema["enum"]:
        errors.append(f"{path}: {doc!r} is not one of {schema['enum']}")

    if isinstance(doc, str):
        if "pattern" in schema and not re.search(schema["pattern"], doc):
            errors.append(f"{path}: {doc!r} does not match /{schema['pattern']}/")
        shortest = schema.get("minLength")
        if shortest is not None and len(doc) < shortest:
            errors.append(f"{path}: is {len(doc)} characters, needs at least {shortest}")

    if isinstance(doc, (int, float)) and not isinstance(doc, bool):
        smallest = schema.get("minimum")
        if smallest is not None and doc < smallest:
            errors.append(f"{path}: {doc} is below the minimum {smallest}")

    if isinstance(doc, dict):
        properties = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in doc:
                errors.append(f"{path}: missing required property {key!r}")
        if schema.get("additionalProperties") is False:
            for key in doc:
                if key not in properties:
                    errors.append(f"{path}: property {key!r} is not permitted here")
        for key, value in doc.items():
            if key in properties:
                errors.extend(validate(value, properties[key], f"{path}.{key}"))

    if isinstance(doc, list):
        minimum = schema.get("minItems")
        if minimum is not None and len(doc) < minimum:
            errors.append(f"{path}: has {len(doc)} items, needs at least {minimum}")
        if "items" in schema:
            for index, entry in enumerate(doc):
                errors.extend(validate(entry, schema["items"], f"{path}[{index}]"))

    return errors


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        sys.stderr.write("usage: validate-json-schema.py <schema.json> <document.json>\n")
        return 2
    try:
        with open(argv[1]) as handle:
            schema = json.load(handle)
        with open(argv[2]) as handle:
            doc = json.load(handle)
    except (OSError, ValueError) as exc:
        sys.stderr.write(f"could not read: {exc}\n")
        return 2
    reasons = validate(doc, schema)
    for reason in reasons:
        print(reason)
    return 1 if reasons else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
