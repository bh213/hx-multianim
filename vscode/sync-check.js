#!/usr/bin/env node
/**
 * sync-check.js — Compares keywords between the hx-multianim parser and the
 * VS Code syntax grammar to find mismatches.
 *
 * Usage:
 *   node sync-check.js                         # default paths (sibling repos)
 *   node sync-check.js <parserDir> <grammarFile>
 *
 * Extracts:
 *   - isKeyword(s, "...") calls from MacroManimParser.hx
 *   - case "..." string-match properties from MacroManimParser.hx
 *   - All keyword patterns from multianim.tmLanguage.json
 *
 * Reports keywords present in one but not the other.
 */

const fs = require("fs");
const path = require("path");

// --- Paths ---

const defaultParserPath = path.resolve(
  __dirname,
  "../src/bh/multianim/MacroManimParser.hx"
);
const defaultGrammarPath = path.resolve(
  __dirname,
  "syntaxes/multianim.tmLanguage.json"
);

const parserPath = process.argv[2] || defaultParserPath;
const grammarPath = process.argv[3] || defaultGrammarPath;

// --- Extract parser keywords ---

function extractParserKeywords(filePath) {
  const src = fs.readFileSync(filePath, "utf-8");

  const keywords = new Set();

  // 1) isKeyword(s, "keyword") or isKeyword(s2, "keyword")
  const isKeywordRe = /isKeyword\(\w+,\s*"(\w+)"\)/g;
  for (const m of src.matchAll(isKeywordRe)) {
    keywords.add(m[1].toLowerCase());
  }

  // 2) case "keyword": (string-matched properties in flow, particles, etc.)
  //    These are lowercase identifiers matched via switch on .toLowerCase()
  const caseStringRe = /case\s+"(\w+)"(?:\s*\|)?/g;
  for (const m of src.matchAll(caseStringRe)) {
    const kw = m[1].toLowerCase();
    // Skip pure numeric values and single chars
    if (/^\d+$/.test(kw) || kw.length <= 1) continue;
    keywords.add(kw);
  }

  return keywords;
}

// --- Extract grammar keywords ---

function extractGrammarKeywords(filePath) {
  const grammar = JSON.parse(fs.readFileSync(filePath, "utf-8"));
  const keywords = new Set();

  function extractFromPattern(pattern) {
    // 1) \b(word1|word2|...)\b alternation groups
    const alternationRe = /\\b\(([^)]+)\)\\b/g;
    for (const m of pattern.matchAll(alternationRe)) {
      for (const word of m[1].split("|")) {
        keywords.add(word.toLowerCase());
      }
    }

    // 2) \bsingleWord\b standalone word boundaries
    const singleWordRe = /\\b([A-Za-z]\w*)\\b/g;
    for (const m of pattern.matchAll(singleWordRe)) {
      keywords.add(m[1].toLowerCase());
    }

    // 3) @(word1|word2|...)\b directive patterns
    const atRe = /@\(([^)]+)\)\\b/g;
    for (const m of pattern.matchAll(atRe)) {
      for (const word of m[1].split("|")) {
        keywords.add(word.toLowerCase());
      }
    }

    // 4) (@word1|@word2|...) conditional begin patterns — strip leading @
    const atCondRe = /\((@\w+(?:\|@\w+)*)/g;
    for (const m of pattern.matchAll(atCondRe)) {
      for (const word of m[1].split("|")) {
        keywords.add(word.replace(/^@/, "").toLowerCase());
      }
    }
  }

  function walk(obj) {
    if (!obj || typeof obj !== "object") return;

    if (typeof obj.match === "string") {
      extractFromPattern(obj.match);
    }
    if (typeof obj.begin === "string") {
      extractFromPattern(obj.begin);
    }

    if (Array.isArray(obj)) {
      obj.forEach(walk);
    } else {
      Object.values(obj).forEach(walk);
    }
  }

  walk(grammar);
  return keywords;
}

// --- Categorize parser keywords ---
// Some keywords are internal parser artifacts, not language-level tokens.
// We skip those to reduce noise.

const PARSER_INTERNAL = new Set([
  // Booleans — handled in grammar as constant.language
  "true",
  "false",
  "yes",
  "no",
  "null",
  // Color names — handled in grammar as support.constant.color
  "maroon",
  "red",
  "orange",
  "yellow",
  "olive",
  "green",
  "lime",
  "purple",
  "fuchsia",
  "teal",
  "cyan",
  "aqua",
  "blue",
  "navy",
  "black",
  "gray",
  "silver",
  "white",
  "brown",
  "coral",
  "crimson",
  "darkgray",
  "forestgreen",
  "gold",
  "indigo",
  "lightgray",
  "skyblue",
  "slate",
  "tomato",
  "wheat",
  // Blend modes — handled in grammar as keyword.other.blendmode
  "none",
  "alpha",
  "add",
  "alphaadd",
  "softadd",
  "multiply",
  "alphamultiply",
  "erase",
  "screen",
  "sub",
  "max",
  "min",
  // Easing functions — handled in grammar as support.constant.easing
  "linear",
  "easeinquad",
  "easeoutquad",
  "easeinoutquad",
  "easeincubic",
  "easeoutcubic",
  "easeinoutcubic",
  "easeinback",
  "easeoutback",
  "easeinoutback",
  "easeoutbounce",
  "easeoutelastic",
  "cubicbezier",
  // Filter keywords — handled in grammar as support.function.filter
  "outline",
  "glow",
  "blur",
  "saturate",
  "brightness",
  "dropshadow",
  "replacepalette",
  "replacecolor",
  "pixeloutline",
  "group",
  "grayscale",
  "hue",
  // Type keywords — handled in grammar as entity.name.type
  "int",
  "uint",
  "float",
  "flags",
  "string",
  "hexdirection",
  "griddirection",
  "bool",
  "color",
  "array",
  "record",
  // Operator — handled in grammar as keyword.operator.div
  "div",
  // Conditionals — handled in grammar via @if/@ifStrict/@else/@default patterns
  "if",
  "ifstrict",
  "else",
  "default",
  // Aliases — alternate spellings of keywords already in grammar
  "animated_path", // alias for animatedPath
  "animatedpath",  // alias for animatedPath
]);

