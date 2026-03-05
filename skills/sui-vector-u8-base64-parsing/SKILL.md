---
name: sui-vector-u8-base64-parsing
description: |
  Fix for silent comparison failures when parsing Sui Move `vector<u8>` fields
  from gRPC/JSON-RPC object content. Use when: (1) comparing on-chain vector<u8>
  values (root hashes, checksums, byte arrays) against locally computed values
  always fails, (2) a parsed vector<u8> field looks like base64 instead of hex
  or a number array, (3) integrity verification or signature comparison silently
  returns false despite correct data. Sui serializes vector<u8> as base64 strings
  in JSON object content — not hex, not JSON arrays. Must decode with fromBase64()
  before comparing.
author: Claude Code
version: 1.0.0
date: 2026-03-05
---

# Sui `vector<u8>` Base64 Parsing

## Problem

Sui gRPC JSON (and JSON-RPC with `showContent: true`) serializes `vector<u8>` Move
fields as **base64-encoded strings**. This is different from how other vector types
are serialized (as JSON arrays) and different from what most developers expect (hex).

When you compute a value locally (e.g., a Merkle root hash as hex) and compare it
against a `vector<u8>` field read from an on-chain object, the comparison **silently
fails** because you're comparing hex against base64.

## Context / Trigger Conditions

- You're parsing a Sui object that has a `vector<u8>` field (root hashes, checksums,
  signatures, arbitrary byte arrays)
- You compute the same value locally and compare — comparison always returns `false`
- The parsed value looks like base64 (e.g., `"qrvM"`) instead of hex (`"aabbcc"`)
  or a number array (`[170, 187, 204]`)
- You're using `SuiGrpcClient` or `SuiClient.getObject({ options: { showContent: true } })`

## How Sui Serializes Move Types in JSON

| Move Type | JSON Format | Example |
|-----------|------------|---------|
| `u8`, `u16`, `u32` | number | `42` |
| `u64`, `u128`, `u256` | string (decimal) | `"1000000000"` |
| `bool` | boolean | `true` |
| `address` | string (hex, 0x-prefixed) | `"0xabc..."` |
| `String` | string | `"hello"` |
| `vector<u8>` | **string (base64)** | `"qrvM"` |
| `vector<T>` (T ≠ u8) | JSON array | `["a", "b"]` |
| `Option<T>` | T \| null | `null` |
| `Balance<T>` | string (decimal u64) | `"10000000000"` |

The key gotcha: `vector<u8>` gets **special treatment** — it's base64, not an array
of numbers, and not hex.

## Solution

### Parsing: Base64 → Hex String

```typescript
import { fromBase64 } from "@mysten/sui/utils";

function parseVectorU8AsHex(value: unknown): string {
  if (!value || typeof value !== "string" || value.length === 0) return "";
  try {
    const bytes = fromBase64(value);
    return Array.from(bytes)
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  } catch {
    return "";
  }
}

// In your parser:
const rootHash = parseVectorU8AsHex(json.root_hash);
// "qrvM" → "aabbcc"
```

### Parsing: Base64 → Uint8Array

```typescript
import { fromBase64 } from "@mysten/sui/utils";

function parseVectorU8AsBytes(value: unknown): Uint8Array {
  if (!value || typeof value !== "string" || value.length === 0)
    return new Uint8Array();
  try {
    return fromBase64(value);
  } catch {
    return new Uint8Array();
  }
}
```

### Comparison: Match Formats

When comparing a locally computed value against an on-chain `vector<u8>`:

```typescript
// Local computation produces hex:
const localHash = Array.from(computedBytes)
  .map((b) => b.toString(16).padStart(2, "0"))
  .join("");

// On-chain value parsed from base64 to hex:
const onChainHash = parseVectorU8AsHex(json.root_hash);

// Now both are hex — comparison works:
const match = localHash === onChainHash; // ✓
```

## Verification

1. Parse a known on-chain object with a `vector<u8>` field
2. Log the raw JSON value — it should look like base64 (alphanumeric + `/+=`)
3. Apply `parseVectorU8AsHex()` and verify it produces the expected hex
4. Compare against a locally computed value — should now match

## Example

Real-world scenario from a Walrus integrity verification system:

```typescript
// On-chain: SkillListing has root_hash: vector<u8>
// Stored bytes: [0xAA, 0xBB, 0xCC]
// gRPC JSON returns: "qrvM" (base64)

// ❌ WRONG: comparing base64 against hex
const rootHash = json.root_hash as string;        // "qrvM"
const derived = computeHex(bytes);                  // "aabbcc"
console.log(rootHash === derived);                  // false — ALWAYS

// ✅ CORRECT: decode base64 first
const rootHash = parseVectorU8AsHex(json.root_hash); // "aabbcc"
const derived = computeHex(bytes);                    // "aabbcc"
console.log(rootHash === derived);                    // true ✓
```

## Notes

- This applies to both `SuiGrpcClient` (gRPC) and `SuiClient` (JSON-RPC) — both
  use the same JSON serialization for object content
- `vector<String>`, `vector<ID>`, etc. are NOT affected — only `vector<u8>` gets
  base64 treatment
- Empty `vector<u8>` (vector[]) serializes as an empty string `""`
- The `seal_key_id` field in many Sui projects is also `vector<u8>` and comes back
  as base64 — if you only use it for display, the wrong format goes unnoticed
- `fromBase64` is available from `@mysten/sui/utils` (SDK v2) or `@mysten/bcs`

## References

- [Sui JSON-RPC Object Content](https://docs.sui.io/references/sui-api)
- [@mysten/sui/utils — fromBase64, toBase64](https://sdk.mysten.sui.io/typescript)
- Related skill: `sui-balance-json-parsing` — similar JSON serialization gotcha for `Balance<T>`
