# Changelog

## [Unreleased]

## [0.1.9]

### Changed
- Removed the unused AceGUI and AceConfig libraries (smaller addon)
- Cleaned up code, test stubs, luacheck globals and docs; fixed two luacheck warnings

## [0.1.8]

### Changed
- Quiver tooltip: "Empty in (Ø)" replaces "Empty in (average)"

## [0.1.1] - [0.1.7]

### Added
- Addon icon and wordmark "A·M·O" in the addon list, options and TOC
- Addon Compartment entry with tooltip (logo, version, author)
- Options page rebuilt with Blizzard widgets: overview with logo, version and author, "General" page with sections
- Color system V1.0 (gold, hunter olive, ivory, black plus status colors), design guidelines and assets under `documentation`
- Chat line after a vendor refill ("Ammo refilled: ...", chat only)

### Changed
- Quiver tooltip: logo header and divider, counts colored by status, averages in the information color, item icons before ammo names, Ø symbol for averages
- Debug mode turns on automatically when BugLab is detected (debug switch removed)
- Refill popup renamed to `AMO_RESTOCK_AMMO`

### Fixed
- Error "Wrong object type for function" in the Addon Compartment tooltip

## [0.1.0]

### Added
- First version: ammo management for hunters (Glimpse: Classes), now a standalone addon
