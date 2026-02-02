# Global Claude Code Guidelines

## Sui Move Development

### Code Quality Workflow (MANDATORY)

**BEFORE writing any Move code**, review and apply these Move 2024 Edition best practices:

1. **Module syntax**: Use `module package::name;` (no curly braces)
2. **Method syntax**: Prefer `id.delete()` over `object::delete(id)`, `ctx.sender()` over `tx_context::sender(ctx)`
3. **String literals**: Use `b"text".to_string()` instead of `string::utf8(b"text")`
4. **Destructuring**: Use `let MyStruct { id, .. } = obj;` to ignore unused fields
5. **Naming conventions**:
   - Error constants: `EPascalCase` (e.g., `ENotAuthorized`)
   - Regular constants: `ALL_CAPS` (e.g., `MAX_FEE`)
   - Capabilities: Suffix with `Cap` (e.g., `AdminCap`)
   - Events: Past tense (e.g., `CardMinted`, `TradePurchased`)
   - Getters: Named after field, no `get_` prefix (e.g., `fn balance()` not `fn get_balance()`)
6. **Test functions**: Don't prefix with `test_` (redundant with `#[test]` attribute)
7. **Test attributes**: Merge on single line: `#[test, expected_failure(abort_code = 0)]`
8. **Test cleanup**: Use `sui::test_utils::destroy` instead of custom destroy functions
9. **Assertions**: Use `assert_eq!(a, b)` instead of `assert!(a == b)` for better error messages
10. **Hot potato**: Use positional structs `struct Receipt() has drop;` for phantom/marker types

**AFTER completing Move implementation**, run the code quality checker:

```
/move-code-quality
```

**Iterate until no issues remain**:
- Address all critical issues immediately
- Apply recommended improvements
- Re-run `/move-code-quality` after each fix cycle
- Only consider implementation complete when the tool reports no issues

This ensures all Move code follows the Move Book Code Quality Checklist standards.

### Move.toml Configuration

```toml
[package]
name = "my_package"
edition = "2024"

[dependencies]
# DO NOT explicitly add Sui dependency - it's auto-added for testnet/mainnet
# Adding it explicitly causes warnings and may cause version conflicts

[addresses]
my_package = "0x0"
```

### Common Compilation Errors & Fixes

#### 1. Mutable Variables
Variables that will be mutated need explicit `mut` keyword:
```move
// WRONG
let balance = balance::zero();
balance::join(&mut balance, other); // Error: invalid mutable borrow

// CORRECT
let mut balance = balance::zero();
balance::join(&mut balance, other);
```

#### 2. Test Address Literals
Addresses must be valid hexadecimal - letters A-F only:
```move
// WRONG - V is not valid hex
const VOTER1: address = @0xV1;

// CORRECT
const VOTER1: address = @0x01;
const ADMIN: address = @0xAD;
const SELLER: address = @0x5E;
```

#### 3. Expected Failure Attributes
Use numeric abort codes, not module::constant references:
```move
// WRONG - won't compile in 2024 edition
#[expected_failure(abort_code = my_module::EInvalidInput)]

// CORRECT - use raw numeric value
#[expected_failure(abort_code = 0)]

// BETTER - add location for specificity
#[expected_failure(abort_code = 0, location = my_package::my_module)]
```

#### 4. Table with Non-Droppable Values
`Balance<T>` doesn't have `drop` ability:
```move
// WRONG - Balance doesn't have drop
let VoterRegistry { id, stakes } = registry;
table::drop(stakes); // Error: Balance doesn't satisfy drop constraint

// CORRECT - ensure table is empty first, then destroy
table::destroy_empty(stakes);
```

#### 5. Deprecated coin::create_currency
```move
// WARNING - deprecated but still works
let (treasury_cap, metadata) = coin::create_currency(...);

// Suppress warning if needed
#[allow(deprecated_usage)]
fun init(witness: MY_TOKEN, ctx: &mut TxContext) { ... }
```

### Testing Patterns

#### Centralized Test Utilities Module
Create a `test_utils.move` for shared test infrastructure:
```move
#[test_only]
module my_package::test_utils;

// Test addresses
const ADMIN: address = @0xAD;
const USER1: address = @0x01;
const USER2: address = @0x02;

public fun admin(): address { ADMIN }
public fun user1(): address { USER1 }

// Setup helpers
public fun begin(): Scenario { ts::begin(ADMIN) }

public fun create_test_coin(amount: u64, scenario: &mut Scenario): Coin<SUI> {
    coin::mint_for_testing<SUI>(amount, ts::ctx(scenario))
}

// Cleanup helpers
public fun destroy_coin<T>(coin: Coin<T>) {
    coin::burn_for_testing(coin);
}
```

#### Test-Only Functions for Object Lifecycle
Every struct should have test-only create/destroy functions:
```move
#[test_only]
public fun create_for_testing(ctx: &mut TxContext): MyStruct {
    MyStruct { id: object::new(ctx), ... }
}

#[test_only]
public fun destroy_for_testing(obj: MyStruct) {
    let MyStruct { id, field1: _, ... } = obj;
    object::delete(id);
}
```

### Design Patterns

#### Capability Pattern
Use capabilities for access control:
```move
public struct AdminCap has key, store { id: UID }
public struct MinterCap has key, store { id: UID, scope: String }

// Require capability as witness (underscore = unused but validates possession)
public fun admin_action(_: &AdminCap, ...) { ... }
```

