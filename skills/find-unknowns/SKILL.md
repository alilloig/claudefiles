---
name: find-unknowns
description: |
  Guided "find your unknowns" loop for the fuzzy front-end of any project:
  brainstorming a fresh concept, defining a spec, scoping an MVP, or shaping a
  new feature. Diagnoses which kind of unknown the user is facing (unknown
  unknowns, unknown knowns, known unknowns) and runs the matching techniques
  from Anthropic's field guide — blind spot pass, divergent brainstorm +
  throwaway prototypes, one-question-at-a-time interview, reference mining,
  and a decisions-first implementation plan — ending with a spec + handoff
  prompt for a fresh implementation session.

  Use this skill whenever the user is STARTING something rather than building
  something already defined: "I want to build X but I'm not sure...", "help me
  spec/scope/define this", "let's brainstorm", "I have a rough idea", "new
  feature/MVP/PoC", "where should I start", "no sé por dónde empezar",
  "blind spot pass", "unknown unknowns", "interview me about this", or when
  their prompt describes a goal with obvious gaps (no success criteria, no
  constraints, unfamiliar domain). Also use when the user asks to plan a
  feature in a part of a codebase they admit they don't know.

  Do NOT use when the user already has a concrete spec/plan and wants it built
  (just build it, or use /lfg to ship), nor for a quick factual question about
  a technology.
---

# /find-unknowns — iterate the unknowns out of a fuzzy idea

The goal of this skill is NOT to produce code. It is to move knowledge between
quadrants until the user can write (or approve) a spec they actually believe:

| | **Known** | **Unknown** |
|---|---|---|
| **Knowns** | stated in the prompt | taste/criteria the user only recognizes on sight |
| **Unknowns** | questions the user can already ask | gaps the user can't see yet |

Every technique below targets one quadrant. Do not run them as a fixed
pipeline — diagnose first, pick the 2–3 that fit, and re-diagnose after each
round. Cheap discovery here is the whole point: a wrong assumption caught
during a throwaway prototype costs minutes; caught during implementation it
costs a rewrite.

## Step 0 — Diagnose and propose a route

Read the user's prompt and rate four things:

1. **Domain familiarity** — do they know this codebase area / technology /
   craft? Low familiarity → blind spot pass first.
2. **Criteria articulation** — can they say what "good" looks like, or is it
   "I'll know it when I see it"? The latter → brainstorm + prototypes.
3. **Ambiguity load** — how many decisions would change the architecture if
   answered differently? High → interview.
4. **Reference availability** — does something that behaves/looks right
   already exist? → reference mining beats any amount of description.

Then present a short "unknowns map" (2–4 bullets: what they clearly know, what
they clearly don't, what you suspect they haven't considered) and propose a
route. Use AskUserQuestion (multiSelect) to let them pick/confirm the
techniques — this is a hand-holding skill; the user chose it to be guided, so
show them the menu instead of silently deciding. If the session is
non-interactive, run your proposed route and say so.

Create `unknowns-notes.md` in the working directory now. Every technique below
appends to it: decisions made, options rejected (and why), open questions.
This file is the raw material for the final spec — without it, insights from
round 1 evaporate by round 3.

## Technique: Blind spot pass — for unknown unknowns

