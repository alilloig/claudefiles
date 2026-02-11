---
name: sui-move-tip
description: |
  Creates Sui Move Tips — concise, punchy technical summaries of Move/Sui features
  for sharing on Slack. Use this skill whenever the user mentions "move tip", "sui tip",
  wants to summarize a Move feature for their team, or wants to turn Sui documentation
  into a developer-friendly quick read. Also trigger when the user pastes Sui/Move
  documentation and asks for a summary or write-up aimed at developers.
allowed-tools: Read, Write, Glob, Grep, Edit, AskUserQuestion
---

# Move Tip Creator

## What is a Move Tip?

Move Tips are short, opinionated technical summaries of Sui Move features posted to Slack. They help developers quickly understand what a feature does, why it matters, and how to use it — with just enough code to make it concrete.

The audience is Sui Move developers who are already familiar with the ecosystem but may not know about a specific feature yet.

## Tip Types

Not all tips are the same. Based on 30 published Move Tips, there are five recurring structures. The first step when creating a tip is identifying which type fits the material.

### Type A — Discovery ("Did you know this exists?")

Short tips that surface an overlooked tool, CLI flag, directory, or configuration option. Minimal code, mostly prose. The value is pure awareness.

**Rhythm**: Hook → what it is → how to use it (1-2 commands or snippets) → why it's useful.

**Examples**: #1 (Move `examples/` directory), #8 (Profile Transaction Costs), #10 (Run Specific Tests), #15 (`--json` flag), #24 (Sui Limits).

### Type B — Best Practice ("Do this, not that")

Tips that contrast a common but suboptimal pattern with a better alternative. The before/after code contrast is the centerpiece. The feature already exists — the tip is about using it *well*.

**Rhythm**: Hook → "Instead of this" (code) → "Do this" (code) → why it's better (1-2 sentences).

**Examples**: #9 (Struct keys for df/dof), #13 (Hot potatoes with metadata), #14 (Skip cleanup in expected-failure tests), #21 (Macros for performance).

### Type C — Concept Explainer ("Here's how X works")

Tips that unpack a language feature, often with edge cases, gotchas, or exercises. The goal is to build the reader's mental model of something they use (or avoid) without fully understanding.

**Rhythm**: Hook → core concept (with code) → nuance/edge cases → gotchas or exercises.

**Examples**: #4 (`#[expected_failure]`), #5 (Enum Missing Variants), #6 (Struct Destructuring), #11 (Positional Structs), #16 (Generics with Conditional Abilities), #19 (Recursive Generics), #23 (Dereferencing).

### Type D — Design Pattern ("Here's an architectural approach")

Tips that teach a reusable pattern for structuring Move code. Heavier on motivation and design rationale. Code illustrates the pattern but isn't the main point.

**Rhythm**: Hook → motivation (why you need this) → the pattern (code + explanation) → key benefits → optional: variations or caveats.

**Examples**: #7 (Versioning Shared Objects), #12 (Decoupling Creation and Sharing), #17 (Module size), #18 (Proof Struct Authorization), #20 (Start Modular), #27 (Mailbox Pattern), #28 (Derived Capability), #29 (Object-as-Actor).

### Type E — New Feature ("Problem → Solution")

Tips that introduce a new Sui/Move capability by contrasting the old pain with the new approach. This is the classic before/after structure.

**Rhythm**: Hook → the problem (old way + pain) → the solution (new way + mental model) → key insight → practical details.

**Examples**: #22 (Display for Every Object), #25 (Party Objects), #26 (Sui Prover), #30 (Address Balances).

## Common Elements (All Types)

Regardless of type, every Move Tip shares these elements:

### 1. Hook (title + opening line)

The title is `# Move Tip #N: [Feature Name]`. The opening line is a "Did you know..." question, a punchy statement, or a direct challenge that makes the reader curious. It should capture the single most interesting thing about the topic.

### 2. Code

Every tip has at least one code snippet. Code is for illustration, not copy-paste. Snippets should be short, use inline comments generously, and highlight the pattern. Full working examples belong in docs.

### 3. The Takeaway

