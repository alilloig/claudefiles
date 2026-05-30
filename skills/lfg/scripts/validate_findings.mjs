#!/usr/bin/env node
// Validates an lfg reviewer findings file. Exit 0 = valid, 1 = invalid, 2 = usage.
import { readFileSync } from "node:fs";

const SEVERITIES = ["critical", "high", "medium", "low", "info"];
const ID_RE = /^[A-Z]+-[0-9]+$/;

function fail(msg) { console.error(`INVALID: ${msg}`); process.exit(1); }

const path = process.argv[2];
if (!path) { console.error("usage: validate_findings.mjs <file.json>"); process.exit(2); }

let doc;
try { doc = JSON.parse(readFileSync(path, "utf8")); }
catch (e) { fail(`not parseable JSON: ${e.message}`); }

if (typeof doc !== "object" || doc === null) fail("top-level must be an object");
for (const k of ["reviewer", "agent_type"]) {
  if (typeof doc[k] !== "string" || doc[k].length === 0) fail(`${k} must be a non-empty string`);
}
if (!Array.isArray(doc.findings)) fail("findings must be an array");

doc.findings.forEach((f, i) => {
  const at = `findings[${i}]`;
  if (!ID_RE.test(f.id ?? "")) fail(`${at}.id must match ${ID_RE}`);
  if (typeof f.dimension !== "string" || !f.dimension) fail(`${at}.dimension required`);
  if (!SEVERITIES.includes(f.severity)) fail(`${at}.severity must be one of ${SEVERITIES.join(", ")}`);
  if (typeof f.file !== "string" || !f.file) fail(`${at}.file required`);
  if (f.line != null && !Number.isInteger(f.line)) fail(`${at}.line must be integer or null`);
  if (typeof f.title !== "string" || !f.title) fail(`${at}.title required`);
  if (typeof f.detail !== "string" || !f.detail) fail(`${at}.detail required`);
  if (f.suggestion != null && typeof f.suggestion !== "string") fail(`${at}.suggestion must be string or null`);
  if (!Number.isInteger(f.confidence) || f.confidence < 0 || f.confidence > 100) fail(`${at}.confidence must be 0..100`);
});

console.log(`VALID: ${doc.findings.length} finding(s) from reviewer "${doc.reviewer}"`);
process.exit(0);