When the user is entering unfamiliar territory (new part of a codebase, a
craft they've never done, a domain with its own vocabulary).

1. Research first: explore the relevant code / docs / prior art yourself.
2. Teach, don't dump. Deliver a short brief covering exactly the four things
   a newcomer can't ask about:
   - the vocabulary and core concepts they'll need to even phrase requests
   - what "good" looks like in this domain (and what experts check first)
   - historical/prior work: what already exists here, what was tried
   - potholes: the classic mistakes and constraints that aren't obvious
3. Ship the brief as a self-contained HTML page following the
   `html-artifact` skill's conventions, and design it to be INVITING, not
   exhaustive: a ~5-minute read — hard cap 1,200 words in the main flow;
   count them before shipping and demote overflow to collapsible sections —
   led by one visual anchor (a mental-model remap table or a small diagram),
   scannable sections, real typographic hierarchy (few font sizes, strong
   contrast between levels). The brief
   competes with the user's reluctance to enter an unfamiliar domain —
   a wall of prose loses that fight even when its content is right. Depth
   that doesn't fit the 5 minutes goes into collapsible sections or
   `unknowns-notes.md`, not the main flow.
4. End the brief with **"how to prompt me better"** — 3–5 concrete prompt
   upgrades the user can now make because they know the terrain. This is the
   article's key move: the pass exists to improve every later interaction,
   not to make the user an expert.

## Technique: Brainstorm + throwaway prototypes — for unknown knowns

When criteria are "I'll know it when I see it" (visual design, UX flows,
naming, scope boundaries). Verbalizing these during prototyping is cheap;
discovering them during implementation is expensive, because small spec
changes cause drastically different implementations.

- **Divergent options, not one best guess.** Offer genuinely different
  directions (e.g. 4 wildly different design directions in one HTML page;
  10 intervention points ordered cheapest → most ambitious) so the user can
  react instead of describe.
- **Prototypes are disposable.** Single self-contained HTML file, fake data,
  zero wiring into the real app. Say so explicitly so nobody mistakes a mock
  for the start of the implementation. Build them with the `html-artifact`
  skill's conventions when they're substantial.
- **Borrow real design skill for design directions.** When the reaction
  target is visual (UI directions, layouts, themes) and a dedicated frontend
  design skill is available (`impeccable`, `frontend-design`), invoke it for
  the mock round instead of hand-rolling the CSS — the user reacts more
  honestly to options that look genuinely different and genuinely good, and
  AI-tell styling (side-tab accents, flat type hierarchy) pollutes the
  reaction.
- After each reaction round, record in `unknowns-notes.md` WHAT they reacted
  to and WHY ("rejected sidebar layout — too dense" is a criterion; "liked
  option 2" is not). Extracting the criterion is the deliverable.

## Technique: Interview — for known unknowns and hidden ambiguity

When brainstorming is done but decisions remain. Ask **one question at a
time** via AskUserQuestion, with concrete options plus your recommendation
first. Prioritize ruthlessly: questions where the answer would change the
architecture or data model come first; cosmetic questions may never be worth
asking. Stop when answers stop changing the spec — an interview that drifts
into trivia burns the user's patience for nothing. Log every answer as a
decision in `unknowns-notes.md`.

## Technique: Reference mining — when description fails

When the user can't articulate what they want but can point at something that
has it. Source code is the richest reference — richer than screenshots or
prose, even across languages. Ask for: a library/crate/folder that implements
the behavior, a component whose look they like, a doc or diagram. Read it,
extract the semantics or criteria into `unknowns-notes.md` in your own words,
and confirm your extraction with the user ("the thing you like about this is
X, Y — right?") before it enters the spec.

## Closing — spec, plan, handoff

When the route is exhausted (or the user says "enough"), produce:

1. **`spec.md`** — distilled from `unknowns-notes.md`, in this shape:
   - **Goal** — the problem being solved, one paragraph, user-visible terms.
   - **Success criteria** — observable, testable statements ("alert arrives
     within one polling interval of a state change"), not vibes ("bot works
     well"). A spec without these can't be verified by the implementing
     session and invites scope drift.
   - **Decisions** — each with the why kept from the notes; a decision whose
     rationale is lost gets silently re-litigated during implementation.
   - **Constraints & assumptions** — what the implementer must not change,
     and what was assumed without user confirmation (marked as such).
   - **Non-goals / rejected options** — with the reason for rejection, so
     they aren't accidentally rebuilt as "improvements".
   - **Open questions** — what remains genuinely undecided.
   Markdown, because its consumer is the next agent session, not a human
   reviewer.
2. **Implementation plan** (only if the user wants to proceed to build) — an
   HTML deliverable via the `html-artifact` skill, **leading with the
   decisions most likely to change**: data model, type interfaces, anything
   user-facing. Mechanical refactoring goes at the bottom. The ordering is
   the feature: the plan exists so the user reviews the 10% they might veto,
   not the 90% they trust you on.
3. **Handoff prompt** — a copy-pasteable prompt for a fresh session that
   passes in `spec.md` + any surviving prototype and includes, verbatim:

   > Keep an implementation-notes.md file. If you hit an edge case that
   > forces you to deviate from the plan, pick the conservative option, log
   > it under 'Deviations', and keep going.

   Explain in one line why the fresh session matters: clean context window,
   all the compiled knowledge, none of the exploration noise. The
   implementation-notes file closes the loop — its Deviations section is the
   input for the next /find-unknowns round.
