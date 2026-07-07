## [7.0.0]

- **Breaking:** removed `error` parameter from `OnTapMatch` callback.
- Added `onError` callback to `TextSniffer` to handle errors thrown during `onTapMatch` execution.

## [6.0.0]

- **Breaking:** renamed `SnifferType` → `Sniffer`, `EmailSnifferType` →
  `EmailSniffer`, `LinkSnifferType` → `LinkSniffer`. Update your custom
  sniffer subclasses to extend `Sniffer` instead of `SnifferType`.
- **Breaking:** renamed widget parameter `snifferTypes` → `sniffers`.
- **Breaking:** each sniffer is now matched with its **own** regex instead
  of a single combined pattern. This preserves per-pattern flags (e.g.
  `caseSensitive: false`) and resolves overlapping matches by sniffer
  priority (order in the `sniffers` list).
- Added `entryResolver` callback — an alternative to positional
  `matchEntries` that resolves entries by matched text/type instead of
  index. Robust when the text or match count changes.
- Added `mouseCursor: SystemMouseCursors.click` on matched spans for
  web/desktop.
- Example: added `book_excerpt_example.dart` — an annotated book reader
  demonstrating `entryResolver` with character names and glossary terms
  (Alice in Wonderland excerpt).

## [5.0.2]

- Fixed: changing `snifferTypes` without changing `text` now correctly
  re-parses. Previously the widget compared the old sniffer signature against
  itself, so pattern/type changes on an existing `TextSniffer` were ignored
  until the text also changed.
- Tests: reached 100% line coverage (added coverage for `matchBuilder`,
  `snifferTypes` re-parsing, `LinkSnifferType`, `SnifferType.toString`, and the
  deprecated `textScaleFactor` getter).
- Chore: added CI (analyze, format, tests with enforced 100% coverage,
  publish-on-release) and switched the license to MIT.

## [5.0.1]

- Docs: documented `onTapMatch`/`matchEntries` behavior (entry is optional and
  per-match; `index` is global across all matches; `error` is reserved).
- Docs: added a "Large Texts (books, articles)" guide — chunk long text with
  `ListView.builder` instead of one big `TextSniffer`.
- Example: added `long_text_example.dart` (lazy `ListView.builder` demo) plus a
  toolbar button to open it; switched example logging to `debugPrint`.
- Tests: added widget tests covering parsing, tap handling and re-parsing.

## [5.0.0]

- **Breaking:** removed `NoMatchEntryFoundException`. Tapping a match no longer
  throws when `matchEntries` is empty or shorter than the number of matches —
  `onTapMatch` is now always called with `match: null` and `error: null` in that
  case. `matchEntries` is fully optional and per-match.
- Fixed: case-insensitive matching is now preserved (regex flags were lost via
  the internal regex cache, breaking uppercase emails/links).
- Fixed: tap callbacks no longer reuse a wrong `index` when the same text is
  matched more than once (matched spans are no longer cached by text).
- Fixed: `sniffersTypes` with a `null`/empty pattern no longer produce an empty
  regex alternative that matched every position.
- Perf: matches are materialized once instead of rebuilding the list per match.
- Fixed: `TapGestureRecognizer`s created per match are now disposed (previously
  leaked on every rebuild). `TextSniffer` is now a `StatefulWidget`.
- Perf: text is parsed (regex run) only when `text` or `sniffers` change,
  not on every rebuild — important for large texts.
- Non-matching text now defaults to `DefaultTextStyle` (theme/dark-mode aware)
  instead of hard-coded black.

## [4.4.4]

- Added the ability to create your own sniffer types.
- Updated documentation

## [3.4.0]

- Improved documentation with detailed examples for `onTapMatch` and styling matches.
- Enhanced README with usage instructions and examples for better developer experience.

## [3.3.0]

- New: Added support for enhanced matching logic with optional entries.

- Added `overflow` property

- Introduced `searchTypes` to refine search for specific patterns (e.g., phone, email, link, custom).

- Optimized `onTapMatch` callback handling for better interaction with matched text.

## [2.2.0]

- fixed: `maxLines` and regular expression for multiple groups

## [1.2.0]

- fixed: `matchEntry` now is nullable because `matchEntries` can be empty

## [1.1.0]

- Fixed `maxLines`

## [1.0.0]

- Created package
