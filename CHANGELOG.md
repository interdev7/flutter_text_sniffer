## [5.0.0]

* **Breaking:** removed `NoMatchEntryFoundException`. Tapping a match no longer
  throws when `matchEntries` is empty or shorter than the number of matches —
  `onTapMatch` is now always called with `match: null` and `error: null` in that
  case. `matchEntries` is fully optional and per-match.
* Fixed: case-insensitive matching is now preserved (regex flags were lost via
  the internal regex cache, breaking uppercase emails/links).
* Fixed: tap callbacks no longer reuse a wrong `index` when the same text is
  matched more than once (matched spans are no longer cached by text).
* Fixed: `snifferTypes` with a `null`/empty pattern no longer produce an empty
  regex alternative that matched every position.
* Perf: matches are materialized once instead of rebuilding the list per match.

## [1.0.0]

* Created package

## [1.1.0]

* Fixed `maxLines`

## [1.2.0]

* fixed: `matchEntry` now is nullable because `matchEntries` can be empty

## [2.2.0]

* fixed: `maxLines` and regular expression for multiple groups

## [3.3.0]

* New: Added support for enhanced matching logic with optional entries.

* Added `overflow` property

* Introduced `searchTypes` to refine search for specific patterns (e.g., phone, email, link, custom).

* Optimized `onTapMatch` callback handling for better interaction with matched text.

## [3.4.0]

* Improved documentation with detailed examples for `onTapMatch` and styling matches.
* Enhanced README with usage instructions and examples for better developer experience.

## [4.4.4]

* Added the ability to create your own sniffer types.
* Updated documentation
