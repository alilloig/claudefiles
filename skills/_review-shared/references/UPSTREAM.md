# Vendored sources

These files are copies of upstream files, tracked here so we can re-sync periodically. Do not edit silently — record any local divergence below.

| Local file | Upstream | Source version |
|---|---|---|
| `scripts/consolidate.js` | `move-pr-review/scripts/consolidate.js` | `sui-pilot` plugin `aee572259e9a` (verbatim) |
| `scripts/coverage_matrix.sh` | `move-pr-review/scripts/coverage_matrix.sh` | `sui-pilot` plugin `aee572259e9a` (verbatim) |
| `scripts/validate_schema.sh` | `move-pr-review/scripts/validate_schema.sh` | `sui-pilot` plugin `aee572259e9a` (LOCAL: expanded category vocabulary + optional `domain`/`spec_reference` fields) |
| `references/html_template.md` | derived from `move-pr-review/SKILL.md` lines 277–294 | `sui-pilot` plugin `aee572259e9a` (distilled) |
| `references/schemas.md` | extends `move-pr-review/references/finding_schema.md` | `sui-pilot` plugin `aee572259e9a` (LOCAL: added `domain`, `spec_reference`; unioned category vocabulary) |

## Local divergence

- `validate_schema.sh` — expanded category list from 11 → 23 (union with `stepped-pr` and `ship-reviewed-pr` vocabularies). Added optional `domain` field validation and conditional `spec_reference` requirement for critical/high.
- `schemas.md` — added `domain` (move/ts-js/generic) and `spec_reference` (required iff severity ∈ {critical, high}) fields. Unioned the category vocabulary.

## Re-sync procedure

When sui-pilot publishes a new `move-pr-review`:
1. Read the new upstream files.
2. Diff against vendored copies.
3. Port upstream changes, preserving local modifications listed above.
4. Bump the "Source version" cell to the new plugin version directory.