#### Hot Potato Pattern
Enforce function call sequences with structs that lack `drop`:
```move
public struct Receipt { ... } // No drop ability!

public fun start_action(...): Receipt { Receipt { ... } }
public fun complete_action(receipt: Receipt) {
    let Receipt { ... } = receipt; // Must be consumed
}
```

#### Error Code Conventions
Use unique prefixes per module to identify error sources:
```move
// admin.move
const ENotAuthorized: u64 = 100;

// token.move
const EInsufficientBalance: u64 = 200;

// marketplace.move
const EListingNotFound: u64 = 500;
```

### Sui-Specific Patterns

#### Object Types
- **Owned objects**: Capabilities, receipts, user-specific data
- **Shared objects**: Registries, configs, global state (use `transfer::share_object`)
- **Immutable objects**: Metadata, frozen configs (use `transfer::public_freeze_object`)

#### Clock for Timestamps
```move
use sui::clock::Clock;

public fun my_function(clock: &Clock, ...) {
    let now = sui::clock::timestamp_ms(clock);
}
```

#### Address Serialization in Hashing
```move
use sui::bcs;
use sui::hash;

let mut data = vector::empty<u8>();
vector::append(&mut data, bcs::to_bytes(&voter_address));
let hash = hash::keccak256(&data);
```

### Build & Test Commands

```bash
# Build
sui move build

# Run all tests
sui move test

# Run specific test
sui move test --filter test_name

# Run with coverage
sui move test --coverage

# Publish to testnet
sui client publish --gas-budget 100000000
```

### Vite Dev Server Configuration

When developing Sui dApps with Vite, always configure the dev server to bind to `0.0.0.0` so the app is accessible over the network (VPN, remote access, mobile testing):

```typescript
// vite.config.mts
export default defineConfig({
  server: {
    host: "0.0.0.0",
  },
  // ...
});
```

This is required when accessing the dev server from a different machine or via VPN (e.g., Tailscale). Without it, Vite only binds to `localhost` and rejects external connections. Remember to access via `http://` (not `https://`) — Vite's dev server does not use TLS.

### Module Documentation Template

```move
/// Module: my_module
/// Brief description of what this module does.
module my_package::my_module;

// === Imports ===
use sui::object::{Self, UID};

// === Errors ===
const EInvalidInput: u64 = 0;

// === Constants ===
const MAX_VALUE: u64 = 1000;

// === Structs ===
public struct MyStruct has key, store { ... }

// === Events ===
public struct MyEvent has copy, drop { ... }

// === Init ===
fun init(ctx: &mut TxContext) { ... }

// === Public Functions ===

// === View Functions ===

// === Internal Functions ===

// === Test Functions ===
#[test_only]
public fun create_for_testing(...) { ... }
```

## Plan Mode Behavior

When in plan mode, actively use the AskUserQuestion tool to clarify requirements, validate assumptions, and present implementation choices before finalizing the plan. Do not write a complete plan without first gathering input through structured questions. Prefer interactive refinement over monologue-style planning.

## Claudefiles Repository Convention

### Overview

All shared Claude Code configuration lives in `~/workspace/claudefiles/`, a git repo symlinked into `~/.claude/`. This keeps skills, commands, global instructions, and settings version-controlled and portable across machines.

### Repository Path

```
~/workspace/claudefiles/
```

### What Lives in the Repo (Shared)

| Item | Repo path | Symlink |
|---|---|---|
| Global instructions | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Skills | `skills/` | `~/.claude/skills/` |
| Commands | `commands/` | `~/.claude/commands/` |
| Local settings | `settings.local.json` | `~/.claude/settings.local.json` |

### What Stays Local (Not Symlinked)

These are machine-specific, session-specific, or runtime data and must **not** be added to the repo:

- `cache/` — runtime cache
- `downloads/` — downloaded files
- `hooks/` — machine-specific hook scripts
- `plans/` — session-specific plan files
- `projects/` — per-project local overrides
- `settings.json` — machine-specific settings
- Other runtime directories and files

### The Rule

**Always create new skills, commands, and shared config inside `~/workspace/claudefiles/`.** Never write directly to `~/.claude/` for shared items — the symlinks ensure files written to `~/.claude/skills/`, `~/.claude/commands/`, etc. already land in the repo.

### Symlink Architecture

Only 4 symlinks are needed (the shared set is the minority):

```
~/.claude/CLAUDE.md          → ~/workspace/claudefiles/CLAUDE.md
~/.claude/commands/          → ~/workspace/claudefiles/commands/
~/.claude/skills/            → ~/workspace/claudefiles/skills/
~/.claude/settings.local.json → ~/workspace/claudefiles/settings.local.json
```

Everything else in `~/.claude/` is a real directory or file (17+ items). This is more efficient than the inverse approach (symlinking `~/.claude` itself to the repo and then symlinking each local item back out).

### Adding a New Shared Item

If a new top-level item needs to be shared (rare):

```bash
# 1. Move the item into the repo
mv ~/.claude/new-item ~/workspace/claudefiles/new-item

# 2. Create the symlink
ln -s ~/workspace/claudefiles/new-item ~/.claude/new-item

# 3. Commit
cd ~/workspace/claudefiles
git add new-item
git commit -m "Add new-item to shared config"
```
