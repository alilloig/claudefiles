---
name: seal-owned-object-setsender
description: |
  Fix for Sui Seal decryption failing with "Transaction was not signed by the correct
  sender: Object ... is owned by account address ..., but given owner/signer address
  is 0x0000000000000000000000000000000000000000000000000000000000000000". Use when:
  (1) seal_approve PTB references an owned object (e.g. PurchaseReceipt, NFT),
  (2) tx.build({ onlyTransactionKind: true }) fails or dry-run returns sender 0x0,
  (3) sealClient.decrypt() throws ownership mismatch errors. Covers the gap between
  Seal documentation (which only shows shared/pure args) and real-world access policies
  that use owned objects as proof of access.
author: Claude Code
version: 1.0.0
date: 2026-03-04
---

# Seal Decryption Fails with Owned Objects in seal_approve PTB

## Problem

When building a `seal_approve` PTB that references an **owned object** (e.g. a
PurchaseReceipt NFT used as proof of purchase), the decryption flow fails with:

```
Error checking transaction input objects: Transaction was not signed by the correct
sender: Object 0x... is owned by account address 0x..., but given owner/signer
address is 0x0000000000000000000000000000000000000000000000000000000000000000
```

## Context / Trigger Conditions

- Your `seal_approve` Move function takes an owned object as a parameter (not just
  shared objects and pure values)
- The PTB is built with `onlyTransactionKind: true` (required by Seal)
- You did NOT call `tx.setSender()` before `tx.build()`
- The Seal documentation examples work fine because they only demonstrate shared
  objects and pure arguments — owned objects are the gap

## Root Cause

`tx.build()` resolves object inputs against the chain even when using
`onlyTransactionKind: true`. For owned objects, the SDK needs to know the sender
to properly resolve the input. Without `setSender()`, the sender defaults to
`0x0000...0000`, causing ownership verification to fail either during build or
during the key server's dry-run.

`onlyTransactionKind: true` only affects the **output format** (strips sender/gas
info from the bytes). The **build process** still performs full input resolution.

## Solution

Add `tx.setSender(account.address)` before building:

```typescript
const tx = new Transaction();
tx.setSender(account.address);  // Required for owned object resolution
tx.moveCall({
  target: `${packageId}::seal_policy::seal_approve`,
  arguments: [
    tx.pure.vector("u8", fromHex(parsed.id)),
    tx.object(SHARED_OBJECT_ID),   // shared — works without setSender
    tx.object(ownedReceiptId),     // owned — NEEDS setSender
  ],
});
const txBytes = await tx.build({
  client: suiClient,
  onlyTransactionKind: true,
});
```

Get the address from the wallet hook:

```typescript
import { useCurrentAccount } from "@mysten/dapp-kit-react";
const account = useCurrentAccount();
// Guard: if (!account) throw new Error("Wallet not connected");
```

## Verification

1. The `tx.build()` call completes without error
2. `sealClient.decrypt()` succeeds — key servers can dry-run the PTB
3. The decrypted content is returned to the browser

## Example

Before (broken):
```typescript
const tx = new Transaction();
tx.moveCall({
  target: `${PACKAGE_ID}::seal_policy::seal_approve`,
  arguments: [
    tx.pure.vector("u8", fromHex(parsed.id)),
    tx.object(PACKAGE_VERSION_ID),  // shared
    tx.object(receiptId),           // owned — causes the error
  ],
});
const txBytes = await tx.build({ client: suiClient, onlyTransactionKind: true });
```

After (fixed):
```typescript
const tx = new Transaction();
tx.setSender(account.address);     // <-- THE FIX
tx.moveCall({
  target: `${PACKAGE_ID}::seal_policy::seal_approve`,
  arguments: [
    tx.pure.vector("u8", fromHex(parsed.id)),
    tx.object(PACKAGE_VERSION_ID),
    tx.object(receiptId),
  ],
});
const txBytes = await tx.build({ client: suiClient, onlyTransactionKind: true });
```

## Notes

- **Shared objects don't need this**: If your `seal_approve` only uses shared objects
  and pure values, `setSender()` is unnecessary — which is why the official Seal docs
  don't mention it.
- **The sender in txBytes is stripped**: `onlyTransactionKind: true` removes sender
  info from the output. The Seal key server injects the sender from the SessionKey
  during dry-run. `setSender()` is only needed for the build-time input resolution.
- **Common owned objects in seal_approve**: PurchaseReceipt, access NFTs, membership
  tokens — any object used as proof-of-access that is owned (not shared).
- **SessionKey address must match**: The address in `SessionKey.create({ address })`
  must be the same wallet that owns the receipt object.
