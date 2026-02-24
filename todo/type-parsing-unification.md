# Type Parsing Unification

## Problem

There are 4 separate locations in MacroManimParser.hx that parse `key:type` or `key:type=>value` patterns, each with their own type dispatch and output structures.

## Current Locations

### 1. `parseDefine()` (line ~1499) — Programmable & Slot Parameters
- Syntax: `name:type=default`
- **14 types:** int, uint, float, bool, string, color, tile, array, flags(N), [enum], N..M range, hexdirection, griddirection
- Output: `DefinitionType` enum + `ResolvedIndexParameters`
- Values are **static** (no $ref, no expressions)

### 2. `parseMetadataValue()` (line ~3954) — Interactive Metadata
- Syntax: `key:type=>value`
- **5 types:** int, float, string, color, bool
- Output: `SettingValueType` enum + `ReferenceableValue`
- Values can be **expressions** ($ref, ternary, arithmetic, callbacks)
- Keys can also be `$references`
- Special: `events: [hover, click, push]` bitflag syntax

### 3. Settings Block (line ~3268) — Node Settings
- Syntax: `key:type=>value`
- **5 types:** int, float, string, color, bool
- Output: `SettingValueType` enum + `ReferenceableValue`
- Values can be **expressions** (same as interactive)
- Untyped `key=>value` **infers type** from parsed value (RVInteger→int, RVFloat→float, else string)
- Supports dotted keys (`item.fontColor`)

### 4. `parseDataType()` (line ~5344) — Data Block Fields
- Syntax: `name: type`
- **5 types:** int, float, string, bool, recordName + type[] arrays
- Output: `DataValueType` enum
- Completely separate type system with record types and arrays

## Comparison Matrix

| Feature           | Programmable | Interactive | Settings | Data |
|-------------------|:---:|:---:|:---:|:---:|
| int               | PPTInt | SVTInt | SVTInt | DVTInt |
| uint              | PPTUnsignedInt | - | - | - |
| float             | PPTFloat | SVTFloat | SVTFloat | DVTFloat |
| bool              | PPTBool | SVTBool | SVTBool | DVTBool |
| string            | PPTString | SVTString | SVTString | DVTString |
| color             | PPTColor | SVTColor | SVTColor | - |
| tile              | PPTTile | - | - | - |
| array             | PPTArray | - | - | DVTArray |
| flags(N)          | PPTFlags | - | - | - |
| [enum]            | PPTEnum | - | - | - |
| N..M range        | PPTRange | - | - | - |
| hexdirection      | PPTHexDirection | - | - | - |
| griddirection     | PPTGridDirection | - | - | - |
| record            | - | - | - | DVTRecord |
| $ref values       | No | Yes | Yes | No |
| $ref keys         | No | Yes | No | No |
| Expressions       | No | Yes | Yes | No |
| Type inference     | No | No (defaults to string) | Yes (int/float/string) | Yes (from value) |
| Dotted keys       | No | No | Yes | No |

## Proposed Changes

### 1. Merge Interactive + Settings type dispatch (easy win)

Extract shared function — eliminates ~20 lines of duplicated switch/case:

```haxe
function parseTypedSettingValue():{ type:SettingValueType, value:ReferenceableValue } {
    final typeName = expectIdentifierOrString();
    expect(TArrow);
    return switch (typeName.toLowerCase()) {
        case "int":    { type: SVTInt,    value: parseIntegerOrReference() };
        case "float":  { type: SVTFloat,  value: parseFloatOrReference() };
        case "string": { type: SVTString, value: parseStringOrReference() };
        case "color":  { type: SVTColor,  value: parseColorOrReference() };
        case "bool":   { type: SVTBool,   value: parseBoolOrReference() };
        default: error('expected int, float, string, color, or bool after : in typed value');
    };
}
```

Both `parseMetadataValue()` and the settings block call this after matching `TColon`.

### 2. Unify type inference for untyped `=>` (trivial)

Settings infers type from value, interactive always defaults to string. Add same inference to interactive so `price => 100` becomes SVTInt, not SVTString.

### 3. Don't merge with Programmable (not recommended)

Fundamentally different semantics: declaration-time definitions with static defaults vs expression-bearing key-value pairs. Different output types, different separator (`=` vs `=>`), 14 vs 5 types. Merging would create a complex superset without real benefit.

### 4. Don't merge with Data (not recommended)

Has record types and array composition (`type[]`) that don't exist elsewhere. Different domain (structured data schema vs visual parameters).

## Status
- [ ] Extract shared `parseTypedSettingValue()` function
- [ ] Unify type inference for untyped `=>`