// Keywords that exist in the grammar under a dedicated scope (colors, blend
// modes, easings, booleans) and don't need to also appear in the generic
// keyword lists. We still collect them from the grammar but mark them so
// we only flag truly missing ones.
// Grammar keywords that exist under dedicated scopes and should not be
// flagged as "stale" when they don't appear in the parser's isKeyword/case
// lists (they may match via different mechanisms or are grammar-only extras).
const GRAMMAR_DEDICATED = new Set([
  // Colors — support.constant.color (grammar may have extras like grey, pink)
  "maroon", "red", "orange", "yellow", "olive", "green", "lime",
  "purple", "fuchsia", "teal", "cyan", "aqua", "blue", "navy",
  "black", "gray", "grey", "silver", "white", "transparent",
  "magenta", "pink", "brown", "coral", "crimson", "darkgray",
  "forestgreen", "gold", "indigo", "lightgray", "skyblue",
  "slate", "tomato", "wheat",
  // Booleans — constant.language
  "true", "false", "yes", "no", "null", "nothing",
  // Blend modes — keyword.other.blendmode
  "none", "alpha", "add", "alphaadd", "softadd", "multiply",
  "alphamultiply", "erase", "screen", "sub", "max", "min", "normal",
  // Easings — support.constant.easing
  "linear", "easeinquad", "easeoutquad", "easeinoutquad",
  "easeincubic", "easeoutcubic", "easeinoutcubic",
  "easeinback", "easeoutback", "easeinoutback",
  "easeoutbounce", "easeoutelastic", "cubicbezier",
  // Filters — support.function.filter
  "outline", "glow", "blur", "saturate", "brightness", "dropshadow",
  "replacepalette", "replacecolor", "pixeloutline", "group",
  "grayscale", "hue",
  // Types — entity.name.type
  "int", "uint", "float", "flags", "string", "hexdirection",
  "griddirection", "bool", "color", "array", "record",
  // Operators
  "div",
  // Conditionals — matched via @-prefix patterns, not \b...\b
  "if", "ifstrict", "else", "default",
  // Regex artifacts — extracted from patterns but not real keywords
  "za", // from [A-Za-z] character class in regex
]);

// --- Main ---

console.log("=== hx-multianim keyword sync check ===\n");
console.log(`Parser:  ${parserPath}`);
console.log(`Grammar: ${grammarPath}\n`);

if (!fs.existsSync(parserPath)) {
  console.error(`ERROR: Parser file not found: ${parserPath}`);
  process.exit(1);
}
if (!fs.existsSync(grammarPath)) {
  console.error(`ERROR: Grammar file not found: ${grammarPath}`);
  process.exit(1);
}

const parserKw = extractParserKeywords(parserPath);
const grammarKw = extractGrammarKeywords(grammarPath);

// Keywords in parser but NOT in grammar (likely need adding to grammar)
const missingFromGrammar = [];
for (const kw of parserKw) {
  if (PARSER_INTERNAL.has(kw)) continue;
  if (!grammarKw.has(kw)) {
    missingFromGrammar.push(kw);
  }
}

// Keywords in grammar but NOT in parser (possibly stale / renamed)
const missingFromParser = [];
for (const kw of grammarKw) {
  if (GRAMMAR_DEDICATED.has(kw)) continue;
  if (!parserKw.has(kw)) {
    missingFromParser.push(kw);
  }
}

missingFromGrammar.sort();
missingFromParser.sort();

let exitCode = 0;

if (missingFromGrammar.length > 0) {
  exitCode = 1;
  console.log(
    `MISSING from grammar (${missingFromGrammar.length} keywords in parser but not highlighted):`
  );
  for (const kw of missingFromGrammar) {
    console.log(`  + ${kw}`);
  }
  console.log();
} else {
  console.log("Grammar has all parser keywords. OK\n");
}

if (missingFromParser.length > 0) {
  exitCode = 1;
  console.log(
    `POSSIBLY STALE in grammar (${missingFromParser.length} keywords in grammar but not in parser):`
  );
  for (const kw of missingFromParser) {
    console.log(`  - ${kw}`);
  }
  console.log();
} else {
  console.log("No stale grammar keywords found. OK\n");
}

// Summary
console.log("---");
console.log(`Parser keywords:  ${parserKw.size}`);
console.log(`Grammar keywords: ${grammarKw.size}`);
console.log(
  `Missing from grammar: ${missingFromGrammar.length}  |  Possibly stale: ${missingFromParser.length}`
);

if (exitCode === 0) {
  console.log("\nAll in sync!");
}

process.exit(exitCode);