Every tip leaves the reader with something: a mental model shift, a practical command to try, a pattern to adopt, or a gotcha to avoid. This can be explicit (a bold "Key Insight" section) or implicit (the structure itself makes the point).

### 4. References (optional)

Links to docs, SIPs, GitHub repos, or design documents. Only if they add value.

## Writing Style

The voice is collegial and direct — one senior dev explaining something to another over coffee. Specific guidelines:

- **Concise over comprehensive.** A Move Tip is not documentation. It's the thing that makes someone go read the documentation. If a section is getting long, it probably belongs in a separate tip.
- **Concrete over abstract.** Use names like Alice and Bob, specific token types like SUI and USDC, real numbers. "Alice holds SUI and USDC? Two entries." beats "Each owner-type pair maps to a single entry."
- **Before/after contrast** (when applicable). The reader should immediately see why the new thing is better. Inline code comments are great for this. Not every tip has a "before" — don't force it.
- **Code is for illustration, not copy-paste.** Snippets should be short and highlight the pattern. Full working examples belong in docs.
- **No filler.** No "In this tip, we'll explore..." or "Let's dive into...". Start with the hook, end when you're done.
- **Introduce concepts before naming them.** When a feature has unfamiliar terminology (like "scheduler" or "settlement"), explain what it does first, then name it. Bold the term on first use.
- **Explain the "why" behind the "how".** Don't just say what something does — say why it was designed that way. "Deposits are easy — you're only adding. Withdrawals are the hard part" is more useful than "The system uses a scheduler for withdrawals."
- **Emojis are fine, sparingly.** Some tips use them effectively for visual landmarks (⚠, ✅, 🚫, 💡). Don't overdo it — one or two per section max.
- **Tease the next tip.** If the feature has depth that warrants a follow-up, end with a forward reference: "More on the scheduler and settlement pipeline in Move Tip #31."

## Process

**IMPORTANT**: This skill is collaborative. Use the `AskUserQuestion` tool at every decision point below — do NOT guess the user's intent or silently make choices. The user knows the audience and has strong opinions on framing, tone, and technical accuracy.

### Step 1: Read the source material

The user will provide documentation about the Move feature — this could be a SIP, internal docs, code comments, pasted text, or just a topic name. Read it carefully and identify:

- What is this about? (feature, pattern, tool, best practice, gotcha?)
- What's the developer-facing API or usage?
- What's the key mental model shift or "aha" moment?
- What are the practical implications (gas, compatibility, concurrency)?

### Step 2: Clarify scope, type, and angle

Before writing anything, use `AskUserQuestion` to align with the user on:

- **Tip number**: What number should this tip be?
- **Tip type**: Which of the five types (A-E) fits best? Present your recommendation with reasoning, but let the user decide. Use the options format:
  - "Discovery — short awareness tip"
  - "Best Practice — do this, not that"
  - "Concept Explainer — how X works"
  - "Design Pattern — architectural approach"
  - "New Feature — problem → solution"
- **Angle**: What's the single most interesting thing about this topic? Propose 2-3 candidate hooks and let the user pick.
- **Audience assumptions**: What can we assume the reader already knows? Is there prerequisite context from a previous tip?

### Step 3: Draft the tip

Write the full tip following the rhythm for the chosen type. Aim for something that fits comfortably in a Slack message — roughly 150-500 words including code snippets (Type A tips can be much shorter than Type D or E tips). If it's getting longer, consider splitting.

### Step 4: Iterate with the user

After presenting the draft, use `AskUserQuestion` to gather structured feedback. Don't just ask "what do you think?" — ask about specific aspects relevant to the tip type:

**For all types:**
- **Hook**: "Does the opening line land? Should I try a different angle?"
- **Code examples**: "Are these snippets idiomatic? Should I use different types/names?"
- **Sections**: "Any sections that feel unnecessary or missing?"
- **Tone/length**: "Too much detail? Too little? Right level for your team?"

**Type-specific questions:**
- **Type B**: "Is the 'don't do this' example realistic? Is this a pain your team actually hits?"
- **Type C**: "Are the edge cases/exercises useful or do they clutter the tip?"
- **Type D**: "Is the motivation clear? Would the reader understand *why* they'd adopt this pattern?"
- **Type E**: "Is the problem framing accurate? Is there a more common pain point?"

Expect 2-4 rounds. Common refinements include tightening prose, adjusting contrasts, adding or removing sections, and fixing technical accuracy. Use `AskUserQuestion` each round to keep feedback structured rather than open-ended.

### Step 5: Output as markdown

Once the user approves, save the final tip as a markdown file in the outputs folder. The user will copy it to Slack from there.

## Reference Examples

### Type B Example: Move Tip #9

```markdown
# Move Tip #9: Use Struct Instead of String at df & dof

Use a struct wrapper instead of raw strings when adding to df & dof

✅ Do this:

\`\`\`move
public struct TreasuryCapKey() has copy, drop, store;
public struct TokenPolicyCapKey() has copy, drop, store;

dof::add(&mut protected_treasury.id, TreasuryCapKey(), treasury_cap);
dof::add(&mut protected_treasury.id, TokenPolicyCapKey(), token_policy_cap);
\`\`\`

🚫 Instead of this:

\`\`\`move
dof::add(&mut protected_treasury.id, TREASURY_CAP_KEY.to_string(), treasury_cap);
dof::add(&mut protected_treasury.id, TOKEN_POLICY_CAP_KEY.to_string(), token_policy_cap);
\`\`\`

❔Why this is safer: Even though the UID is protected, wrapping keys in dedicated structs adds an extra layer of safety. Anyone can construct a String, but not everyone can create instances of TreasuryCapKey or CapabilityKey, preventing misuse and improving access control.

🛡 Strong types, fewer surprises
```

### Type D Example: Move Tip #28

```markdown
# Move Tip #28: Derived Capability

The capability pattern is great—no address assertions, transferable between wallets. But two things are annoying:

- The client needs extra RPC calls to find the user's capability object
- Nothing stops a user from holding multiple

Derived objects to the rescue!

\`\`\`move
fun new_account(registry: &mut AccountRegistry, data: bool, owner: address): Account {
    let id = derived_object::claim(&mut registry.id, owner);
    Account { id, data }
}
\`\`\`

The ID is derived from the registry + owner address. This means:

- The frontend can compute the object ID directly—no fishing through getOwnedObjects
- If a user tries to claim a second one, derived_object::claim aborts
- No Table<address, ID> bookkeeping needed

Key insight: The capability only has `key`, not `store`. This prevents arbitrary transfers via `public_transfer`.

Can we still transfer them? Yes we can! By destroying and recreating:

\`\`\`move
public fun transfer(self: Account, registry: &mut AccountRegistry, recipient: address) {
    let Account { id, data } = self;
    id.delete();
    transfer::transfer(new_account(registry, data, recipient), recipient);
}
\`\`\`

The recipient gets a fresh capability derived from their address. If they already have one? Abort. Single-instance guarantee preserved.
```

### Type E Example: Move Tip #22

```markdown
# Move Tip #22: Display for Every Object

Why add Display to all Objects?

Display is often set only for PFPs, in-game items, or marketplace traded NFTs. But capability objects, system objects, and even shared objects also benefit — without it, wallets and explorers show rows of "No media," hurting clarity and UX.

## How to Enrich Objects

Attach fields like `image_url`, `name`, `description`, and `link` to every object. Even technical resources become easier to identify and richer in context.

No image host? Wallets and explorers support SVG data URLs. Just URL-encode your SVG and pass it directly from Move code or PTB.

\`\`\`move
display.add(
    b"image_url".to_string(),
    b"data:image/svg+xml;utf8,...".to_string(),
);
\`\`\`

## DeFi in Action

Some Sui DeFi protocols apply Display to position objects, generating images that update dynamically with on-chain fields like collateral, debt ratio, or yield. This turns abstract numbers into clear, visual dashboards.

## Benefits

- **Better UX**: Objects become visually distinct and approachable
- **Consistency**: Unified visual language across all object types
- **Dynamic Insight**: On-chain data drives live visuals
- **No Hosting Hassle**: SVG data URLs keep everything self-contained

Safe and beautiful Move development all the way!
```
